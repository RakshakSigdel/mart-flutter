import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_superadmin/admin_model.dart';

/// Search box, provisioning-status filter, and the "New mart" action.
///
/// Stacks vertically on phone; sits in one row on wider screens — the same
/// content either way, just laid out differently.
class AdminToolbar extends StatelessWidget {
  const AdminToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.onCreatePressed,
    required this.onRunMigrationsPressed,
    required this.isRunningMigrations,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final AdminProvisioningStatus? statusFilter;
  final ValueChanged<AdminProvisioningStatus?> onStatusFilterChanged;
  final VoidCallback onCreatePressed;
  final VoidCallback onRunMigrationsPressed;
  final bool isRunningMigrations;

  static const _filterItems = <DropdownMenuItem<AdminProvisioningStatus?>>[
    DropdownMenuItem(value: null, child: Text('All statuses')),
    DropdownMenuItem(
      value: AdminProvisioningStatus.pending,
      child: Text('Pending'),
    ),
    DropdownMenuItem(
      value: AdminProvisioningStatus.ready,
      child: Text('Ready'),
    ),
    DropdownMenuItem(
      value: AdminProvisioningStatus.failed,
      child: Text('Failed'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    final search = AppTextField(
      controller: searchController,
      hint: 'Search by company or username',
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: onSearchChanged,
      onSubmitted: onSearchSubmitted,
    );

    final filter = SizedBox(
      width: isWide ? 200 : double.infinity,
      child: AppDropdownField<AdminProvisioningStatus?>(
        value: statusFilter,
        items: _filterItems,
        onChanged: onStatusFilterChanged,
        hint: 'All statuses',
      ),
    );

    final migrationsButton = AppButton(
      label: 'Run migrations',
      variant: AppButtonVariant.secondary,
      leading: const Icon(Icons.sync_rounded),
      isLoading: isRunningMigrations,
      onPressed: isRunningMigrations ? null : onRunMigrationsPressed,
    );

    final createButton = AppButton(
      label: 'New mart',
      leading: const Icon(Icons.add),
      onPressed: onCreatePressed,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: search),
          const SizedBox(width: AppSpacing.smMd),
          filter,
          const SizedBox(width: AppSpacing.smMd),
          migrationsButton,
          const SizedBox(width: AppSpacing.smMd),
          createButton,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        search,
        const SizedBox(height: AppSpacing.smMd),
        filter,
        const SizedBox(height: AppSpacing.smMd),
        Row(
          children: [
            Expanded(child: migrationsButton),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(child: createButton),
          ],
        ),
      ],
    );
  }
}
