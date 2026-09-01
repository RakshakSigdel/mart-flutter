import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';

/// Picks one unit to grant a permission for. [units] should already exclude
/// whichever units the category has already been granted for this side of
/// the trade — the caller (the detail screen) computes that difference, so
/// this dialog stays a plain picker. Returns the picked unit, or `null` on
/// cancel.
Future<InventoryUnitModel?> showAddCategoryUnitDialog(
  BuildContext context, {
  required String title,
  required List<InventoryUnitModel> units,
}) {
  return showAppDialog<InventoryUnitModel>(
    context: context,
    title: title,
    content: _AddUnitContent(units: units),
  );
}

class _AddUnitContent extends StatefulWidget {
  const _AddUnitContent({required this.units});

  final List<InventoryUnitModel> units;

  @override
  State<_AddUnitContent> createState() => _AddUnitContentState();
}

class _AddUnitContentState extends State<_AddUnitContent> {
  InventoryUnitModel? _selected;

  @override
  Widget build(BuildContext context) {
    if (widget.units.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Every unit in your dictionary is already permitted here.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSearchableDropdownField<InventoryUnitModel>(
          label: 'Unit',
          selectedItem: _selected,
          items: widget.units,
          itemLabel: (unit) => '${unit.name} (${unit.symbol})',
          hint: 'Select a unit',
          onChanged: (unit) => setState(() => _selected = unit),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton.expanded(
          label: 'Add',
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}
