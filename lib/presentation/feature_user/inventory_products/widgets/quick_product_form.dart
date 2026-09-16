import 'package:flutter/material.dart';
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

  InventoryCategoryModel? _category;
  InventoryUnitModel? _sellingUnit;
  bool _saving = false;
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
    _name.dispose();
    _price.dispose();
    _barcode.dispose();
    super.dispose();
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

  Future<void> _addCategory() async {
    final added = await context.push<bool>(Routes.inventoryCategoryNew);
    if (added != true || !mounted) return;
    await ref
        .read(inventoryProductsControllerProvider.notifier)
        .refreshCategoryOptions();
  }

  Future<void> _allowSellingUnit(
    InventoryCategoryModel category,
    InventoryUnitModel sellingUnit,
  ) async {
    final categories = ref.read(inventoryCategoriesRemoteDataSourceProvider);
    final allowed = await categories.unitsForUsage(
      category.id,
      CategoryUnitUsage.selling,
    );
    if (allowed.any((unit) => unit.id == sellingUnit.id)) return;
    await categories.assignUnit(
      category.id,
      AssignCategoryUnitRequest(
        unitId: sellingUnit.id,
        usage: CategoryUnitUsage.selling,
      ),
    );
  }

  Future<void> _save(List<InventoryUnitModel> units) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final category = _category;
    final sellingUnit = _sellingUnit;
    final baseUnit = _baseUnitFor(units);
    final price = double.tryParse(_price.text.trim());
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

    setState(() {
      _saving = true;
      _error = null;
    });

    final controller = ref.read(inventoryProductsControllerProvider.notifier);
    final dataSource = ref.read(inventoryProductsRemoteDataSourceProvider);
    ProductModel? product;
    try {
      await _allowSellingUnit(category, sellingUnit);
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
      await controller.refresh();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = product == null
              ? e.message
              : 'Product was saved, but its selling price could not be added. '
                    'Open product details and add the selling unit there.',
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
                  'Enter what you sell and its price. Supplier packaging can be added later.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
                : (unit) => setState(() => _sellingUnit = unit),
            validator: (value) => value == null ? 'Choose how it is sold.' : null,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _price,
            label: 'Selling price (Rs.)',
            hint: 'e.g. 20',
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final price = double.tryParse((value ?? '').trim());
              return price == null || price < 0 ? 'Enter a valid price.' : null;
            },
          ),
          const SizedBox(height: AppSpacing.smMd),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Barcode (optional)'),
            subtitle: const Text('Add it now only if you have it.'),
            children: [
              AppTextField(
                controller: _barcode,
                label: 'Barcode',
                enabled: !_saving,
              ),
            ],
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
            'Need cartons, purchase prices or a different selling pack? Add those later from product details.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
