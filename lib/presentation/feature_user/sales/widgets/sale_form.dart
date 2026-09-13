import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../../../../data/models/models_user/sale_model.dart';
import '../../../../providers/providers_user/customer_provider.dart';
import '../controllers/sales_controller.dart';
import 'sale_line_item_row.dart';

/// Rings up a basket over any number of products. Calls [Navigator.pop]
/// with the created [SaleDetailModel] on success, so the caller
/// (`SaleFormScreen`) can show a snackbar and hand the fresh record
/// straight to the detail screen it pushes next.
class SaleForm extends ConsumerStatefulWidget {
  const SaleForm({super.key, this.onSubmitted});

  /// Called after the API has created the sale. When omitted, this form is
  /// being shown on a pushed route and returns the result to that route's
  /// caller in the usual way.
  final ValueChanged<SaleDetailModel>? onSubmitted;

  @override
  ConsumerState<SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends ConsumerState<SaleForm> {
  final _formKey = GlobalKey<FormState>();
  final _tenderedController = TextEditingController();
  final _discountController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerPanController = TextEditingController();
  final _remarkController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;

  /// The customer selected from the existing-customer dropdown.
  /// Null when using freehand entry.
  CustomerModel? _selectedCustomer;

  int _nextRowId = 0;
  final Map<int, SaleLineItemData> _rows = {};

  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _addRow();
  }

  @override
  void dispose() {
    _tenderedController.dispose();
    _discountController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerPanController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(
      () => _rows[_nextRowId++] = const SaleLineItemData(
        quantity: 0,
        rate: 0,
        discountAmount: 0,
      ),
    );
  }

  void _removeRow(int rowId) {
    if (_rows.length <= 1) return;
    setState(() => _rows.remove(rowId));
  }

  // ── Customer helpers ────────────────────────────────────────────────────────

