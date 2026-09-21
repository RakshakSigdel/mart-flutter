import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';
import '../../inventory_products/widgets/barcode_scanner_screen.dart';
import 'pos_keyboard.dart';

/// A snapshot of one line item row's editable state — what
/// `SaleLineItemRow` reports up to the form on every change, so the form
/// can compute a running total and, on submit, build the request without
/// reaching back into any row's own widget state.
class SaleLineItemData {
  const SaleLineItemData({
    this.productId,
    this.productName,
    this.sellingUnitId,
    this.sellingUnitLabel,
    required this.quantity,
    required this.rate,
    required this.discountAmount,
  });

  final int? productId;
  final String? productName;
  final int? sellingUnitId;
  final String? sellingUnitLabel;
  final double quantity;
  final double rate;
  final double discountAmount;

  double get lineTotal => (quantity * rate) - discountAmount;

  bool get isComplete =>
      productId != null && sellingUnitId != null && quantity > 0;
}

/// One product/selling-unit/quantity/rate/discount row in the sale form's
/// item list — fully self-contained: it fetches the selected product's own
/// selling units itself and only ever reports a plain [SaleLineItemData]
/// snapshot upward via [onChanged]. Mirrors `PurchaseLineItemRow`; kept as
/// its own widget rather than shared, since a sale line carries a
/// per-line discount a purchase line doesn't.
class SaleLineItemRow extends ConsumerStatefulWidget {
  const SaleLineItemRow({
    super.key,
    required this.onChanged,
    required this.onRemove,
    required this.productFocus,
    this.canRemove = true,
    this.autofocusProduct = false,
  });

  final ValueChanged<SaleLineItemData> onChanged;
  final VoidCallback onRemove;
  final FocusNode productFocus;
  final bool canRemove;
  final bool autofocusProduct;

  @override
  ConsumerState<SaleLineItemRow> createState() => _SaleLineItemRowState();
}

class _SaleLineItemRowState extends ConsumerState<SaleLineItemRow> {
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _discountController = TextEditingController();
  final _quickNameController = TextEditingController();
  final _quickPriceController = TextEditingController();
  FocusNode get _productFocus => widget.productFocus;
  final _quickNameFocus = FocusNode();
  final _sellingUnitFocus = FocusNode();
  final _quantityFocus = FocusNode();

  ProductModel? _product;
  ProductSellingUnitModel? _unit;
  List<ProductSellingUnitModel> _unitOptions = [];
  bool _loadingUnits = false;
  String? _missingBarcode;
  bool _quickAdding = false;

