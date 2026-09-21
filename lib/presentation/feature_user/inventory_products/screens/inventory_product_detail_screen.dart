import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../shared/widgets/section_ui.dart';
import '../controllers/inventory_product_detail_controller.dart';
import '../widgets/inventory_product_purchase_unit_dialog.dart';
import '../widgets/inventory_product_purchase_unit_section.dart';
import '../widgets/inventory_product_selling_unit_dialog.dart';
import '../widgets/inventory_product_selling_unit_section.dart';
import '../widgets/inventory_product_vat_history_dialog.dart';
import '../widgets/inventory_products_badges.dart';
import '../widgets/inventory_products_confirm_dialog.dart';
import '../widgets/product_thumb.dart';

/// One product's detail page: its record and its trading configuration —
/// purchase units (with VAT history) and selling units — the one thing the
/// plain products list deliberately leaves out (see `ProductModel`'s doc
/// comment).
///
/// Full page rather than a dialog/expansion, same reasoning as the
/// category detail screen: there's a whole policy-editing UI here.
class InventoryProductDetailScreen extends ConsumerWidget {
  const InventoryProductDetailScreen({super.key, required this.productId});

  final int productId;

  InventoryProductDetailController _notifier(WidgetRef ref) =>
      ref.read(inventoryProductDetailControllerProvider(productId).notifier);

  Future<void> _editProduct(BuildContext context, WidgetRef ref) async {
    final result = await context.push<bool>(
      Routes.inventoryProductEdit(productId),
    );
    if (result == true) {
      if (context.mounted) AppSnackBar.success(context, 'Product updated.');
      _notifier(ref).refresh();
    }
  }

  // ─── Purchase units ───────────────────────────────────────────────────

  Future<void> _addPurchaseUnit(BuildContext context, WidgetRef ref) async {
    final notifier = _notifier(ref);
    await notifier.ensureUnitOptionsLoaded();
    if (!context.mounted) return;
    final unitOptions = ref
        .read(inventoryProductDetailControllerProvider(productId))
        .unitOptions;
    final result = await showInventoryProductPurchaseUnitDialog(
      context,
      productId: productId,
      unitOptions: unitOptions,
    );
    if (result == true && context.mounted) {
      AppSnackBar.success(context, 'Purchase unit added.');
    }
  }

