import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/staff_model.dart';

/// Renders a staff account's `status` as a colored [AppBadge].
class StaffStatusBadge extends StatelessWidget {
  const StaffStatusBadge({super.key, required this.status});

  final StaffStatus? status;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (status) {
      StaffStatus.active => (
          'Active',
          AppBadgeTone.success,
          Icons.check_circle_outline_rounded,
        ),
      StaffStatus.inactive => (
          'Inactive',
          AppBadgeTone.neutral,
          Icons.pause_circle_outline_rounded,
        ),
      StaffStatus.suspended => (
          'Suspended',
          AppBadgeTone.error,
          Icons.block_outlined,
        ),
      null => ('Unknown', AppBadgeTone.neutral, Icons.help_outline_rounded),
    };
    return AppBadge(label: label, tone: tone, icon: icon);
  }
}

/// Renders a staff member's `role` as a plain (unfilled) [AppBadge] — every
/// role reads the same way, there's no success/warning/error axis to it.
class StaffRoleBadge extends StatelessWidget {
  const StaffRoleBadge({super.key, required this.role});

  final StaffRole? role;

  @override
  Widget build(BuildContext context) {
    return AppBadge(label: role?.label ?? 'Unknown', tone: AppBadgeTone.neutral);
  }
}
