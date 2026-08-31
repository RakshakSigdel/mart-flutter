import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_superadmin/admin_model.dart';
import 'admin_date_format.dart';
import 'admin_row_actions.dart';
import 'admin_status_badges.dart';

/// Phone layout — one card per mart, stacked in a list.
class AdminListCard extends StatelessWidget {
  const AdminListCard({
    super.key,
    required this.admin,
    required this.isBusy,
    required this.onAction,
  });

  final AdminModel admin;
  final bool isBusy;
  final ValueChanged<AdminRowAction> onAction;

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
                    Text(admin.companyName, style: AppTypography.subtitle),
                    Text(admin.slug, style: AppTypography.caption),
                  ],
                ),
              ),
              AdminRowActionsMenu(isBusy: isBusy, onSelected: onAction),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AccountStatusBadge(status: admin.status),
              ProvisioningStatusBadge(status: admin.provisioningStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.smMd),
          _InfoRow(icon: Icons.person_outline, label: admin.username),
          _InfoRow(icon: Icons.mail_outline, label: admin.email),
          _InfoRow(
            icon: Icons.event_outlined,
            label:
                'Subscription until ${formatAdminDate(admin.subscriptionExpiresAt)}',
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
