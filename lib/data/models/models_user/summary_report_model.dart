export '../models_shared/report_date_range.dart';

class PaymentTypeTotal {
  const PaymentTypeTotal({required this.paymentMethod, required this.netTotal});
  final String paymentMethod;
  final double netTotal;

  factory PaymentTypeTotal.fromJson(Map<String, dynamic> json) =>
      PaymentTypeTotal(
        paymentMethod: json['paymentMethod'] as String? ?? 'UNKNOWN',
        netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
      );
}

/// Sales and purchases expose the same summary with different total/count keys.
/// Normalize those names at the data boundary for shared presentation.
class SummaryReportModel {
  const SummaryReportModel({
    required this.netTotal,
    required this.vatAmount,
    required this.count,
    required this.paymentTypeTotals,
  });
  final double netTotal;
  final double vatAmount;
  final int count;
  final List<PaymentTypeTotal> paymentTypeTotals;

  factory SummaryReportModel.fromSalesJson(Map<String, dynamic> json) =>
      SummaryReportModel._parse(json, 'netSales', 'totalSalesCount');
  factory SummaryReportModel.fromPurchasesJson(Map<String, dynamic> json) =>
      SummaryReportModel._parse(json, 'netPurchases', 'totalPurchasesCount');

  factory SummaryReportModel._parse(
    Map<String, dynamic> json,
    String totalKey,
    String countKey,
  ) => SummaryReportModel(
    netTotal: (json[totalKey] as num?)?.toDouble() ?? 0,
    vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0,
    count: (json[countKey] as num?)?.toInt() ?? 0,
    paymentTypeTotals: (json['paymentTypeTotals'] as List<dynamic>? ?? [])
        .map((e) => PaymentTypeTotal.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
