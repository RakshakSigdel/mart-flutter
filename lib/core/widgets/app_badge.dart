import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Semantic tone of a badge — drives its fill and text color.
enum AppBadgeTone { neutral, primary, success, warning, error, info, tertiary }

/// A small pill for statuses and counts: "In stock", "Pending", "-20%".
///
/// Soft fill with a saturated label, so a row of badges stays readable
/// without shouting over the content it annotates.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
    this.solid = false,
  });

  /// A filled, high-contrast badge — for the one status that matters most
  /// in a list (e.g. "Out of stock").
  const AppBadge.solid({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.primary,
    this.icon,
  }) : solid = true;

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  /// Whether to use the saturated fill instead of the soft one.
  final bool solid;

  Color get _color => switch (tone) {
    AppBadgeTone.neutral => AppColors.textSecondary,
    AppBadgeTone.primary => AppColors.primary,
    AppBadgeTone.success => AppColors.success,
    AppBadgeTone.warning => AppColors.warning,
    AppBadgeTone.error => AppColors.error,
    AppBadgeTone.info => AppColors.info,
    AppBadgeTone.tertiary => AppColors.tertiary,
  };

  Color get _softColor => switch (tone) {
    AppBadgeTone.neutral => AppColors.surface,
    AppBadgeTone.primary => AppColors.primarySoft,
    AppBadgeTone.success => AppColors.successSoft,
    AppBadgeTone.warning => AppColors.warningSoft,
    AppBadgeTone.error => AppColors.errorSoft,
    AppBadgeTone.info => AppColors.infoSoft,
    AppBadgeTone.tertiary => AppColors.tertiarySoft,
  };

  /// Yellow needs a dark label; the other tones are dark enough for white.
  Color get _onSolidColor =>
      tone == AppBadgeTone.primary || tone == AppBadgeTone.warning
      ? AppColors.textOnPrimary
      : AppColors.textInverse;

  /// On a soft yellow fill, plain yellow text would vanish — use the deep
  /// brand tone instead.
  Color get _onSoftColor =>
      tone == AppBadgeTone.primary ? AppColors.primaryDeep : _color;

  @override
  Widget build(BuildContext context) {
    final foreground = solid ? _onSolidColor : _onSoftColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: solid ? _color : _softColor,
        borderRadius: AppBorderRadius.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// AppBadge(label: 'In stock', tone: AppBadgeTone.success)
//
// AppBadge(
//   label: 'Pending',
//   tone: AppBadgeTone.warning,
//   icon: Icons.schedule,
// )
//
// AppBadge.solid(label: '-20%', tone: AppBadgeTone.error)
