import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_superadmin/admin_model.dart';
import 'admin_date_format.dart';
import 'admin_row_actions.dart';
import 'admin_status_badges.dart';

/// Tablet/desktop layout — one row per mart in a scrollable table.
class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.admins,
    required this.busyIds,
    required this.onAction,
  });

  final List<AdminModel> admins;
  final Set<String> busyIds;
  final void Function(AdminModel admin, AdminRowAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.eyebrow.copyWith(letterSpacing: 0.4);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: math.max(900, constraints.maxWidth),
          ),
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
            headingTextStyle: headerStyle,
            columnSpacing: AppSpacing.lg,
            columns: const [
              DataColumn(label: Text('COMPANY')),
              DataColumn(label: Text('CONTACT')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('PROVISIONING')),
              DataColumn(label: Text('SUBSCRIPTION')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final admin in admins)
                DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              admin.companyName,
                              style: AppTypography.subtitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              admin.slug,
                              style: AppTypography.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              admin.username,
                              style: AppTypography.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              admin.email,
                              style: AppTypography.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(AccountStatusBadge(status: admin.status)),
                    DataCell(
                      ProvisioningStatusBadge(status: admin.provisioningStatus),
                    ),
                    DataCell(
                      Text(formatAdminDate(admin.subscriptionExpiresAt)),
                    ),
                    DataCell(
                      AdminRowActionsMenu(
                        isBusy: busyIds.contains(admin.id),
                        onSelected: (action) => onAction(admin, action),
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
