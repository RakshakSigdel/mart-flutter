import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/staff_model.dart';
import '../controllers/staff_management_controller.dart';
import '../widgets/staff_confirm_dialog.dart';
import '../widgets/staff_list_card.dart';
import '../widgets/staff_pagination_bar.dart';
import '../widgets/staff_reset_password_dialog.dart';
import '../widgets/staff_row_actions.dart';
import '../widgets/staff_table.dart';
import '../widgets/staff_toolbar.dart';

/// Staff landing screen: the signed-in mart's staff accounts, with search,
/// filtering, pagination, and the full lifecycle of actions the
/// `/admin/staff` endpoints expose (hire, edit, reset password, retire).
///
/// Rendered as a branch of [AdminShellScreen] — no [Scaffold]/`AppBar` of
/// its own, those live on the shell.
class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  final _searchController = TextEditingController();
  final _searchDebouncer = Debouncer();

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  /// Live search: fires once typing settles, but only once there's enough
  /// to search on — clearing the field still searches immediately, so the
  /// full list comes back without needing Enter.
  void _onSearchChanged(String value) {
    _controller.setSearch(value);
    if (value.trim().length < 2 && value.isNotEmpty) {
      _searchDebouncer.cancel();
      return;
    }
    _searchDebouncer.run(_controller.submitSearch);
  }

  StaffManagementController get _controller =>
      ref.read(staffManagementControllerProvider.notifier);

  Future<void> _hireStaff() async {
    final result = await context.push<bool>(Routes.staffNew);
    if (result == true && mounted) {
      AppSnackBar.success(context, 'Staff member hired.');
    }
  }

  Future<void> _handleRowAction(StaffModel staff, StaffRowAction action) async {
    switch (action) {
      case StaffRowAction.edit:
        final result = await context.push<bool>(
          Routes.staffEdit(staff.id),
          extra: staff,
        );
        if (result == true && mounted) {
          AppSnackBar.success(context, 'Staff details updated.');
        }
        break;
      case StaffRowAction.resetPassword:
        final message = await showStaffResetPasswordDialog(
          context,
          staffId: staff.id,
          staffName: staff.displayName,
        );
        if (message != null && mounted) {
          AppSnackBar.success(
            context,
            _clearMessage(message, 'New password set for ${staff.displayName}.'),
          );
        }
        break;
      case StaffRowAction.retire:
        final confirmed = await showStaffConfirmDialog(
          context,
          title: 'Retire staff',
          message:
              '${staff.displayName} will lose access to this mart. This can '
              'be undone later by an admin.',
          confirmLabel: 'Retire',
          destructive: true,
        );
        if (confirmed != true) return;
        try {
          final message = await _controller.retireStaff(staff.id);
          if (mounted) {
            AppSnackBar.success(
              context,
              _clearMessage(message, '${staff.displayName} has been retired.'),
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
    final state = ref.watch(staffManagementControllerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StaffToolbar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onSearchSubmitted: (value) {
                  _searchDebouncer.cancel();
                  _controller.setSearch(value);
                  _controller.submitSearch();
                },
                roleFilter: state.roleFilter,
                onRoleFilterChanged: _controller.setRoleFilter,
                statusFilter: state.statusFilter,
                onStatusFilterChanged: _controller.setStatusFilter,
                onHirePressed: _hireStaff,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildContent(state, isWide)),
              const SizedBox(height: AppSpacing.smMd),
              StaffPaginationBar(
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
    );
  }

  Widget _buildContent(StaffManagementState state, bool isWide) {
    if (state.isLoading) {
      return AppListSkeleton(itemCount: isWide ? 6 : 4, hasThumbnail: false);
    }

    if (state.error != null) {
      return AppEmptyState.error(message: state.error, onAction: _controller.refresh);
    }

    if (state.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: state.search.isEmpty ? 'No staff yet' : 'No results found',
        message: state.search.isEmpty
            ? 'Hire your first staff member to get started.'
            : 'Try a different search or clear your filters.',
        actionLabel: state.search.isEmpty ? 'Hire staff' : null,
        onAction: state.search.isEmpty ? _hireStaff : null,
      );
    }

    if (isWide) {
      return SingleChildScrollView(
        child: StaffTable(
          staff: state.staff,
          busyIds: state.busyIds,
          onAction: _handleRowAction,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.staff.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smMd),
      itemBuilder: (context, index) {
        final staff = state.staff[index];
        return StaffListCard(
          staff: staff,
          isBusy: state.busyIds.contains(staff.id),
          onAction: (action) => _handleRowAction(staff, action),
        );
      },
    );
  }
}
