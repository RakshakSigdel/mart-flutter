import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/core/core.dart';
import 'package:sts_retail/data/models/models_user/stock_model.dart';
import 'package:sts_retail/presentation/feature_user/stock/controllers/stock_controller.dart';
import 'package:sts_retail/presentation/feature_user/stock/screens/stock_screen.dart';
import 'package:sts_retail/presentation/feature_user/stock/widgets/stock_list_card.dart';
import 'package:sts_retail/presentation/feature_user/stock/widgets/stock_row_actions.dart';

const _item = StockLevelModel(
  productId: 1,
  productName: 'Rice',
  quantity: 3,
  reorderLevel: 10,
  baseUnitSymbol: 'kg',
  status: StockStatus.lowStock,
);

class _StockFixture extends StockController {
  @override
  StockState build() => StockState.initial().copyWith(
    isLoading: false,
    isOverviewLoading: false,
    items: [_item],
    totalElements: 1,
    totalPages: 1,
    overview: const StockOverviewModel(trackedProducts: 1, needingAttention: 1),
  );
}

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(760, 700),
    const Size(1280, 800),
  ]) {
    testWidgets('stock renders and scrolls at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [stockControllerProvider.overrideWith(_StockFixture.new)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: StockScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Needs ordering'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Rice').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('reorder button invokes reorder action without opening details', (
    tester,
  ) async {
    final actions = <StockRowAction>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StockListCard(
            item: _item,
            isBusy: false,
            onAction: actions.add,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Set reorder level'));
    expect(actions, [StockRowAction.setReorderLevel]);
  });
}
