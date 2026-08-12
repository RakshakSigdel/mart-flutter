import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradient tokens for the Rakshak Mart design system.
class AppGradients {
  AppGradients._();

  /// Primary yellow gradient — used on primary CTA buttons, active header elements
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDark],
  );

  /// Accent gradient — used on badges, dark stat highlights
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentSoft, AppColors.accent],
  );

  /// Background gradient — subtle page depth, top to bottom
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surface, AppColors.background],
  );

  /// Hero gradient — used on hero/banner sections, translucent overlay
  static final LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.accent.withValues(alpha: 0.12),
      AppColors.primary.withValues(alpha: 0.08),
    ],
  );

  /// Dark hero gradient — black banner with a warm brand glow in one corner
  static final LinearGradient heroDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentElevated, AppColors.accent],
  );

  /// Image scrim — bottom-up fade so inverse text stays readable over photos
  static final LinearGradient imageScrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      AppColors.accent.withValues(alpha: 0.72),
      AppColors.accent.withValues(alpha: 0.0),
    ],
  );

  /// Soft primary gradient — chip selected state, secondary highlights
  static const LinearGradient softPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primarySoft, AppColors.card],
  );

  /// Card shimmer gradient — for skeleton loading states.
  /// Consumed by `AppShimmer`, which slides it across the placeholder.
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.skeletonBase,
      AppColors.skeletonHighlight,
      AppColors.skeletonBase,
    ],
    stops: [0.0, 0.5, 1.0],
  );
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// // As a container background:
// Container(
//   decoration: BoxDecoration(
//     gradient: AppGradients.primary,
//     borderRadius: AppBorderRadius.radiusXL,
//   ),
// )
//
// // As a page background:
// DecoratedBox(
//   decoration: BoxDecoration(gradient: AppGradients.background),
//   child: ...,
// )
//
// // As a hero section overlay:
// Container(
//   decoration: BoxDecoration(gradient: AppGradients.hero),
// )
