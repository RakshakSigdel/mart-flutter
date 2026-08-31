import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_superadmin/admin_model.dart';
import '../controllers/admin_management_controller.dart';
import 'admin_date_format.dart';

/// Create/edit form for one mart. Returns `true` via [Navigator.pop] when
/// the save succeeded, so the caller can show a snackbar with a context
/// that's guaranteed to still be mounted (the dialog's own context is on
/// its way out the moment it pops).
///
/// Opened through [showAdminFormDialog] rather than directly, so callers
/// don't have to know it needs a wide-screen dialog vs. a phone bottom
/// sheet — see that function.
class AdminFormDialog extends ConsumerStatefulWidget {
  const AdminFormDialog({super.key, this.admin});

  /// Null for "create a new mart"; the mart being edited otherwise.
  final AdminModel? admin;

  bool get isEditing => admin != null;

  @override
  ConsumerState<AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends ConsumerState<AdminFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _username = TextEditingController(text: widget.admin?.username);
  late final _email = TextEditingController(text: widget.admin?.email);
  late final _password = TextEditingController();
  late final _fullName = TextEditingController(text: widget.admin?.fullName);
  late final _mobileNumber = TextEditingController(
    text: widget.admin?.mobileNumber,
  );
  late final _companyName = TextEditingController(
    text: widget.admin?.companyName,
  );
  late final _companyAddress = TextEditingController(
    text: widget.admin?.companyAddress,
  );
  late final _companyPhone = TextEditingController(
    text: widget.admin?.companyPhone,
  );
  late final _registrationNumber = TextEditingController(
    text: widget.admin?.registrationNumber,
  );
  late final _slug = TextEditingController(text: widget.admin?.slug);
  late final _subscriptionExpiresAtText = TextEditingController(
    text: widget.admin?.subscriptionExpiresAt == null
        ? ''
        : formatAdminDate(widget.admin!.subscriptionExpiresAt),
  );

  DateTime? _subscriptionExpiresAt;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _subscriptionExpiresAt = widget.admin?.subscriptionExpiresAt;
  }

  @override
  void dispose() {
    for (final c in [
      _username,
      _email,
      _password,
      _fullName,
      _mobileNumber,
      _companyName,
      _companyAddress,
      _companyPhone,
      _registrationNumber,
      _slug,
      _subscriptionExpiresAtText,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickSubscriptionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _subscriptionExpiresAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _subscriptionExpiresAt = picked;
        _subscriptionExpiresAtText.text = formatAdminDate(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final controller = ref.read(adminManagementControllerProvider.notifier);
    try {
      if (widget.isEditing) {
        await controller.updateAdmin(
          widget.admin!.id,
          UpdateAdminRequest(
            username: _username.text.trim(),
            email: _email.text.trim(),
            fullName: _fullName.text.trim(),
            mobileNumber: _emptyToNull(_mobileNumber.text),
            companyName: _companyName.text.trim(),
            companyAddress: _emptyToNull(_companyAddress.text),
            companyPhone: _emptyToNull(_companyPhone.text),
            registrationNumber: _emptyToNull(_registrationNumber.text),
            subscriptionExpiresAt: _subscriptionExpiresAt,
          ),
        );
      } else {
        await controller.createAdmin(
          CreateAdminRequest(
            username: _username.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            mobileNumber: _emptyToNull(_mobileNumber.text),
            companyName: _companyName.text.trim(),
            companyAddress: _emptyToNull(_companyAddress.text),
            companyPhone: _emptyToNull(_companyPhone.text),
            registrationNumber: _emptyToNull(_registrationNumber.text),
            slug: _slug.text.trim(),
            subscriptionExpiresAt: _subscriptionExpiresAt,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  String? _requiredValidator(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? '$label is required' : null;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Company'),
          AppTextField(
            controller: _companyName,
            label: 'Company name',
            enabled: !_submitting,
            validator: (v) => _requiredValidator(v, 'Company name'),
          ),
          const SizedBox(height: AppSpacing.smMd),
          if (!widget.isEditing) ...[
            AppTextField(
              controller: _slug,
              label: 'Slug',
              hint: 'Used in the mart\'s URL/schema — cannot change later',
              enabled: !_submitting,
              validator: (v) => _requiredValidator(v, 'Slug'),
            ),
            const SizedBox(height: AppSpacing.smMd),
          ],
          AppTextField(
            controller: _companyAddress,
            label: 'Company address',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _companyPhone,
            label: 'Company phone',
            keyboardType: TextInputType.phone,
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _registrationNumber,
            label: 'Registration number',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          _DateField(
            label: 'Subscription expires',
            controller: _subscriptionExpiresAtText,
            enabled: !_submitting,
            onTap: _pickSubscriptionDate,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Admin account'),
          AppTextField(
            controller: _username,
            label: 'Username',
            enabled: !_submitting,
            validator: (v) => _requiredValidator(v, 'Username'),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            enabled: !_submitting,
            validator: (v) => _requiredValidator(v, 'Email'),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _fullName,
            label: 'Full name',
            enabled: !_submitting,
            validator: (v) => _requiredValidator(v, 'Full name'),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _mobileNumber,
            label: 'Mobile number',
            keyboardType: TextInputType.phone,
            enabled: !_submitting,
          ),
          if (!widget.isEditing) ...[
            const SizedBox(height: AppSpacing.smMd),
            AppTextField(
              controller: _password,
              label: 'Password',
              obscureText: true,
              enabled: !_submitting,
              validator: (v) => (v == null || v.length < 8)
                  ? 'Password must be at least 8 characters'
                  : null,
            ),
          ],
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: widget.isEditing ? 'Save changes' : 'Create mart',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text.toUpperCase(), style: AppTypography.eyebrow),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AbsorbPointer(
        child: AppTextField(
          controller: controller,
          label: label,
          hint: 'Select a date',
          readOnly: true,
          enabled: enabled,
          suffixIcon: Icons.calendar_today_outlined,
        ),
      ),
    );
  }
}

/// Opens [AdminFormDialog] as a centered dialog on wide screens, or a
/// bottom sheet on phone — same content, the presentation matches the
/// device. Returns `true` if the mart was created/updated.
Future<bool?> showAdminFormDialog(BuildContext context, {AdminModel? admin}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  final title = admin == null ? 'New mart' : 'Edit ${admin.companyName}';
  final content = AdminFormDialog(admin: admin);

  return isWide
      ? showAppDialog<bool>(context: context, title: title, content: content)
      : showAppModal<bool>(context: context, title: title, content: content);
}
