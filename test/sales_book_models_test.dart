import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/data/models/models_shared/report_date_range.dart';
import 'package:sts_retail/data/models/models_user/sales_book_model.dart';

void main() {
  test('sales-book query includes report period and optional date fields', () {
    const base = SalesBookQuery(dateRange: ReportDateRange.thisYear);
    expect(base.toQueryParameters(), {'dateRange': 'THIS_YEAR'});

    final dated = base.copyWith(
      date: DateTime(2026, 9, 12),
      month: '09',
      year: '2026',
    );
    expect(dated.toQueryParameters(), {
      'dateRange': 'THIS_YEAR',
      'date': '2026-09-12',
      'month': '09',
      'year': '2026',
    });
  });

  test('sales-book parser preserves rows and column totals', () {
    final book = SalesBookModel.fromJson({
      'firmName': 'Rakshak Mart',
      'pan': '123456789',
      'month': 'Bhadra',
      'year': '2083',
      'duration': '1 Sep – 30 Sep',
      'rows': [
        {
          'date': '2026-09-12',
          'billNumber': 'INV-1',
          'buyerName': 'Asha',
          'buyerPan': 'PAN-1',
          'totalSales': 113,
          'nonTaxableSales': 0,
          'exportSales': 0,
          'discount': 3,
          'taxableAmount': 100,
          'tax': 13,
        },
      ],
      'total': {
        'totalSales': 113,
        'nonTaxableSales': 0,
        'exportSales': 0,
        'discount': 3,
        'taxableAmount': 100,
        'tax': 13,
      },
    });

    expect(book.rows.single.billNumber, 'INV-1');
    expect(book.rows.single.taxableAmount, 100);
    expect(book.total.tax, 13);
  });
}
