import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import 'inventory_units_badges.dart';
import 'inventory_units_row_actions.dart';

/// Tablet/desktop layout — one row per unit in a scrollable table.
class InventoryUnitsTable extends StatelessWidget {
  const InventoryUnitsTable({
    super.key,
    required this.units,
    required this.busyIds,
    required this.onAction,
  });

  final List<InventoryUnitModel> units;
  final Set<int> busyIds;
  final void Function(InventoryUnitModel unit, InventoryUnitRowAction action)
  onAction;

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
              DataColumn(label: Text('NAME')),
              DataColumn(label: Text('TYPE')),
              DataColumn(label: Text('CONVERSION FACTOR')),
              DataColumn(label: Text('')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final unit in units)
                DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              unit.name,
                              style: AppTypography.subtitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              unit.symbol,
                              style: AppTypography.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(MeasurementTypeBadge(type: unit.measurementType)),
                    DataCell(
                      Text(formatConversionFactor(unit.conversionFactor)),
                    ),
                    DataCell(
                      Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          if (unit.systemDefined) const SystemUnitBadge(),
                          if (unit.referenceUnit) const ReferenceUnitBadge(),
                        ],
                      ),
                    ),
                    DataCell(
                      InventoryUnitRowActionsMenu(
                        isEditable: unit.isEditable,
                        isBusy: busyIds.contains(unit.id),
                        onSelected: (action) => onAction(unit, action),
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
