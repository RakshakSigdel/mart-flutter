import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/core/core.dart';
import 'package:sts_retail/data/models/models_user/inventory_units_model.dart';
import 'package:sts_retail/presentation/feature_user/inventory_units/controllers/inventory_units_controller.dart';
import 'package:sts_retail/presentation/feature_user/inventory_units/screens/inventory_units_screen.dart';
import 'package:sts_retail/presentation/feature_user/inventory_units/widgets/inventory_units_table.dart';
import 'package:sts_retail/presentation/feature_user/inventory_units/widgets/inventory_units_row_actions.dart';

final _custom = InventoryUnitModel.fromJson({
  'id': 1,
  'name': 'Carton',
  'symbol': 'ctn',
  'measurementType': 'COUNT',
});
final _system = InventoryUnitModel.fromJson({
  'id': 2,
  'name': 'Kilogram',
  'symbol': 'kg',
  'measurementType': 'WEIGHT',
  'systemDefined': true,
  'referenceUnit': true,
});

class _UnitsFixture extends InventoryUnitsController {
  @override
  InventoryUnitsState build() => InventoryUnitsState.initial().copyWith(
    isLoading: false,
    units: [_custom, _system],
    totalElements: 2,
    totalPages: 1,
  );
}

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(760, 700),
    const Size(1280, 800),
  ]) {
    testWidgets('units render and scroll at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryUnitsControllerProvider.overrideWith(_UnitsFixture.new),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: InventoryUnitsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Add unit'), findsOneWidget);
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Carton').hitTestable(), findsOneWidget);
    });
  }

  testWidgets(
    'only custom units can open for editing; busy rows are disabled',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      InventoryUnitRowAction? action;
      Future<void> pump(Set<int> busyIds) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: InventoryUnitsTable(
              units: [_custom, _system],
              busyIds: busyIds,
              onAction: (_, value) => action = value,
            ),
          ),
        ),
      );
      await pump({});
      await tester.tap(find.text('Carton'));
      expect(action, InventoryUnitRowAction.edit);
      action = null;
      await tester.tap(find.text('Kilogram'));
      expect(action, isNull);
      await pump({1});
      await tester.tap(find.text('Carton'));
      expect(action, isNull);
    },
  );
}
