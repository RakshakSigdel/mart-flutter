import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import 'inventory_products_badges.dart';
import 'inventory_products_row_actions.dart';

/// Phone layout — one card per product, stacked in a list.
class InventoryProductListCard extends StatelessWidget {
  const InventoryProductListCard({
    super.key,
    required this.product,
    required this.isBusy,
    required this.onAction,
  });

  final ProductModel product;
  final bool isBusy;
  final ValueChanged<InventoryProductRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => onAction(InventoryProductRowAction.viewDetails),
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
                    Text(product.name, style: AppTypography.subtitle),
                    if (product.productCode != null)
                      Text(product.productCode!, style: AppTypography.caption),
                  ],
                ),
              ),
              InventoryProductRowActionsMenu(isBusy: isBusy, onSelected: onAction),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActiveStatusBadge(active: product.active),
              if (product.categoryName != null)
                AppBadge(label: product.categoryName!, tone: AppBadgeTone.neutral),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.smMd),
          _InfoRow(
            icon: Icons.sell_outlined,
            label: product.sellingPrice == null
                ? 'No selling price set'
                : 'Selling price: ${formatMoney(product.sellingPrice)}'
                    '${product.sellingUnitSymbol != null ? ' / ${product.sellingUnitSymbol}' : ''}',
          ),
          if (product.brand != null)
            _InfoRow(icon: Icons.local_offer_outlined, label: product.brand!),
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
