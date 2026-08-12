import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A section heading with an optional eyebrow label above the title
/// and an optional trailing action (e.g. "View all" button).
///
/// Matches the `.app-eyebrow` + `.app-title` pattern from the web design system.
///
/// Example layout:
///   NATIONAL LEAGUE          (eyebrow — small caps, muted)
///   Top Players              (title — bold, large)
///                  View all →  (trailing action, right-aligned)
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.bottomSpacing = AppSpacing.md,
  });

  /// Main bold title text.
  final String title;

  /// Optional small-caps eyebrow shown above the title.
  final String? eyebrow;

  /// Optional widget placed at the trailing (right) end of the title row.
  /// Typically an [AppButton] with ghost variant or a [TextButton].
  final Widget? trailing;

  /// Spacing below the section title before content. Defaults to [AppSpacing.md].
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(eyebrow!.toUpperCase(), style: AppTypography.eyebrow),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A lighter variant — no eyebrow, smaller title size, used for
/// in-card sub-sections.
class AppSubSectionTitle extends StatelessWidget {
  const AppSubSectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.bottomSpacing = AppSpacing.sm,
  });

  final String title;
  final Widget? trailing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: AppTypography.subtitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            DefaultTextStyle(
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// // With eyebrow + trailing action:
// AppSectionTitle(
//   eyebrow: 'National League',
//   title: 'Top Players',
//   trailing: AppButton(
//     label: 'View all',
//     variant: AppButtonVariant.ghost,
//     size: AppButtonSize.sm,
//     onPressed: () => context.push('/players'),
//     trailing: const Icon(Icons.chevron_right),
//   ),
// )
//
// // Simple section header (no eyebrow):
// AppSectionTitle(title: 'Recent Matches')
//
// // In-card sub-section:
// AppSubSectionTitle(
//   title: 'Match Statistics',
//   trailing: TextButton(onPressed: () {}, child: Text('Details')),
// )
