import 'package:flutter/material.dart';

import '../animations/app_transitions.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// The placeholder shown where a list, search result or dashboard section has
/// nothing to display — including error states, which are just an empty state
/// with a retry action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.tone = AppEmptyTone.neutral,
    this.compact = false,
  });

  /// A failure state: red icon wash and a "Try again" action by default.
  const AppEmptyState.error({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.icon = Icons.cloud_off_rounded,
    this.actionLabel = 'Try again',
    required this.onAction,
    this.compact = false,
  }) : tone = AppEmptyTone.error;

  /// A "no search results" state.
  const AppEmptyState.noResults({
    super.key,
    this.title = 'No results found',
    this.message = 'Try a different search or clear your filters.',
    this.icon = Icons.search_off_rounded,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  }) : tone = AppEmptyTone.neutral;

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppEmptyTone tone;

  /// Tightens the padding for use inside a card rather than a full page.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isError = tone == AppEmptyTone.error;

    return AppFadeIn(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: compact ? 56 : 72,
              height: compact ? 56 : 72,
              decoration: BoxDecoration(
                color: isError ? AppColors.errorSoft : AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 26 : 32,
                color: isError ? AppColors.error : AppColors.primaryDeep,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.subtitle,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                variant: isError
                    ? AppButtonVariant.secondary
                    : AppButtonVariant.primary,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Whether an empty state reads as "nothing here yet" or "this failed".
enum AppEmptyTone { neutral, error }

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// AppEmptyState(
//   icon: Icons.shopping_cart_outlined,
//   title: 'Your cart is empty',
//   message: 'Browse the catalogue to add your first item.',
//   actionLabel: 'Start shopping',
//   onAction: () => context.go(Routes.home),
// )
//
// AppEmptyState.error(onAction: _reload)
//
// const AppEmptyState.noResults()
