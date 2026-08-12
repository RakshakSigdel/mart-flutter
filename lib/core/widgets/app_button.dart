import 'package:flutter/material.dart';

import '../animations/animation_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Button variant.
enum AppButtonVariant {
  /// Yellow fill, dark label — the single main action on a screen.
  primary,

  /// White fill with a border — the alternative to a primary action.
  secondary,

  /// Black fill, white label — high emphasis without spending brand yellow.
  dark,

  /// Red fill — destructive actions only.
  danger,

  /// No fill or border — tertiary actions, "view all" links.
  ghost,
}

/// Button size.
enum AppButtonSize { sm, md, lg }

/// Unified button widget for the Rakshak Mart design system.
///
/// For full-width buttons (common in mobile forms), wrap in a SizedBox:
///   SizedBox(width: double.infinity, child: AppButton(...))
///
/// Or use the [AppButton.expanded] constructor.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.expanded = false,
  });

  /// Convenience constructor for full-width buttons.
  const AppButton.expanded({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.lg,
    this.leading,
    this.trailing,
    this.isLoading = false,
  }) : expanded = true;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Optional leading icon (e.g. Icon(Icons.add))
  final Widget? leading;

  /// Optional trailing icon
  final Widget? trailing;

  /// Shows a [CircularProgressIndicator] in place of [leading] when true.
  final bool isLoading;

  /// Whether to stretch to full available width.
  final bool expanded;

  // ─── Size helpers ─────────────────────────────────────────────────────────

  double get _height => switch (size) {
    AppButtonSize.sm => 36.0,
    AppButtonSize.md => 44.0,
    AppButtonSize.lg => 52.0,
  };

  double get _fontSize => switch (size) {
    AppButtonSize.sm => 13.0,
    AppButtonSize.md => 14.0,
    AppButtonSize.lg => 15.0,
  };

  EdgeInsetsGeometry get _padding => switch (size) {
    AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: AppSpacing.smMd),
    AppButtonSize.md => const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    AppButtonSize.lg => const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  };

  // ─── Style helpers ────────────────────────────────────────────────────────

  bool get _enabled => onPressed != null;

  Color get _backgroundColor => switch (variant) {
    AppButtonVariant.primary => AppColors.primary,
    AppButtonVariant.secondary => AppColors.card,
    AppButtonVariant.dark => AppColors.accent,
    AppButtonVariant.danger => AppColors.error,
    AppButtonVariant.ghost => Colors.transparent,
  };

  /// Yellow is a light fill — its label must be dark, never white.
  Color get _foregroundColor => switch (variant) {
    AppButtonVariant.primary => AppColors.textOnPrimary,
    AppButtonVariant.secondary => AppColors.textPrimary,
    AppButtonVariant.dark => AppColors.textInverse,
    AppButtonVariant.danger => AppColors.textInverse,
    AppButtonVariant.ghost => AppColors.accent,
  };

  /// Disabled state uses the flat disabled tokens rather than a faded brand
  /// color, so a disabled primary never reads as "just a paler button".
  Color get _disabledBackgroundColor => switch (variant) {
    AppButtonVariant.ghost => Colors.transparent,
    AppButtonVariant.secondary => AppColors.card,
    _ => AppColors.btnDisabled,
  };

  BorderSide get _border => switch (variant) {
    AppButtonVariant.secondary => BorderSide(
      color: _enabled ? AppColors.borderStrong : AppColors.border,
    ),
    _ => BorderSide.none,
  };

  List<BoxShadow> get _shadows => switch (variant) {
    AppButtonVariant.primary => AppShadows.button,
    _ => AppShadows.none,
  };

  /// Ripple color, picked to stay visible against each fill.
  Color get _splashColor => switch (variant) {
    AppButtonVariant.dark ||
    AppButtonVariant.danger => AppColors.rippleOnDark,
    _ => AppColors.pressedOverlay,
  };

  @override
  Widget build(BuildContext context) {
    final foreground = _enabled
        ? _foregroundColor
        : AppColors.btnDisabledText;

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        else if (leading != null) ...[
          IconTheme(
            data: IconThemeData(color: foreground, size: 18),
            child: leading!,
          ),
        ],
        if ((leading != null || isLoading) && label.isNotEmpty)
          const SizedBox(width: AppSpacing.sm),
        if (label.isNotEmpty)
          Text(
            label,
            style: AppTypography.label.copyWith(
              fontSize: _fontSize,
              color: foreground,
            ),
          ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconTheme(
            data: IconThemeData(color: foreground, size: 18),
            child: trailing!,
          ),
        ],
      ],
    );

    final button = AnimatedContainer(
      duration: AppAnimations.instant,
      curve: AppAnimations.standard,
      height: _height,
      decoration: BoxDecoration(
        color: _enabled ? _backgroundColor : _disabledBackgroundColor,
        borderRadius: AppBorderRadius.radiusL,
        border: Border.fromBorderSide(_border),
        boxShadow: _enabled ? _shadows : AppShadows.none,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppBorderRadius.radiusL,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppBorderRadius.radiusL,
          splashColor: _splashColor,
          highlightColor: Colors.transparent,
          child: Padding(padding: _padding, child: content),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// // Primary (default) — one per screen:
// AppButton(label: 'Add to cart', onPressed: _addToCart)
//
// // Secondary / outline:
// AppButton(
//   label: 'Cancel',
//   variant: AppButtonVariant.secondary,
//   onPressed: () => Navigator.pop(context),
// )
//
// // Dark — high emphasis without spending brand yellow:
// AppButton(
//   label: 'Checkout',
//   variant: AppButtonVariant.dark,
//   onPressed: _checkout,
// )
//
// // Danger:
// AppButton(
//   label: 'Remove item',
//   variant: AppButtonVariant.danger,
//   onPressed: _remove,
// )
//
// // Ghost:
// AppButton(
//   label: 'View all',
//   variant: AppButtonVariant.ghost,
//   onPressed: () => context.push(Routes.products),
//   trailing: const Icon(Icons.arrow_forward),
// )
//
// // Full-width with loading state:
// AppButton.expanded(
//   label: 'Sign in',
//   onPressed: _isLoading ? null : _signIn,
//   isLoading: _isLoading,
// )
//
// // Small with icon:
// AppButton(
//   label: 'Add',
//   size: AppButtonSize.sm,
//   leading: const Icon(Icons.add),
//   onPressed: _showAddDialog,
// )
