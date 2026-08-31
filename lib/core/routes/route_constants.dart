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

  //-----------User---------------
  static const String dashboard = '/dashboard';

  //-----------Superadmin---------------
  static const String adminManagement = '/admin/management';
}
