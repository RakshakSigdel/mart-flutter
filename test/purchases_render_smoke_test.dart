// Render guard for the purchase ledger and the receive-stock form.
//
// The ledger hangs entries off a timeline rail using IntrinsicHeight, and the
// form stacks three panels of reflowing fields, so both are easy to break at
// one width while they still look right at another.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/core/core.dart';
import 'package:sts_retail/data/datasource/datasource_user/inventory_products_datasource.dart';
import 'package:sts_retail/data/datasource/datasource_user/vendor_datasource.dart';
import 'package:sts_retail/data/models/models_user/inventory_products_model.dart';
import 'package:sts_retail/data/models/models_user/purchase_model.dart';
import 'package:sts_retail/presentation/feature_user/purchases/widgets/purchase_form.dart';
import 'package:sts_retail/presentation/feature_user/purchases/screens/purchase_form_screen.dart';
import 'package:sts_retail/presentation/feature_user/purchases/widgets/purchase_ledger.dart';
import 'package:sts_retail/presentation/feature_user/purchases/widgets/purchase_line_item_row.dart';
import 'package:sts_retail/providers/providers_user/inventory_products_provider.dart';
import 'package:sts_retail/providers/providers_user/vendor_provider.dart';

PurchaseModel _purchase({
  int id = 1,
  String vendor = 'Himalayan Distributors',
  String bill = 'INV-2026-0142',
  double net = 12500,
  double discount = 0,
  int daysAgo = 0,
}) => PurchaseModel.fromJson({
  'id': id,
  'billNumber': bill,
  'purchaseDate': DateTime.now()
      .subtract(Duration(days: daysAgo))
      .toIso8601String(),
  'vendorId': 1,
  'vendorName': vendor,
  'paymentMethod': 'CASH',
  'subTotal': net,
  'discountAmount': discount,
  'vatAmount': net * 0.13,
  'netTotal': net,
  'itemCount': 7,
});

