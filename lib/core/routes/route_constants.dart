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

  //-----------Superadmin---------------
  static const String adminManagement = '/admin/management';

  /// The create-mart form, as its own page — see [staffNew] for why.
  static const String adminNew = '/admin/management/new';

  /// Path template for registering the edit-mart route with [GoRouter].
  /// Screens must not build this string by hand — use [adminEdit].
  static const String adminEditPath = '/admin/management/:id/edit';

  static String adminEdit(String id) => '/admin/management/$id/edit';
}
