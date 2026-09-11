import 'package:flutter/material.dart';

import '../../../../core/core.dart';

enum CustomerRowAction { viewDetails, edit, remove }

class CustomerRowActionsMenu extends StatelessWidget {
  const CustomerRowActionsMenu({
    super.key,
    required this.onSelected,
    this.isBusy = false,
  });

  final ValueChanged<CustomerRowAction> onSelected;
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

    return PopupMenuButton<CustomerRowAction>(
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Actions',
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: CustomerRowAction.viewDetails,
          child: _MenuRow(
            icon: Icons.visibility_outlined,
            label: 'View details',
          ),
        ),
        PopupMenuItem(
          value: CustomerRowAction.edit,
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit customer'),
        ),
        PopupMenuItem(
          value: CustomerRowAction.remove,
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Remove customer',
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
