import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/sale_model.dart';
import 'sale_badges.dart';

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

/// Phone layout — one card per bill, stacked in a list. No row-action
/// menu, same reasoning as `SalesTable` — tapping the card opens the
/// detail directly.
class SaleListCard extends StatelessWidget {
  const SaleListCard({super.key, required this.sale, required this.onTap});

  final SaleModel sale;
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
                    Text(sale.invoiceNumber, style: AppTypography.subtitle),
                    Text(
                      sale.customerName ?? '—',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Text(
                formatMoneyAmount(sale.netTotal),
                style: AppTypography.subtitle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              PaymentStatusBadge(status: sale.paymentStatus),
              if (sale.dueAmount > 0)
                AppBadge(
                  label: 'Due ${formatMoneyAmount(sale.dueAmount)}',
                  tone: AppBadgeTone.warning,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.smMd),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.iconInactive,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(_formatDate(sale.soldAt), style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
