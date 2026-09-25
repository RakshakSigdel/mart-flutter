// Render guard for the product screens and forms at each breakpoint.
//
// The products panel, the add form and the edit form all stack headers,
// field sections and footers inside one card, so a spacing or type-scale
// change can start overflowing at one width while looking fine at another.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/core/core.dart';
import 'package:sts_retail/data/datasource/datasource_user/inventory_categories_datasource.dart';
import 'package:sts_retail/data/datasource/datasource_user/inventory_products_datasource.dart';
import 'package:sts_retail/data/datasource/datasource_user/inventory_units_datasource.dart';
import 'package:sts_retail/data/models/models_user/inventory_products_model.dart';
import 'package:sts_retail/presentation/feature_user/inventory_products/screens/inventory_products_screen.dart';
import 'package:sts_retail/presentation/feature_user/inventory_products/widgets/inventory_products_list_card.dart';
import 'package:sts_retail/presentation/feature_user/inventory_products/widgets/inventory_products_table.dart';
import 'package:sts_retail/presentation/feature_user/inventory_products/widgets/quick_product_form.dart';
import 'package:sts_retail/providers/providers_user/inventory_categories_provider.dart';
import 'package:sts_retail/providers/providers_user/inventory_products_provider.dart';
import 'package:sts_retail/providers/providers_user/inventory_units_provider.dart';

ProductModel _product({
  String name = 'Wai Wai Chicken Noodles 75g',
  double? sellingPrice = 25,
  bool active = true,
}) => ProductModel.fromJson({
  'id': 1,
  'name': name,
  'productCode': 'WW-075',
  'brand': 'Chaudhary Group',
  'active': active,
  'categoryName': 'Snacks',
  'sellingPrice': sellingPrice,
  'sellingUnitSymbol': sellingPrice == null ? null : 'pc',
});

Dio _fakeDio() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;
        if (path.contains('/by-barcode/')) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 404,
                data: {'message': 'Barcode not found.'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        }
        // The /selection endpoints return a bare list; the list endpoints
        // return a page envelope.
        final Object data = path.contains('categories')
            ? [
                {'id': 1, 'name': 'Snacks'},
                {'id': 2, 'name': 'Beverages'},
              ]
            : path.contains('units')
            ? [
                {
                  'id': 1,
                  'name': 'Piece',
                  'symbol': 'pc',
                  'measurementType': 'COUNT',
                  'referenceUnit': true,
                  'conversionFactor': 1,
                },
                {
                  'id': 2,
                  'name': 'Carton',
                  'symbol': 'ctn',
                  'measurementType': 'COUNT',
                  'referenceUnit': false,
                },
              ]
            : {
                'content': [
                  {
                    'id': 1,
                    'name': 'Wai Wai Chicken Noodles 75g',
                    'productCode': 'WW-075',
                    'brand': 'Chaudhary Group',
                    'active': true,
                    'categoryName': 'Snacks',
                    'sellingPrice': 25.0,
                    'sellingUnitSymbol': 'pc',
                  },
                  {'id': 2, 'name': 'Unpriced item', 'active': false},
                ],
                'pageNumber': 1,
                'totalPages': 2,
                'totalElements': 14,
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

Widget _harness(Size size, Widget child) {
  final dio = _fakeDio();
  return ProviderScope(
    overrides: [
      inventoryProductsRemoteDataSourceProvider.overrideWithValue(
        InventoryProductsRemoteDataSource(dio),
      ),
      inventoryCategoriesRemoteDataSourceProvider.overrideWithValue(
        InventoryCategoriesRemoteDataSource(dio),
      ),
      inventoryUnitsRemoteDataSourceProvider.overrideWithValue(
        InventoryUnitsRemoteDataSource(dio),
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

/// AppTextField renders its label as a sibling above the input, so a field is
/// located through the closest Column that also holds its label.
Finder _fieldFor(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(TextFormField),
);

void main() {
  testWidgets(
    'Enter on an unknown barcode closes the dialog without disposing its focused field early',
    (tester) async {
      tester.view.physicalSize = const Size(820, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _harness(const Size(820, 900), const InventoryProductsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Find barcode'));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldFor('Barcode'), 'G80200900847');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Find barcode'), findsOneWidget);
      expect(find.text('Barcode not found.'), findsOneWidget);

      await tester.tap(find.text('Find barcode'));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldFor('Barcode'), 'G80200900847');
      await tester.tap(find.text('Find'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Barcode not found.'), findsOneWidget);
    },
  );

  for (final entry in {
    'desktop': const Size(1440, 900),
    'tablet': const Size(820, 700),
    'phone': const Size(420, 780),
  }.entries) {
    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_harness(entry.value, child));
      await tester.pumpAndSettle();
    }

    testWidgets('products list screen renders at ${entry.key}', (tester) async {
      await pump(tester, const InventoryProductsScreen());

      expect(tester.takeException(), isNull);
      expect(find.text('PRODUCTS'), findsOneWidget);
    });

    testWidgets('add product form renders at ${entry.key}', (tester) async {
      await pump(
        tester,
        const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: QuickProductForm(),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('NEW PRODUCT'), findsOneWidget);
      expect(find.text('Save product'), findsOneWidget);
      // Nothing typed yet, so the margin strip prompts rather than computes.
      expect(find.textContaining('Enter both prices'), findsOneWidget);
    });

    testWidgets('product card renders at ${entry.key}', (tester) async {
      await pump(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: InventoryProductListCard(
            product: _product(),
            isBusy: false,
            onAction: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Sells at'), findsOneWidget);
    });
  }

  testWidgets('products table renders and opens a row', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    ProductModel? opened;
    await tester.pumpWidget(
      _harness(
        const Size(1440, 900),
        SingleChildScrollView(
          child: InventoryProductsTable(
            products: [
              _product(),
              _product(name: 'Unpriced', sellingPrice: null),
            ],
            busyIds: const {},
            onAction: (product, _) => opened = product,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Not priced'), findsOneWidget);

    await tester.tap(find.text('Wai Wai Chicken Noodles 75g'));
    await tester.pumpAndSettle();
    expect(opened?.name, 'Wai Wai Chicken Noodles 75g');
  });

  testWidgets('margin read-out reacts to the prices typed', (tester) async {
    tester.view.physicalSize = const Size(820, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _harness(
        const Size(820, 900),
        const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: QuickProductForm(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_fieldFor('Buy at'), '80');
    await tester.enterText(_fieldFor('Sell at'), '100');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('You make'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);

    // Selling under cost must be called out, not quietly accepted.
    await tester.enterText(_fieldFor('Sell at'), '50');
    await tester.pumpAndSettle();
    expect(find.textContaining('Selling below cost'), findsOneWidget);
  });
}
