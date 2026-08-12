import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/core.dart';
import 'core/routes/app_router.dart';
import 'presentation/test_screen.dart';

/// Set to `true` to boot straight into [TestScreen] instead of the real app
/// routing — a quick way to eyeball every design-system token/widget before
/// building real screens against them. Flip back to `false` before shipping.
const bool _showDesignSystemShowcase = true;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge with a transparent status bar; AppBarTheme sets the icon
  // brightness per screen.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MartApp());
}

class MartApp extends StatelessWidget {
  const MartApp({super.key});

  // MaterialApp.router and the plain MaterialApp constructor are mutually
  // exclusive (`home`/`routes` vs `routerConfig`), so the showcase toggle
  // has to pick the constructor, not just a parameter.
  Widget _textScaleClamp(BuildContext context, Widget? child) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showDesignSystemShowcase) {
      return MaterialApp(
        title: 'Mart Management System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const TestScreen(),
        builder: _textScaleClamp,
      );
    }

    return MaterialApp.router(
      title: 'Mart Management System',
      debugShowCheckedModeBanner: false,

      // ─── Theme ────────────────────────────────────────────────────────
      // The whole design system hangs off this one line. Only a light theme
      // exists today, and themeMode pins it so a device in dark mode does
      // not fall back to Flutter's default dark palette.
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      // ─── Routing ──────────────────────────────────────────────────────
      routerConfig: AppRouter.router,

      // ─── Global text scaling ──────────────────────────────────────────
      // Respect the user's font size preference, but clamp it so the denser
      // POS layouts (price rows, tables) cannot overflow.
      builder: _textScaleClamp,
    );
  }
}
