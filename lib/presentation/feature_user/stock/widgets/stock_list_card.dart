import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/stock_model.dart';
import 'stock_badges.dart';
import 'stock_row_actions.dart';

/// Phone layout — one card per product's stock level, stacked in a list.
class StockListCard extends StatelessWidget {
  const StockListCard({
    super.key,
    required this.item,
    required this.isBusy,
    required this.onAction,
  });

  final StockLevelModel item;
  final bool isBusy;
  final ValueChanged<StockRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => onAction(StockRowAction.viewDetails),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: AppTypography.subtitle),
                    if (item.productCode != null)
                      Text(item.productCode!, style: AppTypography.caption),
                  ],
                ),
              ),
              StockRowActionsMenu(isBusy: isBusy, onSelected: onAction),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StockStatusBadge(status: item.status),
              if (item.categoryName != null)
                AppBadge(label: item.categoryName!, tone: AppBadgeTone.neutral),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.smMd),
          _InfoRow(
            icon: Icons.inventory_2_outlined,
            label:
                'On hand: ${formatStockQuantity(item.quantity)}'
                '${item.baseUnitSymbol != null ? ' ${item.baseUnitSymbol}' : ''}',
          ),
          _InfoRow(
            icon: Icons.tune_rounded,
            label: 'Reorder level: ${formatStockQuantity(item.reorderLevel)}',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.iconInactive),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
