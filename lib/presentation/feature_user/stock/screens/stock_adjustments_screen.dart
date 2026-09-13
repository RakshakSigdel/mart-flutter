import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../../../../data/models/models_user/stock_model.dart';
import '../../../../providers/providers_user/inventory_units_provider.dart';
import '../../../../providers/providers_user/stock_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';
import '../controllers/stock_controller.dart';

/// A dedicated workspace for correcting stock after a physical count. It is
/// intentionally separate from [StockScreen], whose job is inspecting stock
/// levels and reorder thresholds rather than changing quantities.
class StockAdjustmentsScreen extends ConsumerStatefulWidget {
  const StockAdjustmentsScreen({super.key});

  @override
  ConsumerState<StockAdjustmentsScreen> createState() =>
      _StockAdjustmentsScreenState();
}

class _StockAdjustmentsScreenState
    extends ConsumerState<StockAdjustmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _remarkController = TextEditingController();

  StockLevelModel? _product;
  InventoryUnitModel? _unit;
  List<InventoryUnitModel> _unitOptions = const [];
  StockMovementType _movementType = StockMovementType.adjustmentIn;
  bool _loadingUnits = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<List<StockLevelModel>> _searchProducts(String query) async {
    try {
      final result = await ref
          .read(stockRemoteDataSourceProvider)
          .list(
            search: query.trim().isEmpty ? null : query.trim(),
            page: 1,
            size: 20,
          );
      return result.content;
    } on ApiException {
      return const [];
    }
  }

  Future<void> _selectProduct(StockLevelModel? product) async {
    setState(() {
      _product = product;
      _unit = null;
      _errorMessage = null;
    });
    if (product == null || _unitOptions.isNotEmpty) return;

    setState(() => _loadingUnits = true);
    try {
      final units = await ref
          .read(inventoryUnitsRemoteDataSourceProvider)
          .selection();
      if (mounted) setState(() => _unitOptions = units);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loadingUnits = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final product = _product;
    final unit = _unit;
    final quantity = double.tryParse(_quantityController.text.trim());
    if (product == null) {
      setState(() => _errorMessage = 'Select a product.');
      return;
    }
    if (unit == null) {
      setState(() => _errorMessage = 'Select a unit.');
      return;
    }
    if (quantity == null || quantity <= 0) {
      setState(() => _errorMessage = 'Enter a positive quantity.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(stockRemoteDataSourceProvider)
          .adjust(
            RecordStockMovementRequest.adjustment(
              productId: product.productId,
              quantity: quantity,
              unitId: unit.id,
              movementType: _movementType,
              remark: _remarkController.text.trim().isEmpty
                  ? null
                  : _remarkController.text.trim(),
            ),
          );
      await ref.read(stockControllerProvider.notifier).refresh();
      if (!mounted) return;
      _quantityController.clear();
      _remarkController.clear();
      AppSnackBar.success(
        context,
        'Stock adjusted for ${product.productName}.',
      );
    } on ApiException catch (e) {
      if (e.type == ApiFailureType.unauthorized) {
        await ref.read(authControllerProvider.notifier).logout();
      }
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Stock adjustments', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Correct on-hand quantities after a physical stock count.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSearchableDropdownField<StockLevelModel>(
                      label: 'Product',
                      selectedItem: _product,
                      asyncItems: _searchProducts,
                      itemLabel: (item) => item.productCode == null
                          ? item.productName
                          : '${item.productName} (${item.productCode})',
                      hint: 'Search a stocked product',
                      onChanged: (value) {
                        if (!_submitting) _selectProduct(value);
                      },
                      validator: (value) =>
                          value == null ? 'Product is required.' : null,
                    ),
                    if (_product != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Current on hand: ${formatStockQuantity(_product!.quantity)}'
                        '${_product!.baseUnitSymbol == null ? '' : ' ${_product!.baseUnitSymbol}'}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppDropdownField<StockMovementType>(
                      label: 'Movement type',
                      value: _movementType,
                      items: StockMovementType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(formatMovementType(type.apiValue)),
                            ),
                          )
                          .toList(),
                      onChanged: (type) {
                        if (type != null && !_submitting) {
                          setState(() => _movementType = type);
                        }
                      },
                      enabled: !_submitting,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_loadingUnits)
                      const Center(child: AppLoader())
                    else
                      AppSearchableDropdownField<InventoryUnitModel>(
                        label: 'Unit',
                        selectedItem: _unit,
                        items: _unitOptions,
                        itemLabel: (item) => '${item.name} (${item.symbol})',
                        hint: _product == null
                            ? 'Select a product first'
                            : 'Select a unit',
                        onChanged: (value) {
                          if (!_submitting && _product != null) {
                            setState(() => _unit = value);
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Unit is required.' : null,
                      ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      hint: 'e.g. 5',
                      enabled: !_submitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        return parsed == null || parsed <= 0
                            ? 'Enter a positive quantity.'
                            : null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField.multiline(
                      controller: _remarkController,
                      label: 'Remark',
                      hint: 'e.g. Recount after stocktake',
                      enabled: !_submitting,
                      minLines: 2,
                      maxLines: 3,
                    ),
                    AppFormError(message: _errorMessage),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.expanded(
                      label: 'Save adjustment',
                      isLoading: _submitting,
                      onPressed: _submitting ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
