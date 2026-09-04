import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/purchase_model.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// Phone layout — one card per purchase, stacked in a list. No row-action
/// menu, same reasoning as `PurchasesTable` — tapping the card opens the
/// (read-only) detail directly.
class PurchaseListCard extends StatelessWidget {
  const PurchaseListCard({
    super.key,
    required this.purchase,
    required this.onTap,
  });

  final PurchaseModel purchase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(purchase.billNumber, style: AppTypography.subtitle),
                    Text(
                      purchase.vendorName ?? '—',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Text(
                formatMoneyAmount(purchase.netTotal),
                style: AppTypography.subtitle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppBadge(
                label: formatPaymentMethod(purchase.paymentMethod),
                tone: AppBadgeTone.neutral,
              ),
              AppBadge(
                label:
                    '${purchase.itemCount} item${purchase.itemCount == 1 ? '' : 's'}',
                tone: AppBadgeTone.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.smMd),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: _formatDate(purchase.purchaseDate),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.iconInactive),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
