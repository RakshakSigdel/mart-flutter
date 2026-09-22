import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';

/// One received line: a product, the pack it arrived in, how many, and what
/// each cost.
///
/// The form owns these — a line only exists once a product has been picked,
/// so there is never a half-empty row waiting to be filled in.
class PurchaseLineItemData {
  const PurchaseLineItemData({
    required this.product,
    required this.unitOptions,
    this.unit,
    this.quantity = 1,
    this.rate = 0,
  });

  final ProductModel product;
  final List<ProductPurchaseUnitModel> unitOptions;
  final ProductPurchaseUnitModel? unit;
  final double quantity;
  final double rate;

  double get lineTotal => quantity * rate;

  bool get isComplete =>
      unit != null &&
      quantity.isFinite &&
      quantity > 0 &&
      rate.isFinite &&
      rate >= 0;

  PurchaseLineItemData copyWith({
    ProductPurchaseUnitModel? unit,
    double? quantity,
    double? rate,
  }) => PurchaseLineItemData(
    product: product,
    unitOptions: unitOptions,
    unit: unit ?? this.unit,
    quantity: quantity ?? this.quantity,
    rate: rate ?? this.rate,
  );
}

/// A received item with unit selection before quantity and cost, followed
/// by an explicit calculation so the user can check the entry.
class PurchaseLineItemRow extends StatefulWidget {
  const PurchaseLineItemRow({
    super.key,
    required this.line,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final PurchaseLineItemData line;
  final bool enabled;
  final ValueChanged<PurchaseLineItemData> onChanged;
  final VoidCallback onRemove;

  @override
  State<PurchaseLineItemRow> createState() => _PurchaseLineItemRowState();
}

class _PurchaseLineItemRowState extends State<PurchaseLineItemRow> {
  late final _quantity = TextEditingController(
    text: _trim(widget.line.quantity),
  );
  late final _rate = TextEditingController(
    text: formatMoneyAmount(widget.line.rate),
  );

  static String _trim(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);

  @override
  void didUpdateWidget(PurchaseLineItemRow old) {
    super.didUpdateWidget(old);
    // The rate follows the pack when a different one is picked.
    if (old.line.rate != widget.line.rate &&
        double.tryParse(_rate.text.trim()) != widget.line.rate) {
      _rate.text = formatMoneyAmount(widget.line.rate);
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _push({ProductPurchaseUnitModel? unit}) {
    if (unit != null) {
      _rate.text = formatMoneyAmount(unit.purchasePrice);
    }
    widget.onChanged(
      widget.line.copyWith(
        unit: unit,
        quantity: double.tryParse(_quantity.text.trim()) ?? 0,
        rate: double.tryParse(_rate.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final needsUnit = line.unit == null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.smMd),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppBorderRadius.radiusL,
        border: Border.all(
          color: needsUnit ? AppColors.warning : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      line.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (line.product.productCode?.isNotEmpty == true)
                      Text(
                        line.product.productCode!,
                        style: AppTypography.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Rs. ${formatMoneyAmount(line.lineTotal)}',
                style: AppTypography.priceSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                color: AppColors.textMuted,
                tooltip: 'Remove ${line.product.name}',
                onPressed: widget.enabled ? widget.onRemove : null,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _UnitField(
            line: line,
            enabled: widget.enabled,
            onChanged: (unit) => _push(unit: unit),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose the unit shown on the supplier bill before entering quantity and cost.',
              style: AppTypography.caption,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _NumberField(
            controller: _quantity,
            label:
                'Quantity received${line.unit == null ? '' : ' (${line.unit!.unit.symbol})'}',
            enabled: widget.enabled,
            onChanged: (_) => _push(),
            validator: (value) {
              final quantity = double.tryParse(value?.trim() ?? '');
              return quantity == null || !quantity.isFinite || quantity <= 0
                  ? 'Enter a quantity greater than zero'
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _NumberField(
            controller: _rate,
            label: 'Cost per ${line.unit?.unit.name ?? 'purchase unit'} (Rs.)',
            enabled: widget.enabled,
            onChanged: (_) => _push(),
            validator: (value) {
              final rate = double.tryParse(value?.trim() ?? '');
              return rate == null || !rate.isFinite || rate < 0
                  ? 'Enter a valid cost (zero or more)'
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_trim(line.quantity)} ${line.unit?.unit.symbol ?? 'units'} × Rs. ${formatMoneyAmount(line.rate)} = Rs. ${formatMoneyAmount(line.lineTotal)}',
              style: AppTypography.subtitle,
            ),
          ),
          if (needsUnit) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    line.unitOptions.isEmpty
                        ? 'This product has no purchase units set up yet.'
                        : 'Choose the pack this arrived in.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.onChanged,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: onChanged,
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({
    required this.line,
    required this.enabled,
    required this.onChanged,
  });

  final PurchaseLineItemData line;
  final bool enabled;
  final ValueChanged<ProductPurchaseUnitModel?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<ProductPurchaseUnitModel>(
      label: 'Purchase unit / pack',
      value: line.unit,
      enabled: enabled && line.unitOptions.isNotEmpty,
      hint: line.unitOptions.isEmpty ? 'None set up' : 'Choose a pack',
      items: [
        for (final unit in line.unitOptions)
          DropdownMenuItem(
            value: unit,
            child: Text('${unit.unit.name} (${unit.unit.symbol})'),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
