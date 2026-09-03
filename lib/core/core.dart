/// The Rakshak Mart design system, in one import.
///
/// ```dart
/// import 'package:sts_retail/core/core.dart';
/// ```
library;

// ─── Theme tokens ─────────────────────────────────────────────────────────────
export 'theme/app_breakpoints.dart';
export 'theme/app_colors.dart';
export 'theme/app_gradients.dart';
export 'theme/app_radius.dart';
export 'theme/app_shadows.dart';
export 'theme/app_spacing.dart';
export 'theme/app_theme.dart';
export 'theme/app_typography.dart';

// ─── Motion ───────────────────────────────────────────────────────────────────
export 'animations/animation_constants.dart';
export 'animations/app_page_route.dart';
export 'animations/app_transitions.dart';

// ─── Routing ──────────────────────────────────────────────────────────────────
// Only the route names live here. `routes/app_router.dart` is imported
// directly by main.dart — exporting it would pull every screen in the app
// into every file that imports core.dart.
export 'routes/route_constants.dart';

// ─── Utilities ────────────────────────────────────────────────────────────────
export 'utils/debouncer.dart';

// ─── Design system widgets ────────────────────────────────────────────────────
export 'widgets/app_badge.dart';
export 'widgets/app_button.dart';
export 'widgets/app_card.dart';
export 'widgets/app_dropdown_field.dart';
export 'widgets/app_empty_state.dart';
export 'widgets/app_form_error.dart';
export 'widgets/app_loader.dart';
export 'widgets/app_modal.dart';
export 'widgets/app_panel.dart';
export 'widgets/app_searchable_dropdown.dart';
export 'widgets/app_section_title.dart';
export 'widgets/app_snack_bar.dart';
export 'widgets/app_soft_card.dart';
export 'widgets/app_text_field.dart';

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// In any screen or widget, import everything with a single line:
//
// import 'package:sts_retail/core/core.dart';
//
// Then use freely:
//
// AppButton(label: 'Save', onPressed: _save)
// AppCard(child: ...)
// AppBadge(label: 'In stock', tone: AppBadgeTone.success)
// AppSnackBar.success(context, 'Saved')
// AppStaggered(index: i, child: ...)
// AppColors.primary
// AppTypography.heading
//
// Two rules keep this system coherent:
//   1. Never write a raw Color, radius, shadow or spacing value in a screen —
//      add a token instead.
//   2. Never write a raw Duration or Curve — use AppAnimations.
