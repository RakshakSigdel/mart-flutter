import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../controllers/vendors_controller.dart';
import '../widgets/vendor_row_actions.dart';
import '../widgets/all_vendor_history_dialog.dart';
import '../widgets/vendors_confirm_dialog.dart';
import '../widgets/vendors_list_card.dart';
import '../widgets/vendors_pagination_bar.dart';
import '../widgets/vendors_table.dart';
import '../widgets/vendors_toolbar.dart';

/// Vendors landing screen: the signed-in mart's supplier directory, with
/// search, pagination, and the full lifecycle of actions the `/vendors`
/// endpoints expose (add, edit, remove — balance/ledger/history live on
/// the detail screen).
///
/// Rendered as a branch of [AdminShellScreen] — no [Scaffold]/`AppBar` of
/// its own, those live on the shell.
class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
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

  VendorsController get _controller =>
      ref.read(vendorsControllerProvider.notifier);

  Future<void> _addVendor() async {
    final result = await context.push<bool>(Routes.vendorNew);
    if (result == true && mounted) {
      AppSnackBar.success(context, 'Vendor added.');
    }
  }

  Future<void> _handleRowAction(
    VendorModel vendor,
    VendorRowAction action,
  ) async {
    switch (action) {
      case VendorRowAction.viewDetails:
        context.push(Routes.vendorDetail(vendor.id));
        break;
      case VendorRowAction.edit:
        final result = await context.push<bool>(
          Routes.vendorEdit(vendor.id),
          extra: vendor,
        );
        if (result == true && mounted) {
          AppSnackBar.success(context, 'Vendor updated.');
        }
        break;
      case VendorRowAction.remove:
        final confirmed = await showVendorConfirmDialog(
          context,
          title: 'Remove vendor',
          message:
              '${vendor.name} will be removed. This only works while nothing '
              'is recorded against them.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (confirmed != true) return;
        try {
          final message = await _controller.removeVendor(vendor.id);
          if (mounted) {
            AppSnackBar.success(
              context,
              _clearMessage(message, '${vendor.name} has been removed.'),
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
    final state = ref.watch(vendorsControllerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.contentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VendorsToolbar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onSearchSubmitted: (value) {
                  _searchDebouncer.cancel();
                  _controller.setSearch(value);
                  _controller.submitSearch();
                },
                onHistoryPressed: () => showAllVendorHistoryDialog(context),
                onAddPressed: _addVendor,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildContent(state, isWide)),
              const SizedBox(height: AppSpacing.smMd),
              VendorsPaginationBar(
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

  Widget _buildContent(VendorsState state, bool isWide) {
    if (state.isLoading) {
      return AppListSkeleton(itemCount: isWide ? 6 : 4, hasThumbnail: false);
    }

    if (state.error != null) {
      return AppEmptyState.error(
        message: state.error,
        onAction: _controller.refresh,
      );
    }

    if (state.isEmpty) {
      return AppEmptyState(
        icon: Icons.local_shipping_outlined,
        title: state.search.isEmpty ? 'No vendors yet' : 'No results found',
        message: state.search.isEmpty
            ? 'Add your first vendor to get started.'
            : 'Try a different search.',
        actionLabel: state.search.isEmpty ? 'Add vendor' : null,
        onAction: state.search.isEmpty ? _addVendor : null,
      );
    }

    if (isWide) {
      return SingleChildScrollView(
        child: VendorsTable(
          vendors: state.vendors,
          busyIds: state.busyIds,
          onAction: _handleRowAction,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.vendors.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smMd),
      itemBuilder: (context, index) {
        final vendor = state.vendors[index];
        return VendorListCard(
          vendor: vendor,
          isBusy: state.busyIds.contains(vendor.id),
          onAction: (action) => _handleRowAction(vendor, action),
        );
      },
    );
  }
}
