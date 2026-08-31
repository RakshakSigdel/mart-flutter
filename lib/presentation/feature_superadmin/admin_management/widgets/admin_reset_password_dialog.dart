import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../controllers/admin_management_controller.dart';

/// Sets a mart admin's password. Returns the backend's own confirmation
/// text (via [Navigator.pop]) on success, `null` on cancel — the caller
/// shows that text directly rather than a generic hardcoded message, using
/// a context that's guaranteed to still be mounted (the dialog's own
/// context is on its way out the moment it pops).
class AdminResetPasswordDialog extends ConsumerStatefulWidget {
  const AdminResetPasswordDialog({
    super.key,
    required this.adminId,
    required this.companyName,
  });

  final String adminId;
  final String companyName;

  @override
  ConsumerState<AdminResetPasswordDialog> createState() =>
      _AdminResetPasswordDialogState();
}

class _AdminResetPasswordDialogState
    extends ConsumerState<AdminResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final message = await ref
          .read(adminManagementControllerProvider.notifier)
          .resetPassword(widget.adminId, _password.text);
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
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
          Text(
            'Set a new password for the admin account at '
            '${widget.companyName}.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _password,
            label: 'New password',
            obscureText: true,
            autofocus: true,
            enabled: !_submitting,
            onSubmitted: (_) => _submit(),
            validator: (v) => (v == null || v.length < 8)
                ? 'Password must be at least 8 characters'
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: 'Reset password',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

Future<String?> showAdminResetPasswordDialog(
  BuildContext context, {
  required String adminId,
  required String companyName,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  final content = AdminResetPasswordDialog(
    adminId: adminId,
    companyName: companyName,
  );

  return isWide
      ? showAppDialog<String>(
          context: context,
          title: 'Reset password',
          content: content,
        )
      : showAppModal<String>(
          context: context,
          title: 'Reset password',
          content: content,
        );
}
