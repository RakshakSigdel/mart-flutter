import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Renders a product/unit's `active` flag as a colored [AppBadge].
class ActiveStatusBadge extends StatelessWidget {
  const ActiveStatusBadge({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: active ? 'Active' : 'Inactive',
      tone: active ? AppBadgeTone.success : AppBadgeTone.neutral,
      icon: active ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded,
    );
  }
}

/// Marks a purchase/selling unit as the product's default for that side of
/// the trade — shown only when true, since "not default" is the common
/// case and doesn't need a badge of its own.
class DefaultUnitBadge extends StatelessWidget {
  const DefaultUnitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBadge(
      label: 'Default',
      tone: AppBadgeTone.tertiary,
      icon: Icons.star_outline_rounded,
    );
  }
}
