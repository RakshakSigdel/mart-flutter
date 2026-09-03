import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';

/// Shown for any unknown route, whenever go_router fails to build one, and
/// (pushed directly at [Routes.notFound]) for a sidebar item this build of
/// the app doesn't have a screen for yet — see `sidebar_menu_registry.dart`.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.location});

  /// The path that could not be resolved. Shown only in debug builds — in
  /// release it is noise to the user.
  final String? location;

  @override
  Widget build(BuildContext context) {
    // Reached by pushing on top of something (a sidebar link to a page
    // this build doesn't implement yet, mainly) — pop back to it directly
    // rather than sending the user all the way to their landing screen.
    // Only a genuinely bad deep link (nothing underneath to pop to) falls
    // back to that.
    final canGoBack = context.canPop();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppScaleIn(
                    child: Text(
                      '404',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -3,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppFadeSlideIn(
                    delay: AppAnimations.fast,
                    child: Column(
                      children: [
                        Text(
                          'Page not found',
                          style: AppTypography.heading,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'The page you were looking for has moved, or never '
                          'existed.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (location != null && kDebugMode) ...[
                          const SizedBox(height: AppSpacing.smMd),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.smMd,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSunken,
                              borderRadius: AppBorderRadius.radiusSM,
                            ),
                            child: Text(
                              location!,
                              style: AppTypography.caption,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: canGoBack ? 'Go back' : 'Back to start',
                          leading: const Icon(Icons.arrow_back),
                          onPressed: () {
                            if (canGoBack) {
                              context.pop();
                            } else {
                              context.go(Routes.splash);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
