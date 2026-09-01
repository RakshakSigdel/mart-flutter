import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../controllers/profile_controller.dart';

/// Changes the signed-in user's own password. Returns the backend's own
/// confirmation text (via [Navigator.pop]) on success, `null` on cancel —
/// the caller shows that text directly rather than a generic hardcoded
/// message, using a context that's guaranteed to still be mounted (the
/// dialog's own context is on its way out the moment it pops).
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final message = await ref.read(profileControllerProvider.notifier).changePassword(
            currentPassword: _currentPassword.text,
            newPassword: _newPassword.text,
          );
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _currentPassword,
            label: 'Current password',
            obscureText: true,
            autofocus: true,
            enabled: !_submitting,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Current password is required' : null,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _newPassword,
            label: 'New password',
            obscureText: true,
            enabled: !_submitting,
            onSubmitted: (_) => _submit(),
            validator: (v) => (v == null || v.length < 8)
                ? 'Password must be at least 8 characters'
                : null,
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: 'Change password',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

Future<String?> showChangePasswordDialog(BuildContext context) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  const content = ChangePasswordDialog();

  return isWide
      ? showAppDialog<String>(
          context: context,
          title: 'Change password',
          content: content,
        )
      : showAppModal<String>(
          context: context,
          title: 'Change password',
          content: content,
        );
}
