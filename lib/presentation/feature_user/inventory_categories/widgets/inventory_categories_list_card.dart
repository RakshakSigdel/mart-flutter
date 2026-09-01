import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import 'inventory_categories_row_actions.dart';
import 'inventory_category_thumbnail.dart';

/// Phone layout — one card per category, stacked in a list.
class InventoryCategoryListCard extends StatelessWidget {
  const InventoryCategoryListCard({
    super.key,
    required this.category,
    required this.isBusy,
    required this.onAction,
  });

  final InventoryCategoryModel category;
  final bool isBusy;
  final ValueChanged<InventoryCategoryRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => onAction(InventoryCategoryRowAction.viewDetails),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryCategoryThumbnail(imageUrl: category.image),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: AppTypography.subtitle),
                if (category.description != null && category.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    category.description!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          InventoryCategoryRowActionsMenu(isBusy: isBusy, onSelected: onAction),
        ],
      ),
    );
  }
}
