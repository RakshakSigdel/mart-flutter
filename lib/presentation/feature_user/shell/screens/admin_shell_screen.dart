import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';
import '../../../feature_shared/profile/widgets/profile_avatar_button.dart';
import '../models/admin_nav_item.dart';
import '../widgets/admin_sidebar.dart';

/// Shared layout for every admin-area screen (dashboard, staff, …): a
/// responsive/collapsible sidebar on tablet+ screens, a [Drawer] on phones,
/// wrapping whichever branch [navigationShell] is currently showing.
///
/// Built as the `builder` of a `StatefulShellRoute.indexedStack` so each
/// branch keeps its own navigation stack and scroll position when switching
/// tabs — see `app_router.dart`.
class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key, required this.navigationShell});

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

  void _onItemSelected(int index, {required bool isWide}) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    if (!isWide && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;
    final companyName = session?.companyName ?? session?.displayName ?? 'Mart Admin';
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;
    final currentIndex = widget.navigationShell.currentIndex;
    final currentItem = adminNavItems[currentIndex];

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
        title: Text(currentItem.label),
        actions: const [ProfileAvatarButton()],
      ),
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: AppColors.card,
              width: AdminSidebar.expandedWidth,
              child: AdminSidebar(
                selectedIndex: currentIndex,
                onItemSelected: (index) => _onItemSelected(index, isWide: false),
                companyName: companyName,
                onLogout: _logout,
              ),
            ),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminSidebar(
                  selectedIndex: currentIndex,
                  onItemSelected: (index) => _onItemSelected(index, isWide: true),
                  companyName: companyName,
                  onLogout: _logout,
                  isCollapsed: _isCollapsed,
                  onToggleCollapse: () => setState(() => _isCollapsed = !_isCollapsed),
                ),
                Expanded(child: widget.navigationShell),
              ],
            )
          : widget.navigationShell,
    );
  }
}
