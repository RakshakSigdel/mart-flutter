import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../../../shared/widgets/section_ui.dart';

/// Search box, measurement-type filter, and the "Add unit" action.
///
/// Stacks vertically on phone; sits in one row on wider screens — the same
/// content either way, just laid out differently.
class InventoryUnitsToolbar extends StatelessWidget {
  const InventoryUnitsToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.measurementTypeFilter,
    required this.onMeasurementTypeFilterChanged,
    required this.onAddPressed,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final UnitMeasurementType? measurementTypeFilter;
  final ValueChanged<UnitMeasurementType?> onMeasurementTypeFilterChanged;
  final VoidCallback onAddPressed;
  final VoidCallback onClearFilters;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final search = AppTextField(
          controller: searchController,
          hint: 'Search by name or symbol',
          prefixIcon: Icons.search,
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
        );

        final typeFilterField = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final item in _typeItems)
              ChoiceChip(
                label: item.child,
                selected: measurementTypeFilter == item.value,
                selectedColor: AppColors.primarySoft,
                onSelected: (_) => onMeasurementTypeFilterChanged(item.value),
              ),
            if (searchController.text.isNotEmpty ||
                measurementTypeFilter != null)
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Clear filters'),
              ),
          ],
        );

        final addButton = SizedBox(
          width: 160,
          child: BrandActionButton(
            label: 'Add unit',
            icon: Icons.add_rounded,
            onPressed: onAddPressed,
          ),
        );

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.smMd),
                  addButton,
                ],
              ),
              const SizedBox(height: AppSpacing.smMd),
              typeFilterField,
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
      },
    );
  }
}
