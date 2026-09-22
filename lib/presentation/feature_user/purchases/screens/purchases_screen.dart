import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/purchase_model.dart';
import '../../../shared/widgets/section_ui.dart';
import '../controllers/purchases_controller.dart';
import '../widgets/purchase_ledger.dart';
import '../widgets/purchases_pagination_bar.dart';
import '../widgets/purchases_toolbar.dart';

/// Purchases landing screen: goods received from vendors, with search,
/// vendor/date filters, and pagination.
///
/// No edit or remove — a recorded purchase is immutable (the backend
/// exposes no `PUT`/`DELETE` for this resource), so a row's only action is
/// opening its (read-only) detail.
///
/// Rendered as a branch of [AdminShellScreen] — no [Scaffold]/`AppBar` of
/// its own, those live on the shell.
class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
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

  PurchasesController get _controller =>
      ref.read(purchasesControllerProvider.notifier);

  Future<void> _addPurchase() async {
    final result = await context.push<PurchaseDetailModel>(Routes.purchaseNew);
    if (result != null && mounted) {
      AppSnackBar.success(context, 'Purchase recorded.');
      context.push(Routes.purchaseDetail(result.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchasesControllerProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
          final gutter = AppBreakpoints.isPhone(constraints.maxWidth)
              ? AppSpacing.sm
              : AppSpacing.md;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.contentMaxWidth,
              ),
              child: Padding(
                padding: EdgeInsets.all(gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PurchasesToolbar(
                      searchController: _searchController,
                      onSearchChanged: _onSearchChanged,
                      onSearchSubmitted: (value) {
                        _searchDebouncer.cancel();
                        _controller.setSearch(value);
                        _controller.submitSearch();
                      },
                      vendorOptions: state.vendorOptions,
                      vendorFilter: state.vendorFilter,
                      onVendorFilterChanged: _controller.setVendorFilter,
                      fromFilter: state.fromFilter,
                      toFilter: state.toFilter,
                      onDateRangeChanged: _controller.setDateRange,
                      onAddPressed: _addPurchase,
                    ),
                    Expanded(child: _buildContent(state, isWide)),
                    PurchasesPaginationBar(
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
        },
      ),
    );
  }

  Widget _buildContent(PurchasesState state, bool isWide) {
    if (state.isLoading) {
      return AppListSkeleton(itemCount: isWide ? 6 : 4, hasThumbnail: false);
    }

    if (state.error != null) {
      return CenterOrScroll(
        child: AppEmptyState.error(
          message: state.error,
          onAction: _controller.refresh,
        ),
      );
    }

    if (state.isEmpty) {
      return CenterOrScroll(
        child: AppEmptyState(
          icon: Icons.receipt_long_outlined,
          title: state.search.isEmpty ? 'No purchases yet' : 'No results found',
          message: state.search.isEmpty
              ? 'Record your first purchase to get started.'
              : 'Try a different search or clear your filters.',
          actionLabel: state.search.isEmpty ? 'New purchase' : null,
          onAction: state.search.isEmpty ? _addPurchase : null,
        ),
      );
    }

    // One ledger at every width — the entries reflow rather than becoming a
    // different component on a phone.
    return PurchaseLedger(
      purchases: state.purchases,
      onOpen: (purchase) => context.push(Routes.purchaseDetail(purchase.id)),
    );
  }
}
