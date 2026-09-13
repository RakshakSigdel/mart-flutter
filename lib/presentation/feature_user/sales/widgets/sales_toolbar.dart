import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/sale_model.dart';

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
    required this.onFindInvoicePressed,
    required this.onAddPressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final PaymentStatus? statusFilter;
  final ValueChanged<PaymentStatus?> onStatusFilterChanged;
  final DateTime? fromFilter;
  final DateTime? toFilter;
  final void Function(DateTime? from, DateTime? to) onDateRangeChanged;
  final VoidCallback onFindInvoicePressed;
  final VoidCallback onAddPressed;

  static const _statusItems = <DropdownMenuItem<PaymentStatus?>>[
    DropdownMenuItem(value: null, child: Text('All statuses')),
    DropdownMenuItem(value: PaymentStatus.unpaid, child: Text('Unpaid')),
    DropdownMenuItem(value: PaymentStatus.partial, child: Text('Partial')),
    DropdownMenuItem(value: PaymentStatus.paid, child: Text('Paid')),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    final search = AppTextField(
      controller: searchController,
      hint: 'Search by invoice or customer',
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: onSearchChanged,
      onSubmitted: onSearchSubmitted,
    );

    final statusField = AppDropdownField<PaymentStatus?>(
      value: statusFilter,
      items: _statusItems,
      onChanged: onStatusFilterChanged,
      hint: 'All statuses',
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

    final addButton = AppButton(
      label: 'New sale',
      leading: const Icon(Icons.add),
      onPressed: onAddPressed,
    );

    final findInvoiceButton = AppButton(
      label: 'Find invoice',
      variant: AppButtonVariant.secondary,
      leading: const Icon(Icons.receipt_long_outlined),
      onPressed: onFindInvoicePressed,
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
              SizedBox(width: 180, child: statusField),
              const SizedBox(width: AppSpacing.smMd),
              findInvoiceButton,
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
        statusField,
        const SizedBox(height: AppSpacing.smMd),
        Row(
          children: [
            Expanded(child: fromField),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(child: toField),
          ],
        ),
        const SizedBox(height: AppSpacing.smMd),
        findInvoiceButton,
        const SizedBox(height: AppSpacing.smMd),
        addButton,
      ],
    );
  }
}
