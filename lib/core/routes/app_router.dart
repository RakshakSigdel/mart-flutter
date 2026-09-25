import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models_shared/auth_session_model.dart';
import '../../data/models/models_superadmin/admin_model.dart';
import '../../data/models/models_user/customer_model.dart';
import '../../data/models/models_user/inventory_categories_model.dart';
import '../../data/models/models_user/inventory_units_model.dart';
import '../../data/models/models_user/staff_model.dart';
import '../../data/models/models_user/vendor_model.dart';
import '../../data/models/models_user/return_note_model.dart';
import '../../presentation/feature_shared/auth/controller/auth_controller.dart';
import '../../presentation/feature_shared/auth/screens/login_screen.dart';
import '../../presentation/feature_shared/profile/screens/profile_screen.dart';
import '../../presentation/feature_superadmin/admin_management/screens/admin_form_screen.dart';
import '../../presentation/feature_superadmin/admin_management/screens/admin_management_screen.dart';
import '../../presentation/feature_user/customers/screens/customer_detail_screen.dart';
import '../../presentation/feature_user/customers/screens/customer_form_screen.dart';
import '../../presentation/feature_user/customers/screens/customers_screen.dart';
import '../../presentation/feature_user/dashboard/screen/dashboard_screen.dart';
import '../../presentation/feature_user/inventory_categories/screens/inventory_categories_screen.dart';
import '../../presentation/feature_user/inventory_categories/screens/inventory_category_detail_screen.dart';
import '../../presentation/feature_user/inventory_categories/screens/inventory_category_form_screen.dart';
import '../../presentation/feature_user/inventory_products/screens/inventory_product_detail_screen.dart';
import '../../presentation/feature_user/inventory_products/screens/inventory_product_form_screen.dart';
import '../../presentation/feature_user/inventory_products/screens/inventory_products_screen.dart';
import '../../presentation/feature_user/inventory_units/screens/inventory_unit_form_screen.dart';
import '../../presentation/feature_user/inventory_units/screens/inventory_units_screen.dart';
import '../../presentation/feature_user/purchases/screens/purchase_detail_screen.dart';
import '../../presentation/feature_user/purchases/screens/purchase_form_screen.dart';
import '../../presentation/feature_user/purchases/screens/purchases_screen.dart';
import '../../presentation/feature_user/returns/screens/return_notes_screen.dart';
import '../../presentation/feature_user/sales/screens/sale_detail_screen.dart';
import '../../presentation/feature_user/sales/screens/sales_screen.dart';
import '../../presentation/feature_user/sales/screens/pos_screen.dart';
import '../../presentation/feature_user/sales_reports/screens/sales_book_screen.dart';
import '../../presentation/feature_user/settings/screens/settings_coming_soon_screen.dart';
import '../../presentation/feature_user/shell/screens/admin_shell_screen.dart';
import '../../presentation/feature_user/staff_management/screens/staff_form_screen.dart';
import '../../presentation/feature_user/staff_management/screens/staff_management_screen.dart';
import '../../presentation/feature_user/stock/screens/stock_detail_screen.dart';
import '../../presentation/feature_user/stock/screens/stock_adjustments_screen.dart';
import '../../presentation/feature_user/stock/screens/stock_screen.dart';
import '../../presentation/feature_user/vendors/screens/vendor_detail_screen.dart';
import '../../presentation/feature_user/vendors/screens/vendor_form_screen.dart';
import '../../presentation/feature_user/vendors/screens/vendors_screen.dart';
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
    location == Routes.profile ||
    location == Routes.dashboard ||
    location.startsWith(Routes.staff) ||
    location.startsWith(Routes.inventory) ||
    location.startsWith(Routes.vendors) ||
    location.startsWith(Routes.customers) ||
    location.startsWith(Routes.stock) ||
    location.startsWith(Routes.pos) ||
    location.startsWith(Routes.purchases) ||
    location.startsWith(Routes.sales) ||
    location.startsWith(Routes.salesReports) ||
    location.startsWith(Routes.settings);

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
      // The signed-in user's own profile — reachable from either role's
      // AppBar, so it's a full page outside both the shell and the
      // superadmin area rather than a branch of one of them.
      GoRoute(
        path: Routes.superadminProfile,
        name: 'superadminProfile',
        pageBuilder: (context, state) =>
            AppPageRoute.sharedAxisHorizontal(state, const ProfileScreen()),
      ),
      // Mart-admin area: a persistent sidebar (see [AdminShellScreen]) around
      // an IndexedStack of branches, so each keeps its own navigation stack
      // and scroll position when switching tabs instead of rebuilding from
      // scratch.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdminShellScreen(
          location: state.matchedLocation,
          navigationShell: navigationShell,
        ),
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
          // Branch order here is otherwise unconstrained — the sidebar
          // navigates by path (`context.go`), not branch index, so it
          // doesn't need to match whatever order `/me/sidebar` returns.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                name: 'profile',
                pageBuilder: (context, state) => AppPageRoute.none(
                  state,
                  const ProfileScreen(inAdminShell: true),
                ),
              ),
            ],
          ),
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
                path: Routes.inventoryProducts,
                name: 'inventoryProducts',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const InventoryProductsScreen()),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.vendors,
                name: 'vendors',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const VendorsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customers,
                name: 'customers',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const CustomersScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.stock,
                name: 'stock',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const StockScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.stockLevels,
                name: 'stockLevels',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const StockScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.stockAdjustments,
                name: 'stockAdjustments',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const StockAdjustmentsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.purchases,
                name: 'purchases',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const PurchasesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.sales,
                name: 'sales',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const SalesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.pos,
                name: 'pos',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const PosScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.salesReports,
                name: 'salesReports',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const SalesBookScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                name: 'settings',
                pageBuilder: (context, state) =>
                    AppPageRoute.none(state, const SettingsComingSoonScreen()),
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
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          const InventoryUnitFormScreen(),
        ),
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
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          const InventoryCategoryFormScreen(),
        ),
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
      // Add/edit product — full pages for the same reason as the staff
      // form routes above. Unlike staff/mart/category/unit, this never
      // takes an `extra` prefill — see `InventoryProductFormScreen`'s doc
      // comment for why.
      GoRoute(
        path: Routes.inventoryProductNew,
        name: 'inventoryProductNew',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          const InventoryProductFormScreen(),
        ),
      ),
      GoRoute(
        path: Routes.inventoryProductEditPath,
        name: 'inventoryProductEdit',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          InventoryProductFormScreen(
            productId: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ),
      // Product detail — trading configuration (purchase/selling units,
      // VAT history), the one thing the plain list doesn't carry.
      GoRoute(
        path: Routes.inventoryProductDetailPath,
        name: 'inventoryProductDetail',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          InventoryProductDetailScreen(
            productId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      // Add/edit vendor — full pages for the same reason as the staff form
      // routes above.
      GoRoute(
        path: Routes.vendorNew,
        name: 'vendorNew',
        pageBuilder: (context, state) =>
            AppPageRoute.sharedAxisHorizontal(state, const VendorFormScreen()),
      ),
      GoRoute(
        path: Routes.vendorEditPath,
        name: 'vendorEdit',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          VendorFormScreen(
            vendorId: int.tryParse(state.pathParameters['id'] ?? ''),
            initialVendor: state.extra as VendorModel?,
          ),
        ),
      ),
      // Vendor detail — balance, ledger and purchase history, the one
      // thing the plain list doesn't carry.
      GoRoute(
        path: Routes.vendorDetailPath,
        name: 'vendorDetail',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          VendorDetailScreen(
            vendorId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      // Add/edit customer — full pages for the same reason as the staff form
      // routes above.
      GoRoute(
        path: Routes.customerNew,
        name: 'customerNew',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          const CustomerFormScreen(),
        ),
      ),
      GoRoute(
        path: Routes.customerEditPath,
        name: 'customerEdit',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          CustomerFormScreen(
            customerId: int.tryParse(state.pathParameters['id'] ?? ''),
            initialCustomer: state.extra as CustomerModel?,
          ),
        ),
      ),
      // Customer detail — balance, credit limit and transaction history, the
      // one thing the plain list doesn't carry.
      GoRoute(
        path: Routes.customerDetailPath,
        name: 'customerDetail',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          CustomerDetailScreen(
            customerId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      // Stock detail — one product's level and full movement ledger, the
      // one thing the plain list doesn't carry. No add/edit routes —
      // levels are derived from purchases/sales/adjustments, never
      // created directly.
      GoRoute(
        path: Routes.stockProductDetailPath,
        name: 'stockProductDetail',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          StockDetailScreen(
            productId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      // Record a purchase — full page for the same reason as the staff
      // form routes above. No edit route — a recorded purchase is
      // immutable.
      GoRoute(
        path: Routes.purchaseNew,
        name: 'purchaseNew',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          const PurchaseFormScreen(),
        ),
      ),
      // Purchase detail — vendor details and every line item, the one
      // thing the plain list doesn't carry.
      GoRoute(
        path: Routes.purchaseDetailPath,
        name: 'purchaseDetail',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          PurchaseDetailScreen(
            purchaseId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      // The former /sales/new form is now the POS branch. Keep old links
      // working while making every "Make bill" entry point use one form.
      GoRoute(
        path: '${Routes.sales}/new',
        redirect: (context, state) => Routes.pos,
      ),
      // Sale detail — customer details, every line item, and the "take
      // payment" action, the things the plain list doesn't carry.
      GoRoute(
        path: Routes.saleDetailPath,
        name: 'saleDetail',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          SaleDetailScreen(
            saleId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: Routes.salesReturns,
        name: 'salesReturns',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          const ReturnNotesScreen(kind: ReturnKind.sale),
        ),
      ),
      GoRoute(
        path: Routes.salesReturnDetailPath,
        name: 'salesReturnDetail',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          ReturnNoteDetailScreen(
            kind: ReturnKind.sale,
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: Routes.purchaseReturns,
        name: 'purchaseReturns',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          const ReturnNotesScreen(kind: ReturnKind.purchase),
        ),
      ),
      GoRoute(
        path: Routes.purchaseReturnDetailPath,
        name: 'purchaseReturnDetail',
        pageBuilder: (context, state) => AppPageRoute.sharedAxisHorizontal(
          state,
          ReturnNoteDetailScreen(
            kind: ReturnKind.purchase,
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
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
      // Create/edit mart full pages for the same reason as the staff
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
