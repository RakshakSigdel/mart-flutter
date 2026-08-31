import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../controller/auth_controller.dart';
import '../widgets/login_form.dart';

/// Staff sign-in. The only entry point into the app for now — no
/// registration, no password reset. Where it lands after a successful
/// login depends on role — see [Routes] and `routerProvider`'s redirect.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref
        .read(authControllerProvider.notifier)
        .login(_usernameController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isSubmitting = authState is AuthAuthenticating;
    // Shown inline in the form — see LoginForm's errorMessage doc comment
    // for why this isn't a snack bar.
    final errorMessage = authState is AuthError ? authState.message : null;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        context.go(
          next.session.isSuperAdmin ? Routes.adminManagement : Routes.dashboard,
        );
      }
    });

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    final card = ClipRRect(
      borderRadius: isWide ? AppBorderRadius.radiusXL : BorderRadius.zero,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Hero(),
            LoginForm(
              formKey: _formKey,
              usernameController: _usernameController,
              passwordController: _passwordController,
              isSubmitting: isSubmitting,
              onSubmit: _submit,
              errorMessage: errorMessage,
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      // A subtle tint on wide screens so the centered card reads as a card;
      // on phone the card fills the width so this color never shows.
      backgroundColor: isWide ? AppColors.surface : AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: isWide ? AppSpacing.xxxl : 0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: responsiveValue(
                  width: width,
                  phone: double.infinity,
                  tablet: 460,
                  desktop: 460,
                ),
              ),
              child: isWide
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppBorderRadius.radiusXL,
                        boxShadow: AppShadows.panel,
                      ),
                      child: card,
                    )
                  : card,
            ),
          ),
        ),
      ),
    );
  }
}

/// Brand header — light, matching the rest of the app.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppScaleIn(
            duration: AppAnimations.slow,
            from: 0.8,
            child: Container(
              width: 72,
              height: 72,
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
          const SizedBox(height: AppSpacing.md),
          AppFadeSlideIn(
            delay: AppAnimations.fast,
            child: Column(
              children: [
                Text('Retail Management', style: AppTypography.heading),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'STAFF LOGIN',
                  style: AppTypography.eyebrow.copyWith(
                    color: AppColors.primaryDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
