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
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final List<InventoryCategoryModel> categoryOptions;
  final int? categoryFilter;
  final ValueChanged<int?> onCategoryFilterChanged;
  final bool lowOnly;
  final ValueChanged<bool> onLowOnlyChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

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

    final lowOnlyToggle = _LowOnlyToggle(
      value: lowOnly,
      onChanged: onLowOnlyChanged,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: search),
          const SizedBox(width: AppSpacing.smMd),
          categoryFilterField,
          const SizedBox(width: AppSpacing.smMd),
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
  }
}

class _LowOnlyToggle extends StatelessWidget {
  const _LowOnlyToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: AppBorderRadius.radiusL,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: AppBorderRadius.radiusL,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppBorderRadius.radiusL,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(value: value, onChanged: onChanged),
              const SizedBox(width: AppSpacing.xs),
              Text('Low stock only', style: AppTypography.label),
            ],
          ),
        ),
      ),
    );
  }
}
