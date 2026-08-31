import 'package:flutter/material.dart';

import '../../../../core/core.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onSubmit,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  /// Shown inline, above the submit button, instead of a snack bar — a
  /// failed login is a form-level problem the user is already looking at
  /// this screen to fix, not a background event.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      delay: AppAnimations.fast,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sign in', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Use your existing staff account to continue.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: usernameController,
                label: 'Username',
                hint: 'Enter your username',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                enabled: !isSubmitting,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Username is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.smMd),
              AppTextField(
                controller: passwordController,
                label: 'Password',
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enabled: !isSubmitting,
                onSubmitted: (_) => onSubmit(),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Password is required'
                    : null,
              ),
              AppFormError(message: errorMessage),
              const SizedBox(height: AppSpacing.xl),
              AppButton.expanded(
                label: 'Sign in',
                isLoading: isSubmitting,
                onPressed: isSubmitting ? null : onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
