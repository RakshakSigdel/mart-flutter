import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart' show formatUnitValue;
import 'inventory_products_badges.dart';

enum ProductPurchaseUnitRowAction { edit, vatHistory, remove }

/// How this product is bought — its purchase units, each with pack size,
/// price, and current VAT rate, plus the actions to manage them.
class InventoryProductPurchaseUnitSection extends StatelessWidget {
  const InventoryProductPurchaseUnitSection({
    super.key,
    required this.units,
    required this.busyIds,
    required this.onAdd,
    required this.onAction,
  });

  final List<ProductPurchaseUnitModel> units;
  final Set<int> busyIds;
  final VoidCallback onAdd;
  final void Function(ProductPurchaseUnitModel unit, ProductPurchaseUnitRowAction action)
      onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Supplier packs & cost',
                  style: AppTypography.subtitle,
                ),
              ),
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
          const Text(
            'Optional: add this only when you buy cartons, boxes or other packs.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.smMd),
          if (units.isEmpty)
            Text(
              'No supplier packs added yet.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            )
          else
            for (var i = 0; i < units.length; i++) ...[
              if (i > 0) const Divider(height: AppSpacing.lg),
              _PurchaseUnitRow(
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

class _PurchaseUnitRow extends StatelessWidget {
  const _PurchaseUnitRow({required this.unit, required this.isBusy, required this.onSelected});

  final ProductPurchaseUnitModel unit;
  final bool isBusy;
  final ValueChanged<ProductPurchaseUnitRowAction> onSelected;

  @override
  Widget build(BuildContext context) {
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
                'Pack of ${formatUnitValue(unit.packQuantity)} · '
                '${formatMoney(unit.purchasePrice)} · '
                'VAT ${unit.currentVatRate == null ? '—' : '${formatMoney(unit.currentVatRate)}%'}',
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
          PopupMenuButton<ProductPurchaseUnitRowAction>(
            onSelected: onSelected,
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Actions',
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ProductPurchaseUnitRowAction.edit,
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: ProductPurchaseUnitRowAction.vatHistory,
                child: Text('VAT history'),
              ),
              PopupMenuItem(
                value: ProductPurchaseUnitRowAction.remove,
                child: Text('Remove', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
      ],
    );
  }
}
