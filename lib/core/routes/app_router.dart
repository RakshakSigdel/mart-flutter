import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models_shared/auth_session_model.dart';
import '../../data/models/models_superadmin/admin_model.dart';
import '../../data/models/models_user/inventory_categories_model.dart';
import '../../data/models/models_user/inventory_units_model.dart';
import '../../data/models/models_user/staff_model.dart';
import '../../presentation/feature_shared/auth/controller/auth_controller.dart';
import '../../presentation/feature_shared/auth/screens/login_screen.dart';
import '../../presentation/feature_superadmin/admin_management/screens/admin_form_screen.dart';
import '../../presentation/feature_superadmin/admin_management/screens/admin_management_screen.dart';
import '../../presentation/feature_user/dashboard/screen/dashboard_screen.dart';
import '../../presentation/feature_user/inventory_categories/screens/inventory_categories_screen.dart';
import '../../presentation/feature_user/inventory_categories/screens/inventory_category_detail_screen.dart';
import '../../presentation/feature_user/inventory_categories/screens/inventory_category_form_screen.dart';
import '../../presentation/feature_user/inventory_units/screens/inventory_unit_form_screen.dart';
import '../../presentation/feature_user/inventory_units/screens/inventory_units_screen.dart';
import '../../presentation/feature_user/shell/screens/admin_shell_screen.dart';
import '../../presentation/feature_user/staff_management/screens/staff_form_screen.dart';
import '../../presentation/feature_user/staff_management/screens/staff_management_screen.dart';
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

/// Whether [location] is part of the mart-admin sidebar area — the shell
/// itself plus any page pushed on top of it (e.g. the hire-staff form).
/// Superadmins are confined out of all of them, not just `/dashboard`.
bool _isAdminShellRoute(String location) =>
    location == Routes.dashboard ||
    location.startsWith(Routes.staff) ||
    location.startsWith(Routes.inventory);

/// Whether [location] is part of the superadmin area — the mart list plus
/// any page pushed on top of it (e.g. the create-mart form).
bool _isSuperAdminRoute(String location) =>
    location.startsWith(Routes.adminManagement);

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
  if (_isSuperAdminRoute(location) && !session.isSuperAdmin) {
    return Routes.dashboard;
  }
  if (_isAdminShellRoute(location) && session.isSuperAdmin) {
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
      //Global Routes
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
        path: Routes.notFound,
        name: 'notFound',
        pageBuilder: (context, state) =>
            AppPageRoute.fadeThrough(state, const NotFoundScreen()),
      ),
      // Mart-admin area: a persistent sidebar (see [AdminShellScreen]) around
      // an IndexedStack of branches, so each keeps its own navigation stack
      // and scroll position when switching tabs instead of rebuilding from
      // scratch.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.dashboard,
                name: 'dashboard',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const DashboardScreen()),
              ),
            ],
          ),
          // Branch order here must match `adminNavItems`' order in
          // admin_nav_item.dart — the sidebar maps a tap on item N straight
          // to `navigationShell.goBranch(N)`.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.inventoryUnits,
                name: 'inventoryUnits',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const InventoryUnitsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.inventoryCategories,
                name: 'inventoryCategories',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const InventoryCategoriesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.staff,
                name: 'staff',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const StaffManagementScreen()),
              ),
            ],
          ),
        ],
      ),
      // Hire/edit staff — full pages rather than branches of the shell
      // above, so they take over the whole screen (no sidebar) instead of
      // squeezing a long form into the branch's content area.
      GoRoute(
        path: Routes.staffNew,
        name: 'staffNew',
        pageBuilder: (context, state) =>
            AppPageRoute.sharedAxisHorizontal(state, const StaffFormScreen()),
      ),
      GoRoute(
        path: Routes.staffEditPath,
        name: 'staffEdit',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          StaffFormScreen(
            staffId: state.pathParameters['id'],
            initialStaff: state.extra as StaffModel?,
          ),
        ),
      ),
      // Add/edit unit — full pages for the same reason as the staff form
      // routes above.
      GoRoute(
        path: Routes.inventoryUnitNew,
        name: 'inventoryUnitNew',
        pageBuilder: (context, state) =>
            AppPageRoute.sharedAxisHorizontal(state, const InventoryUnitFormScreen()),
      ),
      GoRoute(
        path: Routes.inventoryUnitEditPath,
        name: 'inventoryUnitEdit',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          InventoryUnitFormScreen(
            unitId: int.tryParse(state.pathParameters['id'] ?? ''),
            initialUnit: state.extra as InventoryUnitModel?,
          ),
        ),
      ),
      // Add/edit category — full pages for the same reason as the staff
      // form routes above.
      GoRoute(
        path: Routes.inventoryCategoryNew,
        name: 'inventoryCategoryNew',
        pageBuilder: (context, state) =>
            AppPageRoute.sharedAxisHorizontal(state, const InventoryCategoryFormScreen()),
      ),
      GoRoute(
        path: Routes.inventoryCategoryEditPath,
        name: 'inventoryCategoryEdit',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          InventoryCategoryFormScreen(
            categoryId: int.tryParse(state.pathParameters['id'] ?? ''),
            initialCategory: state.extra as InventoryCategoryModel?,
          ),
        ),
      ),
      // Category detail — unit policy and product count, the one thing the
      // plain list doesn't carry.
      GoRoute(
        path: Routes.inventoryCategoryDetailPath,
        name: 'inventoryCategoryDetail',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          InventoryCategoryDetailScreen(
            categoryId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      //SuperAdmin Route
      GoRoute(
        path: Routes.adminManagement,
        name: 'adminManagement',
        pageBuilder: (context, state) =>
            AppPageRoute.fadeThrough(state, const AdminManagementScreen()),
      ),
      // Create/edit mart — full pages for the same reason as the staff
      // form routes above.
      GoRoute(
        path: Routes.adminNew,
        name: 'adminNew',
        pageBuilder: (context, state) =>
            AppPageRoute.sharedAxisHorizontal(state, const AdminFormScreen()),
      ),
      GoRoute(
        path: Routes.adminEditPath,
        name: 'adminEdit',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          AdminFormScreen(
            adminId: state.pathParameters['id'],
            initialAdmin: state.extra as AdminModel?,
          ),
        ),
      ),
    ],
    // Unknown path, or a failure while building a route.
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
});
