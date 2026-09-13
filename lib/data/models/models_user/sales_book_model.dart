import '../models_shared/report_date_range.dart';

class SalesBookQuery {
  const SalesBookQuery({
    this.dateRange = ReportDateRange.thisMonth,
    this.date,
    this.month,
    this.year,
  });

  final ReportDateRange dateRange;
  final DateTime? date;
  final String? month;
  final String? year;

  Map<String, dynamic> toQueryParameters() => {
    'dateRange': dateRange.apiValue,
    if (date != null)
      'date':
          '${date!.year.toString().padLeft(4, '0')}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
    if (month != null && month!.isNotEmpty) 'month': month,
    if (year != null && year!.isNotEmpty) 'year': year,
  };

  SalesBookQuery copyWith({
    ReportDateRange? dateRange,
    Object? date = _unset,
    Object? month = _unset,
    Object? year = _unset,
  }) => SalesBookQuery(
    dateRange: dateRange ?? this.dateRange,
    date: identical(date, _unset) ? this.date : date as DateTime?,
    month: identical(month, _unset) ? this.month : month as String?,
    year: identical(year, _unset) ? this.year : year as String?,
  );
}

const _unset = Object();

class SalesBookAmounts {
  const SalesBookAmounts({
    required this.totalSales,
    required this.nonTaxableSales,
    required this.exportSales,
    required this.discount,
    required this.taxableAmount,
    required this.tax,
  });

  final double totalSales;
  final double nonTaxableSales;
  final double exportSales;
  final double discount;
  final double taxableAmount;
  final double tax;

  factory SalesBookAmounts.fromJson(Map<String, dynamic> json) =>
      SalesBookAmounts(
        totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
        nonTaxableSales: (json['nonTaxableSales'] as num?)?.toDouble() ?? 0,
        exportSales: (json['exportSales'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        taxableAmount: (json['taxableAmount'] as num?)?.toDouble() ?? 0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0,
      );
}

class SalesBookRow extends SalesBookAmounts {
  const SalesBookRow({
    required this.date,
    required this.billNumber,
    required this.buyerName,
    required this.buyerPan,
    required super.totalSales,
    required super.nonTaxableSales,
    required super.exportSales,
    required super.discount,
    required super.taxableAmount,
    required super.tax,
  });

  final String date;
  final String billNumber;
  final String buyerName;
  final String buyerPan;

  factory SalesBookRow.fromJson(Map<String, dynamic> json) => SalesBookRow(
    date: json['date'] as String? ?? '',
    billNumber: json['billNumber'] as String? ?? '',
    buyerName: json['buyerName'] as String? ?? '',
    buyerPan: json['buyerPan'] as String? ?? '',
    totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
    nonTaxableSales: (json['nonTaxableSales'] as num?)?.toDouble() ?? 0,
    exportSales: (json['exportSales'] as num?)?.toDouble() ?? 0,
    discount: (json['discount'] as num?)?.toDouble() ?? 0,
    taxableAmount: (json['taxableAmount'] as num?)?.toDouble() ?? 0,
    tax: (json['tax'] as num?)?.toDouble() ?? 0,
  );
}

class SalesBookModel {
  const SalesBookModel({
    required this.firmName,
    required this.pan,
    required this.month,
    required this.year,
    required this.rows,
    required this.total,
    required this.duration,
  });

  final String firmName;
  final String pan;
  final String month;
  final String year;
  final List<SalesBookRow> rows;
  final SalesBookAmounts total;
  final String duration;

  factory SalesBookModel.fromJson(Map<String, dynamic> json) => SalesBookModel(
    firmName: json['firmName'] as String? ?? '',
    pan: json['pan'] as String? ?? '',
    month: json['month'] as String? ?? '',
    year: json['year'] as String? ?? '',
    rows: (json['rows'] as List<dynamic>? ?? [])
        .map((item) => SalesBookRow.fromJson(item as Map<String, dynamic>))
        .toList(),
    total: SalesBookAmounts.fromJson(
      json['total'] as Map<String, dynamic>? ?? const {},
    ),
    duration: json['duration'] as String? ?? '',
  );
}
