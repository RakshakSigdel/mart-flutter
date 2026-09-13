import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sts_retail/core/network/api_exception.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/sale_model.dart';
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

  Future<void> _addSale() async {
    final result = await context.push<SaleDetailModel>(Routes.saleNew);
    if (result != null && mounted) {
      AppSnackBar.success(context, 'Sale recorded.');
      context.push(Routes.saleDetail(result.id));
    }
  }

  Future<void> _findInvoice() async {
    final invoiceController = TextEditingController();
    final invoiceNumber = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Find invoice'),
        content: AppTextField(
          controller: invoiceController,
          label: 'Invoice number',
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AppButton(
            label: 'Open invoice',
            onPressed: () =>
                Navigator.of(dialogContext).pop(invoiceController.text),
          ),
        ],
      ),
    );
    invoiceController.dispose();
    if (invoiceNumber == null || invoiceNumber.trim().isEmpty || !mounted) {
      return;
    }
    try {
      final sale = await _controller.findByInvoiceNumber(invoiceNumber);
      if (mounted) context.push(Routes.saleDetail(sale.id));
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesControllerProvider);
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
              SalesTotalsStrip(
                totals: state.totals,
                isLoading: state.isTotalsLoading,
              ),
              if (state.totals != null) const SizedBox(height: AppSpacing.md),
              SalesToolbar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onSearchSubmitted: (value) {
                  _searchDebouncer.cancel();
                  _controller.setSearch(value);
                  _controller.submitSearch();
                },
                statusFilter: state.statusFilter,
                onStatusFilterChanged: _controller.setStatusFilter,
                fromFilter: state.fromFilter,
                toFilter: state.toFilter,
                onDateRangeChanged: _controller.setDateRange,
                onFindInvoicePressed: _findInvoice,
                onAddPressed: _addSale,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildContent(state, isWide)),
              const SizedBox(height: AppSpacing.smMd),
              SalesPaginationBar(
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
      return AppEmptyState(
        icon: Icons.point_of_sale_outlined,
        title: state.search.isEmpty ? 'No sales yet' : 'No results found',
        message: state.search.isEmpty
            ? 'Ring up your first sale to get started.'
            : 'Try a different search or clear your filters.',
        actionLabel: state.search.isEmpty ? 'New sale' : null,
        onAction: state.search.isEmpty ? _addSale : null,
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
