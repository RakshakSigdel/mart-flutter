import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/core.dart';
import 'core/routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge with a transparent status bar; AppBarTheme sets the icon
  // brightness per screen.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MartApp()));
}

class MartApp extends ConsumerWidget {
  const MartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched (not read) so the router itself is rebuilt if routerProvider
    // is ever overridden mid-session (tests); the router's own internalÏ
    // state — current location, auth redirect — is independent of this.
    final router = ref.watch(routerProvider);

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
      routerConfig: router,

      // ─── Global text scaling ──────────────────────────────────────────
      // Respect the user's font size preference, but clamp it so the denser
      // POS layouts (price rows, tables) cannot overflow.
      builder: (context, child) {
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
      },
    );
  }
}
