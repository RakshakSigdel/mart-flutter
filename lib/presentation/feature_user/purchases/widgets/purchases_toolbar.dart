import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/vendor_model.dart';

/// Search box, vendor filter, date-range filter, and the "New purchase"
/// action.
///
/// Stacks vertically on phone; sits in one row on wider screens — the same
/// content either way, just laid out differently.
class PurchasesToolbar extends StatelessWidget {
  const PurchasesToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.vendorOptions,
    required this.vendorFilter,
    required this.onVendorFilterChanged,
    required this.fromFilter,
    required this.toFilter,
    required this.onDateRangeChanged,
    required this.onAddPressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final List<VendorModel> vendorOptions;
  final int? vendorFilter;
  final ValueChanged<int?> onVendorFilterChanged;
  final DateTime? fromFilter;
  final DateTime? toFilter;
  final void Function(DateTime? from, DateTime? to) onDateRangeChanged;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    final search = AppTextField(
      controller: searchController,
      hint: 'Search by bill number',
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: onSearchChanged,
      onSubmitted: onSearchSubmitted,
    );

    final selectedVendor = vendorOptions.any((v) => v.id == vendorFilter)
        ? vendorOptions.firstWhere((v) => v.id == vendorFilter)
        : null;

    final vendorField = AppSearchableDropdownField<VendorModel>(
      selectedItem: selectedVendor,
      items: vendorOptions,
      itemLabel: (v) => v.name,
      hint: 'All vendors',
      onChanged: (v) => onVendorFilterChanged(v?.id),
    );

    final fromField = AppDateField(
      hint: 'From date',
      value: fromFilter,
      onChanged: (date) => onDateRangeChanged(date, toFilter),
    );

    final toField = AppDateField(
      hint: 'To date',
      value: toFilter,
      onChanged: (date) => onDateRangeChanged(fromFilter, date),
    );

    final addButton = AppButton(
      label: 'New purchase',
      leading: const Icon(Icons.add),
      onPressed: onAddPressed,
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
              SizedBox(width: 220, child: vendorField),
              const SizedBox(width: AppSpacing.smMd),
              addButton,
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Row(
            children: [
              SizedBox(width: 200, child: fromField),
              const SizedBox(width: AppSpacing.smMd),
              SizedBox(width: 200, child: toField),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        search,
        const SizedBox(height: AppSpacing.smMd),
        vendorField,
        const SizedBox(height: AppSpacing.smMd),
        Row(
          children: [
            Expanded(child: fromField),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(child: toField),
          ],
        ),
        const SizedBox(height: AppSpacing.smMd),
        addButton,
      ],
    );
  }
}
