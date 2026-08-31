import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models_shared/auth_session_model.dart';
import '../../presentation/feature_shared/auth/controller/auth_controller.dart';
import '../../presentation/feature_shared/auth/screens/login_screen.dart';
import '../../presentation/feature_superadmin/admin_management/screens/admin_management_screen.dart';
import '../../presentation/feature_user/dashboard/screen/dashboard_screen.dart';
import '../../presentation/pages/not_found_screen.dart';
import '../../presentation/pages/splash_screen.dart';
import '../animations/app_page_route.dart';
import 'route_constants.dart';

/// Bridges riverpod state changes into something [GoRouter]'s
/// `refreshListenable` understands, so a state change with no explicit
/// navigation call (e.g. an auto-logout after a 401 mid-session) still
/// re-runs [_redirect] for whatever route is currently showing instead of
/// leaving the user stranded on a screen they no longer have access to.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    _subscription = ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

String _landingRouteFor(AuthSessionModel session) =>
    session.isSuperAdmin ? Routes.adminManagement : Routes.dashboard;

/// Route-level auth guard. Runs before every navigation (and whenever
/// [_AuthRefreshListenable] fires), so a direct URL/deep link can't reach a
/// protected screen just because no screen happened to check first.
String? _redirect(BuildContext context, GoRouterState state, Ref ref) {
  final location = state.matchedLocation;

  // Splash owns its own timing/animation and runs the real session check —
  // never intercept it.
  if (location == Routes.splash) return null;

  final authState = ref.read(authControllerProvider);

  // Haven't checked storage yet (e.g. a deep link on cold boot, before
  // splash has had a chance to run). Route through splash first rather than
  // guessing "not signed in" and bouncing a returning user to login.
  if (authState is AuthInitial) return Routes.splash;

  if (authState is! AuthAuthenticated) {
    return location == Routes.login ? null : Routes.login;
  }

  final session = authState.session;

  // Already signed in — /login just forwards to wherever this role lands.
  if (location == Routes.login) return _landingRouteFor(session);

  // Each role is confined to its own area; strict, not just "superadmins can
  // also see the mart dashboard" — keeps the two landing areas unambiguous.
  if (location == Routes.adminManagement && !session.isSuperAdmin) {
    return Routes.dashboard;
  }
  if (location == Routes.dashboard && session.isSuperAdmin) {
    return Routes.adminManagement;
  }

  return null;
}

/// The app's single [GoRouter] instance, as a provider so [_redirect] can
/// read [authControllerProvider] — a plain top-level `GoRouter` has no way
/// to reach riverpod state.
///
/// Every route builds its page through [AppPageRoute] so transitions come
/// from the motion tokens rather than each screen's own choice:
///   - [AppPageRoute.none]                 — splash, redirect targets
///   - [AppPageRoute.fadeThrough]          — switching between top-level areas
///   - [AppPageRoute.sharedAxisHorizontal] — drilling into a detail screen
///   - [AppPageRoute.slideUp]              — full-screen sheets
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refreshListenable,
    redirect: (context, state) => _redirect(context, state, ref),
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        pageBuilder: (context, state) =>
            AppPageRoute.none(state, const SplashScreen()),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (context, state) =>
            AppPageRoute.fadeThrough(state, const LoginScreen()),
      ),
      GoRoute(
        path: Routes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) =>
            AppPageRoute.fadeThrough(state, const DashboardScreen()),
      ),
      GoRoute(
        path: Routes.adminManagement,
        name: 'adminManagement',
        pageBuilder: (context, state) =>
            AppPageRoute.fadeThrough(state, const AdminManagementScreen()),
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
});
