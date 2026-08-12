import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shadow tokens for the Rakshak Mart design system.
///
/// Every shadow is tinted with a brand color rather than pure black, so
/// elevation reads as part of the palette instead of a grey smudge.
class AppShadows {
  AppShadows._();

  /// Card shadow — subtle, used on [AppCard]
  static final List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.06),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  /// Panel shadow — deeper, used on [AppPanel] and hero sections
  static final List<BoxShadow> panel = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.08),
      blurRadius: 60,
      offset: const Offset(0, 20),
    ),
  ];

  /// Button shadow — yellow-tinted glow for primary buttons
  static final List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.32),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Modal shadow — deep, for dialogs lifted above a barrier
  static final List<BoxShadow> modal = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 50,
      offset: const Offset(0, 25),
    ),
  ];

  /// Floating shadow — for FABs, tooltips, dropdowns
  static final List<BoxShadow> floating = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  /// Soft card shadow — very subtle, used on [AppSoftCard]
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.03),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  /// Bottom bar shadow — cast upward, for bars pinned to the bottom edge
  static final List<BoxShadow> bottomBar = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, -8),
    ),
  ];

  /// Focus ring — a soft yellow halo drawn around a focused control
  static final List<BoxShadow> focus = [
    BoxShadow(color: AppColors.focusRing, blurRadius: 0, spreadRadius: 3),
  ];

  /// No shadow — use instead of `[]` so intent is explicit at call sites.
  static const List<BoxShadow> none = [];
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// BoxDecoration(
//   boxShadow: AppShadows.card,
// )
//
// BoxDecoration(
//   boxShadow: isFocused ? AppShadows.focus : AppShadows.none,
// )
