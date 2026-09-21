import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../controllers/inventory_products_controller.dart';
import 'barcode_scanner_screen.dart';

/// One progressive product form: shorthand for ordinary piece goods and the
/// explicit composite payload only when the user chooses a more complex setup.
class _CatalogueMoveFocusIntent extends Intent {
  const _CatalogueMoveFocusIntent(this.forward);
  final bool forward;
}

class _CatalogueMoveFocusAction extends Action<_CatalogueMoveFocusIntent> {
  _CatalogueMoveFocusAction(this.scope);
  final FocusScopeNode scope;
  @override
  Object? invoke(_CatalogueMoveFocusIntent intent) =>
      intent.forward ? scope.nextFocus() : scope.previousFocus();
}

class QuickProductForm extends ConsumerStatefulWidget {
  const QuickProductForm({super.key});
  @override
  ConsumerState<QuickProductForm> createState() => _QuickProductFormState();
}

class _QuickProductFormState extends ConsumerState<QuickProductForm> {
  final _key = GlobalKey<FormState>();
  final _scope = FocusScopeNode(debugLabel: 'add-product-form');
  final _name = TextEditingController(), _barcode = TextEditingController();
  final _buyPrice = TextEditingController(),
      _sellPrice = TextEditingController();
  final _buyQty = TextEditingController(),
      _extraPrice = TextEditingController(),
      _extraQty = TextEditingController();
  InventoryCategoryModel? _category;
  InventoryUnitModel? _sell, _buy, _buyContains, _extra, _extraContains;
  bool _advanced = false, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(inventoryProductsControllerProvider.notifier)
          .ensureUnitOptionsLoaded(),
    );
  }

  @override
  void dispose() {
    _scope.dispose();
    for (final c in [
      _name,
      _barcode,
      _buyPrice,
      _sellPrice,
      _buyQty,
      _extraPrice,
      _extraQty,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim());
  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();
  bool _needsPack(InventoryUnitModel? u) => u?.conversionFactor == null;
  List<InventoryUnitModel> _sameType(List<InventoryUnitModel> all) =>
      _sell?.measurementType == null
      ? all
      : all.where((u) => u.measurementType == _sell!.measurementType).toList();

  ProductTradingLineRequest _line(
    InventoryUnitModel unit,
    double? price,
    bool isDefault,
    TextEditingController? qty,
    InventoryUnitModel? contained, {
    String? barcode,
  }) => ProductTradingLineRequest(
    unitId: unit.id,
    price: price,
    isDefault: isDefault,
    barcode: barcode,
    contains: _needsPack(unit)
        ? ProductContainsRequest(qty: _num(qty!)!, unitId: contained!.id)
        : null,
  );

  Future<void> _save(List<InventoryUnitModel> all) async {
    if (!_key.currentState!.validate() || _category == null || _sell == null) {
      setState(
        () => _error = _category == null
            ? 'Choose a category.'
            : 'Choose how the product is sold.',
      );
      return;
    }
    final sellPrice = _num(_sellPrice),
        buyPrice = _num(_buyPrice),
        buy = _buy ?? _sell!;
    final invalidPack =
        (_needsPack(buy) && (_num(_buyQty) == null || _buyContains == null)) ||
        (_advanced &&
            _extra != null &&
            (_num(_extraPrice) == null ||
                (_needsPack(_extra) &&
                    (_num(_extraQty) == null || _extraContains == null))));
    if (invalidPack) {
      setState(
        () => _error =
            'Add the price and pack contents for each selected pack unit.',
      );
      return;
    }
    // A default Piece sale with no advanced setup uses the API's concise form.
    final shorthand =
        _sell!.measurementType == UnitMeasurementType.count &&
        _sell!.referenceUnit &&
        _buy == null &&
        !_advanced;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final sells = [
        _line(_sell!, sellPrice, true, null, null, barcode: _text(_barcode)),
        if (_advanced && _extra != null)
          _line(_extra!, _num(_extraPrice), false, _extraQty, _extraContains),
      ];
      final buys = buyPrice == null
          ? <ProductTradingLineRequest>[]
          : [_line(buy, buyPrice, true, _buyQty, _buyContains)];
      await ref
          .read(inventoryProductsControllerProvider.notifier)
          .createProduct(
            CreateProductRequest(
              name: _name.text.trim(),
              categoryId: _category!.id,
              purchasePrice: shorthand ? buyPrice : null,
              sellingPrice: shorthand ? sellPrice : null,
              barcode: shorthand ? _text(_barcode) : null,
              sellIn: shorthand ? null : sells,
              buyIn: shorthand || buys.isEmpty ? null : buys,
            ),
          );
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _scan() async {
    final code = await showBarcodeScannerSheet(context);
    if (code != null && mounted) setState(() => _barcode.text = code);
  }

  /// A dropdown's popup owns focus while it is open. Advance only after it
  /// has closed, otherwise the following arrow key would remain trapped in
  /// the just-selected popup.
  void _advanceAfterSelection(VoidCallback selection) {
    selection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scope.nextFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProductsControllerProvider);
    final units = state.unitOptions;
    _sell ??= units.where((u) => u.symbol.toLowerCase() == 'pc').firstOrNull;
    final compatible = _sameType(units);
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown):
            _CatalogueMoveFocusIntent(true),
        SingleActivator(LogicalKeyboardKey.arrowRight):
            _CatalogueMoveFocusIntent(true),
        SingleActivator(LogicalKeyboardKey.arrowUp): _CatalogueMoveFocusIntent(
          false,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft):
            _CatalogueMoveFocusIntent(false),
      },
      child: Actions(
        actions: {_CatalogueMoveFocusIntent: _CatalogueMoveFocusAction(_scope)},
        child: FocusScope(
          node: _scope,
          autofocus: true,
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: Form(
              key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add product', style: AppTypography.heading),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _name,
                    label: 'Name',
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _scope.nextFocus(),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Enter a product name.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.smMd),
                  AppDropdownField<InventoryCategoryModel>(
                    label: 'Category',
                    value: _category,
                    items: [
                      for (final category in state.categoryOptions)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        ),
                    ],
                    hint: 'Choose a category',
                    onChanged: _saving
                        ? (_) {}
                        : (v) => _advanceAfterSelection(
                            () => setState(() => _category = v),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.smMd),
                  AppTextField(
                    controller: _barcode,
                    label: 'Barcode (optional)',
                    suffixIcon: Icons.qr_code_scanner_outlined,
                    onSuffixTap: _saving ? null : _scan,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _scope.nextFocus(),
                  ),
                  const SizedBox(height: AppSpacing.smMd),
                  _price(
                    'Buy at',
                    _buyPrice,
                    _buy ?? _sell,
                    compatible,
                    (v) => setState(() => _buy = v),
                  ),
                  const SizedBox(height: AppSpacing.smMd),
                  _price(
                    'Sell at',
                    _sellPrice,
                    _sell,
                    units,
                    (v) => setState(() {
                      _sell = v;
                      _buy = null;
                      _extra = null;
                    }),
                    required: true,
                  ),
                  if (_needsPack(_buy ?? _sell)) ...[
                    const SizedBox(height: AppSpacing.smMd),
                    _contains(
                      _buyQty,
                      _buyContains,
                      compatible,
                      (v) => setState(() => _buyContains = v),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.smMd),
                  ExpansionTile(
                    title: const Text('Buy in bulk / sell in multiple units'),
                    subtitle: const Text(
                      'Add a supplier pack or another selling size.',
                    ),
                    onExpansionChanged: (v) => setState(() => _advanced = v),
                    children: [
                      if (_advanced)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              AppDropdownField<InventoryUnitModel>(
                                label: 'Extra selling unit',
                                value: _extra,
                                items: _unitItems(compatible),
                                hint: 'Optional',
                                onChanged: (v) => _advanceAfterSelection(
                                  () => setState(() => _extra = v),
                                ),
                              ),
                              if (_extra != null) ...[
                                const SizedBox(height: AppSpacing.smMd),
                                AppTextField(
                                  controller: _extraPrice,
                                  label: 'Extra selling price',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                                if (_needsPack(_extra)) ...[
                                  const SizedBox(height: AppSpacing.smMd),
                                  _contains(
                                    _extraQty,
                                    _extraContains,
                                    compatible,
                                    (v) => setState(() => _extraContains = v),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                  AppFormError(message: _error),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton.expanded(
                    label: 'Save product',
                    isLoading: _saving,
                    onPressed: _saving ? null : () => _save(units),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _price(
    String label,
    TextEditingController controller,
    InventoryUnitModel? selected,
    List<InventoryUnitModel> options,
    ValueChanged<InventoryUnitModel?> changed, {
    bool required = false,
  }) => Row(
    children: [
      Expanded(
        child: AppTextField(
          controller: controller,
          label: label,
          hint: required ? 'Required' : 'Optional',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _scope.nextFocus(),
          validator: required
              ? (v) => _num(controller) == null ? 'Enter a valid price.' : null
              : null,
        ),
      ),
      const SizedBox(width: AppSpacing.smMd),
      Expanded(
        child: AppDropdownField<InventoryUnitModel>(
          label: 'per',
          value: selected,
          items: _unitItems(options),
          hint: 'Unit',
          onChanged: _saving
              ? (_) {}
              : (value) => _advanceAfterSelection(() => changed(value)),
        ),
      ),
    ],
  );
  Widget _contains(
    TextEditingController qty,
    InventoryUnitModel? selected,
    List<InventoryUnitModel> options,
    ValueChanged<InventoryUnitModel?> changed,
  ) => Row(
    children: [
      Expanded(
        child: AppTextField(
          controller: qty,
          label: 'Pack contains',
          hint: 'Quantity',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _scope.nextFocus(),
        ),
      ),
      const SizedBox(width: AppSpacing.smMd),
      Expanded(
        child: AppDropdownField<InventoryUnitModel>(
          label: 'of unit',
          value: selected,
          items: _unitItems(options),
          hint: 'e.g. kg',
          onChanged: _saving
              ? (_) {}
              : (value) => _advanceAfterSelection(() => changed(value)),
        ),
      ),
    ],
  );

  List<DropdownMenuItem<InventoryUnitModel>> _unitItems(
    List<InventoryUnitModel> units,
  ) => [
    for (final unit in units)
      DropdownMenuItem(
        value: unit,
        child: Text('${unit.name} (${unit.symbol})'),
      ),
  ];
}
