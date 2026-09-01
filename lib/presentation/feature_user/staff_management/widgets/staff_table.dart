import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/staff_model.dart';
import 'staff_date_format.dart';
import 'staff_row_actions.dart';
import 'staff_status_badges.dart';

/// Tablet/desktop layout — one row per staff member in a scrollable table.
class StaffTable extends StatelessWidget {
  const StaffTable({
    super.key,
    required this.staff,
    required this.busyIds,
    required this.onAction,
  });

  final List<StaffModel> staff;
  final Set<String> busyIds;
  final void Function(StaffModel staff, StaffRowAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.eyebrow.copyWith(letterSpacing: 0.4);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 900),
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
          headingTextStyle: headerStyle,
          columnSpacing: AppSpacing.lg,
          columns: const [
            DataColumn(label: Text('STAFF')),
            DataColumn(label: Text('CONTACT')),
            DataColumn(label: Text('ROLE')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('LAST LOGIN')),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final member in staff)
              DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            member.displayName,
                            style: AppTypography.subtitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            member.username,
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
                      child: Text(
                        member.email,
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(StaffRoleBadge(role: member.role)),
                  DataCell(StaffStatusBadge(status: member.status)),
                  DataCell(Text(formatStaffDate(member.lastLoginAt))),
                  DataCell(
                    StaffRowActionsMenu(
                      isBusy: busyIds.contains(member.id),
                      onSelected: (action) => onAction(member, action),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
