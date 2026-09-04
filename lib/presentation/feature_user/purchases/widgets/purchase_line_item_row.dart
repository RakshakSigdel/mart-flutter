import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';

/// A snapshot of one line item row's editable state — what
/// `PurchaseLineItemRow` reports up to the form on every change, so the
/// form can compute a running total and, on submit, build the request
/// without reaching back into any row's own widget state.
class PurchaseLineItemData {
  const PurchaseLineItemData({
    this.productId,
    this.productName,
    this.purchaseUnitId,
    this.purchaseUnitLabel,
    required this.quantity,
    required this.rate,
  });

  final int? productId;
  final String? productName;
  final int? purchaseUnitId;
  final String? purchaseUnitLabel;
  final double quantity;
  final double rate;

  double get lineTotal => quantity * rate;

  bool get isComplete =>
      productId != null && purchaseUnitId != null && quantity > 0;
}

/// One product/purchase-unit/quantity/rate row in the purchase form's item
/// list — fully self-contained: it fetches the selected product's own
/// purchase units itself (rather than the form preloading every product's
/// units up front) and only ever reports a plain [PurchaseLineItemData]
/// snapshot upward via [onChanged].
class PurchaseLineItemRow extends ConsumerStatefulWidget {
  const PurchaseLineItemRow({
    super.key,
    required this.onChanged,
    required this.onRemove,
  });

  final ValueChanged<PurchaseLineItemData> onChanged;
  final VoidCallback onRemove;

  @override
  ConsumerState<PurchaseLineItemRow> createState() =>
      _PurchaseLineItemRowState();
}

class _PurchaseLineItemRowState extends ConsumerState<PurchaseLineItemRow> {
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();

  ProductModel? _product;
  ProductPurchaseUnitModel? _unit;
  List<ProductPurchaseUnitModel> _unitOptions = [];
  bool _loadingUnits = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
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
          .purchaseUnits(product.id);
      if (!mounted) return;
      ProductPurchaseUnitModel? defaultUnit;
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
      if (selected != null) {
        _rateController.text = formatMoneyAmount(selected.purchasePrice);
      }
      _notify();
    } on ApiException {
      if (!mounted) return;
      setState(() => _loadingUnits = false);
    }
  }

  void _onUnitSelected(ProductPurchaseUnitModel? unit) {
    setState(() => _unit = unit);
    if (unit != null && _rateController.text.trim().isEmpty) {
      _rateController.text = formatMoneyAmount(unit.purchasePrice);
    }
    _notify();
  }

  void _notify() {
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    widget.onChanged(
      PurchaseLineItemData(
        productId: _product?.id,
        productName: _product?.name,
        purchaseUnitId: _unit?.id,
        purchaseUnitLabel: _unit == null
            ? null
            : '${_unit!.unit.name} (${_unit!.unit.symbol})',
        quantity: quantity,
        rate: rate,
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
                  label: 'Product',
                  selectedItem: _product,
                  asyncItems: _searchProducts,
                  itemLabel: (p) => p.productCode == null
                      ? p.name
                      : '${p.name} (${p.productCode})',
                  hint: 'Search product',
                  onChanged: _onProductSelected,
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
            AppDropdownField<ProductPurchaseUnitModel?>(
              label: 'Purchase unit',
              value: _unit,
              hint: _unitOptions.isEmpty
                  ? 'No purchase units set up'
                  : 'Select a unit',
              items: [
                for (final unit in _unitOptions)
                  DropdownMenuItem(
                    value: unit,
                    child: Text('${unit.unit.name} (${unit.unit.symbol})'),
                  ),
              ],
              onChanged: _onUnitSelected,
            ),
            const SizedBox(height: AppSpacing.smMd),
          ],
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _quantityController,
                  label: 'Quantity',
                  hint: 'e.g. 10',
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
                  controller: _rateController,
                  label: 'Rate',
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
