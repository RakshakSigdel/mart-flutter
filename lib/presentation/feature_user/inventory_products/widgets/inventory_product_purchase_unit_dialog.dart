import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../controllers/inventory_product_detail_controller.dart';

/// Add/edit dialog for one purchase unit. A dialog rather than a full page —
/// unlike the top-level product form, this edits a sub-resource of a page
/// the user should stay oriented on, and the field count (~6, one fewer on
/// edit) stays comfortable in a modal.
///
/// The unit itself and the initial VAT rate are only asked for on create —
/// both are fixed afterward (VAT changes go through its own "open a new
/// rate" flow instead, reachable from the VAT-history dialog).
///
/// Returns `true` via [Navigator.pop] on success.
class InventoryProductPurchaseUnitDialog extends ConsumerStatefulWidget {
  const InventoryProductPurchaseUnitDialog({
    super.key,
    required this.productId,
    required this.unitOptions,
    this.existing,
  });

  final int productId;
  final List<InventoryUnitModel> unitOptions;

  /// Null for "add a new purchase unit"; the one being edited otherwise.
  final ProductPurchaseUnitModel? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<InventoryProductPurchaseUnitDialog> createState() =>
      _InventoryProductPurchaseUnitDialogState();
}

class _InventoryProductPurchaseUnitDialogState
    extends ConsumerState<InventoryProductPurchaseUnitDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _packQuantity = TextEditingController(
    text: widget.existing == null ? '' : formatUnitValue(widget.existing!.packQuantity),
  );
  late final _purchasePrice = TextEditingController(
    text: widget.existing == null ? '' : formatMoney(widget.existing!.purchasePrice),
  );
  late final _vatRate = TextEditingController();
  InventoryUnitModel? _unit;
  bool _active = true;
  bool _isDefault = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _active = widget.existing?.active ?? true;
    _isDefault = widget.existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _packQuantity.dispose();
    _purchasePrice.dispose();
    _vatRate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final packQuantity = double.tryParse(_packQuantity.text.trim());
    final purchasePrice = double.tryParse(_purchasePrice.text.trim());
    if (packQuantity == null || packQuantity <= 0) {
      setState(() => _errorMessage = 'Pack quantity must be a positive number');
      return;
    }
    if (purchasePrice == null || purchasePrice < 0) {
      setState(() => _errorMessage = 'Purchase price must be a valid number');
      return;
    }

    if (!widget.isEditing) {
      if (_unit == null) {
        setState(() => _errorMessage = 'Unit is required');
        return;
      }
      final vatRate = double.tryParse(_vatRate.text.trim());
      if (vatRate == null || vatRate < 0) {
        setState(() => _errorMessage = 'VAT rate must be a valid number');
        return;
      }
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final notifier = ref.read(
      inventoryProductDetailControllerProvider(widget.productId).notifier,
    );
    try {
      if (widget.isEditing) {
        await notifier.updatePurchaseUnit(
          widget.existing!.id,
          UpdatePurchaseUnitRequest(
            packQuantity: packQuantity,
            purchasePrice: purchasePrice,
            active: _active,
            isDefault: _isDefault,
          ),
        );
      } else {
        await notifier.addPurchaseUnit(
          CreatePurchaseUnitRequest(
            unitId: _unit!.id,
            packQuantity: packQuantity,
            purchasePrice: purchasePrice,
            active: _active,
            isDefault: _isDefault,
            vat: OpenVatRateRequest(
              rate: double.parse(_vatRate.text.trim()),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isEditing) ...[
            AppSearchableDropdownField<InventoryUnitModel>(
              label: 'Unit',
              selectedItem: _unit,
              items: widget.unitOptions,
              itemLabel: (u) => '${u.name} (${u.symbol})',
              hint: 'Select a unit',
              onChanged: (value) => setState(() => _unit = value),
              validator: (value) => value == null ? 'Unit is required' : null,
            ),
            const SizedBox(height: AppSpacing.smMd),
          ],
          AppTextField(
            controller: _packQuantity,
            label: 'Pack quantity',
            hint: 'e.g. 12',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            enabled: !_submitting,
            validator: (v) {
              final parsed = double.tryParse((v ?? '').trim());
              return (parsed == null || parsed <= 0) ? 'Enter a positive number' : null;
            },
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _purchasePrice,
            label: 'Purchase price',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            enabled: !_submitting,
            validator: (v) {
              final parsed = double.tryParse((v ?? '').trim());
              return (parsed == null || parsed < 0) ? 'Enter a valid price' : null;
            },
          ),
          if (!widget.isEditing) ...[
            const SizedBox(height: AppSpacing.smMd),
            AppTextField(
              controller: _vatRate,
              label: 'Initial VAT rate (%)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              enabled: !_submitting,
              validator: (v) {
                final parsed = double.tryParse((v ?? '').trim());
                return (parsed == null || parsed < 0) ? 'Enter a valid rate' : null;
              },
            ),
          ],
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active', style: AppTypography.body),
            value: _active,
            onChanged: _submitting ? null : (value) => setState(() => _active = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Default purchase unit', style: AppTypography.body),
            value: _isDefault,
            onChanged: _submitting ? null : (value) => setState(() => _isDefault = value),
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.lg),
          AppButton.expanded(
            label: widget.isEditing ? 'Save changes' : 'Add purchase unit',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

/// Opens [InventoryProductPurchaseUnitDialog] as a centered dialog on wide
/// screens, or a bottom sheet on phone.
Future<bool?> showInventoryProductPurchaseUnitDialog(
  BuildContext context, {
  required int productId,
  required List<InventoryUnitModel> unitOptions,
  ProductPurchaseUnitModel? existing,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  final title = existing == null ? 'Add purchase unit' : 'Edit purchase unit';
  final content = InventoryProductPurchaseUnitDialog(
    productId: productId,
    unitOptions: unitOptions,
    existing: existing,
  );

  return isWide
      ? showAppDialog<bool>(context: context, title: title, content: content)
      : showAppModal<bool>(context: context, title: title, content: content);
}