Dio _fakeDio() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;
        final Object data = path.contains('vendors')
            ? [
                {'id': 1, 'name': 'Himalayan Distributors'},
                {'id': 2, 'name': 'Everest Foods'},
              ]
            : path.contains('purchase-units')
            ? [
                {
                  'id': 9,
                  'unit': {'id': 2, 'name': 'Carton', 'symbol': 'ctn'},
                  'packQuantity': 24,
                  'purchasePrice': 480.0,
                  'isDefault': true,
                },
              ]
            : {
                'content': [
                  {
                    'id': 1,
                    'name': 'Wai Wai Chicken Noodles 75g',
                    'productCode': 'WW-075',
                    'active': true,
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

Widget _harness(Size size, Widget child) {
  final dio = _fakeDio();
  return ProviderScope(
    overrides: [
      vendorRemoteDataSourceProvider.overrideWithValue(
        VendorRemoteDataSource(dio),
      ),
      inventoryProductsRemoteDataSourceProvider.overrideWithValue(
        InventoryProductsRemoteDataSource(dio),
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

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(1024, 768),
    const Size(420, 780),
  ]) {
    testWidgets('receive stock screen maps panels at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_harness(size, const PurchaseFormScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final bill = tester.getTopLeft(find.text('THE BILL'));
      final items = tester.getTopLeft(find.text('WHAT ARRIVED'));
      final review = tester.getTopLeft(find.text('REVIEW & SAVE'));
      if (size.width >= 1200) {
        expect(bill.dx, lessThan(items.dx));
        expect(items.dx, lessThan(review.dx));
        expect(bill.dy, items.dy);
        expect(items.dy, review.dy);
        expect(find.text('Save received stock').hitTestable(), findsOneWidget);
      } else if (size.width >= 800) {
        expect(items.dx, lessThan(bill.dx));
        expect(bill.dx, review.dx);
        expect(bill.dy, lessThan(review.dy));
      } else {
        expect(bill.dy, lessThan(items.dy));
        expect(items.dy, lessThan(review.dy));
        await tester.ensureVisible(find.text('Save received stock'));
        await tester.pumpAndSettle();
        expect(find.text('Save received stock').hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
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

    testWidgets('purchase ledger renders at ${entry.key}', (tester) async {
      await pump(
        tester,
        PurchaseLedger(
          purchases: [
            _purchase(),
            _purchase(id: 2, vendor: 'Everest Foods', net: 3400),
            _purchase(id: 3, bill: 'INV-9', net: 800, daysAgo: 1),
            _purchase(id: 4, bill: 'INV-7', net: 2200, daysAgo: 9),
          ],
          onOpen: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      // Same-day bills collapse under one dated heading carrying its spend.
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text(' · 2 bills'), findsOneWidget);
    });

    testWidgets('receive stock form renders at ${entry.key}', (tester) async {
      await pump(
        tester,
        const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: PurchaseForm(),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('THE BILL'), findsOneWidget);
      expect(find.text('WHAT ARRIVED'), findsOneWidget);
      expect(find.text('Nothing added yet'), findsOneWidget);
      expect(find.text('Save received stock'), findsOneWidget);
    });
  }

  testWidgets('ledger totals each day separately', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    PurchaseModel? opened;
    await tester.pumpWidget(
      _harness(
        const Size(1440, 900),
        PurchaseLedger(
          purchases: [
            _purchase(net: 1000),
            _purchase(id: 2, vendor: 'Everest Foods', net: 500),
            _purchase(id: 3, vendor: 'Old Supplier', net: 250, daysAgo: 3),
            _purchase(id: 4, vendor: 'Old Supplier', net: 150, daysAgo: 3),
          ],
          onOpen: (purchase) => opened = purchase,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Each heading totals only its own day. Both sums are chosen so they
    // cannot collide with any single bill's amount.
    expect(find.text('Rs. 1500.00'), findsOneWidget); // today
    expect(find.text('Rs. 400.00'), findsOneWidget); // three days ago

    await tester.tap(find.text('Himalayan Distributors').first);
    await tester.pumpAndSettle();
    expect(opened?.id, 1);
  });

  testWidgets('a received line starts filled in and re-totals as edited', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var line = PurchaseLineItemData(
      product: ProductModel.fromJson({
        'id': 1,
        'name': 'Wai Wai Chicken Noodles 75g',
        'productCode': 'WW-075',
        'active': true,
      }),
      unitOptions: [_carton],
      unit: _carton,
      rate: 480,
    );

    await tester.pumpWidget(
      _harness(
        const Size(900, 700),
        StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: PurchaseLineItemRow(
              line: line,
              enabled: true,
              onChanged: (updated) => setState(() => line = updated),
              onRemove: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Default pack and its usual cost arrive pre-filled: 1 x 480.
    expect(find.text('Rs. 480.00'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Quantity received (ctn)'),
              matching: find.byType(Column),
            )
            .first,
        matching: find.byType(TextFormField),
      ),
      '3',
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rs. 1440.00'), findsOneWidget);
    expect(line.quantity, 3);
  });

  testWidgets(
    'purchase unit comes before numbers and changing it updates cost',
    (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final piece = ProductPurchaseUnitModel.fromJson({
        'id': 10,
        'unit': {'id': 3, 'name': 'Piece', 'symbol': 'pc'},
        'packQuantity': 1,
        'purchasePrice': 20.0,
      });
      var line = PurchaseLineItemData(
        product: ProductModel.fromJson({'id': 1, 'name': 'Noodles'}),
        unitOptions: [_carton, piece],
        unit: _carton,
        quantity: 2,
        rate: 480,
      );
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: StatefulBuilder(
                  builder: (context, update) => PurchaseLineItemRow(
                    line: line,
                    enabled: true,
                    onChanged: (value) => update(() => line = value),
                    onRemove: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('Purchase unit / pack')).dy,
        lessThan(tester.getTopLeft(find.text('Quantity received (ctn)')).dy),
      );
      await tester.tap(find.text('Carton (ctn)').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Piece (pc)').last);
      await tester.pumpAndSettle();
      expect(line.rate, 20);
      expect(line.quantity, 2);
      expect(line.lineTotal, 40);
      expect(find.text('Cost per Piece (Rs.)'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '0');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Enter a quantity greater than zero'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final _carton = ProductPurchaseUnitModel.fromJson({
  'id': 9,
  'unit': {'id': 2, 'name': 'Carton', 'symbol': 'ctn'},
  'packQuantity': 24,
  'purchasePrice': 480.0,
  'isDefault': true,
});
