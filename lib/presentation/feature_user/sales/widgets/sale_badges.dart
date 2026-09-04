import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/sale_model.dart';

/// Where a bill stands against payment — red while nothing's been paid,
/// amber for a partial payment, green once it's settled.
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final parsed = PaymentStatus.fromApiValue(status);
    if (parsed == null) return const SizedBox.shrink();

    final tone = switch (parsed) {
      PaymentStatus.unpaid => AppBadgeTone.error,
      PaymentStatus.partial => AppBadgeTone.warning,
      PaymentStatus.paid => AppBadgeTone.success,
    };

    return AppBadge(label: parsed.label, tone: tone);
  }
}
