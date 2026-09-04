import 'dart:math' as math;

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

/// Tablet/desktop layout — one row per bill in a scrollable table.
///
/// No row-action menu — a bill is immutable once rung up apart from
/// taking a payment against it, which lives on the detail screen. Tapping
/// the row opens that directly.
class SalesTable extends StatelessWidget {
  const SalesTable({super.key, required this.sales, required this.onTap});

  final List<SaleModel> sales;
  final ValueChanged<SaleModel> onTap;

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
              DataColumn(label: Text('INVOICE')),
              DataColumn(label: Text('CUSTOMER')),
              DataColumn(label: Text('DATE')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('NET TOTAL'), numeric: true),
              DataColumn(label: Text('DUE'), numeric: true),
            ],
            rows: [
              for (final sale in sales)
                DataRow(
                  cells: [
                    DataCell(
                      Text(sale.invoiceNumber, style: AppTypography.subtitle),
                      onTap: () => onTap(sale),
                    ),
                    DataCell(Text(sale.customerName ?? '—')),
                    DataCell(Text(_formatDate(sale.soldAt))),
                    DataCell(PaymentStatusBadge(status: sale.paymentStatus)),
                    DataCell(Text(formatMoneyAmount(sale.netTotal))),
                    DataCell(Text(formatMoneyAmount(sale.dueAmount))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
