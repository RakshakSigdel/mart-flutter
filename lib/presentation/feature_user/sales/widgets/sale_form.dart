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

/// Moves through the till without requiring a mouse or Tab key. Up/down
/// intentionally leave left/right alone: those arrows still edit a number
/// field's caret and navigate an open menu as users expect.
class _PosMoveFocusIntent extends Intent {
  const _PosMoveFocusIntent(this.forward);

  final bool forward;
}

class _PosMoveFocusAction extends Action<_PosMoveFocusIntent> {
  _PosMoveFocusAction(this.scope);

  final FocusScopeNode scope;

  @override
  Object? invoke(_PosMoveFocusIntent intent) {
    if (intent.forward) {
      scope.nextFocus();
    } else {
      scope.previousFocus();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext != null) Scrollable.ensureVisible(focusContext);
    });
    return null;
  }
}

class _SaleFormState extends ConsumerState<SaleForm> {
  final _formKey = GlobalKey<FormState>();
  final _tenderedController = TextEditingController();
  final _discountController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerPanController = TextEditingController();
  final _remarkController = TextEditingController();
  final _posScope = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

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
    _posScope.dispose();
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
    if (_paymentMethod == PaymentMethod.credit &&
        _selectedCustomer == null &&
        _customerNameController.text.trim().isEmpty) {
      setState(
        () => _errorMessage =
            'Choose or enter a customer before recording a credit sale.',
      );
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

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown): _PosMoveFocusIntent(true),
        SingleActivator(LogicalKeyboardKey.arrowUp): _PosMoveFocusIntent(false),
      },
      child: Actions(
        actions: {
          _PosMoveFocusIntent: _PosMoveFocusAction(_posScope),
        },
        child: FocusScope(
          node: _posScope,
          autofocus: true,
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: Form(
              key: _formKey,
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppBorderRadius.radiusL,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Make a bill', style: AppTypography.title),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '1. Add products  2. Take payment  3. Save the bill',
                  style: AppTypography.bodySmall,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Keyboard: ↑/↓ move · Enter select or act · Esc closes menus',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Expanded(
                child: Text('1. Add products', style: AppTypography.subtitle),
              ),
              AppButton(
                label: 'Add another product',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                leading: const Icon(Icons.add, size: 16),
                onPressed: _submitting ? null : _addRow,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Search by product name or barcode. Quantity starts at 1.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.smMd),
          for (final entry in _rows.entries) ...[
            SaleLineItemRow(
              key: ValueKey(entry.key),
              onChanged: (data) => setState(() => _rows[entry.key] = data),
              onRemove: () => _removeRow(entry.key),
              autofocusProduct: entry.key == _rows.keys.last,
            ),
            const SizedBox(height: AppSpacing.smMd),
          ],
          const Divider(height: AppSpacing.xl),
          // POS only selects the payment method.
          AppDropdownField<PaymentMethod>(
            label: 'How is the customer paying?',
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
                    label: 'Customer gave (cash)',
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
          if (_paymentMethod == PaymentMethod.cash) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final amount in const [100, 500, 1000, 2000])
                  ActionChip(
                    label: Text('Rs. $amount'),
                    onPressed: _submitting
                        ? null
                        : () => setState(
                            () => _tenderedController.text = '$amount',
                          ),
                  ),
                ActionChip(
                  label: const Text('Exact amount'),
                  onPressed: _submitting
                      ? null
                      : () => setState(
                          () => _tenderedController.text =
                              _estimatedNetTotal.toStringAsFixed(2),
                        ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // ── Customer section ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  _paymentMethod == PaymentMethod.credit
                      ? 'Customer for credit / उधारो'
                      : 'Customer (optional)',
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
            label: 'Find saved customer',
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
            label: 'Customer name',
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
                  label: 'Phone number',
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
            label: 'Note (optional)',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Items ─────────────────────────────────────────────────────────
          // ── Totals preview ────────────────────────────────────────────────
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('Bill total', style: AppTypography.subtitle),
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
                    'Change to return',
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
            'Tax and final total are confirmed when the bill is saved.',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: 'Save bill / बिल सुरक्षित गर्नुहोस्',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
