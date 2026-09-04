import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/stock_model.dart';
import '../controllers/stock_detail_controller.dart';
import '../widgets/stock_adjust_dialog.dart';
import '../widgets/stock_badges.dart';
import '../widgets/stock_movements_section.dart';
import '../widgets/stock_reorder_level_dialog.dart';
import '../widgets/stock_write_off_dialog.dart';

/// One product's stock detail page: its current level and its full
/// movement ledger — everything `/stock/products/{id}` and
/// `/stock/movements` expose about that one product's stock.
///
/// A product has exactly one stock level, so — like the vendor detail
/// screen — there's nowhere else to navigate to from here; adjust,
/// write-off and reorder-level are all dialogs over this one page rather
/// than pushed screens of their own.
class StockDetailScreen extends ConsumerWidget {
  const StockDetailScreen({super.key, required this.productId});

  final int productId;

  StockDetailController _notifier(WidgetRef ref) =>
      ref.read(stockDetailControllerProvider(productId).notifier);

  Future<void> _adjust(BuildContext context, WidgetRef ref) async {
    final notifier = _notifier(ref);
    await notifier.ensureUnitOptionsLoaded();
    if (!context.mounted) return;
    final unitOptions = ref
        .read(stockDetailControllerProvider(productId))
        .unitOptions;
    final result = await showStockAdjustDialog(
      context,
      productId: productId,
      unitOptions: unitOptions,
    );
    if (result == true && context.mounted) {
      AppSnackBar.success(context, 'Stock adjusted.');
    }
  }

  Future<void> _writeOff(BuildContext context, WidgetRef ref) async {
    final notifier = _notifier(ref);
    await notifier.ensureUnitOptionsLoaded();
    if (!context.mounted) return;
    final unitOptions = ref
        .read(stockDetailControllerProvider(productId))
        .unitOptions;
    final result = await showStockWriteOffDialog(
      context,
      productId: productId,
      unitOptions: unitOptions,
    );
    if (result == true && context.mounted) {
      AppSnackBar.success(context, 'Stock written off.');
    }
  }

  Future<void> _setReorderLevel(
    BuildContext context,
    WidgetRef ref,
    StockLevelModel level,
  ) async {
    final result = await showStockReorderLevelDialog(
      context,
      currentLevel: level.reorderLevel,
      onSubmit: (value) => _notifier(ref).setReorderLevel(value),
    );
    if (result == true && context.mounted) {
      AppSnackBar.success(context, 'Reorder level updated.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockDetailControllerProvider(productId));
    final level = state.level;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(level?.productName ?? 'Stock'),
      ),
      body: _buildBody(context, ref, state, level),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    StockDetailState state,
    StockLevelModel? level,
  ) {
    if (state.isLoading && level == null) {
      return const AppLoader();
    }

    if (state.error != null && level == null) {
      return AppEmptyState.error(
        message: state.error,
        onAction: () => _notifier(ref).refresh(),
      );
    }

    if (level == null) return const SizedBox.shrink();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StockLevelCard(
                level: level,
                onSetReorderLevel: () => _setReorderLevel(context, ref, level),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Adjust stock',
                      variant: AppButtonVariant.secondary,
                      leading: const Icon(Icons.tune_rounded, size: 18),
                      onPressed: () => _adjust(context, ref),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  Expanded(
                    child: AppButton(
                      label: 'Write off',
                      variant: AppButtonVariant.danger,
                      leading: const Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 18,
                      ),
                      onPressed: () => _writeOff(context, ref),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              StockMovementsSection(
                movements: state.movements,
                onRetry: () => _notifier(
                  ref,
                ).loadMovements(page: state.movements.pageNumber),
                onPrevious: () => _notifier(ref).previousMovementsPage(),
                onNext: () => _notifier(ref).nextMovementsPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockLevelCard extends StatelessWidget {
  const _StockLevelCard({required this.level, required this.onSetReorderLevel});

  final StockLevelModel level;
  final VoidCallback onSetReorderLevel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(level.productName, style: AppTypography.title),
              ),
              StockStatusBadge(status: level.status),
            ],
          ),
          if (level.productCode != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              level.productCode!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.smMd),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.smMd),
          _InfoRow(label: 'Category', value: level.categoryName ?? '—'),
          _InfoRow(
            label: 'On hand',
            value:
                '${formatStockQuantity(level.quantity)}'
                '${level.baseUnitSymbol != null ? ' ${level.baseUnitSymbol}' : ''}',
          ),
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  label: 'Reorder level',
                  value: formatStockQuantity(level.reorderLevel),
                ),
              ),
              TextButton(
                onPressed: onSetReorderLevel,
                child: const Text('Edit'),
              ),
            ],
          ),
        ],
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
