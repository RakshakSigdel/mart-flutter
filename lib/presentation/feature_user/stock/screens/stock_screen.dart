import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/stock_model.dart';
import '../controllers/stock_controller.dart';
import '../widgets/stock_list_card.dart';
import '../widgets/stock_overview_strip.dart';
import '../widgets/stock_pagination_bar.dart';
import '../widgets/stock_reorder_level_dialog.dart';
import '../widgets/stock_row_actions.dart';
import '../widgets/stock_table.dart';
import '../widgets/stock_toolbar.dart';

/// Stock landing screen: on-hand quantities across the signed-in mart's
/// products, with search, category/low-stock filters, and pagination.
///
/// Adjusting, writing off, or drilling into the full movement ledger live
/// on the per-product detail screen — this list is about *finding* a
/// product, not editing its stock.
///
/// Rendered as a branch of [AdminShellScreen] — no [Scaffold]/`AppBar` of
/// its own, those live on the shell.
class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
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

  StockController get _controller => ref.read(stockControllerProvider.notifier);

  Future<void> _handleRowAction(
    StockLevelModel item,
    StockRowAction action,
  ) async {
    switch (action) {
      case StockRowAction.viewDetails:
        context.push(Routes.stockProductDetail(item.productId));
        break;
      case StockRowAction.setReorderLevel:
        final result = await showStockReorderLevelDialog(
          context,
          currentLevel: item.reorderLevel,
          onSubmit: (level) =>
              _controller.setReorderLevel(item.productId, level),
        );
        if (result == true && mounted) {
          AppSnackBar.success(context, 'Reorder level updated.');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockControllerProvider);
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
              StockOverviewStrip(
                overview: state.overview,
                isLoading: state.isOverviewLoading,
              ),
              if (state.overview != null) const SizedBox(height: AppSpacing.md),
              StockToolbar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onSearchSubmitted: (value) {
                  _searchDebouncer.cancel();
                  _controller.setSearch(value);
                  _controller.submitSearch();
                },
                categoryOptions: state.categoryOptions,
                categoryFilter: state.categoryFilter,
                onCategoryFilterChanged: _controller.setCategoryFilter,
                lowOnly: state.lowOnly,
                onLowOnlyChanged: _controller.setLowOnly,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildContent(state, isWide)),
              const SizedBox(height: AppSpacing.smMd),
              StockPaginationBar(
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

  Widget _buildContent(StockState state, bool isWide) {
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
        icon: Icons.inventory_2_outlined,
        title: state.lowOnly
            ? 'Nothing is low on stock'
            : 'No stock records yet',
        message: state.search.isEmpty
            ? 'Stock levels appear here once a product has been purchased or sold.'
            : 'Try a different search or clear your filters.',
      );
    }

    if (isWide) {
      return SingleChildScrollView(
        child: StockTable(
          items: state.items,
          busyIds: state.busyIds,
          onAction: _handleRowAction,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smMd),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return StockListCard(
          item: item,
          isBusy: state.busyIds.contains(item.productId),
          onAction: (action) => _handleRowAction(item, action),
        );
      },
    );
  }
}
