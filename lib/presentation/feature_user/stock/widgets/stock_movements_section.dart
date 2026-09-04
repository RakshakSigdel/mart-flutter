import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/stock_model.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// The product's movement ledger — every purchase, sale, adjustment and
/// write-off that touched its on-hand quantity, newest first per the
/// backend's own ordering.
///
/// Kept on the product's one detail page rather than a route of its own,
/// same reasoning as the vendor detail screen's ledger/history tabs — a
/// section within a plain scrollable page here since there's only the one
/// sub-list, not several needing tabs to switch between.
class StockMovementsSection extends StatelessWidget {
  const StockMovementsSection({
    super.key,
    required this.movements,
    required this.onRetry,
    required this.onPrevious,
    required this.onNext,
  });

  final PagedSubList<StockMovementModel> movements;
  final VoidCallback onRetry;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Movements', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.smMd),
          _buildContent(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  movements.totalPages == 0
                      ? 'No results'
                      : 'Page ${movements.pageNumber} of ${movements.totalPages} · '
                            '${movements.totalElements} movement${movements.totalElements == 1 ? '' : 's'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              IconButton(
                onPressed: movements.hasPreviousPage ? onPrevious : null,
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous page',
              ),
              IconButton(
                onPressed: movements.hasNextPage ? onNext : null,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (movements.isLoading && movements.items.isEmpty) {
      return const AppListSkeleton(
        itemCount: 3,
        hasThumbnail: false,
        padding: EdgeInsets.zero,
      );
    }

    if (movements.error != null && movements.items.isEmpty) {
      return AppEmptyState.error(
        message: movements.error,
        onAction: onRetry,
        compact: true,
      );
    }

    if (movements.isEmpty) {
      return const AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No movements yet',
        message:
            'Purchases, sales, adjustments and write-offs will show up here.',
        compact: true,
      );
    }

    return Column(
      children: [
        for (var i = 0; i < movements.items.length; i++) ...[
          if (i > 0) const Divider(height: AppSpacing.lg),
          _MovementRow(movement: movements.items[i]),
        ],
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final StockMovementModel movement;

  @override
  Widget build(BuildContext context) {
    final increase = movement.direction >= 0;
    final tone = increase ? AppColors.success : AppColors.error;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          increase ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 18,
          color: tone,
        ),
        const SizedBox(width: AppSpacing.smMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatMovementType(movement.movementType),
                      style: AppTypography.subtitle,
                    ),
                  ),
                  Text(
                    '${increase ? '+' : '-'}${formatStockQuantity(movement.quantity)}',
                    style: AppTypography.subtitle.copyWith(color: tone),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Balance after: ${formatStockQuantity(movement.balanceAfter)}'
                '${movement.remark != null && movement.remark!.isNotEmpty ? ' · ${movement.remark}' : ''}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatDate(movement.createdAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
