import 'package:flutter/material.dart';

import '../../../../core/core.dart';

enum AdminRowAction { edit, resetPassword, provision, retire }

/// The per-row action menu shared by the table (desktop) and card (mobile)
/// layouts, so the set of actions and their icons/labels only live once.
class AdminRowActionsMenu extends StatelessWidget {
  const AdminRowActionsMenu({
    super.key,
    required this.onSelected,
    this.isBusy = false,
  });

  final ValueChanged<AdminRowAction> onSelected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return PopupMenuButton<AdminRowAction>(
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Actions',
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: AdminRowAction.edit,
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit details'),
        ),
        PopupMenuItem(
          value: AdminRowAction.resetPassword,
          child: _MenuRow(icon: Icons.key_outlined, label: 'Reset password'),
        ),
        PopupMenuItem(
          value: AdminRowAction.provision,
          child: _MenuRow(
            icon: Icons.build_circle_outlined,
            label: 'Re-provision schema',
          ),
        ),
        PopupMenuItem(
          value: AdminRowAction.retire,
          child: _MenuRow(
            icon: Icons.block_outlined,
            label: 'Retire mart',
            destructive: true,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.smMd),
        Text(label, style: AppTypography.body.copyWith(color: color)),
      ],
    );
  }
}
