import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../controllers/vendors_controller.dart';

/// Add/edit form for one vendor. Calls [Navigator.pop] with `true` when the
/// save succeeds, so the caller (`VendorFormScreen`) can show a snackbar
/// with a context that's guaranteed to still be mounted.
///
/// Plain content — no page chrome of its own. Hosted by
/// `VendorFormScreen` rather than a dialog, for the same reason as
/// `InventoryUnitForm`.
class VendorForm extends ConsumerStatefulWidget {
  const VendorForm({super.key, this.vendor});

  /// Null for "add a new vendor"; the vendor being edited otherwise.
  final VendorModel? vendor;

  bool get isEditing => vendor != null;

  @override
  ConsumerState<VendorForm> createState() => _VendorFormState();
}

class _VendorFormState extends ConsumerState<VendorForm> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.vendor?.name);
  late final _address = TextEditingController(text: widget.vendor?.address);
  late final _contactNumber = TextEditingController(
    text: widget.vendor?.contactNumber,
  );
  late final _panNumber = TextEditingController(text: widget.vendor?.panNumber);

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _contactNumber.dispose();
    _panNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final controller = ref.read(vendorsControllerProvider.notifier);
    final request = UpsertVendorRequest(
      name: _name.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      contactNumber: _contactNumber.text.trim().isEmpty
          ? null
          : _contactNumber.text.trim(),
      panNumber: _panNumber.text.trim().isEmpty ? null : _panNumber.text.trim(),
    );
    try {
      if (widget.isEditing) {
        await controller.updateVendor(widget.vendor!.id, request);
      } else {
        await controller.createVendor(request);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _requiredValidator(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? '$label is required' : null;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _name,
            label: 'Name',
            hint: 'e.g. Kathmandu Distributors',
            enabled: !_submitting,
            validator: (v) => _requiredValidator(v, 'Name'),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _contactNumber,
            label: 'Contact number',
            hint: 'e.g. 98XXXXXXXX',
            keyboardType: TextInputType.phone,
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _panNumber,
            label: 'PAN number',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField.multiline(
            controller: _address,
            label: 'Address',
            enabled: !_submitting,
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: widget.isEditing ? 'Save changes' : 'Add vendor',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
