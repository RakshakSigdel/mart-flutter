import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/core/core.dart';
import 'package:sts_retail/data/models/models_user/inventory_categories_model.dart';
import 'package:sts_retail/presentation/feature_user/inventory_categories/controllers/inventory_categories_controller.dart';
import 'package:sts_retail/presentation/feature_user/inventory_categories/screens/inventory_categories_screen.dart';
import 'package:sts_retail/presentation/feature_user/inventory_categories/widgets/inventory_categories_table.dart';
import 'package:sts_retail/presentation/feature_user/inventory_categories/widgets/inventory_categories_row_actions.dart';

const _category = InventoryCategoryModel(
  id: 1,
  name: 'Groceries',
  description: 'Everyday essentials',
);

class _CategoriesFixture extends InventoryCategoriesController {
  @override
  InventoryCategoriesState build() =>
      InventoryCategoriesState.initial().copyWith(
        isLoading: false,
        categories: [_category],
        totalElements: 1,
        totalPages: 1,
      );
}

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(760, 700),
    const Size(1280, 800),
  ]) {
    testWidgets('categories render and scroll at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryCategoriesControllerProvider.overrideWith(
              _CategoriesFixture.new,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: InventoryCategoriesScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Add category'), findsOneWidget);
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Groceries').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('category row opens details and busy rows cannot open', (
    tester,
  ) async {
    InventoryCategoryRowAction? action;
    Future<void> pump(Set<int> busyIds) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: InventoryCategoriesTable(
            categories: [_category],
            busyIds: busyIds,
            onAction: (_, value) => action = value,
          ),
        ),
      ),
    );
    await pump({});
    await tester.tap(find.text('Groceries'));
    expect(action, InventoryCategoryRowAction.viewDetails);
    action = null;
    await pump({1});
    await tester.tap(find.text('Groceries'));
    expect(action, isNull);
  });
}
