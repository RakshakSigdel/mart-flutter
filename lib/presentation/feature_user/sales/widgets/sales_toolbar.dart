import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/sale_model.dart';
import '../../../shared/widgets/section_ui.dart';

/// Search box, payment-status filter, date-range filter, and the "New
/// sale" action.
///
/// Stacks vertically on phone; sits in one row on wider screens — the same
/// content either way, just laid out differently.
///
/// The date fields pick a plain day; [onDateRangeChanged] is handed the
/// start of that day for "from" and the end of it for "to", so the filter
/// covers the whole day rather than the single instant midnight names —
/// `soldAt`/`from`/`to` are full date-times on this endpoint, unlike
/// purchases' date-only fields.
class SalesToolbar extends StatelessWidget {
  const SalesToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.fromFilter,
    required this.toFilter,
    required this.onDateRangeChanged,
    required this.onAddPressed,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final PaymentStatus? statusFilter;
  final ValueChanged<PaymentStatus?> onStatusFilterChanged;
  final DateTime? fromFilter;
  final DateTime? toFilter;
  final void Function(DateTime? from, DateTime? to) onDateRangeChanged;
  final VoidCallback onAddPressed;
  final VoidCallback onClearFilters;

  static const _statusItems = <DropdownMenuItem<PaymentStatus?>>[
    DropdownMenuItem(value: null, child: Text('All statuses')),
    DropdownMenuItem(value: PaymentStatus.unpaid, child: Text('Unpaid')),
    DropdownMenuItem(value: PaymentStatus.partial, child: Text('Partial')),
    DropdownMenuItem(value: PaymentStatus.paid, child: Text('Paid')),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;

        final search = AppTextField(
          controller: searchController,
          hint: 'Search bill no. or customer',
          prefixIcon: Icons.search,
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
        );

        final statusField = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in _statusItems)
              ChoiceChip(
                label: item.child,
                selected: statusFilter == item.value,
                selectedColor: AppColors.primarySoft,
                onSelected: (_) => onStatusFilterChanged(item.value),
              ),
          ],
        );

        final fromField = AppDateField(
          hint: 'From date',
          value: fromFilter,
          onChanged: (date) => date == null
              ? onDateRangeChanged(null, toFilter)
              : onDateRangeChanged(
                  DateTime(date.year, date.month, date.day),
                  toFilter,
                ),
        );

        final toField = AppDateField(
          hint: 'To date',
          value: toFilter,
          onChanged: (date) => date == null
              ? onDateRangeChanged(fromFilter, null)
              : onDateRangeChanged(
                  fromFilter,
                  DateTime(date.year, date.month, date.day, 23, 59, 59),
                ),
        );

        final addButton = SizedBox(
          width: 150,
          child: BrandActionButton(
            label: 'Make bill',
            icon: Icons.add_rounded,
            onPressed: onAddPressed,
          ),
        );

        final dates = Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: isWide ? 190 : (constraints.maxWidth - 12) / 2,
              child: fromField,
            ),
            SizedBox(
              width: isWide ? 190 : (constraints.maxWidth - 12) / 2,
              child: toField,
            ),
            if (searchController.text.isNotEmpty ||
                statusFilter != null ||
                fromFilter != null ||
                toFilter != null)
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.smMd),
                  addButton,
                ],
              ),
              const SizedBox(height: AppSpacing.smMd),
              statusField,
              const SizedBox(height: AppSpacing.smMd),
              dates,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: AppSpacing.smMd),
            statusField,
            const SizedBox(height: AppSpacing.smMd),
            dates,
            const SizedBox(height: AppSpacing.smMd),
            addButton,
          ],
        );
      },
    );
  }
}
