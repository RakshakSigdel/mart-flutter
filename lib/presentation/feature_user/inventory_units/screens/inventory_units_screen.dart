import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../controllers/inventory_units_controller.dart';
import '../widgets/inventory_units_confirm_dialog.dart';
import '../widgets/inventory_units_list_card.dart';
import '../widgets/inventory_units_pagination_bar.dart';
import '../widgets/inventory_units_row_actions.dart';
import '../widgets/inventory_units_table.dart';
import '../widgets/inventory_units_toolbar.dart';

/// Units landing screen: the signed-in mart's unit-of-measure dictionary,
/// with search, filtering, pagination, and the full lifecycle of actions
/// the `/inventory/units` endpoints expose (add, edit, remove).
///
/// Rendered as a branch of [AdminShellScreen] — no [Scaffold]/`AppBar` of
/// its own, those live on the shell.
class InventoryUnitsScreen extends ConsumerStatefulWidget {
  const InventoryUnitsScreen({super.key});

  @override
  ConsumerState<InventoryUnitsScreen> createState() => _InventoryUnitsScreenState();
}

class _InventoryUnitsScreenState extends ConsumerState<InventoryUnitsScreen> {
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

  InventoryUnitsController get _controller =>
      ref.read(inventoryUnitsControllerProvider.notifier);

  Future<void> _addUnit() async {
    final result = await context.push<bool>(Routes.inventoryUnitNew);
    if (result == true && mounted) {
      AppSnackBar.success(context, 'Unit added.');
    }
  }

  Future<void> _handleRowAction(
    InventoryUnitModel unit,
    InventoryUnitRowAction action,
  ) async {
    switch (action) {
      case InventoryUnitRowAction.edit:
        final result = await context.push<bool>(
          Routes.inventoryUnitEdit(unit.id),
          extra: unit,
        );
        if (result == true && mounted) {
          AppSnackBar.success(context, 'Unit updated.');
        }
        break;
      case InventoryUnitRowAction.remove:
        final confirmed = await showInventoryUnitConfirmDialog(
          context,
          title: 'Remove unit',
          message:
              '${unit.name} (${unit.symbol}) will be removed from your '
              'unit dictionary. This cannot be undone.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (confirmed != true) return;
        try {
          final message = await _controller.removeUnit(unit.id);
          if (mounted) {
            AppSnackBar.success(
              context,
              _clearMessage(message, '${unit.name} has been removed.'),
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
    final state = ref.watch(inventoryUnitsControllerProvider);
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
              InventoryUnitsToolbar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onSearchSubmitted: (value) {
                  _searchDebouncer.cancel();
                  _controller.setSearch(value);
                  _controller.submitSearch();
                },
                measurementTypeFilter: state.measurementTypeFilter,
                onMeasurementTypeFilterChanged: _controller.setMeasurementTypeFilter,
                onAddPressed: _addUnit,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildContent(state, isWide)),
              const SizedBox(height: AppSpacing.smMd),
              InventoryUnitsPaginationBar(
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

  Widget _buildContent(InventoryUnitsState state, bool isWide) {
    if (state.isLoading) {
      return AppListSkeleton(itemCount: isWide ? 6 : 4, hasThumbnail: false);
    }

    if (state.error != null) {
      return AppEmptyState.error(message: state.error, onAction: _controller.refresh);
    }

    if (state.isEmpty) {
      return AppEmptyState(
        icon: Icons.straighten_outlined,
        title: state.search.isEmpty ? 'No units yet' : 'No results found',
        message: state.search.isEmpty
            ? 'Add your first unit to get started.'
            : 'Try a different search or clear your filters.',
        actionLabel: state.search.isEmpty ? 'Add unit' : null,
        onAction: state.search.isEmpty ? _addUnit : null,
      );
    }

    if (isWide) {
      return SingleChildScrollView(
        child: InventoryUnitsTable(
          units: state.units,
          busyIds: state.busyIds,
          onAction: _handleRowAction,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.units.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smMd),
      itemBuilder: (context, index) {
        final unit = state.units[index];
        return InventoryUnitListCard(
          unit: unit,
          isBusy: state.busyIds.contains(unit.id),
          onAction: (action) => _handleRowAction(unit, action),
        );
      },
    );
  }
}
