import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import 'inventory_products_badges.dart';
import 'inventory_products_row_actions.dart';
import 'product_thumb.dart';

/// Tablet/desktop layout — one row per product in a scrollable table.
class InventoryProductsTable extends StatelessWidget {
  const InventoryProductsTable({
    super.key,
    required this.products,
    required this.busyIds,
    required this.onAction,
  });

  final List<ProductModel> products;
  final Set<int> busyIds;
  final void Function(ProductModel product, InventoryProductRowAction action)
  onAction;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.eyebrow.copyWith(
      fontSize: 10,
      letterSpacing: 0.8,
      color: AppColors.textMuted,
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: math.max(860, constraints.maxWidth),
          ),
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(
              AppColors.surfaceSunken,
            ),
            headingTextStyle: headerStyle,
            dividerThickness: 1,
            columnSpacing: AppSpacing.lg,
            horizontalMargin: AppSpacing.md,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 64,
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('PRODUCT')),
              DataColumn(label: Text('CATEGORY')),
              DataColumn(label: Text('SELLING PRICE'), numeric: true),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final product in products)
                DataRow(
                  // The whole row opens the product; its trading units are
                  // the reason anyone comes to this table.
                  onSelectChanged: (_) =>
                      onAction(product, InventoryProductRowAction.viewDetails),
                  cells: [
                    DataCell(_ProductCell(product: product)),
                    DataCell(
                      product.categoryName?.isNotEmpty == true
                          ? AppBadge(
                              label: product.categoryName!,
                              tone: AppBadgeTone.neutral,
                            )
                          : Text('Uncategorised', style: AppTypography.caption),
                    ),
                    DataCell(_PriceCell(product: product)),
                    DataCell(ActiveStatusBadge(active: product.active)),
                    DataCell(
                      InventoryProductRowActionsMenu(
                        isBusy: busyIds.contains(product.id),
                        onSelected: (action) => onAction(product, action),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCell extends StatelessWidget {
  const _ProductCell({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (product.productCode?.isNotEmpty == true) product.productCode!,
      if (product.brand?.isNotEmpty == true) product.brand!,
    ].join(' · ');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProductThumb(name: product.name, imageUrl: product.image, size: 38),
          const SizedBox(width: AppSpacing.smMd),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  meta.isEmpty ? 'No code or brand' : meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  const _PriceCell({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    if (product.sellingPrice == null) {
      return Text('Not priced', style: AppTypography.caption);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatMoney(product.sellingPrice),
          style: AppTypography.priceSmall,
        ),
        if (product.sellingUnitSymbol != null)
          Text(
            'per ${product.sellingUnitSymbol}',
            style: AppTypography.caption,
          ),
      ],
    );
  }
}
