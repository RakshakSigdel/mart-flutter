import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/vendor_model.dart';

/// Which side of the account a ledger entry/balance sits on — amber for
/// what the mart owes the vendor, green for the reverse.
class VendorBalanceTypeBadge extends StatelessWidget {
  const VendorBalanceTypeBadge({super.key, required this.type});

  final VendorBalanceType? type;

  @override
  Widget build(BuildContext context) {
    final type = this.type;
    if (type == null) return const SizedBox.shrink();

    return AppBadge(
      label: type.label,
      tone: type == VendorBalanceType.payable
          ? AppBadgeTone.warning
          : AppBadgeTone.success,
      icon: type == VendorBalanceType.payable
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded,
    );
  }
}
