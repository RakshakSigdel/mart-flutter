import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens for the Rakshak Mart design system.
/// Mirrors the web text utility classes:
///   .app-title, .app-subtitle, .app-eyebrow, .app-muted
///
/// Prefer these over Theme.of(context).textTheme.* in screens and widgets,
/// so that text styles remain consistent regardless of context inheritance.
class AppTypography {
  AppTypography._();

  /// The single source of truth for the app font family.
  ///
  /// `null` means "use the platform default" — no font asset is bundled yet.
  /// Add a font to `pubspec.yaml` and set this to its family name; every
  /// style below and the whole [ThemeData] follow along automatically.
  static const String? fontFamily = null;

  /// Consistent external labels for text inputs and both dropdown styles.
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  // ─── Display ──────────────────────────────────────────────────────────────

  /// 32px / ExtraBold — page hero titles
  /// Matches: headlineLarge in ThemeData
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  /// 28px / Bold — section-level display text
  static const TextStyle displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ─── Headings ─────────────────────────────────────────────────────────────

  /// 24px / Bold — screen-level headings (e.g. "Player Profile")
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// 20px / Bold — section titles inside a screen
  /// Mirrors: .app-title
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// 16px / SemiBold — card titles, list item headings
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────

  /// 16px / Regular — default body text
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// 14px / Regular — secondary body, descriptions
  /// Mirrors: .app-muted  (color is textSecondary)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ─── Labels ───────────────────────────────────────────────────────────────

  /// 14px / Bold — button labels, tab labels
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textPrimary,
  );

  /// 12px / SemiBold — form field labels, meta info
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.textSecondary,
  );

  // ─── Eyebrow / Caption ────────────────────────────────────────────────────

  /// 11px / Bold / UpperCase — section eyebrows, category labels
  /// Mirrors: .app-eyebrow
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    height: 1.0,
    color: AppColors.textSecondary,
  );

  /// 12px / Regular — timestamps, helper text, captions
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textMuted,
  );

  // ─── Numeric ──────────────────────────────────────────────────────────────

  /// 22px / Bold / tabular figures — prices, totals, cart amounts.
  /// Tabular figures keep digits the same width so columns of prices align.
  static const TextStyle price = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  /// 14px / SemiBold / tabular figures — inline prices in list rows.
  static const TextStyle priceSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  /// 28px / ExtraBold / tabular figures — dashboard stat values.
  static const TextStyle metric = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1.0,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  /// 14px / Regular with a strikethrough — original price next to a discount.
  static const TextStyle priceStruck = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.2,
    decoration: TextDecoration.lineThrough,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textMuted,
  );
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// Text('Player Profile', style: AppTypography.heading)
//
// Text('Clubs', style: AppTypography.title)
//
// Text('Joined 2023', style: AppTypography.caption)
//
// Text(
//   'NATIONAL LEAGUE',
//   style: AppTypography.eyebrow.copyWith(color: AppColors.primary),
// )
//
// Text(
//   'Ahmed Al-Rashid',
//   style: AppTypography.subtitle,
// )
