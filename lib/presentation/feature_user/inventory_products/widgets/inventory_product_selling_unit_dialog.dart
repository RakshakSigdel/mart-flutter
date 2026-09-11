import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../controllers/inventory_product_detail_controller.dart';

/// Add/edit dialog for one selling unit — same reasoning for staying a
/// dialog (not a full page) as `InventoryProductPurchaseUnitDialog`.
///
/// The unit itself is only asked for on create — fixed afterward.
///
/// Returns `true` via [Navigator.pop] on success.
class InventoryProductSellingUnitDialog extends ConsumerStatefulWidget {
  const InventoryProductSellingUnitDialog({
    super.key,
    required this.productId,
    required this.unitOptions,
    this.existing,
  });

  final int productId;
  final List<InventoryUnitModel> unitOptions;

  /// Null for "add a new selling unit"; the one being edited otherwise.
  final ProductSellingUnitModel? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<InventoryProductSellingUnitDialog> createState() =>
      _InventoryProductSellingUnitDialogState();
}

class _InventoryProductSellingUnitDialogState
    extends ConsumerState<InventoryProductSellingUnitDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _packQuantity = TextEditingController(
    text: widget.existing == null ? '' : formatUnitValue(widget.existing!.packQuantity),
  );
  late final _sellingPrice = TextEditingController(
    text: widget.existing == null ? '' : formatMoney(widget.existing!.sellingPrice),
  );
  late final _mrp = TextEditingController(
    text: widget.existing?.mrp == null ? '' : formatMoney(widget.existing!.mrp),
  );
  late final _sku = TextEditingController(text: widget.existing?.sku);
  late final _barcode = TextEditingController(text: widget.existing?.barcode);

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
    _sellingPrice.dispose();
    _mrp.dispose();
    _sku.dispose();
    _barcode.dispose();
    super.dispose();
  }

  static String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final packQuantity = double.tryParse(_packQuantity.text.trim());
    final sellingPrice = double.tryParse(_sellingPrice.text.trim());
    final mrpText = _mrp.text.trim();
    final mrp = mrpText.isEmpty ? null : double.tryParse(mrpText);
    if (packQuantity == null || packQuantity <= 0) {
      setState(() => _errorMessage = 'Pack quantity must be a positive number');
      return;
    }
    if (sellingPrice == null || sellingPrice < 0) {
      setState(() => _errorMessage = 'Selling price must be a valid number');
      return;
    }
    if (mrpText.isNotEmpty && mrp == null) {
      setState(() => _errorMessage = 'MRP must be a valid number');
      return;
    }
    if (!widget.isEditing && _unit == null) {
      setState(() => _errorMessage = 'Unit is required');
      return;
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
        await notifier.updateSellingUnit(
          widget.existing!.id,
          UpdateSellingUnitRequest(
            packQuantity: packQuantity,
            sellingPrice: sellingPrice,
            mrp: mrp,
            sku: _emptyToNull(_sku.text),
            barcode: _emptyToNull(_barcode.text),
            active: _active,
            isDefault: _isDefault,
          ),
        );
      } else {
        await notifier.addSellingUnit(
          CreateSellingUnitRequest(
            unitId: _unit!.id,
            packQuantity: packQuantity,
            sellingPrice: sellingPrice,
            mrp: mrp,
            sku: _emptyToNull(_sku.text),
            barcode: _emptyToNull(_barcode.text),
            active: _active,
            isDefault: _isDefault,
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
            hint: 'e.g. 1',
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
            controller: _sellingPrice,
            label: 'Selling price',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            enabled: !_submitting,
            validator: (v) {
              final parsed = double.tryParse((v ?? '').trim());
              return (parsed == null || parsed < 0) ? 'Enter a valid price' : null;
            },
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _mrp,
            label: 'MRP',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _sku,
            label: 'SKU',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _barcode,
            label: 'Barcode',
            enabled: !_submitting,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active', style: AppTypography.body),
            value: _active,
            onChanged: _submitting ? null : (value) => setState(() => _active = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Default selling unit', style: AppTypography.body),
            value: _isDefault,
            onChanged: _submitting ? null : (value) => setState(() => _isDefault = value),
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.lg),
          AppButton.expanded(
            label: widget.isEditing ? 'Save changes' : 'Add selling unit',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

/// Opens [InventoryProductSellingUnitDialog] as a centered dialog on wide
/// screens, or a bottom sheet on phone.
Future<bool?> showInventoryProductSellingUnitDialog(
  BuildContext context, {
  required int productId,
  required List<InventoryUnitModel> unitOptions,
  ProductSellingUnitModel? existing,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  final title = existing == null ? 'Add selling unit' : 'Edit selling unit';
  final content = InventoryProductSellingUnitDialog(
    productId: productId,
    unitOptions: unitOptions,
    existing: existing,
  );

  return isWide
      ? showAppDialog<bool>(context: context, title: title, content: content)
      : showAppModal<bool>(context: context, title: title, content: content);
}
