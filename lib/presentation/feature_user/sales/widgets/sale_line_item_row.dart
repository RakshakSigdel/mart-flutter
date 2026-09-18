import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';

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
    this.autofocusProduct = false,
  });

  final ValueChanged<SaleLineItemData> onChanged;
  final VoidCallback onRemove;
  final bool autofocusProduct;

  @override
  ConsumerState<SaleLineItemRow> createState() => _SaleLineItemRowState();
}

class _SaleLineItemRowState extends ConsumerState<SaleLineItemRow> {
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _discountController = TextEditingController();
  final _productFocus = FocusNode();
  final _sellingUnitFocus = FocusNode();
  final _quantityFocus = FocusNode();

  ProductModel? _product;
  ProductSellingUnitModel? _unit;
  List<ProductSellingUnitModel> _unitOptions = [];
  bool _loadingUnits = false;

  @override
  void initState() {
    super.initState();
    if (widget.autofocusProduct) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _productFocus.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    _productFocus.dispose();
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
      return const [];
    }
  }

  Future<void> _onProductSelected(ProductModel? product) async {
    setState(() {
      _product = product;
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
      if (!mounted) return;
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
        if (!mounted) return;
        (units.isEmpty ? _quantityFocus : _sellingUnitFocus).requestFocus();
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _loadingUnits = false);
    }
  }

  void _onUnitSelected(ProductSellingUnitModel? unit) {
    setState(() => _unit = unit);
    if (unit != null && _rateController.text.trim().isEmpty) {
      _rateController.text = formatMoneyAmount(unit.sellingPrice);
    }
    _notify();
    _quantityFocus.requestFocus();
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
                child: AppSearchableDropdownField<ProductModel>(
                  label: 'Product or barcode',
                  selectedItem: _product,
                  asyncItems: _searchProducts,
                  itemLabel: (p) => p.productCode == null
                      ? p.name
                      : '${p.name} (${p.productCode})',
                  hint: 'Search by name or code',
                  onChanged: _onProductSelected,
                  autofocus: widget.autofocusProduct,
                  focusNode: _productFocus,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remove item',
                onPressed: widget.onRemove,
              ),
            ],
          ),
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
            AppDropdownField<ProductSellingUnitModel?>(
              label: 'Selling unit',
              value: _unit,
              hint: _unitOptions.isEmpty
                  ? 'No selling units set up'
                  : 'Select a unit',
              items: [
                for (final unit in _unitOptions)
                  DropdownMenuItem(
                    value: unit,
                    child: Text('${unit.unit.name} (${unit.unit.symbol})'),
                  ),
              ],
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
