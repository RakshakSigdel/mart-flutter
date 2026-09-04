import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/purchase_model.dart';

/// Tablet/desktop layout — one row per purchase in a scrollable table.
///
/// No row-action menu — a purchase is immutable once recorded (the backend
/// exposes no edit/remove for this resource), so the only thing a row can
/// do is open its detail. Tapping the row does that directly.
class PurchasesTable extends StatelessWidget {
  const PurchasesTable({
    super.key,
    required this.purchases,
    required this.onTap,
  });

  final List<PurchaseModel> purchases;
  final ValueChanged<PurchaseModel> onTap;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.eyebrow.copyWith(letterSpacing: 0.4);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: math.max(900, constraints.maxWidth),
          ),
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
            headingTextStyle: headerStyle,
            columnSpacing: AppSpacing.lg,
            columns: const [
              DataColumn(label: Text('BILL NUMBER')),
              DataColumn(label: Text('VENDOR')),
              DataColumn(label: Text('DATE')),
              DataColumn(label: Text('PAYMENT')),
              DataColumn(label: Text('ITEMS')),
              DataColumn(label: Text('NET TOTAL'), numeric: true),
            ],
            rows: [
              for (final purchase in purchases)
                DataRow(
                  cells: [
                    DataCell(
                      Text(purchase.billNumber, style: AppTypography.subtitle),
                      onTap: () => onTap(purchase),
                    ),
                    DataCell(Text(purchase.vendorName ?? '—')),
                    DataCell(Text(_formatDate(purchase.purchaseDate))),
                    DataCell(Text(formatPaymentMethod(purchase.paymentMethod))),
                    DataCell(Text('${purchase.itemCount}')),
                    DataCell(Text(formatMoneyAmount(purchase.netTotal))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
