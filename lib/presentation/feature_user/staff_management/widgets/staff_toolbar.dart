import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/staff_model.dart';

/// Search box, role/status filters, and the "Hire staff" action.
///
/// Stacks vertically on phone; sits in one row on wider screens — the same
/// content either way, just laid out differently.
class StaffToolbar extends StatelessWidget {
  const StaffToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.roleFilter,
    required this.onRoleFilterChanged,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.onHirePressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final StaffRole? roleFilter;
  final ValueChanged<StaffRole?> onRoleFilterChanged;
  final StaffStatus? statusFilter;
  final ValueChanged<StaffStatus?> onStatusFilterChanged;
  final VoidCallback onHirePressed;

  static final _roleItems = <DropdownMenuItem<StaffRole?>>[
    const DropdownMenuItem(value: null, child: Text('All roles')),
    for (final role in StaffRole.values)
      DropdownMenuItem(
        value: role,
        child: Text(role.label, overflow: TextOverflow.ellipsis),
      ),
  ];

  static final _statusItems = <DropdownMenuItem<StaffStatus?>>[
    const DropdownMenuItem(value: null, child: Text('All statuses')),
    for (final status in StaffStatus.values)
      DropdownMenuItem(
        value: status,
        child: Text(status.label, overflow: TextOverflow.ellipsis),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    final search = AppTextField(
      controller: searchController,
      hint: 'Search by name, username or email',
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: onSearchChanged,
      onSubmitted: onSearchSubmitted,
    );

    final roleFilterField = SizedBox(
      width: isWide ? 200 : double.infinity,
      child: AppDropdownField<StaffRole?>(
        value: roleFilter,
        items: _roleItems,
        onChanged: onRoleFilterChanged,
        hint: 'All roles',
      ),
    );

    final statusFilterField = SizedBox(
      width: isWide ? 200 : double.infinity,
      child: AppDropdownField<StaffStatus?>(
        value: statusFilter,
        items: _statusItems,
        onChanged: onStatusFilterChanged,
        hint: 'All statuses',
      ),
    );

    final hireButton = AppButton(
      label: 'Hire staff',
      leading: const Icon(Icons.person_add_alt_1_rounded),
      onPressed: onHirePressed,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: search),
          const SizedBox(width: AppSpacing.smMd),
          roleFilterField,
          const SizedBox(width: AppSpacing.smMd),
          statusFilterField,
          const SizedBox(width: AppSpacing.smMd),
          hireButton,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        search,
        const SizedBox(height: AppSpacing.smMd),
        roleFilterField,
        const SizedBox(height: AppSpacing.smMd),
        statusFilterField,
        const SizedBox(height: AppSpacing.smMd),
        hireButton,
      ],
    );
  }
}
