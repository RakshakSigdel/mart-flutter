import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/customer_model.dart';
import 'customer_avatar.dart';
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
  final void Function(CustomerModel customer, CustomerRowAction action)
  onAction;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.eyebrow.copyWith(
      fontSize: 10,
      letterSpacing: 0.8,
      color: AppColors.textMuted,
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: math.max(760, constraints.maxWidth),
          ),
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(
              AppColors.surfaceSunken,
            ),
            headingTextStyle: headerStyle,
            dividerThickness: 1,
            columnSpacing: AppSpacing.lg,
            horizontalMargin: AppSpacing.md,
            dataRowMinHeight: 62,
            dataRowMaxHeight: 62,
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('CUSTOMER')),
              DataColumn(label: Text('PHONE')),
              DataColumn(label: Text('CREDIT LIMIT'), numeric: true),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final customer in customers)
                DataRow(
                  // The whole row opens the customer — the credit details
                  // are the reason anyone visits this table.
                  onSelectChanged: (_) =>
                      onAction(customer, CustomerRowAction.viewDetails),
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomerAvatar(name: customer.name, size: 34),
                            const SizedBox(width: AppSpacing.smMd),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    customer.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    customer.email?.isNotEmpty == true
                                        ? customer.email!
                                        : 'No email',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        customer.phone?.isNotEmpty == true
                            ? customer.phone!
                            : 'Not set',
                        style: AppTypography.bodySmall.copyWith(
                          color: customer.phone?.isNotEmpty == true
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    DataCell(
                      customer.creditLimit > 0
                          ? Text(
                              'Rs. ${formatMoneyAmount(customer.creditLimit)}',
                              style: AppTypography.priceSmall,
                            )
                          : Text('No credit', style: AppTypography.caption),
                    ),
                    DataCell(
                      customer.active
                          ? const AppBadge(
                              label: 'Active',
                              tone: AppBadgeTone.success,
                            )
                          : const AppBadge(
                              label: 'Inactive',
                              tone: AppBadgeTone.neutral,
                            ),
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
