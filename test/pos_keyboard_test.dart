import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:sts_retail/core/core.dart';
import 'package:sts_retail/data/datasource/datasource_user/inventory_products_datasource.dart';
import 'package:sts_retail/data/datasource/datasource_user/customer_datasource.dart';
import 'package:sts_retail/data/models/models_user/sale_model.dart';
import 'package:sts_retail/providers/providers_user/inventory_products_provider.dart';
import 'package:sts_retail/providers/providers_user/customer_provider.dart';
import 'package:sts_retail/presentation/feature_user/sales/controllers/sales_controller.dart';
import 'package:sts_retail/presentation/feature_user/sales/widgets/sale_form.dart';
import 'package:sts_retail/presentation/feature_user/sales/widgets/sale_line_item_row.dart';
import 'package:sts_retail/presentation/feature_user/sales/widgets/pos_keyboard.dart';

void main() {
  testWidgets(
    'entering and returning to the retained Make Bill page focuses product without refresh',
    (tester) async {
      var active = false;
      late StateSetter changePage;
      final otherFocus = FocusNode();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                changePage = setState;
                return Scaffold(
                  body: IndexedStack(
                    index: active ? 0 : 1,
                    children: [
                      TickerMode(
                        enabled: active,
                        child: const SingleChildScrollView(child: SaleForm()),
                      ),
                      TextField(focusNode: otherFocus, autofocus: true),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(otherFocus.hasFocus, isTrue);
      final row = find.byType(SaleLineItemRow, skipOffstage: false);
      final originalState = tester.state(row);
      changePage(() => active = true);
      await tester.pumpAndSettle();
      expect(tester.widget<SaleLineItemRow>(row).productFocus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      changePage(() => active = false);
      await tester.pumpAndSettle();
      otherFocus.requestFocus();
      await tester.pumpAndSettle();
      expect(otherFocus.hasFocus, isTrue);
      changePage(() => active = true);
      await tester.pumpAndSettle();
      expect(tester.state(row), same(originalState));
      expect(tester.widget<SaleLineItemRow>(row).productFocus.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
      otherFocus.dispose();
    },
  );
  testWidgets(
    'complete POS: products, row removal, unit price, cash, customer details and save using arrows',
    (tester) async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final data = options.path.endsWith('selling-units')
                ? [
                    {
                      'id': 5,
                      'unit': {'id': 1, 'name': 'Piece', 'symbol': 'pc'},
                      'packQuantity': 1,
                      'sellingPrice': 25,
                      'isDefault': true,
                    },
                    {
                      'id': 6,
                      'unit': {'id': 2, 'name': 'Dozen', 'symbol': 'dz'},
                      'packQuantity': 12,
                      'sellingPrice': 250,
                    },
                  ]
                : {
                    'content': [
                      {'id': 99, 'name': 'Noodles', 'active': true},
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
      final controller = _RecordingSales();
      var submitted = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryProductsRemoteDataSourceProvider.overrideWithValue(
              InventoryProductsRemoteDataSource(dio),
            ),
            customerRemoteDataSourceProvider.overrideWithValue(
              CustomerRemoteDataSource(dio),
            ),
            salesControllerProvider.overrideWith(() => controller),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SaleForm(onSubmitted: (_) => submitted = true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> key(LogicalKeyboardKey key) async {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      bool hasFocus(Finder finder) {
        if (finder.evaluate().length != 1) return false;
        final target = finder.evaluate().single;
        var found = FocusManager.instance.primaryFocus?.context == target;
        FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
          element,
        ) {
          if (element == target) {
            found = true;
            return false;
          }
          return true;
        });
        return found;
      }

      Future<void> moveTo(Finder target) async {
        for (var i = 0; i < 45 && !hasFocus(target); i++) {
          await key(LogicalKeyboardKey.arrowDown);
        }
        expect(
          hasFocus(target),
          isTrue,
          reason: 'Arrow traversal must reach $target',
        );
      }

      Finder textField(String label) =>
          find.byWidgetPredicate((w) => w is AppTextField && w.label == label);
      Finder picker(String label) =>
          find.byWidgetPredicate((w) => w is PosPicker && w.label == label);
      Future<void> type(String label, String text) async {
        final target = textField(label);
        await moveTo(target);
        await tester.enterText(
          find.descendant(of: target, matching: find.byType(TextField)),
          text,
        );
        await tester.pumpAndSettle();
      }

      await key(LogicalKeyboardKey.arrowRight); // Product search.
      await key(LogicalKeyboardKey.arrowDown);
      await key(
        LogicalKeyboardKey.arrowRight,
      ); // Noodles; units load and gain focus.
      expect(hasFocus(picker('Selling unit')), isTrue);
      await key(LogicalKeyboardKey.arrowDown);
      expect(hasFocus(textField('Quantity')), isTrue);
      await key(LogicalKeyboardKey.arrowUp);
      expect(hasFocus(picker('Selling unit')), isTrue);
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.arrowRight); // Dozen.
      expect(hasFocus(textField('Quantity')), isTrue);
      expect(
        tester
            .widget<AppTextField>(textField('Selling price'))
            .controller!
            .text,
        '250.00',
      );
      await type('Quantity', '2');
      await type('Selling price', '240');
      await type('Item discount (optional)', '5');
      await key(LogicalKeyboardKey.arrowDown);
      expect(hasFocus(picker('How is the customer paying?')), isTrue);
      await key(LogicalKeyboardKey.arrowUp);
      expect(hasFocus(textField('Item discount (optional)')), isTrue);

      await moveTo(find.widgetWithText(AppButton, 'Add another product'));
      await key(LogicalKeyboardKey.arrowRight);
      expect(find.byType(SaleLineItemRow), findsNWidgets(2));
      final newRow = find.byType(SaleLineItemRow).last;
      await moveTo(
        find.descendant(of: newRow, matching: find.byTooltip('Remove item')),
      );
      await key(LogicalKeyboardKey.arrowRight);
      expect(find.byType(SaleLineItemRow), findsOneWidget);
      expect(hasFocus(picker('Product or barcode')), isTrue);
      await moveTo(picker('Selling unit'));
      await key(LogicalKeyboardKey.arrowDown);
      expect(hasFocus(textField('Quantity')), isTrue);

      await moveTo(picker('How is the customer paying?'));
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.arrowRight); // Cash.
      await type('Customer gave (cash)', '500');
      await key(LogicalKeyboardKey.arrowDown);
      expect(hasFocus(textField('Bill discount')), isTrue);
      await type('Bill discount', '10');
      await key(LogicalKeyboardKey.arrowDown);
      expect(hasFocus(find.byType(ExpansionTile)), isTrue);
      await key(LogicalKeyboardKey.arrowDown);
      expect(
        hasFocus(
          find.byWidgetPredicate(
            (w) => w is AppButton && w.label.startsWith('Save bill'),
          ),
        ),
        isTrue,
      );
      await key(LogicalKeyboardKey.arrowUp);
      expect(hasFocus(find.byType(ExpansionTile)), isTrue);
      await key(LogicalKeyboardKey.arrowRight);
      await type('Customer name', 'Walk in');
      await type('Phone number', '9800000000');
      await type('PAN', '123');
      await type('Note (optional)', 'Keyboard sale');
      await key(LogicalKeyboardKey.arrowDown);
      expect(
        hasFocus(
          find.byWidgetPredicate(
            (w) => w is AppButton && w.label.startsWith('Save bill'),
          ),
        ),
        isTrue,
      );
      await moveTo(
        find.byWidgetPredicate(
          (w) => w is AppButton && w.label.startsWith('Save bill'),
        ),
      );
      await key(LogicalKeyboardKey.arrowRight);
      expect(submitted, isTrue);
      expect(controller.request!.items.single.productId, 99);
      expect(controller.request!.items.single.sellingUnitId, 6);
      expect(controller.request!.items.single.quantity, 2);
      expect(controller.request!.items.single.rate, 240);
      expect(controller.request!.tenderedAmount, 500);
      expect(controller.request!.remark, 'Keyboard sale');

      // Credit hides cash fields and opens customer details. Traversal must
      // follow the new visible controls, including saved-customer selection.
      await moveTo(picker('How is the customer paying?'));
      await key(LogicalKeyboardKey.arrowRight);
      for (var i = 0; i < 4; i++) {
        await key(LogicalKeyboardKey.arrowDown);
      }
      await key(LogicalKeyboardKey.arrowRight);
      expect(textField('Customer gave (cash)'), findsNothing);
      await moveTo(picker('Find saved customer'));
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.arrowRight);
      expect(
        tester
            .widget<AppTextField>(textField('Customer name'))
            .controller!
            .text,
        'Noodles',
      );
      await moveTo(find.widgetWithText(TextButton, 'Clear'));
      await key(LogicalKeyboardKey.arrowRight);
      expect(hasFocus(picker('Find saved customer')), isTrue);
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.arrowRight);
      await moveTo(
        find.byWidgetPredicate(
          (w) => w is AppButton && w.label.startsWith('Save bill'),
        ),
      );
      await key(LogicalKeyboardKey.arrowRight);
      expect(controller.request!.customerId, 99);
      await tester.pumpWidget(const SizedBox());
      dio.close();
    },
  );
  testWidgets(
    'barcode miss focuses quick-add, Right creates and restores quantity focus',
    (tester) async {
      final dio = Dio();
      Map<String, dynamic>? posted;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('by-barcode')) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: options,
                    statusCode: 404,
                    data: {'message': 'Not found'},
                  ),
                ),
              );
            } else if (options.path.endsWith('quick-add')) {
              posted = options.data as Map<String, dynamic>;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'id': 5,
                      'productId': 99,
                      'productName': 'Biscuit',
                      'unit': {'id': 1, 'name': 'Piece', 'symbol': 'pc'},
                      'sellingPrice': 30,
                      'packQuantity': 1,
                      'isDefault': true,
                    },
                  },
                ),
              );
            } else {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {'content': []},
                  },
                ),
              );
            }
          },
        ),
      );
      final scope = FocusScopeNode();
      final product = FocusNode();
      SaleLineItemData? row;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryProductsRemoteDataSourceProvider.overrideWithValue(
              InventoryProductsRemoteDataSource(dio),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PosKeyboardNavigation(
                scope: scope,
                child: SaleLineItemRow(
                  productFocus: product,
                  autofocusProduct: true,
                  onChanged: (value) => row = value,
                  onRemove: () {},
                  canRemove: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '8901234',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      final name = find.byWidgetPredicate(
        (w) => w is AppTextField && w.label == 'Name',
      );
      expect(tester.widget<AppTextField>(name).focusNode!.hasFocus, isTrue);
      await tester.enterText(
        find.descendant(of: name, matching: find.byType(TextField)),
        'Biscuit',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      tester.testTextInput.enterText('30');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(posted, {
        'name': 'Biscuit',
        'sellingPrice': 30.0,
        'barcode': '8901234',
      });
      expect(row!.productId, 99);
      expect(row!.sellingUnitId, 5);
      final quantity = find.byWidgetPredicate(
        (w) => w is AppTextField && w.label == 'Quantity',
      );
      expect(tester.widget<AppTextField>(quantity).focusNode!.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
      product.dispose();
      dio.close();
    },
  );
  testWidgets(
    'four arrows navigate text, activate an action and restore picker focus',
    (tester) async {
      final scope = FocusScopeNode();
      final name = FocusNode();
      final picker = FocusNode();
      final amount = FocusNode();
      String? choice;
      var saved = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosKeyboardNavigation(
              scope: scope,
              child: Column(
                children: [
                  TextField(focusNode: name, autofocus: true),
                  PosPicker<String>(
                    label: 'Product',
                    selectedItem: null,
                    focusNode: picker,
                    items: List.generate(30, (i) => 'Product $i'),
                    itemLabel: (s) => s,
                    onChanged: (s) => choice = s,
                  ),
                  TextField(focusNode: amount),
                  AppButton(label: 'Save', onPressed: () => saved++),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(name.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(picker.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      for (var i = 0; i < 18; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Product 17'))
            .selected,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(choice, 'Product 16');
      expect(picker.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(amount.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(picker.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(saved, 1);
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
      name.dispose();
      picker.dispose();
      amount.dispose();
    },
  );

  testWidgets(
    'search ignores stale responses and Left cancels without selecting',
    (tester) async {
      final scope = FocusScopeNode();
      final old = Completer<List<String>>();
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosKeyboardNavigation(
              scope: scope,
              child: PosPicker<String>(
                label: 'Customer',
                selectedItem: null,
                autofocus: true,
                search: (q) => q == 'old'
                    ? old.future
                    : Future.value([q.isEmpty ? 'All' : q]),
                itemLabel: (s) => s,
                onChanged: (s) => selected = s,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'old');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.enterText(find.byType(TextField), 'new');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      old.complete(['stale']);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'new'), findsOneWidget);
      expect(find.text('stale'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(selected, isNull);
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
    },
  );
}

class _RecordingSales extends SalesController {
  CreateSaleRequest? request;
  @override
  SalesState build() {
    ref.keepAlive();
    return SalesState.initial();
  }

  @override
  Future<SaleDetailModel> createSale(CreateSaleRequest value) async {
    request = value;
    return SaleDetailModel.fromJson({'id': 1, 'invoiceNumber': 'TEST'});
  }
}
