import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import '../feature_shared/auth/controller/auth_controller.dart';

/// First screen the app shows.
///
/// Holds the brand while it checks for a saved session, then hands off to
/// the login screen, or straight past it to the right landing screen for
/// the restored user's role.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Started immediately so it overlaps with the minimum on-screen delay
    // below rather than adding to it.
    final restoreFuture = ref
        .read(authControllerProvider.notifier)
        .restoreSession();

    // Minimum on-screen time so the logo does not flash on a fast start.
    await Future<void>.delayed(AppAnimations.deliberate);
    final restored = await restoreFuture;
    if (!mounted) return;

    if (!restored) {
      context.go(Routes.login);
      return;
    }

    final session = (ref.read(authControllerProvider) as AuthAuthenticated)
        .session;
    context.go(session.isSuperAdmin ? Routes.adminManagement : Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                  child: Image.asset(
                    'assets/icon/icon.png',
                    height: 48,
                    width: 48,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppFadeSlideIn(
                delay: AppAnimations.fast,
                child: Column(
                  children: [
                    Text('Retail Management', style: AppTypography.heading),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'POINT OF SALE',
                      style: AppTypography.eyebrow.copyWith(
                        color: AppColors.primaryDeep,
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
    );
  }
}
