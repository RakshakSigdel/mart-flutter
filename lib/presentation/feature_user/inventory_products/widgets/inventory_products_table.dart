import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import 'inventory_products_badges.dart';
import 'inventory_products_row_actions.dart';

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
  final void Function(ProductModel product, InventoryProductRowAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.eyebrow.copyWith(letterSpacing: 0.4);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 900),
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
          headingTextStyle: headerStyle,
          columnSpacing: AppSpacing.lg,
          columns: const [
            DataColumn(label: Text('PRODUCT')),
            DataColumn(label: Text('CATEGORY')),
            DataColumn(label: Text('SELLING PRICE')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final product in products)
              DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: AppTypography.subtitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [
                              if (product.productCode != null) product.productCode!,
                              if (product.brand != null) product.brand!,
                            ].join(' · '),
                            style: AppTypography.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text(product.categoryName ?? '—')),
                  DataCell(
                    Text(
                      product.sellingPrice == null
                          ? '—'
                          : '${formatMoney(product.sellingPrice)}'
                              '${product.sellingUnitSymbol != null ? ' / ${product.sellingUnitSymbol}' : ''}',
                    ),
                  ),
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
    );
  }
}
