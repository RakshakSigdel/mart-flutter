import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../controllers/inventory_category_detail_controller.dart';
import '../widgets/inventory_categories_confirm_dialog.dart';
import '../widgets/inventory_category_add_unit_dialog.dart';
import '../widgets/inventory_category_thumbnail.dart';
import '../widgets/inventory_category_unit_section.dart';

/// One category's detail page: its record, product count, and the
/// purchase/selling unit policy — the one thing the plain categories list
/// deliberately leaves out (see `InventoryCategoryModel`'s doc comment).
///
/// Full page rather than a dialog/expansion, same reasoning as the add/edit
/// forms: there's a whole policy-editing UI here, not a few fields.
class InventoryCategoryDetailScreen extends ConsumerWidget {
  const InventoryCategoryDetailScreen({super.key, required this.categoryId});

  final int categoryId;

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    InventoryCategoryDetailModel category,
  ) async {
    final result = await context.push<bool>(
      Routes.inventoryCategoryEdit(categoryId),
      extra: category.summary,
    );
    if (result == true) {
      if (context.mounted) AppSnackBar.success(context, 'Category updated.');
      ref
          .read(inventoryCategoryDetailControllerProvider(categoryId).notifier)
          .refresh();
    }
  }

  Future<void> _addUnit(
    BuildContext context,
    WidgetRef ref,
    CategoryUnitUsage usage,
  ) async {
    final notifier = ref.read(
      inventoryCategoryDetailControllerProvider(categoryId).notifier,
    );
    await notifier.ensureAssignableUnitsLoaded();
    if (!context.mounted) return;

    final state = ref.read(
      inventoryCategoryDetailControllerProvider(categoryId),
    );
    final category = state.category;
    if (category == null) return;

    final existingIds =
        (usage == CategoryUnitUsage.purchase
                ? state.purchaseUnits
                : state.sellingUnits)
            .map((u) => u.id)
            .toSet();
    final available = state.assignableUnits
        .where((u) => !existingIds.contains(u.id))
        .toList();

    final picked = await showAddCategoryUnitDialog(
      context,
      title: usage == CategoryUnitUsage.purchase
          ? 'Add purchase unit'
          : 'Add selling unit',
      units: available,
    );
    if (picked == null || !context.mounted) return;

    try {
      await notifier.assignUnit(picked.id, usage);
      if (context.mounted) {
        AppSnackBar.success(context, '${picked.name} added.');
      }
    } on ApiException catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.message);
    }
  }

  Future<void> _withdrawUnit(
    BuildContext context,
    WidgetRef ref,
    InventoryUnitModel unit,
  ) async {
    final confirmed = await showInventoryCategoryConfirmDialog(
      context,
      title: 'Withdraw unit',
      message:
          'Remove ${unit.name} (${unit.symbol}) from this category\'s unit policy?',
      confirmLabel: 'Withdraw',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final message = await ref
          .read(inventoryCategoryDetailControllerProvider(categoryId).notifier)
          .withdrawUnit(unit.id);
      if (context.mounted) {
        AppSnackBar.success(
          context,
          message.trim().isEmpty ? '${unit.name} withdrawn.' : message,
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      inventoryCategoryDetailControllerProvider(categoryId),
    );
    final category = state.category;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(category?.name ?? 'Category'),
        actions: [
          if (category != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit category',
              onPressed: () => _editCategory(context, ref, category),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _buildBody(context, ref, state, category),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    InventoryCategoryDetailState state,
    InventoryCategoryDetailModel? category,
  ) {
    if (state.isLoading && category == null) {
      return const AppLoader();
    }

    if (state.error != null && category == null) {
      return AppEmptyState.error(
        message: state.error,
        onAction: () => ref
            .read(
              inventoryCategoryDetailControllerProvider(categoryId).notifier,
            )
            .refresh(),
      );
    }

    if (category == null) return const SizedBox.shrink();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InventoryCategoryThumbnail(
                      imageUrl: category.image,
                      size: 64,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category.name, style: AppTypography.title),
                          if (category.description != null &&
                              category.description!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              category.description!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.smMd),
                          AppBadge(
                            label:
                                '${category.productCount} product${category.productCount == 1 ? '' : 's'}',
                            tone: AppBadgeTone.info,
                            icon: Icons.inventory_2_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InventoryCategoryUnitSection(
                title: 'Purchase units',
                units: state.purchaseUnits,
                busyUnitIds: state.busyUnitIds,
                onAdd: () => _addUnit(context, ref, CategoryUnitUsage.purchase),
                onWithdraw: (unit) => _withdrawUnit(context, ref, unit),
              ),
              const SizedBox(height: AppSpacing.md),
              InventoryCategoryUnitSection(
                title: 'Selling units',
                units: state.sellingUnits,
                busyUnitIds: state.busyUnitIds,
                onAdd: () => _addUnit(context, ref, CategoryUnitUsage.selling),
                onWithdraw: (unit) => _withdrawUnit(context, ref, unit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
