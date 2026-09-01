import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';

/// One side of a category's unit policy (purchase or selling) — its
/// currently permitted units as chips, plus an "Add" action.
class InventoryCategoryUnitSection extends StatelessWidget {
  const InventoryCategoryUnitSection({
    super.key,
    required this.title,
    required this.units,
    required this.busyUnitIds,
    required this.onAdd,
    required this.onWithdraw,
  });

  final String title;
  final List<InventoryUnitModel> units;
  final Set<int> busyUnitIds;
  final VoidCallback onAdd;
  final ValueChanged<InventoryUnitModel> onWithdraw;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.subtitle)),
              AppButton(
                label: 'Add',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                leading: const Icon(Icons.add, size: 16),
                onPressed: onAdd,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          if (units.isEmpty)
            Text(
              'No units permitted yet.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final unit in units)
                  _UnitChip(
                    unit: unit,
                    isBusy: busyUnitIds.contains(unit.id),
                    onWithdraw: () => onWithdraw(unit),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.unit, required this.isBusy, required this.onWithdraw});

  final InventoryUnitModel unit;
  final bool isBusy;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: AppSpacing.smMd,
        right: AppSpacing.xs,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.radiusFull,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${unit.name} (${unit.symbol})',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(width: AppSpacing.xs),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.all(4),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            InkWell(
              onTap: onWithdraw,
              borderRadius: AppBorderRadius.radiusFull,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: AppColors.iconInactive),
              ),
            ),
        ],
      ),
    );
  }
}