  Future<void> _handlePurchaseUnitAction(
    BuildContext context,
    WidgetRef ref,
    ProductPurchaseUnitModel unit,
    ProductPurchaseUnitRowAction action,
  ) async {
    switch (action) {
      case ProductPurchaseUnitRowAction.edit:
        final result = await showInventoryProductPurchaseUnitDialog(
          context,
          productId: productId,
          unitOptions: const [],
          existing: unit,
        );
        if (result == true && context.mounted) {
          AppSnackBar.success(context, 'Purchase unit updated.');
        }
        break;
      case ProductPurchaseUnitRowAction.vatHistory:
        showInventoryProductVatHistoryDialog(
          context,
          productId: productId,
          purchaseUnitId: unit.id,
          unitLabel: '${unit.unit.name} (${unit.unit.symbol})',
        );
        break;
      case ProductPurchaseUnitRowAction.remove:
        final confirmed = await showInventoryProductConfirmDialog(
          context,
          title: 'Remove purchase unit',
          message:
              '${unit.unit.name} (${unit.unit.symbol}) will no longer be a way '
              'to buy this product.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (confirmed != true || !context.mounted) return;
        try {
          final message = await _notifier(ref).removePurchaseUnit(unit.id);
          if (context.mounted) {
            AppSnackBar.success(
              context,
              message.trim().isEmpty ? 'Purchase unit removed.' : message,
            );
          }
        } on ApiException catch (e) {
          if (context.mounted) AppSnackBar.error(context, e.message);
        }
        break;
    }
  }

  // ─── Selling units ────────────────────────────────────────────────────

  Future<void> _addSellingUnit(BuildContext context, WidgetRef ref) async {
    final notifier = _notifier(ref);
    await notifier.ensureUnitOptionsLoaded();
    if (!context.mounted) return;
    final unitOptions = ref
        .read(inventoryProductDetailControllerProvider(productId))
        .unitOptions;
    final result = await showInventoryProductSellingUnitDialog(
      context,
      productId: productId,
      unitOptions: unitOptions,
    );
    if (result == true && context.mounted) {
      AppSnackBar.success(context, 'Selling unit added.');
    }
  }

  Future<void> _handleSellingUnitAction(
    BuildContext context,
    WidgetRef ref,
    ProductSellingUnitModel unit,
    ProductSellingUnitRowAction action,
  ) async {
    switch (action) {
      case ProductSellingUnitRowAction.edit:
        final result = await showInventoryProductSellingUnitDialog(
          context,
          productId: productId,
          unitOptions: const [],
          existing: unit,
        );
        if (result == true && context.mounted) {
          AppSnackBar.success(context, 'Selling unit updated.');
        }
        break;
      case ProductSellingUnitRowAction.remove:
        final confirmed = await showInventoryProductConfirmDialog(
          context,
          title: 'Remove selling unit',
          message:
              '${unit.unit.name} (${unit.unit.symbol}) will no longer be a way '
              'to sell this product.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (confirmed != true || !context.mounted) return;
        try {
          final message = await _notifier(ref).removeSellingUnit(unit.id);
          if (context.mounted) {
            AppSnackBar.success(
              context,
              message.trim().isEmpty ? 'Selling unit removed.' : message,
            );
          }
        } on ApiException catch (e) {
          if (context.mounted) AppSnackBar.error(context, e.message);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      inventoryProductDetailControllerProvider(productId),
    );
    final product = state.product;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(product?.name ?? 'Product'),
        actions: [
          if (product != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit product',
              onPressed: () => _editProduct(context, ref),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: _buildBody(context, ref, state, product),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    InventoryProductDetailState state,
    ProductDetailModel? product,
  ) {
    if (state.isLoading && product == null) {
      return const AppLoader();
    }

    if (state.error != null && product == null) {
      return AppEmptyState.error(
        message: state.error,
        onAction: () => _notifier(ref).refresh(),
      );
    }

    if (product == null) return const SizedBox.shrink();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionPanelHeader(
                      icon: Icons.inventory_2_rounded,
                      eyebrow: 'PRODUCT',
                      subtitle: product.categoryName?.isNotEmpty == true
                          ? 'In ${product.categoryName}'
                          : 'Uncategorised',
                      trailing: ActiveStatusBadge(active: product.active),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              ProductThumb(
                                name: product.name,
                                imageUrl: product.image,
                                size: 56,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      product.name,
                                      style: AppTypography.title,
                                    ),
                                    if (product.description?.isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        product.description!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: AppSpacing.md),
                          _InfoRow(
                            label: 'Category',
                            value: product.categoryName ?? 'Not set',
                          ),
                          _InfoRow(
                            label: 'Base unit',
                            value: product.baseUnit == null
                                ? 'Not set'
                                : '${product.baseUnit!.name} (${product.baseUnit!.symbol})',
                          ),
                          if (product.productCode != null)
                            _InfoRow(
                              label: 'Product code',
                              value: product.productCode!,
                            ),
                          if (product.baseCode != null)
                            _InfoRow(
                              label: 'Base code',
                              value: product.baseCode!,
                            ),
                          if (product.brand != null)
                            _InfoRow(label: 'Brand', value: product.brand!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InventoryProductPurchaseUnitSection(
                units: product.purchaseUnits,
                busyIds: state.busyPurchaseUnitIds,
                onAdd: () => _addPurchaseUnit(context, ref),
                onAction: (unit, action) =>
                    _handlePurchaseUnitAction(context, ref, unit, action),
              ),
              const SizedBox(height: AppSpacing.md),
              InventoryProductSellingUnitSection(
                units: product.sellingUnits,
                busyIds: state.busySellingUnitIds,
                onAdd: () => _addSellingUnit(context, ref),
                onAction: (unit, action) =>
                    _handleSellingUnitAction(context, ref, unit, action),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
