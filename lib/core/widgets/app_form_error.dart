import 'package:flutter/material.dart';

import '../animations/app_transitions.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// An inline, form-level error banner — for a failed submit the user is
/// already looking at this form to fix, not a background event a snack bar
/// would suit better.
///
/// Safe to pass a `null` [message]: the banner animates its own height to
/// zero rather than the caller needing to conditionally include it.
class AppFormError extends StatelessWidget {
  const AppFormError({super.key, this.message, this.padding});

  final String? message;

  /// Defaults to top-only spacing, for placing this right after the last
  /// field and before the submit button.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppExpandable(
      expanded: message != null,
      child: Padding(
        padding: padding ?? const EdgeInsets.only(top: AppSpacing.smMd),
        child: message == null
            ? const SizedBox.shrink()
            : _Banner(message: message!),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smMd,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: AppBorderRadius.radiusMD,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// Column(
//   children: [
//     ...fields,
//     AppFormError(message: errorMessage),
//     AppButton.expanded(label: 'Save', onPressed: _submit),
//   ],
// )
