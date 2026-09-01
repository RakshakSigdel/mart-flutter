import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_superadmin/admin_model.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';
import '../controllers/admin_management_controller.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_list_card.dart';
import '../widgets/admin_pagination_bar.dart';
import '../widgets/admin_reset_password_dialog.dart';
import '../widgets/admin_row_actions.dart';
import '../widgets/admin_table.dart';
import '../widgets/admin_toolbar.dart';

/// Superadmin landing screen: every mart in the installation, with search,
/// filtering, pagination, and the full lifecycle of actions the
/// `/superadmin/admins` endpoints expose (create, edit, reset password,
/// re-provision, retire, and a global "run migrations").
class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() =>
      _AdminManagementScreenState();
}

class _AdminManagementScreenState
    extends ConsumerState<AdminManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  AdminManagementController get _controller =>
      ref.read(adminManagementControllerProvider.notifier);

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go(Routes.login);
  }

  Future<void> _createMart() async {
    final result = await context.push<bool>(Routes.adminNew);
    if (result == true && mounted) {
      AppSnackBar.success(context, 'Mart created.');
    }
  }

  Future<void> _runMigrations() async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Run migrations',
      message:
          'Apply any new tenant migrations to every mart in the '
          'installation. This can take a while for a large number of marts.',
      confirmLabel: 'Run migrations',
    );
    if (confirmed != true) return;

    try {
      final results = await _controller.runMigrations();
      if (mounted) {
        AppSnackBar.success(
          context,
          'Migrations applied to ${results.length} mart'
          '${results.length == 1 ? '' : 's'}.',
        );
      }
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    }
  }

  Future<void> _handleRowAction(AdminModel admin, AdminRowAction action) async {
    switch (action) {
      case AdminRowAction.edit:
        final result = await context.push<bool>(
          Routes.adminEdit(admin.id),
          extra: admin,
        );
        if (result == true && mounted) {
          AppSnackBar.success(context, 'Mart updated.');
        }
        break;
      case AdminRowAction.resetPassword:
        final message = await showAdminResetPasswordDialog(
          context,
          adminId: admin.id,
          companyName: admin.companyName,
        );
        if (message != null && mounted) {
          AppSnackBar.success(
            context,
            _clearMessage(message, 'New password set for ${admin.companyName}.'),
          );
        }
        break;
      case AdminRowAction.provision:
        final confirmed = await showAdminConfirmDialog(
          context,
          title: 'Re-provision schema',
          message:
              'Re-run schema creation and migration for '
              '${admin.companyName}. Existing data is not affected.',
          confirmLabel: 'Provision',
        );
        if (confirmed != true) return;
        try {
          await _controller.provisionAdmin(admin.id);
          if (mounted) AppSnackBar.success(context, 'Provisioning started.');
        } on ApiException catch (e) {
          if (mounted) AppSnackBar.error(context, e.message);
        }
        break;
      case AdminRowAction.retire:
        final confirmed = await showAdminConfirmDialog(
          context,
          title: 'Retire mart',
          message:
              '${admin.companyName} and its staff accounts will be '
              'retired. Its data and schema are left in place and this can '
              'be undone by re-provisioning later.',
          confirmLabel: 'Retire',
          destructive: true,
        );
        if (confirmed != true) return;
        try {
          final message = await _controller.retireAdmin(admin.id);
          if (mounted) {
            AppSnackBar.success(
              context,
              _clearMessage(message, '${admin.companyName} has been retired.'),
            );
          }
        } on ApiException catch (e) {
          if (mounted) AppSnackBar.error(context, e.message);
        }
        break;
    }
  }

  /// The backend's own confirmation text, shown as-is — falls back to a
  /// plain-language default only if it ever sends an empty string.
  static String _clearMessage(String backendMessage, String fallback) =>
      backendMessage.trim().isEmpty ? fallback : backendMessage;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminManagementControllerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Admin Management'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminToolbar(
                  searchController: _searchController,
                  onSearchSubmitted: (value) {
                    _controller.setSearch(value);
                    _controller.submitSearch();
                  },
                  statusFilter: state.statusFilter,
                  onStatusFilterChanged: _controller.setStatusFilter,
                  onCreatePressed: _createMart,
                  onRunMigrationsPressed: _runMigrations,
                  isRunningMigrations: state.isRunningMigrations,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: _buildContent(state, isWide)),
                const SizedBox(height: AppSpacing.smMd),
                AdminPaginationBar(
                  pageNumber: state.pageNumber,
                  totalPages: state.totalPages,
                  totalElements: state.totalElements,
                  hasPrevious: state.hasPreviousPage,
                  hasNext: state.hasNextPage,
                  onPrevious: _controller.previousPage,
                  onNext: _controller.nextPage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AdminManagementState state, bool isWide) {
    if (state.isLoading) {
      return AppListSkeleton(itemCount: isWide ? 6 : 4, hasThumbnail: false);
    }

    if (state.error != null) {
      return AppEmptyState.error(message: state.error, onAction: _controller.refresh);
    }

    if (state.isEmpty) {
      return AppEmptyState(
        icon: Icons.storefront_outlined,
        title: state.search.isEmpty ? 'No marts yet' : 'No results found',
        message: state.search.isEmpty
            ? 'Create the first mart to get started.'
            : 'Try a different search or clear your filters.',
        actionLabel: state.search.isEmpty ? 'New mart' : null,
        onAction: state.search.isEmpty ? _createMart : null,
      );
    }

    if (isWide) {
      return SingleChildScrollView(
        child: AdminTable(
          admins: state.admins,
          busyIds: state.busyIds,
          onAction: _handleRowAction,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.admins.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smMd),
      itemBuilder: (context, index) {
        final admin = state.admins[index];
        return AdminListCard(
          admin: admin,
          isBusy: state.busyIds.contains(admin.id),
          onAction: (action) => _handleRowAction(admin, action),
        );
      },
    );
  }
}
