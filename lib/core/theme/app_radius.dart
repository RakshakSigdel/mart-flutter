import 'package:flutter/material.dart';

/// Border radius tokens for the AYGH design system.
/// Use [AppBorderRadius] for [BorderRadius] objects and [AppRadius] for raw [double] values.
class AppRadius {
  AppRadius._();

  /// 6px — small elements: tags, inline badges
  static const double xs = 6.0;

  /// 8px — inputs, small buttons
  static const double sm = 8.0;

  /// 12px — chips, secondary buttons
  static const double md = 12.0;

  /// 16px — cards, primary buttons, inputs (matches rounded-2xl area)
  static const double lg = 16.0;

  /// 20px — panels, modals (matches rounded-[1.25rem] in web)
  static const double xl = 20.0;

  /// 999px — fully rounded: pill buttons, chips, avatars
  static const double full = 999.0;
}

/// Pre-built [BorderRadius] objects for direct use in [BoxDecoration] and [ShapeBorder].
class AppBorderRadius {
  AppBorderRadius._();

  static final BorderRadius radiusXS = BorderRadius.circular(AppRadius.xs);
  static final BorderRadius radiusSM = BorderRadius.circular(AppRadius.sm);
  static final BorderRadius radiusMD = BorderRadius.circular(AppRadius.md);
  static final BorderRadius radiusL = BorderRadius.circular(AppRadius.lg);
  static final BorderRadius radiusXL = BorderRadius.circular(AppRadius.xl);
  static final BorderRadius radiusFull = BorderRadius.circular(AppRadius.full);
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// // In BoxDecoration:
// BoxDecoration(borderRadius: AppBorderRadius.radiusXL)
//
// // In RoundedRectangleBorder (buttons, cards):
// RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusL)
//
// // Raw value when you need a double:
// BorderRadius.circular(AppRadius.md)
