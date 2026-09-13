import 'package:flutter/material.dart';

/// All color tokens for the Rakshak Mart design system.
///
/// Nothing outside this file may declare a raw [Color]. Screens, widgets and
/// the other token files (gradients, shadows, theme) all read from here.
class AppColors {
  AppColors._();

  // ─── Brand ────────────────────────────────────────────────────────────────

  /// Primary yellow — buttons, active states, focus rings, highlights
  static const Color primary = Color(0xFFFFBF1F);

  /// Pressed/darker yellow — button pressed state, gradient endpoint
  static const Color primaryDark = Color(0xFFE0A400);

  /// Deepest yellow — text/icons that must read as "brand" on light fills
  static const Color primaryDeep = Color(0xFF9A6F00);

  /// Soft yellow — chip backgrounds, subtle highlights
  static const Color primarySoft = Color(0xFFFFF4D1);

  /// Accent black — secondary brand color, nav bars, headers, dark surfaces
  static const Color accent = Color(0xFF121212);

  /// Accent elevated — dark surfaces stacked on top of [accent]
  static const Color accentElevated = Color(0xFF1F1F1F);

  /// Soft accent — muted dark tint for badges / subtle dark highlights
  static const Color accentSoft = Color(0xFFE7E5DE);

  // ─── Backgrounds ──────────────────────────────────────────────────────────

  /// Page background — main screen background
  static const Color background = Color(0xFFFFFFFF);

  /// Surface — cards, section backgrounds, containers on top of background
  static const Color surface = Color(0xFFF7F7F4);

  /// Surface sunken — inputs, wells, inset regions
  static const Color surfaceSunken = Color(0xFFEFEDE7);

  /// Card background — white
  static const Color card = Color(0xFFFFFFFF);

  /// Soft card — muted panel background
  static const Color cardSoft = Color(0xFFF6F5F1);

  /// Panel — elevated section background
  static const Color panel = Color(0xFFFFFFFF);

  /// Dark background — dark sections / bottom nav
  static const Color backgroundDark = Color(0xFF121212);

  // ─── Buttons ──────────────────────────────────────────────────────────────

  /// Disabled button fill
  static const Color btnDisabled = Color(0xFFE7E5DE);

  /// Disabled button text
  static const Color btnDisabledText = Color(0xFFA8A59C);

  // ─── Text ─────────────────────────────────────────────────────────────────

  /// Primary text — headings, body
  static const Color textPrimary = Color(0xFF141414);

  /// Secondary text — subtext, descriptions
  static const Color textSecondary = Color(0xFF3D3D3D);

  /// Muted text — hints, placeholders, timestamps
  static const Color textMuted = Color(0xFF73736C);

  /// Inverse text — white, used on dark/black surfaces
  static const Color textInverse = Color(0xFFFFFFFF);

  /// Text on yellow surfaces — dark, used on primary/warning fills.
  /// Yellow is a light color; white text on it is unreadable.
  static const Color textOnPrimary = Color(0xFF121212);

  // ─── Borders & Dividers ───────────────────────────────────────────────────

  /// Default border
  static const Color border = Color(0xFFE7E7E0);

  /// Strong border — used for emphasis, dividers between sections
  static const Color borderStrong = Color(0xFFD0CDC3);

  /// Border on dark surfaces
  static const Color borderDark = Color(0xFF2A2A2A);

  /// Focus ring — yellow at 35%, drawn around focused inputs/controls
  static const Color focusRing = Color(0x59FFBF1F);

  // ─── Semantic ─────────────────────────────────────────────────────────────

  /// Error / destructive actions
  static const Color error = Color(0xFFD93A3A);

  /// Soft error — backgrounds for error badges / containers
  static const Color errorSoft = Color(0xFFFCEBEB);

  /// Success / positive states
  static const Color success = Color(0xFF16A46B);

  /// Soft success — backgrounds for success badges / containers
  static const Color successSoft = Color(0xFFE7F6EF);

  /// Warning / caution states — kept distinct from primary yellow
  static const Color warning = Color(0xFFF08C00);

  /// Soft warning — backgrounds for warning badges / containers
  static const Color warningSoft = Color(0xFFFEF2E3);

  /// Informational states
  static const Color info = Color(0xFF2C6BE5);

  /// Soft info — backgrounds for info badges / containers
  static const Color infoSoft = Color(0xFFE9EFFC);

  /// Tertiary brand color — used for variety in dashboard metrics
  static const Color tertiary = Color(0xFF6B4EFF);

  /// Soft tertiary — backgrounds for tertiary badges / containers
  static const Color tertiarySoft = Color(0xFFEFEBFF);

  // ─── Icons ────────────────────────────────────────────────────────────────

  /// Icon on light surfaces
  static const Color iconActive = Color(0xFF121212);

  /// Icon on dark/yellow surfaces
  static const Color iconActiveOnDark = primary;

  /// Inactive icon
  static const Color iconInactive = Color(0xFF8C8A84);

  // ─── Overlay & feedback ───────────────────────────────────────────────────

  /// Modal backdrop — black at 45% opacity
  static const Color modalBarrier = Color(0x73000000);

  /// Scrim over imagery so inverse text stays readable
  static const Color scrim = Color(0x99000000);

  /// Hover overlay on light surfaces
  static const Color hoverOverlay = Color(0x0D000000);

  /// Pressed overlay on light surfaces
  static const Color pressedOverlay = Color(0x14000000);

  /// Splash/ripple on dark or primary fills
  static const Color rippleOnDark = Color(0x1FFFFFFF);

  /// Skeleton base — resting color of a loading placeholder
  static const Color skeletonBase = Color(0xFFEDEBE3);

  /// Skeleton highlight — the band that sweeps across a shimmer
  static const Color skeletonHighlight = Color(0xFFF9F8F4);
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// Container(color: AppColors.primary)
//
// Text('Hello', style: TextStyle(color: AppColors.textSecondary))
//
// Border.all(color: AppColors.border)
//
// // Text sitting on a yellow button/surface must use textOnPrimary, not
// // textInverse — yellow is a light color, white text will be unreadable.
// Text('Continue', style: TextStyle(color: AppColors.textOnPrimary))
//
// // Never do this in a widget or screen:
// // Container(color: Color(0xFFFFBF1F))  ← wrong
