import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../controllers/inventory_units_controller.dart';

/// Add/edit form for one unit. Calls [Navigator.pop] with `true` when the
/// save succeeds, so the caller (`InventoryUnitFormScreen`) can show a
/// snackbar with a context that's guaranteed to still be mounted.
///
/// Plain content — no page chrome of its own. Hosted by
/// `InventoryUnitFormScreen` rather than a dialog, for the same reason as
/// `StaffForm`/`AdminForm`.
class InventoryUnitForm extends ConsumerStatefulWidget {
  const InventoryUnitForm({super.key, this.unit});

  /// Null for "add a new unit"; the unit being edited otherwise.
  final InventoryUnitModel? unit;

  bool get isEditing => unit != null;

  @override
  ConsumerState<InventoryUnitForm> createState() => _InventoryUnitFormState();
}

class _InventoryUnitFormState extends ConsumerState<InventoryUnitForm> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.unit?.name);
  late final _symbol = TextEditingController(text: widget.unit?.symbol);
  late final _conversionFactor = TextEditingController(
    text: widget.unit?.conversionFactor == null
        ? ''
        : formatUnitValue(widget.unit!.conversionFactor!),
  );

  UnitMeasurementType? _measurementType;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _measurementType = widget.unit?.measurementType;
  }

  @override
  void dispose() {
    _name.dispose();
    _symbol.dispose();
    _conversionFactor.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final type = _measurementType;
    if (type == null) {
      setState(() => _errorMessage = 'Measurement type is required');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final controller = ref.read(inventoryUnitsControllerProvider.notifier);
    final request = UpsertInventoryUnitRequest(
      name: _name.text.trim(),
      symbol: _symbol.text.trim(),
      measurementType: type,
      conversionFactor: _conversionFactor.text.trim().isEmpty
          ? null
          : double.tryParse(_conversionFactor.text.trim()),
    );
    try {
      if (widget.isEditing) {
        await controller.updateUnit(widget.unit!.id, request);
      } else {
        await controller.createUnit(request);
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
            hint: 'e.g. Kilogram',
            enabled: !_submitting,
            validator: (v) => _requiredValidator(v, 'Name'),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _symbol,
            label: 'Symbol',
            hint: 'e.g. kg',
            enabled: !_submitting,
            validator: (v) => _requiredValidator(v, 'Symbol'),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppDropdownField<UnitMeasurementType?>(
            label: 'Measurement type',
            value: _measurementType,
            hint: 'Select a type',
            enabled: !_submitting,
            items: [
              for (final type in UnitMeasurementType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (value) => setState(() => _measurementType = value),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _conversionFactor,
            label: 'Conversion factor (optional)',
            hint: 'Leave blank for a variable pack such as a sack or carton',
            enabled: !_submitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) =>
                value == null ||
                    value.trim().isEmpty ||
                    double.tryParse(value.trim()) != null
                ? null
                : 'Enter a valid number.',
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: widget.isEditing ? 'Save changes' : 'Add unit',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
