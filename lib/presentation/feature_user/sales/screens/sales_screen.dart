import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../shared/widgets/section_ui.dart';
import '../controllers/sales_controller.dart';
import '../widgets/sale_list_card.dart';
import '../widgets/sales_pagination_bar.dart';
import '../widgets/sales_table.dart';
import '../widgets/sales_toolbar.dart';
import '../widgets/sales_totals_strip.dart';

/// Sales landing screen: bills rung up at this mart, with search, payment-
/// status/date filters, pagination, and the headline totals for the same
/// window.
///
/// No edit or remove — a rung-up bill is immutable apart from taking a
/// payment against it, which lives on the detail screen. A row's only
/// action here is opening that detail.
///
/// Rendered as a branch of [AdminShellScreen] — no [Scaffold]/`AppBar` of
/// its own, those live on the shell.
class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
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

  SalesController get _controller => ref.read(salesControllerProvider.notifier);

  void _openMakeBill() => context.go(Routes.pos);

  void _clearFilters() {
    _searchDebouncer.cancel();
    _searchController.clear();
    _controller.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesControllerProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionPanel(
                      child: Column(
                        children: [
                          SectionPanelHeader(
                            icon: Icons.receipt_long_outlined,
                            eyebrow: 'SALES HISTORY',
                            subtitle:
                                'Find a bill, review payments, and open sale details',
                            trailing: IconButton(
                              tooltip: 'Refresh sales',
                              onPressed: state.isLoading
                                  ? null
                                  : _controller.refresh,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'SALES OVERVIEW · ${state.fromFilter == null && state.toFilter == null ? 'ALL TIME' : 'SELECTED DATES'}',
                                  style: AppTypography.eyebrow,
                                ),
                                const SizedBox(height: AppSpacing.smMd),
                                SalesTotalsStrip(
                                  totals: state.totals,
                                  isLoading: state.isTotalsLoading,
                                ),
                                if (state.totals != null)
                                  const SizedBox(height: AppSpacing.md),
                                SalesToolbar(
                                  searchController: _searchController,
                                  onSearchChanged: _onSearchChanged,
                                  onSearchSubmitted: (value) {
                                    _searchDebouncer.cancel();
                                    _controller.setSearch(value);
                                    _controller.submitSearch();
                                  },
                                  statusFilter: state.statusFilter,
                                  onStatusFilterChanged:
                                      _controller.setStatusFilter,
                                  fromFilter: state.fromFilter,
                                  toFilter: state.toFilter,
                                  onDateRangeChanged: _controller.setDateRange,
                                  onAddPressed: _openMakeBill,
                                  onClearFilters: _clearFilters,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ],
            body: SectionPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionPanelHeader(
                    icon: Icons.format_list_bulleted_rounded,
                    eyebrow: 'BILLS',
                    subtitle: 'Select a bill to view its details',
                    trailing: SectionBadge(
                      label: state.isLoading
                          ? 'Loading…'
                          : '${state.totalElements} bills',
                    ),
                  ),
                  Expanded(child: _buildContent(state, isWide)),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: SalesPaginationBar(
                      pageNumber: state.pageNumber,
                      totalPages: state.totalPages,
                      totalElements: state.totalElements,
                      hasPrevious: !state.isLoading && state.hasPreviousPage,
                      hasNext: !state.isLoading && state.hasNextPage,
                      onPrevious: _controller.previousPage,
                      onNext: _controller.nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(SalesState state, bool isWide) {
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
      final hasFilters =
          state.search.isNotEmpty ||
          state.statusFilter != null ||
          state.fromFilter != null ||
          state.toFilter != null;
      return AppEmptyState(
        icon: Icons.point_of_sale_outlined,
        title: hasFilters ? 'No matching bills' : 'No sales yet',
        message: !hasFilters
            ? 'Ring up your first sale to get started.'
            : 'Try a different search or clear your filters.',
        actionLabel: hasFilters ? 'Clear filters' : 'Make bill',
        onAction: hasFilters ? _clearFilters : _openMakeBill,
      );
    }

    if (isWide) {
      return SingleChildScrollView(
        child: SalesTable(
          sales: state.sales,
          onTap: (sale) => context.push(Routes.saleDetail(sale.id)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.smMd),
      itemCount: state.sales.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smMd),
      itemBuilder: (context, index) {
        final sale = state.sales[index];
        return SaleListCard(
          sale: sale,
          onTap: () => context.push(Routes.saleDetail(sale.id)),
        );
      },
    );
  }
}
