import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/staff_model.dart';
import '../controllers/staff_management_controller.dart';
import 'staff_date_format.dart';

const _genderOptions = <DropdownMenuItem<String?>>[
  DropdownMenuItem(value: null, child: Text('Not specified')),
  DropdownMenuItem(value: 'MALE', child: Text('Male')),
  DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
];

/// Hire/edit form for one staff member. Calls [Navigator.pop] with `true`
/// when the save succeeds, so the caller (`StaffFormScreen`) can show a
/// snackbar with a context that's guaranteed to still be mounted.
///
/// Plain content — no page chrome of its own. Hosted by `StaffFormScreen`
/// rather than a dialog: the field count made a dialog/bottom-sheet feel
/// cramped, so this is a full page instead.
class StaffForm extends ConsumerStatefulWidget {
  const StaffForm({super.key, this.staff});

  /// Null for "hire a new staff member"; the staff being edited otherwise.
  final StaffModel? staff;

  bool get isEditing => staff != null;

  @override
  ConsumerState<StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends ConsumerState<StaffForm> {
  final _formKey = GlobalKey<FormState>();

  late final _username = TextEditingController(text: widget.staff?.username);
  late final _email = TextEditingController(text: widget.staff?.email);
  late final _password = TextEditingController();
  late final _fullName = TextEditingController(text: widget.staff?.fullName);
  late final _mobileNumber = TextEditingController(text: widget.staff?.mobileNumber);
  late final _country = TextEditingController(text: widget.staff?.country);
  late final _addressLine1 = TextEditingController(text: widget.staff?.addressLine1);
  late final _addressLine2 = TextEditingController(text: widget.staff?.addressLine2);
  late final _city = TextEditingController(text: widget.staff?.city);
  late final _state = TextEditingController(text: widget.staff?.state);
  late final _zipCode = TextEditingController(text: widget.staff?.zipCode);
  late final _dobText = TextEditingController(
    text: widget.staff?.dob == null ? '' : formatStaffDate(widget.staff!.dob),
  );
  late final _expiresAtText = TextEditingController(
    text: widget.staff?.expiresAt == null ? '' : formatStaffDate(widget.staff!.expiresAt),
  );

  DateTime? _dob;
  DateTime? _expiresAt;
  StaffRole? _role;
  StaffStatus _status = StaffStatus.active;
  String? _gender;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dob = widget.staff?.dob;
    _expiresAt = widget.staff?.expiresAt;
    _role = widget.staff?.role;
    _status = widget.staff?.status ?? StaffStatus.active;
    _gender = widget.staff?.gender;
    // Fired from here rather than the controller's `build` so it only
    // happens when this form actually opens, not on every visit to the
    // staff list.
    ref.read(staffManagementControllerProvider.notifier).ensureAssignableRolesLoaded();
  }

  @override
  void dispose() {
    for (final c in [
      _username,
      _email,
      _password,
      _fullName,
      _mobileNumber,
      _country,
      _addressLine1,
      _addressLine2,
      _city,
      _state,
      _zipCode,
      _dobText,
      _expiresAtText,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final role = _role;
    if (role == null) {
      setState(() => _errorMessage = 'Role is required');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final controller = ref.read(staffManagementControllerProvider.notifier);
    try {
      if (widget.isEditing) {
        await controller.updateStaff(
          widget.staff!.id,
          UpdateStaffRequest(
            username: _username.text.trim(),
            email: _email.text.trim(),
            role: role,
            status: _status,
            expiresAt: _expiresAt,
            fullName: _fullName.text.trim(),
            dob: _dob,
            gender: _gender,
            country: _emptyToNull(_country.text),
            mobileNumber: _emptyToNull(_mobileNumber.text),
            addressLine1: _emptyToNull(_addressLine1.text),
            addressLine2: _emptyToNull(_addressLine2.text),
            city: _emptyToNull(_city.text),
            state: _emptyToNull(_state.text),
            zipCode: _emptyToNull(_zipCode.text),
          ),
        );
      } else {
        await controller.hireStaff(
          HireStaffRequest(
            username: _username.text.trim(),
            password: _password.text,
            email: _email.text.trim(),
            role: role,
            status: _status,
            expiresAt: _expiresAt,
            fullName: _fullName.text.trim(),
            dob: _dob,
            gender: _gender,
            country: _emptyToNull(_country.text),
            mobileNumber: _emptyToNull(_mobileNumber.text),
            addressLine1: _emptyToNull(_addressLine1.text),
            addressLine2: _emptyToNull(_addressLine2.text),
            city: _emptyToNull(_city.text),
            state: _emptyToNull(_state.text),
            zipCode: _emptyToNull(_zipCode.text),
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
    final assignableRoles = ref.watch(
      staffManagementControllerProvider.select((s) => s.assignableRoles),
    );
    final roleOptions = assignableRoles.isNotEmpty ? assignableRoles : StaffRole.values;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Account'),
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
          const SizedBox(height: AppSpacing.smMd),
          AppDropdownField<StaffRole?>(
            label: 'Role',
            value: roleOptions.contains(_role) ? _role : null,
            hint: 'Select a role',
            enabled: !_submitting,
            items: [
              for (final role in roleOptions)
                DropdownMenuItem(value: role, child: Text(role.label)),
            ],
            onChanged: (value) => setState(() => _role = value),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppDropdownField<StaffStatus>(
            label: 'Status',
            value: _status,
            enabled: !_submitting,
            items: [
              for (final status in StaffStatus.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: (value) => setState(() => _status = value ?? _status),
          ),
          const SizedBox(height: AppSpacing.smMd),
          _DateField(
            label: 'Account expires',
            controller: _expiresAtText,
            enabled: !_submitting,
            onTap: () => _pickDate(
              initial: _expiresAt,
              onPicked: (picked) => setState(() {
                _expiresAt = picked;
                _expiresAtText.text = formatStaffDate(picked);
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Personal'),
          AppTextField(
            controller: _fullName,
            label: 'Full name',
            enabled: !_submitting,
            validator: (v) => _requiredValidator(v, 'Full name'),
          ),
          const SizedBox(height: AppSpacing.smMd),
          _DateField(
            label: 'Date of birth',
            controller: _dobText,
            enabled: !_submitting,
            onTap: () => _pickDate(
              initial: _dob,
              onPicked: (picked) => setState(() {
                _dob = picked;
                _dobText.text = formatStaffDate(picked);
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppDropdownField<String?>(
            label: 'Gender',
            value: _gender,
            items: _genderOptions,
            enabled: !_submitting,
            onChanged: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _mobileNumber,
            label: 'Mobile number',
            keyboardType: TextInputType.phone,
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _country,
            label: 'Country',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Address'),
          AppTextField(
            controller: _addressLine1,
            label: 'Address line 1',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _addressLine2,
            label: 'Address line 2',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _city,
            label: 'City',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _state,
            label: 'State',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _zipCode,
            label: 'Zip code',
            enabled: !_submitting,
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: widget.isEditing ? 'Save changes' : 'Hire staff',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
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
