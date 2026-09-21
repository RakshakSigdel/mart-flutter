import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import 'inventory_products_badges.dart';
import 'inventory_products_row_actions.dart';
import 'product_thumb.dart';

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumb(
                name: product.name,
                imageUrl: product.image,
                size: 46,
              ),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.productCode?.isNotEmpty == true
                          ? product.productCode!
                          : 'No product code',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              InventoryProductRowActionsMenu(
                isBusy: isBusy,
                onSelected: onAction,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          // Price is the fact a shopkeeper scans this list for, so it gets
          // its own band rather than being one more grey info line.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.smMd,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: product.sellingPrice == null
                  ? AppColors.surfaceSunken
                  : AppColors.primarySoft,
              borderRadius: AppBorderRadius.radiusMD,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sell_outlined,
                  size: 16,
                  color: product.sellingPrice == null
                      ? AppColors.textMuted
                      : AppColors.primaryDeep,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    product.sellingPrice == null
                        ? 'No selling price set'
                        : 'Sells at',
                    style: AppTypography.bodySmall.copyWith(
                      color: product.sellingPrice == null
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (product.sellingPrice != null)
                  Text(
                    '${formatMoney(product.sellingPrice)}'
                    '${product.sellingUnitSymbol != null ? ' / ${product.sellingUnitSymbol}' : ''}',
                    style: AppTypography.priceSmall.copyWith(
                      color: AppColors.primaryDeep,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.smMd),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActiveStatusBadge(active: product.active),
              if (product.categoryName?.isNotEmpty == true)
                AppBadge(
                  label: product.categoryName!,
                  tone: AppBadgeTone.neutral,
                ),
              if (product.brand?.isNotEmpty == true)
                AppBadge(
                  label: product.brand!,
                  tone: AppBadgeTone.info,
                  icon: Icons.local_offer_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
