import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';

/// Search box, category/active filters, and the "Add product" action.
///
/// Stacks vertically on phone; sits in one row on wider screens — the same
/// content either way, just laid out differently.
class InventoryProductsToolbar extends StatelessWidget {
  const InventoryProductsToolbar({
    super.key,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.categoryOptions,
    required this.categoryFilter,
    required this.onCategoryFilterChanged,
    required this.activeFilter,
    required this.onActiveFilterChanged,
    required this.onAddPressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final List<InventoryCategoryModel> categoryOptions;
  final int? categoryFilter;
  final ValueChanged<int?> onCategoryFilterChanged;
  final bool? activeFilter;
  final ValueChanged<bool?> onActiveFilterChanged;
  final VoidCallback onAddPressed;

  static const _activeItems = <DropdownMenuItem<bool?>>[
    DropdownMenuItem(value: null, child: Text('All products')),
    DropdownMenuItem(value: true, child: Text('Active')),
    DropdownMenuItem(value: false, child: Text('Inactive')),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    final search = AppTextField(
      controller: searchController,
      hint: 'Search by name or product code',
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
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
        value: categoryOptions.any((c) => c.id == categoryFilter) ? categoryFilter : null,
        items: categoryItems,
        onChanged: onCategoryFilterChanged,
        hint: 'All categories',
      ),
    );

    final activeFilterField = SizedBox(
      width: isWide ? 160 : double.infinity,
      child: AppDropdownField<bool?>(
        value: activeFilter,
        items: _activeItems,
        onChanged: onActiveFilterChanged,
        hint: 'All products',
      ),
    );

    final addButton = AppButton(
      label: 'Add product',
      leading: const Icon(Icons.add),
      onPressed: onAddPressed,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: search),
          const SizedBox(width: AppSpacing.smMd),
          categoryFilterField,
          const SizedBox(width: AppSpacing.smMd),
          activeFilterField,
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
        categoryFilterField,
        const SizedBox(height: AppSpacing.smMd),
        activeFilterField,
        const SizedBox(height: AppSpacing.smMd),
        addButton,
      ],
    );
  }
}
