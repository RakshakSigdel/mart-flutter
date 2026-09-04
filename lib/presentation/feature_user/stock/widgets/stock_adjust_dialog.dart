import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../controllers/stock_detail_controller.dart';

/// Corrects a stock figure after a physical count, in either direction.
class StockAdjustDialog extends ConsumerStatefulWidget {
  const StockAdjustDialog({
    super.key,
    required this.productId,
    required this.unitOptions,
  });

  final int productId;
  final List<InventoryUnitModel> unitOptions;

  @override
  ConsumerState<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends ConsumerState<StockAdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _remarkController = TextEditingController();
  InventoryUnitModel? _unit;
  bool _increase = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final unit = _unit;
    if (unit == null) {
      setState(() => _errorMessage = 'Unit is required');
      return;
    }
    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      setState(() => _errorMessage = 'Enter a positive quantity');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(stockDetailControllerProvider(widget.productId).notifier)
          .adjust(
            quantity: quantity,
            unitId: unit.id,
            increase: _increase,
            remark: _remarkController.text.trim().isEmpty
                ? null
                : _remarkController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Increase',
                  variant: _increase
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                  leading: const Icon(Icons.add_rounded, size: 16),
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _increase = true),
                ),
              ),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: AppButton(
                  label: 'Decrease',
                  variant: !_increase
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                  leading: const Icon(Icons.remove_rounded, size: 16),
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _increase = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppSearchableDropdownField<InventoryUnitModel>(
            label: 'Unit',
            selectedItem: _unit,
            items: widget.unitOptions,
            itemLabel: (u) => '${u.name} (${u.symbol})',
            hint: 'Select a unit',
            onChanged: (value) => setState(() => _unit = value),
            validator: (value) => value == null ? 'Unit is required' : null,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField(
            controller: _quantityController,
            label: 'Quantity',
            hint: 'e.g. 5',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            enabled: !_submitting,
            validator: (v) {
              final parsed = double.tryParse((v ?? '').trim());
              return (parsed == null || parsed <= 0)
                  ? 'Enter a positive number'
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField.multiline(
            controller: _remarkController,
            label: 'Remark',
            hint: 'e.g. Recount after stocktake',
            minLines: 2,
            maxLines: 3,
            enabled: !_submitting,
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: 'Save adjustment',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

/// Opens [StockAdjustDialog] as a centered dialog on wide screens, or a
/// bottom sheet on phone. Resolves `true` once the adjustment is recorded.
Future<bool?> showStockAdjustDialog(
  BuildContext context, {
  required int productId,
  required List<InventoryUnitModel> unitOptions,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  final content = StockAdjustDialog(
    productId: productId,
    unitOptions: unitOptions,
  );

  return isWide
      ? showAppDialog<bool>(
          context: context,
          title: 'Adjust stock',
          content: content,
        )
      : showAppModal<bool>(
          context: context,
          title: 'Adjust stock',
          content: content,
        );
}
