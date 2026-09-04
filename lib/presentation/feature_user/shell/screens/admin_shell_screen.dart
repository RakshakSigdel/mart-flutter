import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';
import '../controllers/sidebar_controller.dart';
import '../models/sidebar_menu_registry.dart';
import '../widgets/admin_sidebar.dart';

/// Fallback page titles for a branch route the current sidebar data
/// doesn't happen to name — e.g. a role whose `/me/sidebar` response
/// omits an item for a page the user reached by direct URL. Keyed by the
/// same paths `AppRouter` registers as shell branches.
const Map<String, String> _fallbackTitles = {
  Routes.dashboard: 'Dashboard',
  Routes.inventoryUnits: 'Units',
  Routes.inventoryCategories: 'Categories',
  Routes.inventoryProducts: 'Products',
  Routes.staff: 'Staff',
  Routes.vendors: 'Vendors',
  Routes.stock: 'Stock',
  Routes.purchases: 'Purchases',
  Routes.sales: 'Sales',
};

/// Shared layout for every admin-area screen (dashboard, staff, …): a
/// responsive/collapsible sidebar on tablet+ screens, a [Drawer] on phones,
/// wrapping whichever branch [navigationShell] is currently showing.
///
/// The sidebar itself is data-driven — see [SidebarController] — so
/// switching branches here goes through [GoRouter.go] against each entry's
/// own path rather than [StatefulNavigationShell.goBranch]'s branch index,
/// which the backend's menu shape has no reason to line up with.
///
/// Built as the `builder` of a `StatefulShellRoute.indexedStack` so each
/// branch keeps its own navigation stack and scroll position when switching
/// tabs — see `app_router.dart`.
class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({
    super.key,
    required this.location,
    required this.navigationShell,
  });

  /// The active branch's own matched location (e.g. `/inventory/units`) —
  /// threaded straight from `StatefulShellRoute.indexedStack`'s `builder`
  /// rather than read back via `GoRouterState.of(context)`, since this
  /// widget's own context sits above `navigationShell`'s nested Navigator
  /// and isn't guaranteed to resolve to the active branch's route.
  final String location;

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isCollapsed = false;

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go(Routes.login);
  }

  void _onNavigate(String path, {required bool isWide}) {
    // Branch tabs replace the current location (tab-like); anything else
    // (e.g. the profile page) is a full page outside the shell, so it gets
    // pushed on top instead — see `isSidebarShellBranch`'s doc comment for
    // why that's what gives it a working back action.
    if (isSidebarShellBranch(path)) {
      context.go(path);
    } else {
      context.push(path);
    }
    if (!isWide && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  String _titleFor(List<ResolvedSidebarSection> sections, String location) {
    for (final section in sections) {
      for (final entry in section.entries) {
        switch (entry) {
          case ResolvedSidebarLink():
            if (entry.path == location) return entry.name;
          case ResolvedSidebarGroup():
            for (final child in entry.children) {
              if (child.path == location) return child.name;
            }
        }
      }
    }
    return _fallbackTitles[location] ?? 'Mart Admin';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;
    final companyName =
        session?.companyName ?? session?.displayName ?? 'Mart Admin';
    final sidebarState = ref.watch(sidebarControllerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;
    final location = widget.location;
    final title = _titleFor(sidebarState.sections, location);

    Widget buildSidebar({required bool isWide}) => AdminSidebar(
      sections: sidebarState.sections,
      selectedPath: location,
      onNavigate: (path) => _onNavigate(path, isWide: isWide),
      companyName: companyName,
      onLogout: _logout,
      isCollapsed: isWide && _isCollapsed,
      onToggleCollapse: isWide
          ? () => setState(() => _isCollapsed = !_isCollapsed)
          : null,
      isRefreshing: sidebarState.isLoading,
      refreshFailed: sidebarState.error != null,
      onRetry: () => ref.read(sidebarControllerProvider.notifier).refresh(),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Text(title),
      ),
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: AppColors.card,
              width: AdminSidebar.expandedWidth,
              child: buildSidebar(isWide: false),
            ),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildSidebar(isWide: true),
                Expanded(child: widget.navigationShell),
              ],
            )
          : widget.navigationShell,
    );
  }
}
