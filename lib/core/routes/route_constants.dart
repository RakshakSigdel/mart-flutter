/// Every route path in the app, in one place.
///
/// Screens must never write a path literal — `context.go(Routes.splash)`,
/// not `context.go('/')`.
class Routes {
  Routes._();

  // Initial entry point
  static const String splash = '/';

  // Catch-all for unknown paths
  static const String notFound = '/404';

  //-----------Auth---------------
  static const String login = '/login';

  //-----------Shared (any signed-in role)---------------

  /// The signed-in user's own account and change-password gateway —
  /// reachable from an `AppBar` avatar regardless of role, so it lives
  /// outside both the admin shell and the superadmin area.
  static const String profile = '/profile';

  //-----------User (Admin shell)---------------
  static const String dashboard = '/dashboard';
  static const String staff = '/staff';

  /// The hire-staff form, as its own page rather than a dialog — the form
  /// is long enough that a dialog/bottom-sheet cramped it.
  static const String staffNew = '/staff/new';

  /// Path template for registering the edit-staff route with [GoRouter].
  /// Screens must not build this string by hand — use [staffEdit].
  static const String staffEditPath = '/staff/:id/edit';

  static String staffEdit(String id) => '/staff/$id/edit';

  /// Shared prefix for every inventory route — `inventory_products` and
  /// `inventory_categories` will hang off this the same way `units` does.
  static const String inventory = '/inventory';

  static const String inventoryUnits = '$inventory/units';

  /// New/edit unit forms, as their own page rather than a dialog — same
  /// reasoning as [staffNew].
  static const String inventoryUnitNew = '$inventoryUnits/new';

  /// Path template for registering the edit-unit route with [GoRouter].
  /// Screens must not build this string by hand — use [inventoryUnitEdit].
  static const String inventoryUnitEditPath = '$inventoryUnits/:id/edit';

  /// Unit ids are numeric (unlike staff/mart ids, which are UUIDs) — see
  /// [InventoryUnitModel.id].
  static String inventoryUnitEdit(int id) => '$inventoryUnits/$id/edit';

  static const String inventoryCategories = '$inventory/categories';

  /// New/edit category forms, as their own page — same reasoning as
  /// [staffNew].
  static const String inventoryCategoryNew = '$inventoryCategories/new';

  /// Path template for registering the edit-category route with
  /// [GoRouter]. Screens must not build this string by hand — use
  /// [inventoryCategoryEdit].
  static const String inventoryCategoryEditPath =
      '$inventoryCategories/:id/edit';

  static String inventoryCategoryEdit(int id) =>
      '$inventoryCategories/$id/edit';

  /// Path template for registering the category-detail route (unit policy,
  /// product count) with [GoRouter]. Screens must not build this string by
  /// hand — use [inventoryCategoryDetail].
  static const String inventoryCategoryDetailPath = '$inventoryCategories/:id';

  static String inventoryCategoryDetail(int id) => '$inventoryCategories/$id';

  static const String inventoryProducts = '$inventory/products';

  /// New/edit product forms, as their own page — same reasoning as
  /// [staffNew].
  static const String inventoryProductNew = '$inventoryProducts/new';

  /// Path template for registering the edit-product route with
  /// [GoRouter]. Screens must not build this string by hand — use
  /// [inventoryProductEdit].
  static const String inventoryProductEditPath = '$inventoryProducts/:id/edit';

  static String inventoryProductEdit(int id) => '$inventoryProducts/$id/edit';

  /// Path template for registering the product-detail route (trading
  /// configuration, VAT history) with [GoRouter]. Screens must not build
  /// this string by hand — use [inventoryProductDetail].
  static const String inventoryProductDetailPath = '$inventoryProducts/:id';

  static String inventoryProductDetail(int id) => '$inventoryProducts/$id';

  static const String vendors = '/vendors';

  /// New/edit vendor forms, as their own page — same reasoning as
  /// [staffNew].
  static const String vendorNew = '$vendors/new';

  /// Path template for registering the edit-vendor route with [GoRouter].
  /// Screens must not build this string by hand — use [vendorEdit].
  static const String vendorEditPath = '$vendors/:id/edit';

  static String vendorEdit(int id) => '$vendors/$id/edit';

  /// Path template for registering the vendor-detail route (balance,
  /// ledger, purchase history) with [GoRouter]. Screens must not build
  /// this string by hand — use [vendorDetail].
  static const String vendorDetailPath = '$vendors/:id';

  static String vendorDetail(int id) => '$vendors/$id';

  static const String customers = '/customers';

  static const String customerNew = '$customers/new';

  static const String customerEditPath = '$customers/:id/edit';

  static String customerEdit(int id) => '$customers/$id/edit';

  static const String customerDetailPath = '$customers/:id';

  static String customerDetail(int id) => '$customers/$id';

  static const String stock = '/stock';

  /// Path template for registering the stock product-detail route (level,
  /// movement ledger) with [GoRouter]. Screens must not build this string
  /// by hand — use [stockProductDetail].
  static const String stockProductDetailPath = '$stock/products/:id';

  static String stockProductDetail(int id) => '$stock/products/$id';

  static const String purchases = '/purchases';

  /// The record-purchase form, as its own page — same reasoning as
  /// [staffNew]. No edit form — a recorded purchase is immutable.
  static const String purchaseNew = '$purchases/new';

  /// Path template for registering the purchase-detail route with
  /// [GoRouter]. Screens must not build this string by hand — use
  /// [purchaseDetail].
  static const String purchaseDetailPath = '$purchases/:id';

  static String purchaseDetail(int id) => '$purchases/$id';

  static const String sales = '/sales';

  /// The ring-up-a-sale form, as its own page — same reasoning as
  /// [staffNew]. No edit form — a rung-up bill is immutable apart from
  /// taking a payment against it, which is [saleDetail]'s own action.
  static const String saleNew = '$sales/new';

  /// Path template for registering the sale-detail route with [GoRouter].
  /// Screens must not build this string by hand — use [saleDetail].
  static const String saleDetailPath = '$sales/:id';

  static String saleDetail(int id) => '$sales/$id';

  //-----------Superadmin---------------
  static const String adminManagement = '/admin/management';

  /// The create-mart form, as its own page — see [staffNew] for why.
  static const String adminNew = '/admin/management/new';

  /// Path template for registering the edit-mart route with [GoRouter].
  /// Screens must not build this string by hand — use [adminEdit].
  static const String adminEditPath = '/admin/management/:id/edit';

  static String adminEdit(String id) => '/admin/management/$id/edit';
}
