import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../controllers/customers_controller.dart';

class CustomerForm extends ConsumerStatefulWidget {
  const CustomerForm({super.key, this.customer});

  final CustomerModel? customer;

  bool get isEditing => customer != null;

  @override
  ConsumerState<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<CustomerForm> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.customer?.name);
  late final _phone = TextEditingController(text: widget.customer?.phone);
  late final _email = TextEditingController(text: widget.customer?.email);
  late final _panNumber = TextEditingController(text: widget.customer?.panNumber);
  late final _address = TextEditingController(text: widget.customer?.address);
  late final _creditLimit = TextEditingController(
      text: widget.customer != null ? widget.customer!.creditLimit.toString() : '0');
  late bool _active = widget.customer?.active ?? true;

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _panNumber.dispose();
    _address.dispose();
    _creditLimit.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final controller = ref.read(customersControllerProvider.notifier);
    final request = UpsertCustomerRequest(
      name: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      panNumber: _panNumber.text.trim().isEmpty ? null : _panNumber.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      creditLimit: double.tryParse(_creditLimit.text.trim()) ?? 0.0,
      active: _active,
    );

    try {
      if (widget.isEditing) {
        await controller.updateCustomer(widget.customer!.id, request);
      } else {
        await controller.createCustomer(request);
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
            hint: 'e.g. John Doe',
            enabled: !_submitting,
            validator: (v) => _requiredValidator(v, 'Name'),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _phone,
            label: 'Phone number',
            hint: 'e.g. 98XXXXXXXX',
            keyboardType: TextInputType.phone,
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _panNumber,
            label: 'PAN number',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _creditLimit,
            label: 'Credit Limit',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField.multiline(
            controller: _address,
            label: 'Address',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          SwitchListTile(
            title: const Text('Active Customer'),
            value: _active,
            onChanged: _submitting ? null : (val) => setState(() => _active = val),
            contentPadding: EdgeInsets.zero,
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: widget.isEditing ? 'Save changes' : 'Add customer',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
