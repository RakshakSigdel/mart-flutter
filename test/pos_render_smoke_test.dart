// Render guard for the POS screens at each breakpoint.
//
// The three POS steps lay out panels with Expanded inside LayoutBuilder, so a
// spacing or type-scale change can silently start overflowing at one width
// while looking fine at another. These pump each step at desktop, tablet and
// phone sizes and fail on any layout exception.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/core/core.dart';
import 'package:sts_retail/data/datasource/datasource_user/inventory_categories_datasource.dart';
import 'package:sts_retail/data/datasource/datasource_user/inventory_products_datasource.dart';
import 'package:sts_retail/providers/providers_user/inventory_categories_provider.dart';
import 'package:sts_retail/providers/providers_user/inventory_products_provider.dart';
import 'package:sts_retail/data/models/models_user/sale_model.dart';
import 'package:sts_retail/presentation/feature_user/sales/models/pos_cart_item.dart';
import 'package:sts_retail/presentation/feature_user/sales/widgets/pos_payment_step.dart';
import 'package:sts_retail/presentation/feature_user/sales/widgets/pos_print_step.dart';
import 'package:sts_retail/presentation/feature_user/sales/widgets/pos_product_selection.dart';

Dio _fakeDio() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final Object data = options.path.contains('categories')
            ? {
                'content': [
                  {'id': 1, 'name': 'Snacks'},
                  {'id': 2, 'name': 'Beverages'},
                  {'id': 3, 'name': 'Household and cleaning'},
                ],
              }
            : {
                'content': [
                  for (var i = 1; i <= 8; i++)
                    {
                      'id': i,
                      'name': 'Product number $i',
                      'active': true,
                      'sellingPrice': 25.0 * i,
                      'sellingUnitSymbol': 'pc',
                      'categoryName': 'Snacks',
                    },
                ],
              };
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'data': data},
          ),
        );
      },
    ),
  );
  return dio;
}

Widget _harness(Size size, List<PosCartItem> cart) {
  final dio = _fakeDio();
  return ProviderScope(
    overrides: [
      inventoryProductsRemoteDataSourceProvider.overrideWithValue(
        InventoryProductsRemoteDataSource(dio),
      ),
      inventoryCategoriesRemoteDataSourceProvider.overrideWithValue(
        InventoryCategoriesRemoteDataSource(dio),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: PosProductSelection(
            cart: cart,
            selectedCartIndex: cart.isEmpty ? null : 0,
            onCartRowSelected: (_) {},
            onCartItemUpdated: (_, _) {},
            onCartItemRemoved: (_) {},
            onAddUnitToCart: (_) {},
            onProceedToPayment: () {},
          ),
        ),
      ),
    ),
  );
}

List<PosCartItem> _cart() => [
  const PosCartItem(
    productId: 1,
    productName: 'Wai Wai Chicken Noodles 75g',
    sellingUnitId: 5,
    sellingUnitLabel: 'pc',
    rate: 25,
    quantity: 3,
  ),
  const PosCartItem(
    productId: 2,
    productName: 'Coca Cola 1.5L',
    sellingUnitId: 6,
    sellingUnitLabel: 'btl',
    rate: 145,
    quantity: 1,
  ),
];

void main() {
  for (final entry in {
    'desktop': const Size(1440, 900),
    'tablet': const Size(820, 700),
    'phone': const Size(420, 780),
  }.entries) {
    testWidgets('POS renders at ${entry.key} with items', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness(entry.value, _cart()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CURRENT SALE'), findsOneWidget);
      expect(find.textContaining('Proceed to Payment'), findsOneWidget);
    });

    testWidgets('POS renders at ${entry.key} with an empty cart', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness(entry.value, const []));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ready to scan'), findsOneWidget);
    });

    testWidgets('payment step renders at ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          entry.value,
          PosPaymentStep(
            cart: _cart(),
            onBack: () {},
            onBillSaved: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('PAYMENT'), findsOneWidget);
      expect(find.text('ORDER SUMMARY'), findsOneWidget);
    });

    testWidgets('receipt step renders at ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(entry.value, PosPrintStep(sale: _sale(), onNewBill: () {})),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bill saved'), findsOneWidget);
      expect(find.text('RECEIPT'), findsOneWidget);
    });
  }
}

Widget _wrap(Size size, Widget child) {
  final dio = _fakeDio();
  return ProviderScope(
    overrides: [
      inventoryProductsRemoteDataSourceProvider.overrideWithValue(
        InventoryProductsRemoteDataSource(dio),
      ),
      inventoryCategoriesRemoteDataSourceProvider.overrideWithValue(
        InventoryCategoriesRemoteDataSource(dio),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SizedBox(width: size.width, height: size.height, child: child),
      ),
    ),
  );
}

SaleDetailModel _sale() => SaleDetailModel.fromJson({
  'id': 1,
  'invoiceNumber': 'INV-0042',
  'subTotal': 220.0,
  'discountAmount': 20.0,
  'vatAmount': 26.0,
  'netTotal': 226.0,
  'paidAmount': 500.0,
  'changeAmount': 274.0,
  'paymentMethod': 'CASH',
  'items': [
    {
      'id': 1,
      'productId': 1,
      'productName': 'Wai Wai Chicken Noodles 75g',
      'unitSymbol': 'pc',
      'quantity': 3,
      'rate': 25.0,
      'lineTotal': 75.0,
    },
    {
      'id': 2,
      'productId': 2,
      'productName': 'Coca Cola 1.5L',
      'unitSymbol': 'btl',
      'quantity': 1,
      'rate': 145.0,
      'lineTotal': 145.0,
    },
  ],
});
