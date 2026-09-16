import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/purchase_model.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../../../../providers/providers_user/vendor_provider.dart';
import '../controllers/purchases_controller.dart';
import 'purchase_line_item_row.dart';

/// Records a purchase over any number of products. Calls [Navigator.pop]
/// with the created [PurchaseDetailModel] on success, so the caller
/// (`PurchaseFormScreen`) can show a snackbar and — unlike the simpler
/// forms elsewhere — hand the fresh record straight to the detail screen
/// it pushes next, rather than a bare `true` the caller would need to
/// refetch to act on.
class PurchaseForm extends ConsumerStatefulWidget {
  const PurchaseForm({super.key});

  @override
  ConsumerState<PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends ConsumerState<PurchaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _billNumberController = TextEditingController();
  final _discountController = TextEditingController();
  final _remarkController = TextEditingController();

  VendorModel? _vendor;
  DateTime? _purchaseDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  TaxScheme _taxScheme = TaxScheme.vat;

  int _nextRowId = 0;
  final Map<int, PurchaseLineItemData> _rows = {};

  List<VendorModel> _vendorOptions = const [];
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _addRow();
    // Vendors were already loaded for the list screen's own filter — this
    // form doesn't watch that provider (it may outlive the list screen,
    // e.g. reached directly), so it fetches its own copy once instead.
    Future.microtask(_loadVendors);
  }

  Future<void> _loadVendors() async {
    try {
      final vendors = await ref
          .read(vendorRemoteDataSourceProvider)
          .selection();
      if (mounted) setState(() => _vendorOptions = vendors);
    } on ApiException {
      // Swallowed — the picker just shows an empty list if this never
      // resolves; not worth a screen-level error for a secondary dictionary.
    }
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _discountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(
      () => _rows[_nextRowId++] = const PurchaseLineItemData(
        quantity: 0,
        rate: 0,
      ),
    );
  }

  void _removeRow(int rowId) {
    if (_rows.length <= 1) return;
    setState(() => _rows.remove(rowId));
  }

  double get _subTotal =>
      _rows.values.fold(0, (sum, row) => sum + row.lineTotal);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vendor = _vendor;
    if (vendor == null) {
      setState(() => _errorMessage = 'Supplier is required');
      return;
    }
    final purchaseDate = _purchaseDate;
    if (purchaseDate == null) {
      setState(() => _errorMessage = 'Purchase date is required');
      return;
    }
    final completeRows = _rows.values.where((r) => r.isComplete).toList();
    if (completeRows.isEmpty) {
      setState(() => _errorMessage = 'Add at least one complete item');
      return;
    }
    final discount = double.tryParse(_discountController.text.trim());

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final request = CreatePurchaseRequest(
      vendorId: vendor.id,
      billNumber: _billNumberController.text.trim(),
      purchaseDate: purchaseDate,
      paymentMethod: _paymentMethod,
      taxScheme: _taxScheme,
      discountAmount: discount,
      remark: _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
      items: [
        for (final row in completeRows)
          CreatePurchaseItemRequest(
            productId: row.productId!,
            purchaseUnitId: row.purchaseUnitId!,
            quantity: row.quantity,
            rate: row.rate,
          ),
      ],
    );

    try {
      final purchase = await ref
          .read(purchasesControllerProvider.notifier)
          .createPurchase(request);
      if (mounted) Navigator.of(context).pop(purchase);
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
          AppSearchableDropdownField<VendorModel>(
            label: 'Supplier / आपूर्तिकर्ता',
            selectedItem: _vendor,
            items: _vendorOptions,
            itemLabel: (v) => v.name,
            hint: 'Select a supplier',
            onChanged: (v) => setState(() => _vendor = v),
            validator: (v) => v == null ? 'Supplier is required' : null,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _billNumberController,
            label: 'Supplier bill number',
            hint: 'e.g. INV-2026-0142',
            enabled: !_submitting,
            validator: (v) => _requiredValidator(v, 'Bill number'),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppDateField(
            label: 'Goods received date',
            value: _purchaseDate,
            enabled: !_submitting,
            onChanged: (date) => setState(() => _purchaseDate = date),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppDropdownField<PaymentMethod>(
            label: 'How did you pay the supplier?',
            value: _paymentMethod,
            enabled: !_submitting,
            items: [
              for (final method in PaymentMethod.values)
                DropdownMenuItem(value: method, child: Text(method.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _paymentMethod = value);
            },
          ),
          const SizedBox(height: AppSpacing.smMd),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Tax, discount and note (optional)'),
            subtitle: const Text('Only change these when this bill needs it.'),
            children: [
              AppDropdownField<TaxScheme>(
                label: 'Tax scheme',
                value: _taxScheme,
                enabled: !_submitting,
                items: [
                  for (final scheme in TaxScheme.values)
                    DropdownMenuItem(
                      value: scheme,
                      child: Text(scheme.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _taxScheme = value);
                },
              ),
              const SizedBox(height: AppSpacing.smMd),
              AppTextField(
                controller: _discountController,
                label: 'Discount amount',
                hint: 'e.g. 0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                enabled: !_submitting,
              ),
              const SizedBox(height: AppSpacing.smMd),
              AppTextField.multiline(
                controller: _remarkController,
                label: 'Note',
                enabled: !_submitting,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Expanded(
                child: Text('Items received', style: AppTypography.subtitle),
              ),
              AppButton(
                label: 'Add another item',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                leading: const Icon(Icons.add, size: 16),
                onPressed: _submitting ? null : _addRow,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          for (final entry in _rows.entries) ...[
            PurchaseLineItemRow(
              key: ValueKey(entry.key),
              onChanged: (data) => setState(() => _rows[entry.key] = data),
              onRemove: () => _removeRow(entry.key),
            ),
            const SizedBox(height: AppSpacing.smMd),
          ],
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estimated goods total',
                  style: AppTypography.subtitle,
                ),
              ),
              Text(formatMoneyAmount(_subTotal), style: AppTypography.title),
            ],
          ),
          Text(
            'Tax and final total are confirmed when the purchase is saved.',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: 'Save received stock',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
