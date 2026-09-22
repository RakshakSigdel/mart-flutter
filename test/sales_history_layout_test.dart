import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/core/core.dart';
import 'package:sts_retail/data/models/models_user/sale_model.dart';
import 'package:sts_retail/presentation/feature_user/sales/controllers/sales_controller.dart';
import 'package:sts_retail/presentation/feature_user/sales/screens/sales_screen.dart';
import 'package:sts_retail/presentation/feature_user/sales/widgets/sales_table.dart';

final _sale = SaleModel.fromJson({
  'id': 1,
  'invoiceNumber': 'INV-001',
  'customerName': 'Test customer',
  'netTotal': 1200,
  'dueAmount': 200,
  'paymentStatus': 'PARTIAL',
});

class _SalesFixture extends SalesController {
  @override
  SalesState build() => SalesState.initial().copyWith(
    isLoading: false,
    isTotalsLoading: false,
    sales: [_sale],
    totalElements: 1,
    totalPages: 1,
    totals: SalesTotalsModel.fromJson({
      'billCount': 1,
      'netSales': 1200,
      'outstanding': 200,
    }),
  );
}

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(760, 700),
    const Size(1280, 800),
  ]) {
    testWidgets('Sales History scrolls without overflow at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [salesControllerProvider.overrideWith(_SalesFixture.new)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: SalesScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('INV-001').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('customer cell opens a bill as well as the invoice cell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SaleModel? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SalesTable(sales: [_sale], onTap: (sale) => opened = sale),
        ),
      ),
    );
    await tester.tap(find.text('Test customer'));
    expect(opened, same(_sale));
  });
}
