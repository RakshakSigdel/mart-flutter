import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../shared/widgets/section_ui.dart';

/// Search box and the "Add category" action.
///
/// Stacks vertically on phone; sits in one row on wider screens — the same
/// content either way, just laid out differently.
class InventoryCategoriesToolbar extends StatelessWidget {
  const InventoryCategoriesToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onAddPressed,
    required this.onClearSearch,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onAddPressed;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final search = AppTextField(
          controller: searchController,
          hint: 'Search categories by name',
          prefixIcon: Icons.search,
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
        );

        final addButton = SizedBox(
          width: 180,
          child: BrandActionButton(
            label: 'Add category',
            icon: Icons.add_rounded,
            onPressed: onAddPressed,
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: search),
              if (searchController.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClearSearch,
                  icon: const Icon(Icons.close_rounded),
                ),
              const SizedBox(width: AppSpacing.smMd),
              addButton,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            if (searchController.text.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onClearSearch,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Clear search'),
                ),
              ),
            const SizedBox(height: AppSpacing.smMd),
            addButton,
          ],
        );
      },
    );
  }
}
