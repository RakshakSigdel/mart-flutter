import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart' show formatConversionFactor;
import 'inventory_products_badges.dart';

enum ProductSellingUnitRowAction { edit, remove }

/// How this product is sold — its selling units, each with pack size,
/// price, MRP, SKU and barcode, plus the actions to manage them.
class InventoryProductSellingUnitSection extends StatelessWidget {
  const InventoryProductSellingUnitSection({
    super.key,
    required this.units,
    required this.busyIds,
    required this.onAdd,
    required this.onAction,
  });

  final List<ProductSellingUnitModel> units;
  final Set<int> busyIds;
  final VoidCallback onAdd;
  final void Function(ProductSellingUnitModel unit, ProductSellingUnitRowAction action)
      onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Selling units', style: AppTypography.subtitle)),
              AppButton(
                label: 'Add',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                leading: const Icon(Icons.add, size: 16),
                onPressed: onAdd,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          if (units.isEmpty)
            Text(
              'No selling units configured yet.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            )
          else
            for (var i = 0; i < units.length; i++) ...[
              if (i > 0) const Divider(height: AppSpacing.lg),
              _SellingUnitRow(
                unit: units[i],
                isBusy: busyIds.contains(units[i].id),
                onSelected: (action) => onAction(units[i], action),
              ),
            ],
        ],
      ),
    );
  }
}

class _SellingUnitRow extends StatelessWidget {
  const _SellingUnitRow({required this.unit, required this.isBusy, required this.onSelected});

  final ProductSellingUnitModel unit;
  final bool isBusy;
  final ValueChanged<ProductSellingUnitRowAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      'Pack of ${formatConversionFactor(unit.packQuantity)}',
      formatMoney(unit.sellingPrice),
      if (unit.mrp != null) 'MRP ${formatMoney(unit.mrp)}',
      if (unit.sku != null && unit.sku!.isNotEmpty) 'SKU ${unit.sku}',
      if (unit.barcode != null && unit.barcode!.isNotEmpty) unit.barcode!,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${unit.unit.name} (${unit.unit.symbol})', style: AppTypography.subtitle),
                  const SizedBox(width: AppSpacing.sm),
                  if (unit.isDefault) const DefaultUnitBadge(),
                  if (!unit.active) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const ActiveStatusBadge(active: false),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                details.join(' · '),
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (isBusy)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          PopupMenuButton<ProductSellingUnitRowAction>(
            onSelected: onSelected,
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Actions',
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ProductSellingUnitRowAction.edit,
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: ProductSellingUnitRowAction.remove,
                child: Text('Remove', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
      ],
    );
  }
}
