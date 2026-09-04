import 'package:flutter/material.dart';

import '../../../../core/core.dart';

enum StockRowAction { viewDetails, setReorderLevel }

/// The per-row action menu shared by the table (desktop) and card (mobile)
/// layouts, so the set of actions and their icons/labels only live once.
///
/// Adjusting or writing off stock needs a fuller form (unit, remark) and
/// only lives on the detail screen — see `StockDetailScreen`.
class StockRowActionsMenu extends StatelessWidget {
  const StockRowActionsMenu({
    super.key,
    required this.onSelected,
    this.isBusy = false,
  });

  final ValueChanged<StockRowAction> onSelected;
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

    return PopupMenuButton<StockRowAction>(
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Actions',
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: StockRowAction.viewDetails,
          child: _MenuRow(
            icon: Icons.visibility_outlined,
            label: 'View details',
          ),
        ),
        PopupMenuItem(
          value: StockRowAction.setReorderLevel,
          child: _MenuRow(icon: Icons.tune_rounded, label: 'Set reorder level'),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.smMd),
        Text(label, style: AppTypography.body),
      ],
    );
  }
}
