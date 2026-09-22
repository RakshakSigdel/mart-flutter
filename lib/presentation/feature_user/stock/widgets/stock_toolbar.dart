import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';

/// Search box, category filter, and the "low stock only" toggle.
///
/// Stacks vertically on phone; sits in one row on wider screens — the same
/// content either way, just laid out differently. No "add" action — stock
/// levels are derived from purchases/sales/adjustments, never created
/// directly.
class StockToolbar extends StatelessWidget {
  const StockToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.categoryOptions,
    required this.categoryFilter,
    required this.onCategoryFilterChanged,
    required this.lowOnly,
    required this.onLowOnlyChanged,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final List<InventoryCategoryModel> categoryOptions;
  final int? categoryFilter;
  final ValueChanged<int?> onCategoryFilterChanged;
  final bool lowOnly;
  final ValueChanged<bool> onLowOnlyChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;

        final search = AppTextField(
          controller: searchController,
          hint: 'Search by product name or code',
          prefixIcon: Icons.search,
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
        );

        final categoryItems = <DropdownMenuItem<int?>>[
          const DropdownMenuItem(value: null, child: Text('All categories')),
          for (final category in categoryOptions)
            DropdownMenuItem(
              value: category.id,
              child: Text(category.name, overflow: TextOverflow.ellipsis),
            ),
        ];

        final categoryFilterField = SizedBox(
          width: isWide ? 200 : double.infinity,
          child: AppDropdownField<int?>(
            value: categoryOptions.any((c) => c.id == categoryFilter)
                ? categoryFilter
                : null,
            items: categoryItems,
            onChanged: onCategoryFilterChanged,
            hint: 'All categories',
          ),
        );

        final lowOnlyToggle = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('All stock'),
              selected: !lowOnly,
              selectedColor: AppColors.primarySoft,
              onSelected: (_) => onLowOnlyChanged(false),
            ),
            ChoiceChip(
              label: const Text('Needs ordering'),
              avatar: const Icon(Icons.warning_amber_rounded, size: 18),
              selected: lowOnly,
              selectedColor: AppColors.primarySoft,
              onSelected: (_) => onLowOnlyChanged(true),
            ),
            if (searchController.text.isNotEmpty ||
                categoryFilter != null ||
                lowOnly)
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Clear filters'),
              ),
          ],
        );

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.smMd),
                  categoryFilterField,
                ],
              ),
              const SizedBox(height: AppSpacing.smMd),
              lowOnlyToggle,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: AppSpacing.smMd),
            categoryFilterField,
            const SizedBox(height: AppSpacing.smMd),
            lowOnlyToggle,
          ],
        );
      },
    );
  }
}
