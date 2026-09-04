import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/stock_model.dart';
import 'stock_badges.dart';
import 'stock_row_actions.dart';

/// Tablet/desktop layout — one row per product's stock level in a
/// scrollable table.
class StockTable extends StatelessWidget {
  const StockTable({
    super.key,
    required this.items,
    required this.busyIds,
    required this.onAction,
  });

  final List<StockLevelModel> items;
  final Set<int> busyIds;
  final void Function(StockLevelModel item, StockRowAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.eyebrow.copyWith(letterSpacing: 0.4);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: math.max(800, constraints.maxWidth),
          ),
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
            headingTextStyle: headerStyle,
            columnSpacing: AppSpacing.lg,
            columns: const [
              DataColumn(label: Text('PRODUCT')),
              DataColumn(label: Text('CATEGORY')),
              DataColumn(label: Text('QUANTITY')),
              DataColumn(label: Text('REORDER LEVEL')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final item in items)
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
                              item.productName,
                              style: AppTypography.subtitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.productCode != null)
                              Text(
                                item.productCode!,
                                style: AppTypography.caption,
                              ),
                          ],
                        ),
                      ),
                      onTap: () => onAction(item, StockRowAction.viewDetails),
                    ),
                    DataCell(Text(item.categoryName ?? '—')),
                    DataCell(
                      Text(
                        '${formatStockQuantity(item.quantity)}'
                        '${item.baseUnitSymbol != null ? ' ${item.baseUnitSymbol}' : ''}',
                      ),
                    ),
                    DataCell(Text(formatStockQuantity(item.reorderLevel))),
                    DataCell(StockStatusBadge(status: item.status)),
                    DataCell(
                      StockRowActionsMenu(
                        isBusy: busyIds.contains(item.productId),
                        onSelected: (action) => onAction(item, action),
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
