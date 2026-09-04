import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/stock_model.dart';

/// Whether a product's on-hand quantity needs attention — green when it
/// doesn't, amber/red the closer it gets to (or past) zero.
class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({super.key, required this.status});

  final StockStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null) return const SizedBox.shrink();

    final tone = switch (status) {
      StockStatus.inStock => AppBadgeTone.success,
      StockStatus.lowStock => AppBadgeTone.warning,
      StockStatus.outOfStock => AppBadgeTone.error,
    };

    return AppBadge(label: status.label, tone: tone);
  }
}
