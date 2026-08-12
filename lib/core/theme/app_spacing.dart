/// Spacing scale for the AYGH design system.
/// All padding, margin, and gap values must come from here.
///
/// Based on an 8-point grid system.
class AppSpacing {
  AppSpacing._();

  /// 4px — tight spacing, icon gaps, small badges
  static const double xs = 4.0;

  /// 8px — compact spacing, between label and input
  static const double sm = 8.0;

  /// 12px — between related elements, internal chip padding
  static const double smMd = 12.0;

  /// 16px — default content padding, card internal padding
  static const double md = 16.0;

  /// 20px — section internal padding, card header padding (matches p-5 in Tailwind)
  static const double mdLg = 20.0;

  /// 24px — between sections, button horizontal padding
  static const double lg = 24.0;

  /// 32px — large section gaps
  static const double xl = 32.0;

  /// 40px — page-level vertical rhythm
  static const double xxl = 40.0;

  /// 48px — hero sections, large breathing room
  static const double xxxl = 48.0;
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// Padding(
//   padding: EdgeInsets.all(AppSpacing.md),
//   child: ...,
// )
//
// SizedBox(height: AppSpacing.lg)
//
// EdgeInsets.symmetric(
//   horizontal: AppSpacing.mdLg,
//   vertical: AppSpacing.sm,
// )
