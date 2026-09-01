import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import 'inventory_units_badges.dart';
import 'inventory_units_row_actions.dart';

/// Phone layout — one card per unit, stacked in a list.
class InventoryUnitListCard extends StatelessWidget {
  const InventoryUnitListCard({
    super.key,
    required this.unit,
    required this.isBusy,
    required this.onAction,
  });

  final InventoryUnitModel unit;
  final bool isBusy;
  final ValueChanged<InventoryUnitRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                    Text(unit.name, style: AppTypography.subtitle),
                    Text(unit.symbol, style: AppTypography.caption),
                  ],
                ),
              ),
              InventoryUnitRowActionsMenu(
                isEditable: unit.isEditable,
                isBusy: isBusy,
                onSelected: onAction,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              MeasurementTypeBadge(type: unit.measurementType),
              if (unit.systemDefined) const SystemUnitBadge(),
              if (unit.referenceUnit) const ReferenceUnitBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.smMd),
          _InfoRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Conversion factor: ${formatConversionFactor(unit.conversionFactor)}',
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
