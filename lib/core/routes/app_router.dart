import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/not_found_screen.dart';
import '../../presentation/pages/splash_screen.dart';
import '../animations/app_page_route.dart';
import 'route_constants.dart';

/// The app's single [GoRouter] instance.
///
/// Every route builds its page through [AppPageRoute] so transitions come
/// from the motion tokens rather than each screen's own choice:
///   - [AppPageRoute.none]                 — splash, redirect targets
///   - [AppPageRoute.fadeThrough]          — switching between top-level areas
///   - [AppPageRoute.sharedAxisHorizontal] — drilling into a detail screen
///   - [AppPageRoute.slideUp]              — full-screen sheets
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: kDebugMode,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        pageBuilder: (context, state) =>
            AppPageRoute.none(state, const SplashScreen()),
      ),
      GoRoute(
        path: Routes.notFound,
        name: 'notFound',
        pageBuilder: (context, state) =>
            AppPageRoute.fadeThrough(state, const NotFoundScreen()),
      ),
    ],
    // Unknown path, or a failure while building a route.
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}
