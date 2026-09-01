import 'package:flutter/material.dart';

import '../../../../core/core.dart';

enum InventoryUnitRowAction { edit, remove }

/// The per-row action menu shared by the table (desktop) and card (mobile)
/// layouts, so the set of actions and their icons/labels only live once.
///
/// System-defined units can't be edited or removed (see
/// [InventoryUnitModel.isEditable]) — those rows show a lock icon instead
/// of the action menu.
class InventoryUnitRowActionsMenu extends StatelessWidget {
  const InventoryUnitRowActionsMenu({
    super.key,
    required this.isEditable,
    required this.onSelected,
    this.isBusy = false,
  });

  final bool isEditable;
  final ValueChanged<InventoryUnitRowAction> onSelected;
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

    if (!isEditable) {
      return const Tooltip(
        message: 'System-defined — read only',
        child: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.iconInactive),
      );
    }

    return PopupMenuButton<InventoryUnitRowAction>(
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Actions',
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: InventoryUnitRowAction.edit,
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit unit'),
        ),
        PopupMenuItem(
          value: InventoryUnitRowAction.remove,
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Remove unit',
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
