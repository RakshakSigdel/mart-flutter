import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../../../../providers/providers_user/inventory_categories_provider.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';
import '../controllers/inventory_products_controller.dart';
import 'barcode_scanner_screen.dart';

/// The everyday catalogue entry point. It asks for the four things a
/// shopkeeper knows at the shelf, then creates the product and its default
/// selling unit with the existing frontend endpoints.
class QuickProductForm extends ConsumerStatefulWidget {
  const QuickProductForm({super.key});

  @override
  ConsumerState<QuickProductForm> createState() => _QuickProductFormState();
}

class _QuickProductFormState extends ConsumerState<QuickProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _barcode = TextEditingController();
  final _purchasePackQuantity = TextEditingController();
  final _purchaseCost = TextEditingController();
  final _purchaseVat = TextEditingController(text: '0');
  final _additionalSellingQuantity = TextEditingController();
  final _additionalSellingPrice = TextEditingController();
  final _priceFocus = FocusNode();
  final _barcodeFocus = FocusNode();

  InventoryCategoryModel? _category;
  InventoryUnitModel? _sellingUnit;
  InventoryUnitModel? _purchaseUnit;
  InventoryUnitModel? _additionalSellingUnit;
  bool _addPurchasePack = false;
  bool _addSellingSize = false;
  bool _saving = false;
  String? _error;
  String _hardwareScanBuffer = '';
  DateTime? _lastHardwareScanKey;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(inventoryProductsControllerProvider.notifier)
          .ensureUnitOptionsLoaded(),
    );
    HardwareKeyboard.instance.addHandler(_handleHardwareScannerInput);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _barcode.dispose();
    _purchasePackQuantity.dispose();
    _purchaseCost.dispose();
    _purchaseVat.dispose();
    _additionalSellingQuantity.dispose();
    _additionalSellingPrice.dispose();
    _priceFocus.dispose();
    _barcodeFocus.dispose();
    HardwareKeyboard.instance.removeHandler(_handleHardwareScannerInput);
    super.dispose();
  }

  /// Handheld scanners usually behave as a keyboard. When one scans while
  /// the selling-price field is focused, its rapid, Enter-terminated value
  /// belongs in Barcode rather than in the price.
  bool _handleHardwareScannerInput(KeyEvent event) {
    if (!_priceFocus.hasFocus || event is! KeyDownEvent) return false;

    final now = DateTime.now();
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final isScannerInput =
          _hardwareScanBuffer.length >= 6 &&
          _lastHardwareScanKey != null &&
          now.difference(_lastHardwareScanKey!) < const Duration(milliseconds: 150);
      final barcode = _hardwareScanBuffer;
      _hardwareScanBuffer = '';
      _lastHardwareScanKey = null;

      if (isScannerInput) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _price.clear();
            _barcode.text = barcode;
          });
          _barcodeFocus.requestFocus();
        });
        return true;
      }
      return false;
    }

    final character = event.character;
    if (character == null || character.isEmpty) {
      _hardwareScanBuffer = '';
      _lastHardwareScanKey = null;
      return false;
    }

    if (_lastHardwareScanKey == null ||
        now.difference(_lastHardwareScanKey!) > const Duration(milliseconds: 80)) {
      _hardwareScanBuffer = '';
    }
    _hardwareScanBuffer += character;
    _lastHardwareScanKey = now;
    return false;
  }

  InventoryUnitModel? _baseUnitFor(List<InventoryUnitModel> units) {
    final sellingUnit = _sellingUnit;
    if (sellingUnit == null) return null;
    for (final unit in units) {
      if (unit.referenceUnit &&
          unit.measurementType == sellingUnit.measurementType) {
        return unit;
      }
    }
    return null;
  }

  List<InventoryUnitModel> _compatibleUnits(List<InventoryUnitModel> units) {
    final sellingUnit = _sellingUnit;
    if (sellingUnit == null) return const [];
    return units
        .where((unit) => unit.measurementType == sellingUnit.measurementType)
        .toList();
  }

  Future<void> _addCategory() async {
    final added = await context.push<bool>(Routes.inventoryCategoryNew);
    if (added != true || !mounted) return;
    await ref
        .read(inventoryProductsControllerProvider.notifier)
        .refreshCategoryOptions();
  }

  Future<void> _scanBarcode() async {
    final barcode = await showBarcodeScannerSheet(context);
    if (barcode == null || !mounted) return;
    setState(() => _barcode.text = barcode);
  }

  Future<void> _allowUnit(
    InventoryCategoryModel category,
    InventoryUnitModel unit,
    CategoryUnitUsage usage,
  ) async {
    final categories = ref.read(inventoryCategoriesRemoteDataSourceProvider);
    final allowed = await categories.unitsForUsage(category.id, usage);
    if (allowed.any((allowedUnit) => allowedUnit.id == unit.id)) return;
    await categories.assignUnit(
      category.id,
      AssignCategoryUnitRequest(
        unitId: unit.id,
        usage: usage,
      ),
    );
  }

  Future<void> _save(List<InventoryUnitModel> units) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final category = _category;
    final sellingUnit = _sellingUnit;
    final baseUnit = _baseUnitFor(units);
    final price = double.tryParse(_price.text.trim());
    final purchasePackQuantity = double.tryParse(_purchasePackQuantity.text.trim());
    final purchaseCost = double.tryParse(_purchaseCost.text.trim());
    final purchaseVat = double.tryParse(_purchaseVat.text.trim());
    final additionalSellingQuantity = double.tryParse(
      _additionalSellingQuantity.text.trim(),
    );
    final additionalSellingPrice = double.tryParse(
      _additionalSellingPrice.text.trim(),
    );
    if (category == null || sellingUnit == null) {
      setState(() => _error = 'Choose a category and how this product is sold.');
      return;
    }
    if (baseUnit == null) {
      setState(
        () => _error =
            'This selling unit has no base unit. Ask an owner to set up units first.',
      );
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Enter a valid selling price.');
      return;
    }
    if (_addPurchasePack &&
        (_purchaseUnit == null ||
            purchasePackQuantity == null ||
            purchasePackQuantity <= 0 ||
            purchaseCost == null ||
            purchaseCost < 0 ||
            purchaseVat == null ||
            purchaseVat < 0)) {
      setState(
        () => _error =
            'Complete the supplier pack with its unit, quantity, cost and VAT.',
      );
      return;
    }
    if (_addSellingSize &&
        (_additionalSellingUnit == null ||
            additionalSellingQuantity == null ||
            additionalSellingQuantity <= 0 ||
            additionalSellingPrice == null ||
            additionalSellingPrice < 0)) {
      setState(
        () => _error = 'Complete the extra selling size with its unit, quantity and price.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final controller = ref.read(inventoryProductsControllerProvider.notifier);
    final dataSource = ref.read(inventoryProductsRemoteDataSourceProvider);
    ProductModel? product;
    try {
      await _allowUnit(category, sellingUnit, CategoryUnitUsage.selling);
      if (_addPurchasePack) {
        await _allowUnit(
          category,
          _purchaseUnit!,
          CategoryUnitUsage.purchase,
        );
      }
      if (_addSellingSize) {
        await _allowUnit(
          category,
          _additionalSellingUnit!,
          CategoryUnitUsage.selling,
        );
      }
      product = await controller.createProduct(
        CreateProductRequest(
          name: _name.text.trim(),
          categoryId: category.id,
          baseUnitId: baseUnit.id,
        ),
      );
      await dataSource.addSellingUnit(
        product.id,
        CreateSellingUnitRequest(
          unitId: sellingUnit.id,
          packQuantity: 1,
          sellingPrice: price,
          barcode: _emptyToNull(_barcode.text),
          active: true,
          isDefault: true,
        ),
      );
      if (_addPurchasePack) {
        await dataSource.addPurchaseUnit(
          product.id,
          CreatePurchaseUnitRequest(
            unitId: _purchaseUnit!.id,
            packQuantity: purchasePackQuantity!,
            purchasePrice: purchaseCost!,
            active: true,
            isDefault: true,
            vat: OpenVatRateRequest(rate: purchaseVat!),
          ),
        );
      }
      if (_addSellingSize) {
        await dataSource.addSellingUnit(
          product.id,
          CreateSellingUnitRequest(
            unitId: _additionalSellingUnit!.id,
            packQuantity: additionalSellingQuantity!,
            sellingPrice: additionalSellingPrice!,
            active: true,
            isDefault: false,
          ),
        );
      }
      await controller.refresh();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = product == null
              ? e.message
              : 'Product was saved, but one or more prices or pack details '
                    'could not be added. Open product details to finish them.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProductsControllerProvider);
    final units = state.unitOptions;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppBorderRadius.radiusL,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add a product quickly', style: AppTypography.title),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Start with the main item. Supplier packs and extra selling sizes are optional.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Main item', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Required details for the product customers buy one at a time.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _name,
            label: 'Product name',
            hint: 'e.g. Wai Wai noodles',
            enabled: !_saving,
            autofocus: true,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the product name.'
                : null,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppSearchableDropdownField<InventoryCategoryModel>(
            label: 'Category',
            selectedItem: _category,
            items: state.categoryOptions,
            itemLabel: (category) => category.name,
            hint: state.categoryOptions.isEmpty
                ? 'Add a category first'
                : 'Choose a category',
            onChanged: _saving
                ? (_) {}
                : (category) => setState(() => _category = category),
            validator: (value) => value == null ? 'Choose a category.' : null,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _saving ? null : _addCategory,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add a category'),
            ),
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppSearchableDropdownField<InventoryUnitModel>(
            label: 'Sold as',
            selectedItem: _sellingUnit,
            items: units,
            itemLabel: (unit) => '${unit.name} (${unit.symbol})',
            hint: units.isEmpty ? 'Loading units...' : 'Piece, packet, kg...',
            onChanged: _saving
                ? (_) {}
                : (unit) => setState(() {
                    _sellingUnit = unit;
                    if (_purchaseUnit?.measurementType != unit?.measurementType) {
                      _purchaseUnit = null;
                    }
                    if (_additionalSellingUnit?.measurementType !=
                        unit?.measurementType) {
                      _additionalSellingUnit = null;
                    }
                  }),
            validator: (value) => value == null ? 'Choose how it is sold.' : null,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _price,
            label: 'Selling price (Rs.)',
            hint: 'e.g. 20',
            enabled: !_saving,
            focusNode: _priceFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final price = double.tryParse((value ?? '').trim());
              return price == null || price < 0 ? 'Enter a valid price.' : null;
            },
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _barcode,
            label: 'Barcode (optional)',
            hint: 'Enter barcode manually',
            enabled: !_saving,
            focusNode: _barcodeFocus,
            suffixIcon: Icons.qr_code_scanner_outlined,
            onSuffixTap: _saving ? null : _scanBarcode,
          ),
          const SizedBox(height: AppSpacing.smMd),
          _OptionalDetailsSection(
            title: 'Supplier pack & cost',
            subtitle: 'Optional — add the pack you buy from suppliers.',
            isExpanded: _addPurchasePack,
            onExpansionChanged: _saving
                ? null
                : (expanded) => setState(() => _addPurchasePack = expanded),
            child: _SupplierPackFields(
              units: _compatibleUnits(units),
              selectedUnit: _purchaseUnit,
              packQuantity: _purchasePackQuantity,
              cost: _purchaseCost,
              vat: _purchaseVat,
              enabled: !_saving,
              onUnitChanged: (unit) => setState(() => _purchaseUnit = unit),
            ),
          ),
          const SizedBox(height: AppSpacing.smMd),
          _OptionalDetailsSection(
            title: 'Extra selling size & price',
            subtitle: 'Optional — sell the same product in another size.',
            isExpanded: _addSellingSize,
            onExpansionChanged: _saving
                ? null
                : (expanded) => setState(() => _addSellingSize = expanded),
            child: _AdditionalSellingFields(
              units: _compatibleUnits(units),
              selectedUnit: _additionalSellingUnit,
              quantity: _additionalSellingQuantity,
              price: _additionalSellingPrice,
              enabled: !_saving,
              onUnitChanged: (unit) =>
                  setState(() => _additionalSellingUnit = unit),
            ),
          ),
          AppFormError(message: _error),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: 'Save product',
            isLoading: _saving,
            onPressed: _saving ? null : () => _save(units),
          ),
          const SizedBox(height: AppSpacing.smMd),
          const Text(
            'You can always add more packs and selling sizes from product details.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _OptionalDetailsSection extends StatelessWidget {
  const _OptionalDetailsSection({
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.child,
  });

  final String title;
  final String subtitle;
  final bool isExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppBorderRadius.radiusL,
      ),
      child: ExpansionTile(
        enabled: onExpansionChanged != null,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        title: Text(title, style: AppTypography.body),
        subtitle: Text(subtitle, style: AppTypography.bodySmall),
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SupplierPackFields extends StatelessWidget {
  const _SupplierPackFields({
    required this.units,
    required this.selectedUnit,
    required this.packQuantity,
    required this.cost,
    required this.vat,
    required this.enabled,
    required this.onUnitChanged,
  });

  final List<InventoryUnitModel> units;
  final InventoryUnitModel? selectedUnit;
  final TextEditingController packQuantity;
  final TextEditingController cost;
  final TextEditingController vat;
  final bool enabled;
  final ValueChanged<InventoryUnitModel?> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSearchableDropdownField<InventoryUnitModel>(
          label: 'Supplier pack unit',
          selectedItem: selectedUnit,
          items: units,
          itemLabel: (unit) => '${unit.name} (${unit.symbol})',
          hint: units.isEmpty ? 'Choose the main selling unit first' : 'e.g. carton',
          onChanged: enabled ? onUnitChanged : (_) {},
        ),
        const SizedBox(height: AppSpacing.smMd),
        AppTextField(
          controller: packQuantity,
          label: 'Items in this pack',
          hint: 'e.g. 12',
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.smMd),
        AppTextField(
          controller: cost,
          label: 'Supplier cost (Rs.)',
          hint: 'e.g. 180',
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.smMd),
        AppTextField(
          controller: vat,
          label: 'VAT rate (%)',
          hint: '0',
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}

class _AdditionalSellingFields extends StatelessWidget {
  const _AdditionalSellingFields({
    required this.units,
    required this.selectedUnit,
    required this.quantity,
    required this.price,
    required this.enabled,
    required this.onUnitChanged,
  });

  final List<InventoryUnitModel> units;
  final InventoryUnitModel? selectedUnit;
  final TextEditingController quantity;
  final TextEditingController price;
  final bool enabled;
  final ValueChanged<InventoryUnitModel?> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSearchableDropdownField<InventoryUnitModel>(
          label: 'Selling unit',
          selectedItem: selectedUnit,
          items: units,
          itemLabel: (unit) => '${unit.name} (${unit.symbol})',
          hint: units.isEmpty ? 'Choose the main selling unit first' : 'e.g. carton',
          onChanged: enabled ? onUnitChanged : (_) {},
        ),
        const SizedBox(height: AppSpacing.smMd),
        AppTextField(
          controller: quantity,
          label: 'Items in this size',
          hint: 'e.g. 12',
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.smMd),
        AppTextField(
          controller: price,
          label: 'Selling price (Rs.)',
          hint: 'e.g. 240',
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}
