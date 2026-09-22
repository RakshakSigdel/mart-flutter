import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/purchase_model.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';
import '../../../../providers/providers_user/vendor_provider.dart';
import '../../../shared/widgets/section_ui.dart';
import '../../inventory_products/widgets/barcode_scanner_screen.dart';
import '../controllers/purchases_controller.dart';
import 'purchase_line_item_row.dart';

/// Records a purchase over any number of products. Calls [Navigator.pop]
/// with the created [PurchaseDetailModel] on success, so the caller
/// (`PurchaseFormScreen`) can show a snackbar and — unlike the simpler
/// forms elsewhere — hand the fresh record straight to the detail screen
/// it pushes next, rather than a bare `true` the caller would need to
/// refetch to act on.
///
/// Shaped around what receiving stock actually is: goods first. One scan or
/// search box adds a line already filled in with the product's usual pack
/// and cost, so the common case is scan, check, save. The supplier's bill
/// details sit above it, and everything that only some bills need (tax,
/// discount, note) stays folded away.
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

  final List<PurchaseLineItemData> _lines = [];
  final List<Key> _lineKeys = [];

  List<VendorModel> _vendorOptions = const [];
  bool _submitting = false;
  bool _addingLine = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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

  // ── Lines ─────────────────────────────────────────────────────────────────

  Future<List<ProductModel>> _searchProducts(String query) async {
    try {
      final result = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .list(
            search: query.trim().isEmpty ? null : query.trim(),
            active: true,
            size: 20,
          );
      return result.content;
    } on ApiException {
      return const [];
    }
  }

  /// Adds a line for [product], pre-filled with its default pack and that
  /// pack's usual cost — the values are right most of the time, so the
  /// cashier only corrects the exceptions.
  Future<void> _addLine(ProductModel product) async {
    if (_addingLine || _submitting) return;
    setState(() => _addingLine = true);
    List<ProductPurchaseUnitModel> units = const [];
    try {
      units = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .purchaseUnits(product.id);
    } on ApiException {
      // Fall through with no packs; the row asks the user to set one up.
    }
    if (!mounted) return;

    ProductPurchaseUnitModel? preferred;
    for (final unit in units) {
      if (unit.isDefault) {
        preferred = unit;
        break;
      }
    }
    preferred ??= units.isEmpty ? null : units.first;

    setState(() {
      _addingLine = false;
      _errorMessage = null;
      _lineKeys.add(UniqueKey());
      _lines.add(
        PurchaseLineItemData(
          product: product,
          unitOptions: units,
          unit: preferred,
          rate: preferred?.purchasePrice ?? 0,
        ),
      );
    });
  }

  Future<void> _scanToAdd() async {
    final barcode = await showBarcodeScannerSheet(context);
    if (barcode == null || !mounted) return;
    final matches = await _searchProducts(barcode);
    if (!mounted) return;
    if (matches.isEmpty) {
      AppSnackBar.error(context, 'No product found for this barcode.');
      return;
    }
    await _addLine(matches.first);
  }

  double get _goodsTotal => _lines.fold(0, (sum, line) => sum + line.lineTotal);

  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0;

  double get _netEstimate {
    final net = _goodsTotal - _discount;
    return net < 0 ? 0 : net;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_submitting || _addingLine) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vendor = _vendor;
    if (vendor == null) {
      setState(
        () => _errorMessage = 'Choose which supplier this bill is from.',
      );
      return;
    }
    final purchaseDate = _purchaseDate;
    if (purchaseDate == null) {
      setState(() => _errorMessage = 'Set the date the goods arrived.');
      return;
    }
    final completeLines = _lines.where((line) => line.isComplete).toList();
    if (completeLines.isEmpty || completeLines.length != _lines.length) {
      setState(
        () => _errorMessage = _lines.isEmpty
            ? 'Scan or search to add what you received.'
            : 'Check every item: choose a purchase unit, enter a quantity above zero, and a valid cost. No items have been saved.',
      );
      return;
    }

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
      discountAmount: _discount > 0 ? _discount : null,
      remark: _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
      items: [
        for (final line in completeLines)
          CreatePurchaseItemRequest(
            productId: line.product.id,
            purchaseUnitId: line.unit!.id,
            quantity: line.quantity,
            rate: line.rate,
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Each desktop area scrolls independently: adding more products
          // does not push the supplier details or Save button off screen.
          Widget pane(Widget child) => constraints.hasBoundedHeight
              ? SingleChildScrollView(primary: false, child: child)
              : child;

          if (constraints.maxWidth >= 1200) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300, child: pane(_buildBillPanel(false))),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: pane(_buildItemsPanel())),
                const SizedBox(width: AppSpacing.md),
                SizedBox(width: 320, child: pane(_buildTotalsPanel())),
              ],
            );
          }

          if (constraints.maxWidth >= 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: pane(_buildItemsPanel())),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 320,
                  child: pane(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBillPanel(false),
                        const SizedBox(height: AppSpacing.md),
                        _buildTotalsPanel(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final wide = constraints.maxWidth >= 560;
          return pane(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBillPanel(wide),
                const SizedBox(height: AppSpacing.md),
                _buildItemsPanel(),
                const SizedBox(height: AppSpacing.md),
                _buildTotalsPanel(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillPanel(bool wide) {
    final supplier = AppSearchableDropdownField<VendorModel>(
      label: 'Supplier',
      selectedItem: _vendor,
      items: _vendorOptions,
      itemLabel: (v) => v.name,
      hint: 'Who did you buy from?',
      onChanged: (v) => setState(() => _vendor = v),
      validator: (v) => v == null ? 'Supplier is required' : null,
    );

    final billNumber = AppTextField(
      controller: _billNumberController,
      label: 'Their bill number',
      hint: 'e.g. INV-2026-0142',
      enabled: !_submitting,
      validator: (v) => _requiredValidator(v, 'Bill number'),
    );

    final date = AppDateField(
      label: 'Arrived on',
      value: _purchaseDate,
      enabled: !_submitting,
      onChanged: (date) => setState(() => _purchaseDate = date),
    );

    final payment = AppDropdownField<PaymentMethod>(
      label: 'Paid by',
      value: _paymentMethod,
      enabled: !_submitting,
      items: [
        for (final method in PaymentMethod.values)
          DropdownMenuItem(value: method, child: Text(method.label)),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _paymentMethod = value);
      },
    );

    return SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionPanelHeader(
            icon: Icons.local_shipping_rounded,
            eyebrow: 'THE BILL',
            subtitle: '1. Select the supplier and enter their bill details',
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                supplier,
                const SizedBox(height: AppSpacing.smMd),
                billNumber,
                const SizedBox(height: AppSpacing.md),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: date),
                      const SizedBox(width: AppSpacing.smMd),
                      Expanded(child: payment),
                    ],
                  )
                else ...[
                  date,
                  const SizedBox(height: AppSpacing.smMd),
                  payment,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsPanel() {
    return SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionPanelHeader(
            icon: Icons.inventory_rounded,
            eyebrow: 'WHAT ARRIVED',
            subtitle: _lines.isEmpty
                ? '2. Add products, then check each unit, quantity and cost'
                : '${_lines.length} item${_lines.length == 1 ? '' : 's'} on this bill',
            trailing: SectionBadge(label: '${_lines.length}'),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAddBar(),
                const SizedBox(height: AppSpacing.smMd),
                if (_lines.isEmpty)
                  _EmptyLines()
                else
                  for (var i = 0; i < _lines.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    PurchaseLineItemRow(
                      key: _lineKeys[i],
                      line: _lines[i],
                      enabled: !_submitting,
                      onChanged: (updated) =>
                          setState(() => _lines[i] = updated),
                      onRemove: () => setState(() {
                        _lines.removeAt(i);
                        _lineKeys.removeAt(i);
                      }),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppSearchableDropdownField<ProductModel>(
            // Always unselected: picking a product adds a line rather than
            // filling this box in.
            label: 'Add an item',
            selectedItem: null,
            asyncItems: _searchProducts,
            itemLabel: (p) =>
                p.productCode == null ? p.name : '${p.name} (${p.productCode})',
            hint: 'Scan a barcode or search by name',
            onChanged: (product) {
              if (product != null && !_submitting && !_addingLine)
                _addLine(product);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(top: 26),
          child: _ScanButton(
            busy: _addingLine,
            onPressed: _submitting ? null : _scanToAdd,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsPanel() {
    return SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionPanelHeader(
            icon: Icons.fact_check_outlined,
            eyebrow: 'REVIEW & SAVE',
            subtitle: '3. Check the items and total against the supplier bill',
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _TotalRow(
                  label: 'Goods total',
                  value: 'Rs. ${formatMoneyAmount(_goodsTotal)}',
                ),
                const SizedBox(height: AppSpacing.smMd),
                AppTextField(
                  controller: _discountController,
                  label: 'Discount from supplier (optional)',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  enabled: !_submitting,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.smMd),
                _MoreOptions(
                  taxScheme: _taxScheme,
                  remarkController: _remarkController,
                  enabled: !_submitting,
                  onTaxSchemeChanged: (value) =>
                      setState(() => _taxScheme = value),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSunken,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'BILL TOTAL',
                        style: AppTypography.eyebrow.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Rs. ${formatMoneyAmount(_netEstimate)}',
                          style: AppTypography.price,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'VAT and the final total are confirmed when you save.',
                  style: AppTypography.caption,
                ),
                AppFormError(message: _errorMessage),
                const SizedBox(height: AppSpacing.smMd),
                BrandActionButton(
                  label: 'Save received stock',
                  icon: Icons.check_circle_outline_rounded,
                  loading: _submitting || _addingLine,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Scan a barcode',
      child: Material(
        color: AppColors.primarySoft,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusL,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onPressed,
          child: SizedBox(
            width: 52,
            height: 48,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(15),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryDeep,
                    ),
                  )
                : const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primaryDeep,
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyLines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.radiusL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            size: 28,
            color: AppColors.primaryDeep,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nothing added yet',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Scan a barcode or search above. Each item arrives with its\n'
            'usual pack and cost already filled in.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.bodySmall)),
        Text(value, style: AppTypography.priceSmall),
      ],
    );
  }
}

/// Tax scheme and note — the parts only some bills need.
class _MoreOptions extends StatelessWidget {
  const _MoreOptions({
    required this.taxScheme,
    required this.remarkController,
    required this.enabled,
    required this.onTaxSchemeChanged,
  });

  final TaxScheme taxScheme;
  final TextEditingController remarkController;
  final bool enabled;
  final ValueChanged<TaxScheme> onTaxSchemeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.radiusL,
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        title: Text(
          'Tax scheme and note',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Only change these when this bill needs it.',
          style: AppTypography.caption,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppDropdownField<TaxScheme>(
                  label: 'Tax scheme',
                  value: taxScheme,
                  enabled: enabled,
                  items: [
                    for (final scheme in TaxScheme.values)
                      DropdownMenuItem(
                        value: scheme,
                        child: Text(scheme.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onTaxSchemeChanged(value);
                  },
                ),
                const SizedBox(height: AppSpacing.smMd),
                AppTextField.multiline(
                  controller: remarkController,
                  label: 'Note',
                  enabled: enabled,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
