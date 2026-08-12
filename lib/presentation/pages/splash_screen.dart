import 'package:flutter/material.dart';

import '../../core/core.dart';

/// First screen the app shows.
///
/// Holds the brand while startup work runs. Wire the real hand-off in
/// [_bootstrap] once auth exists: check the stored session, then
/// `context.go(...)` to the dashboard or the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Minimum on-screen time so the logo does not flash on a fast start.
    await Future<void>.delayed(AppAnimations.deliberate);
    if (!mounted) return;

    // TODO(auth): restore the session and redirect, e.g.
    // context.go(session.isValid ? Routes.dashboard : Routes.staffLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.heroDark),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                AppScaleIn(
                  duration: AppAnimations.slow,
                  from: 0.8,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: AppBorderRadius.radiusXL,
                      boxShadow: AppShadows.button,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 48,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppFadeSlideIn(
                  delay: AppAnimations.fast,
                  child: Column(
                    children: [
                      Text(
                        'Rakshak Mart',
                        style: AppTypography.heading.copyWith(
                          color: AppColors.textInverse,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'POINT OF SALE',
                        style: AppTypography.eyebrow.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AppFadeIn(
                  delay: AppAnimations.normal,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
