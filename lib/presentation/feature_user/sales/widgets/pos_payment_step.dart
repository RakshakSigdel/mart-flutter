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
import '../models/pos_cart_item.dart';
import 'pos_keyboard.dart';

/// Step 1 of the POS flow — payment details, customer info, and bill creation.
class PosPaymentStep extends ConsumerStatefulWidget {
  const PosPaymentStep({
    super.key,
    required this.cart,
    required this.onBack,
    required this.onBillSaved,
    this.active = true,
  });

  final List<PosCartItem> cart;
  final VoidCallback onBack;
  final Future<void> Function(SaleDetailModel) onBillSaved;

  /// Whether this step is the one currently shown to the user. The parent's
  /// [IndexedStack] keeps every step mounted, so this flags the transition
  /// into view — used to move keyboard focus onto the form.
  final bool active;

  @override
  ConsumerState<PosPaymentStep> createState() => _PosPaymentStepState();
}

class _PosPaymentStepState extends ConsumerState<PosPaymentStep> {
  final _formKey = GlobalKey<FormState>();
  final _tenderedCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final _customerFocus = FocusNode(debugLabel: 'customer-search');
  final _paymentMethodFocus = FocusNode(debugLabel: 'payment-method');
  final _posScope = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  PaymentMethod _paymentMethod = PaymentMethod.cash;
  CustomerModel? _selectedCustomer;
  bool _showCustomerSection = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void didUpdateWidget(PosPaymentStep old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active) _paymentMethodFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _tenderedCtrl.dispose();
    _discountCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _panCtrl.dispose();
    _remarkCtrl.dispose();
    _customerFocus.dispose();
    _paymentMethodFocus.dispose();
    _posScope.dispose();
    super.dispose();
  }

  // ── Totals ─────────────────────────────────────────────────────────────────

  double get _subtotal =>
      widget.cart.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get _billDiscount => double.tryParse(_discountCtrl.text.trim()) ?? 0;

  double get _netTotal {
    final t = _subtotal - _billDiscount;
    return t < 0 ? 0 : t;
  }

  double? get _change {
    if (_paymentMethod != PaymentMethod.cash) return null;
    final tendered = double.tryParse(_tenderedCtrl.text.trim());
    if (tendered == null) return null;
    final c = tendered - _netTotal;
    return c < 0 ? 0 : c;
  }

  // ── Customer helpers ───────────────────────────────────────────────────────

  void _onCustomerSelected(CustomerModel? c) {
    setState(() {
      _selectedCustomer = c;
      if (c != null) {
        _nameCtrl.text = c.name;
        _phoneCtrl.text = c.phone ?? '';
        _panCtrl.text = c.panNumber ?? '';
      }
    });
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _panCtrl.clear();
    });
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.cart.isEmpty) {
      setState(() => _errorMessage = 'Cart is empty.');
      return;
    }
    if (_paymentMethod == PaymentMethod.credit &&
        _selectedCustomer == null &&
        _nameCtrl.text.trim().isEmpty) {
      setState(() {
        _showCustomerSection = true;
        _errorMessage = 'Enter customer details for a credit sale.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final request = CreateSaleRequest(
      taxScheme: TaxScheme.vat,
      paymentMethod: _paymentMethod,
      tenderedAmount: double.tryParse(_tenderedCtrl.text.trim()),
      discountAmount: _billDiscount > 0 ? _billDiscount : null,
      customerId: _selectedCustomer?.id,
      customerName: _nameCtrl.text.trim().isEmpty
          ? null
          : _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
      customerPan: _panCtrl.text.trim().isEmpty ? null : _panCtrl.text.trim(),
      remark: _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
      items: [
        for (final item in widget.cart)
          CreateSaleItemRequest(
            productId: item.productId,
            sellingUnitId: item.sellingUnitId,
            quantity: item.quantity,
            rate: item.rate,
            discountAmount: item.discountAmount > 0
                ? item.discountAmount
                : null,
          ),
      ],
    );

    try {
      final sale = await ref
          .read(salesControllerProvider.notifier)
          .createSale(request);
      if (!mounted) return;
      await widget.onBillSaved(sale);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final change = _change;
    return PosKeyboardNavigation(
      scope: _posScope,
      enabled: !_submitting,
      child: AbsorbPointer(
        absorbing: _submitting,
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left: payment form ──────────────────────────────────────────
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Back to products',
                            onPressed: _submitting ? null : widget.onBack,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Payment', style: AppTypography.title),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Keyboard: ↑/↓ move · → open/select/act · ← back · Shift+arrows edit text',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Payment method
                      PosPicker<PaymentMethod>(
                        label: 'Payment method',
                        focusNode: _paymentMethodFocus,
                        autofocus: widget.active,
                        selectedItem: _paymentMethod,
                        enabled: !_submitting,
                        items: PaymentMethod.values,
                        itemLabel: (m) => m.label,
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value;
                            if (value == PaymentMethod.credit) {
                              _showCustomerSection = true;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.smMd),

                      // Tendered / discount
                      Row(
                        children: [
                          if (_paymentMethod == PaymentMethod.cash) ...[
                            Expanded(
                              child: AppTextField(
                                controller: _tenderedCtrl,
                                label: 'Customer gave (cash)',
                                hint: 'e.g. 1000',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                enabled: !_submitting,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.smMd),
                          ],
                          Expanded(
                            child: AppTextField(
                              controller: _discountCtrl,
                              label: 'Bill discount',
                              hint: '0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                              enabled: !_submitting,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),

                      // Quick-cash chips — shortcuts only, mouse/touch-driven,
                      // so arrow-key/Tab traversal skips straight over them.
                      if (_paymentMethod == PaymentMethod.cash) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ExcludeFocus(
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final amt in const [100, 500, 1000, 2000])
                                ActionChip(
                                  label: Text('Rs. $amt'),
                                  onPressed: _submitting
                                      ? null
                                      : () => setState(
                                          () => _tenderedCtrl.text = '$amt',
                                        ),
                                ),
                              ActionChip(
                                label: const Text('Exact'),
                                onPressed: _submitting
                                    ? null
                                    : () => setState(
                                        () => _tenderedCtrl.text = _netTotal
                                            .toStringAsFixed(2),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),

                      // Customer section (expandable)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: AppBorderRadius.radiusL,
                        ),
                        child: ExpansionTile(
                          key: ValueKey('customer-${_paymentMethod.name}'),
                          enabled: !_submitting,
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          title: Text(
                            _paymentMethod == PaymentMethod.credit
                                ? 'Customer details'
                                : 'Customer details (optional)',
                            style: AppTypography.body,
                          ),
                          subtitle: Text(
                            _paymentMethod == PaymentMethod.credit
                                ? 'Required for a credit sale.'
                                : 'Add a saved customer or enter their details.',
                            style: AppTypography.bodySmall,
                          ),
                          initiallyExpanded: _showCustomerSection,
                          onExpansionChanged: (v) =>
                              setState(() => _showCustomerSection = v),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                0,
                                AppSpacing.md,
                                AppSpacing.md,
                              ),
                              child: Column(
                                children: [
                                  if (_selectedCustomer != null)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: _submitting
                                            ? null
                                            : _clearCustomer,
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('Clear'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.textMuted,
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ),
                                  PosPicker<CustomerModel>(
                                    label: 'Find saved customer',
                                    focusNode: _customerFocus,
                                    selectedItem: _selectedCustomer,
                                    search: (filter) async {
                                      final ds = ref.read(
                                        customerRemoteDataSourceProvider,
                                      );
                                      final page = await ds.list(
                                        search: filter.isEmpty ? null : filter,
                                        size: 30,
                                      );
                                      return page.content;
                                    },
                                    itemLabel: (c) => c.phone != null
                                        ? '${c.name} (${c.phone})'
                                        : c.name,
                                    onChanged: _submitting
                                        ? (_) {}
                                        : _onCustomerSelected,
                                  ),
                                  const SizedBox(height: AppSpacing.smMd),
                                  AppTextField(
                                    controller: _nameCtrl,
                                    label: 'Customer name',
                                    enabled: !_submitting,
                                    onChanged: (_) {
                                      if (_selectedCustomer != null) {
                                        setState(
                                          () => _selectedCustomer = null,
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.smMd),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppTextField(
                                          controller: _phoneCtrl,
                                          label: 'Phone number',
                                          keyboardType: TextInputType.phone,
                                          enabled: !_submitting,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.smMd),
                                      Expanded(
                                        child: AppTextField(
                                          controller: _panCtrl,
                                          label: 'PAN',
                                          enabled: !_submitting,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.smMd),
                                  AppTextField.multiline(
                                    controller: _remarkCtrl,
                                    label: 'Note (optional)',
                                    enabled: !_submitting,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      AppFormError(message: _errorMessage),
                      const SizedBox(height: AppSpacing.md),

                      AppButton.expanded(
                        label: 'Save Bill / बिल सुरक्षित गर्नुहोस्',
                        isLoading: _submitting,
                        onPressed: _submitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),

              // Vertical divider
              const VerticalDivider(width: 1),

              // ── Right: order summary ────────────────────────────────────────
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'Order Summary',
                        style: AppTypography.subtitle,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: widget.cart.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: AppSpacing.smMd),
                        itemBuilder: (ctx, i) {
                          final item = widget.cart[i];
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: AppTypography.body,
                                    ),
                                    Text(
                                      '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}'
                                      ' x ${formatMoneyAmount(item.rate)}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatMoneyAmount(item.lineTotal),
                                style: AppTypography.body,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: 'Subtotal',
                            value: formatMoneyAmount(_subtotal),
                          ),
                          if (_billDiscount > 0)
                            _SummaryRow(
                              label: 'Discount',
                              value: '- ${formatMoneyAmount(_billDiscount)}',
                            ),
                          const Divider(height: AppSpacing.smMd),
                          _SummaryRow(
                            label: 'Estimated Total',
                            value: 'Rs. ${formatMoneyAmount(_netTotal)}',
                            bold: true,
                          ),
                          if (change != null && change > 0) ...[
                            const SizedBox(height: AppSpacing.xs),
                            _SummaryRow(
                              label: 'Change to return',
                              value: formatMoneyAmount(change),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Final total confirmed after saving.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTypography.subtitle : AppTypography.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: bold ? style : style.copyWith(color: AppColors.textMuted),
            ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}
