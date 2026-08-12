import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// A softer, flatter card with a muted warm background and no border.
/// Matches the web `.app-card-soft` component.
///
/// Use for secondary content areas, stat summaries, or inline info blocks
/// that should not compete visually with [AppCard].
class AppSoftCard extends StatelessWidget {
  const AppSoftCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;

  /// Custom padding. Defaults to EdgeInsets.all(AppSpacing.mdLg).
  final EdgeInsetsGeometry? padding;

  /// If provided, wraps the card in an InkWell with ripple.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.mdLg),
      decoration: BoxDecoration(
        // Approximates CSS: color-mix(in srgb, var(--app-panel) 90%, var(--app-bg))
        color: AppColors.cardSoft,
        borderRadius: AppBorderRadius.radiusXL,
        boxShadow: AppShadows.soft,
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

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// // Stat summary row inside a profile screen:
// Row(
//   children: [
//     Expanded(
//       child: AppSoftCard(
//         padding: const EdgeInsets.all(AppSpacing.md),
//         child: Column(
//           children: [
//             Text('12', style: AppTypography.heading),
//             Text('Goals', style: AppTypography.caption),
//           ],
//         ),
//       ),
//     ),
//     const SizedBox(width: AppSpacing.sm),
//     Expanded(
//       child: AppSoftCard(
//         padding: const EdgeInsets.all(AppSpacing.md),
//         child: Column(
//           children: [
//             Text('7', style: AppTypography.heading),
//             Text('Assists', style: AppTypography.caption),
//           ],
//         ),
//       ),
//     ),
//   ],
// )
