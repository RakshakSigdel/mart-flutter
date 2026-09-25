import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/data/datasource/datasource_user/inventory_categories_datasource.dart';
import 'package:sts_retail/data/datasource/datasource_user/inventory_products_datasource.dart';
import 'package:sts_retail/presentation/feature_user/sales/screens/pos_screen.dart';
import 'package:sts_retail/providers/providers_user/inventory_categories_provider.dart';
import 'package:sts_retail/providers/providers_user/inventory_products_provider.dart';

void main() {
  testWidgets('hardware barcode lookup keeps an internal hyphen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final dio = Dio();
    addTearDown(dio.close);
    final lookups = <String>[];
    final searches = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/by-barcode/')) {
            lookups.add(options.path);
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'message': 'No product found'},
                ),
              ),
            );
            return;
          }
          if (options.queryParameters['search'] case final String search) {
            searches.add(search);
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'content': <dynamic>[],
                  'pageNumber': 1,
                  'totalPages': 0,
                  'totalElements': 0,
                  'last': true,
                },
              },
            ),
          );
        },
      ),
    );

    final products = InventoryProductsRemoteDataSource(dio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProductsRemoteDataSourceProvider.overrideWithValue(products),
          inventoryCategoriesRemoteDataSourceProvider.overrideWithValue(
            InventoryCategoriesRemoteDataSource(dio),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: PosScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    FocusManager.instance.primaryFocus?.unfocus();

    final keys = <(LogicalKeyboardKey, String)>[
      (LogicalKeyboardKey.keyG, 'G'),
      (LogicalKeyboardKey.digit8, '8'),
      (LogicalKeyboardKey.digit0, '0'),
      (LogicalKeyboardKey.minus, '-'),
      (LogicalKeyboardKey.digit3, '3'),
      (LogicalKeyboardKey.digit0, '0'),
      (LogicalKeyboardKey.digit1, '1'),
      (LogicalKeyboardKey.digit8, '8'),
      (LogicalKeyboardKey.digit0, '0'),
      (LogicalKeyboardKey.digit3, '3'),
    ];
    for (final (key, char) in keys) {
      await tester.sendKeyEvent(key, character: char);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(lookups, ['/inventory/products/by-barcode/G80-301803']);
    expect(tester.takeException(), isNull);

    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Search products by name...',
    );
    await tester.enterText(searchField, 'G80-301803');
    await tester.pump();
    expect(searches, ['G80-301803']);
  });
}
