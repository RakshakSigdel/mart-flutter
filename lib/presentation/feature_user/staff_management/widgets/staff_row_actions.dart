import 'package:flutter/material.dart';

import '../../../../core/core.dart';

enum StaffRowAction { edit, resetPassword, retire }

/// The per-row action menu shared by the table (desktop) and card (mobile)
/// layouts, so the set of actions and their icons/labels only live once.
class StaffRowActionsMenu extends StatelessWidget {
  const StaffRowActionsMenu({
    super.key,
    required this.onSelected,
    this.isBusy = false,
  });

  final ValueChanged<StaffRowAction> onSelected;
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

    return PopupMenuButton<StaffRowAction>(
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Actions',
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: StaffRowAction.edit,
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit details'),
        ),
        PopupMenuItem(
          value: StaffRowAction.resetPassword,
          child: _MenuRow(icon: Icons.key_outlined, label: 'Reset password'),
        ),
        PopupMenuItem(
          value: StaffRowAction.retire,
          child: _MenuRow(
            icon: Icons.block_outlined,
            label: 'Retire staff',
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
