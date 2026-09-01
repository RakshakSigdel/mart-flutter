import 'package:flutter/material.dart';

import '../../../../core/core.dart';

enum InventoryCategoryRowAction { viewDetails, edit, remove }

/// The per-row action menu shared by the table (desktop) and card (mobile)
/// layouts, so the set of actions and their icons/labels only live once.
///
/// Whether a category can actually be removed depends on its product
/// count, which the summary list this menu is used from doesn't carry (see
/// `InventoryCategoryModel`) — a category with products still shows
/// "Remove"; the backend rejects it and the row surfaces that error rather
/// than the menu guessing client-side.
class InventoryCategoryRowActionsMenu extends StatelessWidget {
  const InventoryCategoryRowActionsMenu({
    super.key,
    required this.onSelected,
    this.isBusy = false,
  });

  final ValueChanged<InventoryCategoryRowAction> onSelected;
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

    return PopupMenuButton<InventoryCategoryRowAction>(
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Actions',
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: InventoryCategoryRowAction.viewDetails,
          child: _MenuRow(icon: Icons.visibility_outlined, label: 'View details'),
        ),
        PopupMenuItem(
          value: InventoryCategoryRowAction.edit,
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit category'),
        ),
        PopupMenuItem(
          value: InventoryCategoryRowAction.remove,
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Remove category',
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
