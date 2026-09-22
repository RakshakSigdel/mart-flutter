import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import 'inventory_categories_row_actions.dart';
import 'inventory_category_thumbnail.dart';

/// Tablet/desktop layout — one row per category in a scrollable table.
class InventoryCategoriesTable extends StatelessWidget {
  const InventoryCategoriesTable({
    super.key,
    required this.categories,
    required this.busyIds,
    required this.onAction,
  });

  final List<InventoryCategoryModel> categories;
  final Set<int> busyIds;
  final void Function(
    InventoryCategoryModel category,
    InventoryCategoryRowAction action,
  )
  onAction;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.eyebrow.copyWith(letterSpacing: 0.4);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: math.max(700, constraints.maxWidth),
          ),
          child: DataTable(
            showCheckboxColumn: false,
            dataRowMinHeight: 76,
            dataRowMaxHeight: 76,
            headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
            headingTextStyle: headerStyle,
            columnSpacing: AppSpacing.lg,
            columns: const [
              DataColumn(label: Text('CATEGORY')),
              DataColumn(label: Text('DESCRIPTION')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: [
              for (final category in categories)
                DataRow(
                  onSelectChanged: busyIds.contains(category.id)
                      ? null
                      : (_) => onAction(
                          category,
                          InventoryCategoryRowAction.viewDetails,
                        ),
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InventoryCategoryThumbnail(
                            imageUrl: category.image,
                            size: 36,
                          ),
                          const SizedBox(width: AppSpacing.smMd),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              category.name,
                              style: AppTypography.subtitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          (category.description == null ||
                                  category.description!.isEmpty)
                              ? 'No description added'
                              : category.description!,
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      InventoryCategoryRowActionsMenu(
                        isBusy: busyIds.contains(category.id),
                        onSelected: (action) => onAction(category, action),
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
