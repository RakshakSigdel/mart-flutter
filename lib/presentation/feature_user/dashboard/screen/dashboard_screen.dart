import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Landing screen after sign-in. Only auth is built so far — this stands in
/// for the real dashboard until that feature exists, but already shows the
/// session data the login now returns (name, role, company).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(session?.companyName ?? 'Retail Management'),
        actions: [
          IconButton(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: responsiveValue(
                width: width,
                phone: double.infinity,
                tablet: 480,
                desktop: 480,
              ),
            ),
            child: AppFadeIn(
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 32,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Welcome, ${session?.displayName ?? 'Staff'}',
                      style: AppTypography.title,
                      textAlign: TextAlign.center,
                    ),
                    if (session?.role != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      AppBadge(label: session!.role!, tone: AppBadgeTone.primary),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'You are signed in. The real dashboard isn\'t built yet '
                      '— this screen is a placeholder.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Log out',
                      variant: AppButtonVariant.secondary,
                      leading: const Icon(Icons.logout),
                      onPressed: () => _logout(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
