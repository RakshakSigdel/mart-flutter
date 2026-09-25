import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/data/models/models_user/summary_report_model.dart';
import 'package:sts_retail/data/models/models_user/stock_model.dart';
import 'package:sts_retail/presentation/feature_user/dashboard/widgets/dashboard_report_card.dart';
import 'package:sts_retail/presentation/feature_user/dashboard/widgets/dashboard_section.dart';
import 'package:sts_retail/presentation/feature_user/dashboard/widgets/dashboard_stock_card.dart';

void main() {
  test('sales and purchases parse their distinct API total/count fields', () {
    final sales = SummaryReportModel.fromSalesJson({
      'netSales': 450,
      'vatAmount': 58.5,
      'totalSalesCount': 3,
      'paymentTypeTotals': [
        {'paymentMethod': 'CREDIT', 'netTotal': 450},
      ],
    });
    final purchases = SummaryReportModel.fromPurchasesJson({
      'netPurchases': 230.5,
      'vatAmount': 30,
      'totalPurchasesCount': 2,
      'paymentTypeTotals': [],
    });
    expect(sales.netTotal, 450);
    expect(sales.count, 3);
    expect(sales.paymentTypeTotals.single.paymentMethod, 'CREDIT');
    expect(purchases.netTotal, 230.5);
    expect(purchases.count, 2);
    expect(purchases.vatAmount, 30);
    expect(purchases.returns?.netAfterReturns, 230.5);
  });

  test('purchase report parses return-adjusted totals independently', () {
    final purchases = SummaryReportModel.fromPurchasesJson({
      'netPurchases': 1000,
      'vatAmount': 130,
      'totalPurchasesCount': 4,
      'purchaseReturnCount': 2,
      'purchaseReturnAmount': 250,
      'purchaseReturnVatAmount': 32.5,
      'netPurchasesAfterReturns': 750,
      'vatAmountAfterReturns': 97.5,
    });
    expect(purchases.netTotal, 1000);
    expect(purchases.returns?.count, 2);
    expect(purchases.returns?.amount, 250);
    expect(purchases.returns?.vatAmount, 32.5);
    expect(purchases.returns?.netAfterReturns, 750);
    expect(purchases.returns?.vatAmountAfterReturns, 97.5);
  });

  test('sales report parses credit note totals independently', () {
    final sales = SummaryReportModel.fromSalesJson({
      'netSales': 1200,
      'vatAmount': 156,
      'totalSalesCount': 5,
      'salesReturnCount': 1,
      'salesReturnAmount': 200,
      'salesReturnVatAmount': 26,
      'netSalesAfterReturns': 1000,
      'vatAmountAfterReturns': 130,
    });
    expect(sales.netTotal, 1200);
    expect(sales.returns?.subject, 'Sales');
    expect(sales.returns?.count, 1);
    expect(sales.returns?.amount, 200);
    expect(sales.returns?.vatAmount, 26);
    expect(sales.returns?.netAfterReturns, 1000);
    expect(sales.returns?.vatAmountAfterReturns, 130);
  });

  for (final width in [320.0, 600.0, 1200.0]) {
    testWidgets('report and stock cards fit width $width with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1600),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    DashboardReportCard(
                      title: 'Sales',
                      period: 'This month',
                      report: SummaryReportModel.fromSalesJson({
                        'netSales': 1000000.25,
                        'vatAmount': 130000,
                        'totalSalesCount': 3,
                        'salesReturnCount': 1,
                        'salesReturnAmount': 100,
                        'salesReturnVatAmount': 13,
                        'netSalesAfterReturns': 999900.25,
                        'vatAmountAfterReturns': 129987,
                        'paymentTypeTotals': [
                          {
                            'paymentMethod': 'BANK_TRANSFER',
                            'netTotal': 1000000.25,
                          },
                        ],
                      }),
                      icon: Icons.receipt_long,
                      color: Colors.amber,
                    ),
                    DashboardReportCard(
                      title: 'Purchases',
                      period: 'This month',
                      report: SummaryReportModel.fromPurchasesJson({
                        'netPurchases': 1000,
                        'vatAmount': 130,
                        'totalPurchasesCount': 4,
                        'purchaseReturnCount': 2,
                        'purchaseReturnAmount': 250,
                        'purchaseReturnVatAmount': 32.5,
                        'netPurchasesAfterReturns': 750,
                        'vatAmountAfterReturns': 97.5,
                      }),
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.blue,
                    ),
                    const DashboardStockCard(
                      overview: StockOverviewModel(
                        trackedProducts: 40,
                        needingAttention: 7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Needing attention'), findsOneWidget);
      if (width == 320) {
        await tester.ensureVisible(find.text('Sales returns'));
        await tester.tap(find.text('Sales returns'));
        await tester.pumpAndSettle();
        expect(find.text('Sales before returns'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('failed section offers retry without showing a zero report', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSection<int>(
            title: 'Sales',
            value: AsyncError(Exception('offline'), StackTrace.empty),
            onRetry: () => retried = true,
            builder: (value) => Text('Total: $value'),
          ),
        ),
      ),
    );
    expect(find.text('Total: 0'), findsNothing);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });
}
