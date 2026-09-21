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
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.categoryOptions,
    required this.categoryFilter,
    required this.onCategoryFilterChanged,
    required this.activeFilter,
    required this.onActiveFilterChanged,
    required this.onBarcodeLookupPressed,
    required this.onAddPressed,
    required this.onImportPressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final List<InventoryCategoryModel> categoryOptions;
  final int? categoryFilter;
  final ValueChanged<int?> onCategoryFilterChanged;
  final bool? activeFilter;
  final ValueChanged<bool?> onActiveFilterChanged;
  final VoidCallback onBarcodeLookupPressed;
  final VoidCallback onAddPressed;
  final VoidCallback onImportPressed;

  static const _activeItems = <DropdownMenuItem<bool?>>[
    DropdownMenuItem(value: null, child: Text('All products')),
    DropdownMenuItem(value: true, child: Text('Active')),
    DropdownMenuItem(value: false, child: Text('Inactive')),
  ];

  @override
  Widget build(BuildContext context) {
    // This toolbar lives beside the sidebar, so viewport width overstates the
    // room it actually has. Measure its actual controls rather than using a
    // conservative breakpoint: keep one row whenever it can truly fit.
    return LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        double buttonWidth(String label) {
          final text = TextPainter(
            text: TextSpan(
              text: label,
              style: AppTypography.label.copyWith(fontSize: 14),
            ),
            textDirection: direction,
          )..layout();
          // AppButton.md: 16px padding on either side, plus an 18px icon
          // and 8px icon/text gap.
          return text.width + 32 + 18 + AppSpacing.sm;
        }

        const categoryWidth = 200.0;
        const activeWidth = 160.0;
        const minimumSearchWidth = 180.0;
        final controlsWidth =
            categoryWidth +
            activeWidth +
            buttonWidth('Find barcode') +
            buttonWidth('Import CSV') +
            buttonWidth('Quick add product');
        final gapsWidth = AppSpacing.smMd * 5;
        final isWide =
            constraints.maxWidth >=
            controlsWidth + gapsWidth + minimumSearchWidth;

        final search = AppTextField(
          controller: searchController,
          hint: 'Search by name or product code',
          prefixIcon: Icons.search,
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
        );

        final selectedCategory =
            categoryOptions.any((category) => category.id == categoryFilter)
            ? categoryOptions.firstWhere(
                (category) => category.id == categoryFilter,
              )
            : null;

        final categoryFilterField = SizedBox(
          width: isWide ? 200 : double.infinity,
          child: AppSearchableDropdownField<InventoryCategoryModel>(
            selectedItem: selectedCategory,
            items: categoryOptions,
            itemLabel: (category) => category.name,
            hint: 'All categories',
            searchHint: 'Search categories...',
            showClearButton: true,
            onChanged: (category) => onCategoryFilterChanged(category?.id),
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
          label: 'Quick add product',
          leading: const Icon(Icons.add),
          onPressed: onAddPressed,
        );

        final barcodeButton = AppButton(
          label: 'Find barcode',
          variant: AppButtonVariant.secondary,
          leading: const Icon(Icons.qr_code_scanner_outlined),
          onPressed: onBarcodeLookupPressed,
        );
        final importButton = AppButton(
          label: 'Import CSV',
          variant: AppButtonVariant.secondary,
          leading: const Icon(Icons.upload_file_outlined),
          onPressed: onImportPressed,
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
              barcodeButton,
              const SizedBox(width: AppSpacing.smMd),
              importButton,
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
            barcodeButton,
            const SizedBox(height: AppSpacing.smMd),
            importButton,
            const SizedBox(height: AppSpacing.smMd),
            addButton,
          ],
        );
      },
    );
  }
}
