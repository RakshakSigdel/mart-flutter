import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Search box and the "Add vendor" action.
///
/// Stacks vertically on phone; sits in one row on wider screens — the same
/// content either way, just laid out differently.
class VendorsToolbar extends StatelessWidget {
  const VendorsToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onHistoryPressed,
    required this.onAddPressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onHistoryPressed;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    final search = AppTextField(
      controller: searchController,
      hint: 'Search by name, contact number or PAN',
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: onSearchChanged,
      onSubmitted: onSearchSubmitted,
    );

    final addButton = AppButton(
      label: 'Add vendor',
      leading: const Icon(Icons.add),
      onPressed: onAddPressed,
    );

    final historyButton = AppButton(
      label: 'All history',
      variant: AppButtonVariant.secondary,
      leading: const Icon(Icons.history_rounded),
      onPressed: onHistoryPressed,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: search),
          const SizedBox(width: AppSpacing.smMd),
          historyButton,
          const SizedBox(width: AppSpacing.smMd),
          addButton,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        search,
        const SizedBox(height: AppSpacing.smMd),
        historyButton,
        const SizedBox(height: AppSpacing.smMd),
        addButton,
      ],
    );
  }
}