  void _onCustomerSelected(CustomerModel? customer) {
    setState(() {
      _selectedCustomer = customer;
      if (customer != null) {
        _customerNameController.text = customer.name;
        _customerPhoneController.text = customer.phone ?? '';
        _customerPanController.text = customer.panNumber ?? '';
      }
    });
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerPanController.clear();
    });
  }

  // ── Totals ──────────────────────────────────────────────────────────────────

  double get _itemsTotal =>
      _rows.values.fold(0, (sum, row) => sum + row.lineTotal);

  double get _estimatedNetTotal {
    final discount = double.tryParse(_discountController.text.trim()) ?? 0;
    final total = _itemsTotal - discount;
    return total < 0 ? 0 : total;
  }

  double? get _estimatedChange {
    if (_paymentMethod != PaymentMethod.cash) return null;
    final tendered = double.tryParse(_tenderedController.text.trim());
    if (tendered == null) return null;
    final change = tendered - _estimatedNetTotal;
    return change < 0 ? 0 : change;
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final completeRows = _rows.values.where((r) => r.isComplete).toList();
    if (completeRows.isEmpty) {
      setState(() => _errorMessage = 'Add at least one complete item');
      return;
    }
    final tendered = double.tryParse(_tenderedController.text.trim());
    final discount = double.tryParse(_discountController.text.trim());

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final request = CreateSaleRequest(
      // The create-sale API still requires a scheme; POS uses its existing
      // VAT default without exposing a per-sale override.
      taxScheme: TaxScheme.vat,
      paymentMethod: _paymentMethod,
      tenderedAmount: tendered,
      discountAmount: discount,
      customerId: _selectedCustomer?.id,
      customerName: _customerNameController.text.trim().isEmpty
          ? null
          : _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim().isEmpty
          ? null
          : _customerPhoneController.text.trim(),
      customerPan: _customerPanController.text.trim().isEmpty
          ? null
          : _customerPanController.text.trim(),
      remark: _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
      items: [
        for (final row in completeRows)
          CreateSaleItemRequest(
            productId: row.productId!,
            sellingUnitId: row.sellingUnitId!,
            quantity: row.quantity,
            rate: row.rate,
            discountAmount: row.discountAmount > 0 ? row.discountAmount : null,
          ),
      ],
    );

    try {
      final sale = await ref
          .read(salesControllerProvider.notifier)
          .createSale(request);
      if (!mounted) return;
      if (widget.onSubmitted case final onSubmitted?) {
        onSubmitted(sale);
      } else {
        Navigator.of(context).pop(sale);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final change = _estimatedChange;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // POS only selects the payment method.
          AppDropdownField<PaymentMethod>(
            label: 'Payment method',
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

          // ── Tendered / discount ───────────────────────────────────────────
          Row(
            children: [
              if (_paymentMethod == PaymentMethod.cash) ...[
                Expanded(
                  child: AppTextField(
                    controller: _tenderedController,
                    label: 'Tendered amount',
                    hint: 'e.g. 1000',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    enabled: !_submitting,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.smMd),
              ],
              Expanded(
                child: AppTextField(
                  controller: _discountController,
                  label: 'Bill discount',
                  hint: 'e.g. 0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  enabled: !_submitting,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Customer section ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Customer (optional)',
                  style: AppTypography.subtitle,
                ),
              ),
              if (_selectedCustomer != null)
                TextButton.icon(
                  onPressed: _submitting ? null : _clearCustomer,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),

          // Existing-customer searchable picker
          AppSearchableDropdownField<CustomerModel>(
            label: 'Select existing customer',
            selectedItem: _selectedCustomer,
            hint: 'Search by name or phone...',
            searchHint: 'Type to search customers...',
            asyncItems: (filter) async {
              final ds = ref.read(customerRemoteDataSourceProvider);
              final page = await ds.list(
                search: filter.isEmpty ? null : filter,
                size: 30,
              );
              return page.content;
            },
            itemLabel: (c) =>
                c.phone != null ? '${c.name} (${c.phone})' : c.name,
            onChanged: _submitting ? (_) {} : _onCustomerSelected,
          ),
          const SizedBox(height: AppSpacing.smMd),

          // Manual fields — pre-filled from picker, still editable
          AppTextField(
            controller: _customerNameController,
            label: 'Name',
            enabled: !_submitting,
            onChanged: (_) {
              if (_selectedCustomer != null) {
                setState(() => _selectedCustomer = null);
              }
            },
          ),
          const SizedBox(height: AppSpacing.smMd),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _customerPhoneController,
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                  enabled: !_submitting,
                  onChanged: (_) {
                    if (_selectedCustomer != null) {
                      setState(() => _selectedCustomer = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: AppTextField(
                  controller: _customerPanController,
                  label: 'PAN',
                  enabled: !_submitting,
                  onChanged: (_) {
                    if (_selectedCustomer != null) {
                      setState(() => _selectedCustomer = null);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField.multiline(
            controller: _remarkController,
            label: 'Remark',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Items ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: Text('Items', style: AppTypography.subtitle)),
              AppButton(
                label: 'Add item',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                leading: const Icon(Icons.add, size: 16),
                onPressed: _submitting ? null : _addRow,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          for (final entry in _rows.entries) ...[
            SaleLineItemRow(
              key: ValueKey(entry.key),
              onChanged: (data) => setState(() => _rows[entry.key] = data),
              onRemove: () => _removeRow(entry.key),
            ),
            const SizedBox(height: AppSpacing.smMd),
          ],

          // ── Totals preview ────────────────────────────────────────────────
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('Estimated total', style: AppTypography.subtitle),
              ),
              Text(
                formatMoneyAmount(_estimatedNetTotal),
                style: AppTypography.title,
              ),
            ],
          ),
          if (change != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Estimated change',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Text(formatMoneyAmount(change), style: AppTypography.subtitle),
              ],
            ),
          ],
          Text(
            'Tax, net total and change are calculated by the server on save.',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: 'Complete sale',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
