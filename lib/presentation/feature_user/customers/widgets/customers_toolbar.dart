import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Search box and the "Add customer" action.
class CustomersToolbar extends StatelessWidget {
  const CustomersToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onAddPressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    final search = AppTextField(
      controller: searchController,
      hint: 'Search by name, phone or email',
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: onSearchChanged,
      onSubmitted: onSearchSubmitted,
    );

    final addButton = AppButton(
      label: 'Add customer',
      leading: const Icon(Icons.add),
      onPressed: onAddPressed,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: search),
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
        addButton,
      ],
    );
  }
}
