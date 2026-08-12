import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Tone of a snack bar — picks its icon and accent color.
enum AppSnackTone { neutral, success, error, warning, info }

/// App-wide toast messages.
///
/// Always go through here rather than building a raw [SnackBar], so every
/// message shares the same shape, placement and dismiss behaviour.
///
/// ```dart
/// AppSnackBar.success(context, 'Order placed');
/// AppSnackBar.error(context, 'Could not reach the server');
/// ```
class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message, {String? action, VoidCallback? onAction}) =>
      show(context, message, tone: AppSnackTone.success, actionLabel: action, onAction: onAction);

  static void error(BuildContext context, String message, {String? action, VoidCallback? onAction}) =>
      show(context, message, tone: AppSnackTone.error, actionLabel: action, onAction: onAction);

  static void warning(BuildContext context, String message, {String? action, VoidCallback? onAction}) =>
      show(context, message, tone: AppSnackTone.warning, actionLabel: action, onAction: onAction);

  static void info(BuildContext context, String message, {String? action, VoidCallback? onAction}) =>
      show(context, message, tone: AppSnackTone.info, actionLabel: action, onAction: onAction);

  /// Shows a snack bar, replacing any that is already on screen so messages
  /// never queue up behind each other.
  static void show(
    BuildContext context,
    String message, {
    AppSnackTone tone = AppSnackTone.neutral,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.smMd,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusMD),
          content: Row(
            children: [
              Icon(_icon(tone), size: 20, color: _accent(tone)),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ],
          ),
          action: (actionLabel != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: AppColors.primary,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  /// Dismisses whatever is currently showing — e.g. when navigating away.
  static void dismiss(BuildContext context) =>
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();

  static IconData _icon(AppSnackTone tone) => switch (tone) {
    AppSnackTone.success => Icons.check_circle_outline_rounded,
    AppSnackTone.error => Icons.error_outline_rounded,
    AppSnackTone.warning => Icons.warning_amber_rounded,
    AppSnackTone.info => Icons.info_outline_rounded,
    AppSnackTone.neutral => Icons.notifications_none_rounded,
  };

  static Color _accent(AppSnackTone tone) => switch (tone) {
    AppSnackTone.success => AppColors.success,
    AppSnackTone.error => AppColors.error,
    AppSnackTone.warning => AppColors.warning,
    AppSnackTone.info => AppColors.info,
    AppSnackTone.neutral => AppColors.primary,
  };
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// AppSnackBar.success(context, 'Item added to cart');
//
// AppSnackBar.error(
//   context,
//   'Payment failed',
//   action: 'Retry',
//   onAction: _retryPayment,
// );
