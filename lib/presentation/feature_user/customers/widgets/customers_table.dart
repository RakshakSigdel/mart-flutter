import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/customer_model.dart';
import 'customer_row_actions.dart';

class CustomersTable extends StatelessWidget {
  const CustomersTable({
    super.key,
    required this.customers,
    required this.busyIds,
    required this.onAction,
  });

  final List<CustomerModel> customers;
  final Set<int> busyIds;
  final void Function(CustomerModel customer, CustomerRowAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.eyebrow.copyWith(letterSpacing: 0.4);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: math.max(800, constraints.maxWidth),
          ),
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
            headingTextStyle: headerStyle,
            columnSpacing: AppSpacing.lg,
            columns: const [
              DataColumn(label: Text('NAME')),
              DataColumn(label: Text('PHONE')),
              DataColumn(label: Text('EMAIL')),
              DataColumn(label: Text('CREDIT LIMIT')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final customer in customers)
                DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          customer.name,
                          style: AppTypography.subtitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () =>
                          onAction(customer, CustomerRowAction.viewDetails),
                    ),
                    DataCell(
                      Text(
                        customer.phone?.isNotEmpty == true
                            ? customer.phone!
                            : '—',
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          customer.email?.isNotEmpty == true
                              ? customer.email!
                              : '—',
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text('Rs. ${customer.creditLimit.toStringAsFixed(2)}'),
                    ),
                    DataCell(
                      customer.active
                          ? const AppBadge(label: 'Active', tone: AppBadgeTone.success)
                          : const AppBadge(label: 'Inactive', tone: AppBadgeTone.neutral),
                    ),
                    DataCell(
                      CustomerRowActionsMenu(
                        isBusy: busyIds.contains(customer.id),
                        onSelected: (action) => onAction(customer, action),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
