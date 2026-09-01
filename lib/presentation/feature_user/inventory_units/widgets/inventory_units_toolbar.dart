import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';

/// Search box, measurement-type filter, and the "Add unit" action.
///
/// Stacks vertically on phone; sits in one row on wider screens — the same
/// content either way, just laid out differently.
class InventoryUnitsToolbar extends StatelessWidget {
  const InventoryUnitsToolbar({
    super.key,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.measurementTypeFilter,
    required this.onMeasurementTypeFilterChanged,
    required this.onAddPressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final UnitMeasurementType? measurementTypeFilter;
  final ValueChanged<UnitMeasurementType?> onMeasurementTypeFilterChanged;
  final VoidCallback onAddPressed;

  static final _typeItems = <DropdownMenuItem<UnitMeasurementType?>>[
    const DropdownMenuItem(value: null, child: Text('All types')),
    for (final type in UnitMeasurementType.values)
      DropdownMenuItem(
        value: type,
        child: Text(type.label, overflow: TextOverflow.ellipsis),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    final search = AppTextField(
      controller: searchController,
      hint: 'Search by name or symbol',
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onSubmitted: onSearchSubmitted,
    );

    final typeFilterField = SizedBox(
      width: isWide ? 200 : double.infinity,
      child: AppDropdownField<UnitMeasurementType?>(
        value: measurementTypeFilter,
        items: _typeItems,
        onChanged: onMeasurementTypeFilterChanged,
        hint: 'All types',
      ),
    );

    final addButton = AppButton(
      label: 'Add unit',
      leading: const Icon(Icons.add),
      onPressed: onAddPressed,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: search),
          const SizedBox(width: AppSpacing.smMd),
          typeFilterField,
          const SizedBox(width: AppSpacing.smMd),
          addButton,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        search,
        const SizedBox(height: AppSpacing.smMd),
        typeFilterField,
        const SizedBox(height: AppSpacing.smMd),
        addButton,
      ],
    );
  }
}
