import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/staff_model.dart';
import 'staff_date_format.dart';
import 'staff_row_actions.dart';
import 'staff_status_badges.dart';

/// Phone layout — one card per staff member, stacked in a list.
class StaffListCard extends StatelessWidget {
  const StaffListCard({
    super.key,
    required this.staff,
    required this.isBusy,
    required this.onAction,
  });

  final StaffModel staff;
  final bool isBusy;
  final ValueChanged<StaffRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.displayName, style: AppTypography.subtitle),
                    Text(staff.username, style: AppTypography.caption),
                  ],
                ),
              ),
              StaffRowActionsMenu(isBusy: isBusy, onSelected: onAction),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StaffRoleBadge(role: staff.role),
              StaffStatusBadge(status: staff.status),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.smMd),
          _InfoRow(icon: Icons.mail_outline, label: staff.email),
          if (staff.mobileNumber != null && staff.mobileNumber!.isNotEmpty)
            _InfoRow(icon: Icons.call_outlined, label: staff.mobileNumber!),
          _InfoRow(
            icon: Icons.event_outlined,
            label: 'Last login ${formatStaffDate(staff.lastLoginAt)}',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.iconInactive),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
