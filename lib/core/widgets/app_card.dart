import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// A standard card with white background, border, and a subtle 32px shadow.
/// Matches the web `.app-card` component.
///
/// Padding defaults to [AppSpacing.mdLg] (20px) to match Tailwind's `p-5`.
/// Pass [padding] to override for tighter or custom layouts.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;

  /// Custom padding. Defaults to EdgeInsets.all(AppSpacing.mdLg).
  final EdgeInsetsGeometry? padding;

  /// Custom margin.
  final EdgeInsetsGeometry? margin;

  /// If provided, wraps the card in an InkWell with ripple.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.mdLg),
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppBorderRadius.radiusXL,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: AppBorderRadius.radiusXL,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.radiusXL,
        splashColor: AppColors.primarySoft,
        highlightColor: Colors.transparent,
        child: card,
      ),
    );
  }
}
