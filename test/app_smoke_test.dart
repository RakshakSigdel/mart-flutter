import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mart_flutter/core/core.dart';
import 'package:mart_flutter/core/routes/app_router.dart';

/// Long enough to drain the splash bootstrap delay and every entrance
/// animation's start delay, so no [Timer] is left pending when the test ends.
const _settle = Duration(seconds: 2);

/// Exercises [AppRouter] and [AppTheme] directly rather than through
/// [MartApp] — `main.dart` currently has a showcase toggle that can point
/// its root widget at [TestScreen] instead of the real router, and these
/// tests should hold regardless of how that toggle is set.
Widget _routedApp() {
  return MaterialApp.router(
    theme: AppTheme.lightTheme,
    routerConfig: AppRouter.router,
  );
}

void main() {
  testWidgets('app boots into the splash screen with the app theme', (
    tester,
  ) async {
    await tester.pumpWidget(_routedApp());
    // Not pumpAndSettle: the splash spinner animates forever.
    await tester.pump(_settle);

    expect(find.text('Rakshak Mart'), findsOneWidget);

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.colorScheme.primary, AppColors.primary);
    // Yellow is a light fill — its foreground must stay dark.
    expect(theme.colorScheme.onPrimary, AppColors.textOnPrimary);
  });

  testWidgets('unknown routes land on the 404 screen', (tester) async {
    await tester.pumpWidget(_routedApp());
    await tester.pump(_settle);

    AppRouter.router.go('/nope');
    await tester.pump();
    await tester.pump(_settle);

    expect(find.text('Page not found'), findsOneWidget);
  });
}
