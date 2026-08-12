import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// A prominent panel with a deep 60px shadow, used for hero sections,
/// profile headers, and large stat summaries.
/// Matches the web `.app-panel` component.
///
/// More visually dominant than [AppCard]. Use for focal content areas,
/// not list items.
class AppPanel extends StatelessWidget {
  const AppPanel({super.key, required this.child, this.padding, this.color});

  final Widget child;

  /// Custom padding. Defaults to [AppSpacing.lg] (24px).
  final EdgeInsetsGeometry? padding;

  /// Override background color. Defaults to white ([AppColors.panel]).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color ?? AppColors.panel,
        borderRadius: AppBorderRadius.radiusXL,
        boxShadow: AppShadows.panel,
      ),
      child: child,
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// // Profile header panel:
// AppPanel(
//   child: Row(
//     children: [
//       CircleAvatar(radius: 36, backgroundImage: NetworkImage(player.avatarUrl)),
//       const SizedBox(width: AppSpacing.md),
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(player.name, style: AppTypography.heading),
//             Text(player.position, style: AppTypography.bodySmall),
//           ],
//         ),
//       ),
//     ],
//   ),
// )
//
// // With gradient background:
// AppPanel(
//   color: Colors.transparent,
//   child: DecoratedBox(
//     decoration: BoxDecoration(gradient: AppGradients.hero),
//     child: ...,
//   ),
// )