  @override
  void initState() {
    super.initState();
    if (widget.autofocusProduct) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && TickerMode.valuesOf(context).enabled)
          _productFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    _quickNameController.dispose();
    _quickPriceController.dispose();
    _quickNameFocus.dispose();
    _sellingUnitFocus.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

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
      rethrow;
    }
  }

  Future<void> _findProductByBarcode(String barcode) async {
    final value = barcode.trim();
    if (value.isEmpty) return;

    try {
      final unit = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .getByBarcode(value);
      if (!mounted) return;
      _applyResolvedUnit(unit);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 404) {
        setState(() => _missingBarcode = value);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && TickerMode.valuesOf(context).enabled)
            _quickNameFocus.requestFocus();
        });
      } else {
        AppSnackBar.error(context, e.message);
      }
    }
  }

  void _applyResolvedUnit(ProductSellingUnitModel unit) {
    final productId = unit.productId;
    if (productId == null) return;
    setState(() {
      _product = ProductModel(
        id: productId,
        name: unit.productName ?? '',
        active: unit.active,
      );
      _unit = unit;
      _unitOptions = [unit];
      _loadingUnits = false;
      _missingBarcode = null;
      _quantityController.text = _quantityController.text.trim().isEmpty
          ? '1'
          : _quantityController.text;
      _rateController.text = formatMoneyAmount(unit.sellingPrice);
    });
    _notify();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && TickerMode.valuesOf(context).enabled)
        _quantityFocus.requestFocus();
    });
  }

  Future<void> _quickAdd() async {
    final barcode = _missingBarcode;
    final price = double.tryParse(_quickPriceController.text.trim());
    if (barcode == null ||
        _quickNameController.text.trim().isEmpty ||
        price == null) {
      AppSnackBar.error(context, 'Enter the product name and selling price.');
      return;
    }
    setState(() => _quickAdding = true);
    try {
      final unit = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .quickAdd(
            QuickAddProductRequest(
              name: _quickNameController.text.trim(),
              sellingPrice: price,
              barcode: barcode,
            ),
          );
      if (mounted) _applyResolvedUnit(unit);
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _quickAdding = false);
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await showBarcodeScannerSheet(context);
    if (barcode == null || !mounted) return;
    await _findProductByBarcode(barcode);
  }

  Future<void> _onProductSelected(ProductModel? product) async {
    setState(() {
      _product = product;
      _missingBarcode = null;
      _unit = null;
      _unitOptions = [];
      _loadingUnits = product != null;
    });
    _notify();
    if (product == null) return;

    try {
      final units = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .sellingUnits(product.id);
      if (!mounted || _product?.id != product.id) return;
      ProductSellingUnitModel? defaultUnit;
      for (final unit in units) {
        if (unit.isDefault) {
          defaultUnit = unit;
          break;
        }
      }
      final selected = defaultUnit ?? (units.isEmpty ? null : units.first);
      setState(() {
        _unitOptions = units;
        _loadingUnits = false;
        _unit = selected;
      });
      if (_quantityController.text.trim().isEmpty) {
        _quantityController.text = '1';
      }
      if (selected != null) {
        _rateController.text = formatMoneyAmount(selected.sellingPrice);
      }
      _notify();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !TickerMode.valuesOf(context).enabled ||
            !_productFocus.hasFocus)
          return;
        (units.isEmpty ? _quantityFocus : _sellingUnitFocus).requestFocus();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingUnits = false);
      AppSnackBar.error(context, e.message);
      if (TickerMode.valuesOf(context).enabled) _productFocus.requestFocus();
    }
  }

  void _onUnitSelected(ProductSellingUnitModel? unit) {
    setState(() => _unit = unit);
    if (unit != null) {
      _rateController.text = formatMoneyAmount(unit.sellingPrice);
    }
    _notify();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && TickerMode.valuesOf(context).enabled)
        _quantityFocus.requestFocus();
    });
  }

  void _notify() {
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    final discount = double.tryParse(_discountController.text.trim()) ?? 0;
    widget.onChanged(
      SaleLineItemData(
        productId: _product?.id,
        productName: _product?.name,
        sellingUnitId: _unit?.id,
        sellingUnitLabel: _unit == null
            ? null
            : '${_unit!.unit.name} (${_unit!.unit.symbol})',
        quantity: quantity,
        rate: rate,
        discountAmount: discount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PosPicker<ProductModel>(
                  label: 'Product or barcode',
                  selectedItem: _product,
                  search: _searchProducts,
                  itemLabel: (p) => p.productCode == null
                      ? p.name
                      : '${p.name} (${p.productCode})',
                  onChanged: _onProductSelected,
                  autofocus: widget.autofocusProduct,
                  focusNode: _productFocus,
                  onScan: _scanBarcode,
                  onBarcode: _findProductByBarcode,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remove item',
                onPressed: widget.canRemove ? widget.onRemove : null,
              ),
            ],
          ),
          if (_missingBarcode != null) ...[
            const SizedBox(height: AppSpacing.smMd),
            Text(
              'Barcode not found — add it and ring it up.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _quickNameController,
                    focusNode: _quickNameFocus,
                    label: 'Name',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: _quickPriceController,
                    label: 'Sell price',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: 'Add & ring up',
                  isLoading: _quickAdding,
                  onPressed: _quickAdding ? null : _quickAdd,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.smMd),
          if (_loadingUnits)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_product != null) ...[
            PosPicker<ProductSellingUnitModel>(
              label: 'Selling unit',
              selectedItem: _unit,
              enabled: _unitOptions.isNotEmpty,
              items: _unitOptions,
              itemLabel: (unit) => '${unit.unit.name} (${unit.unit.symbol})',
              onChanged: _onUnitSelected,
              focusNode: _sellingUnitFocus,
            ),
            const SizedBox(height: AppSpacing.smMd),
          ],
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _quantityController,
                  label: 'Quantity',
                  hint: 'e.g. 2',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  focusNode: _quantityFocus,
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: AppTextField(
                  controller: _rateController,
                  label: 'Selling price',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: AppTextField(
                  controller: _discountController,
                  label: 'Item discount (optional)',
                  hint: 'e.g. 0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
