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

class ReturnSummary {
  const ReturnSummary({
    required this.subject,
    required this.count,
    required this.amount,
    required this.vatAmount,
    required this.netAfterReturns,
    required this.vatAmountAfterReturns,
  });

  final String subject;
  final int count;
  final double amount;
  final double vatAmount;
  final double netAfterReturns;
  final double vatAmountAfterReturns;

  factory ReturnSummary.fromSalesJson(Map<String, dynamic> json) =>
      ReturnSummary._parse(json, 'Sales', 'salesReturn', 'netSales');

  factory ReturnSummary.fromPurchasesJson(Map<String, dynamic> json) =>
      ReturnSummary._parse(json, 'Purchases', 'purchaseReturn', 'netPurchases');

  factory ReturnSummary._parse(
    Map<String, dynamic> json,
    String subject,
    String returnPrefix,
    String netKey,
  ) => ReturnSummary(
    subject: subject,
    count: (json['${returnPrefix}Count'] as num?)?.toInt() ?? 0,
    amount: (json['${returnPrefix}Amount'] as num?)?.toDouble() ?? 0,
    vatAmount: (json['${returnPrefix}VatAmount'] as num?)?.toDouble() ?? 0,
    netAfterReturns:
        (json['${netKey}AfterReturns'] as num?)?.toDouble() ??
        (json[netKey] as num?)?.toDouble() ??
        0,
    vatAmountAfterReturns:
        (json['vatAmountAfterReturns'] as num?)?.toDouble() ??
        (json['vatAmount'] as num?)?.toDouble() ??
        0,
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
    this.returns,
  });
  final double netTotal;
  final double vatAmount;
  final int count;
  final List<PaymentTypeTotal> paymentTypeTotals;
  final ReturnSummary? returns;

  factory SummaryReportModel.fromSalesJson(Map<String, dynamic> json) =>
      SummaryReportModel._parse(
        json,
        'netSales',
        'totalSalesCount',
        returns: ReturnSummary.fromSalesJson(json),
      );
  factory SummaryReportModel.fromPurchasesJson(Map<String, dynamic> json) =>
      SummaryReportModel._parse(
        json,
        'netPurchases',
        'totalPurchasesCount',
        returns: ReturnSummary.fromPurchasesJson(json),
      );

  factory SummaryReportModel._parse(
    Map<String, dynamic> json,
    String totalKey,
    String countKey, {
    ReturnSummary? returns,
  }) => SummaryReportModel(
    netTotal: (json[totalKey] as num?)?.toDouble() ?? 0,
    vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0,
    count: (json[countKey] as num?)?.toInt() ?? 0,
    paymentTypeTotals: (json['paymentTypeTotals'] as List<dynamic>? ?? [])
        .map((e) => PaymentTypeTotal.fromJson(e as Map<String, dynamic>))
        .toList(),
    returns: returns,
  );
}
