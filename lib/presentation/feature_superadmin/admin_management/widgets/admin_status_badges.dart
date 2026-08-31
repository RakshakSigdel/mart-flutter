import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_superadmin/admin_model.dart';

/// Renders a mart's `provisioningStatus` as a colored [AppBadge].
class ProvisioningStatusBadge extends StatelessWidget {
  const ProvisioningStatusBadge({super.key, required this.status});

  final AdminProvisioningStatus? status;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (status) {
      AdminProvisioningStatus.ready => (
          'Ready',
          AppBadgeTone.success,
          Icons.check_circle_outline_rounded,
        ),
      AdminProvisioningStatus.pending => (
          'Pending',
          AppBadgeTone.warning,
          Icons.schedule_rounded,
        ),
      AdminProvisioningStatus.failed => (
          'Failed',
          AppBadgeTone.error,
          Icons.error_outline_rounded,
        ),
      null => ('Unknown', AppBadgeTone.neutral, Icons.help_outline_rounded),
    };
    return AppBadge(label: label, tone: tone, icon: icon);
  }
}

/// Renders a mart's account `status` (a free string — see [AdminModel.status]).
class AccountStatusBadge extends StatelessWidget {
  const AccountStatusBadge({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final label = (status == null || status!.isEmpty) ? 'Unknown' : status!;
    final tone = status == 'ACTIVE' ? AppBadgeTone.success : AppBadgeTone.neutral;
    return AppBadge(label: label, tone: tone);
  }
}
