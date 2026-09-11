import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../controllers/customers_controller.dart';
import '../widgets/customer_row_actions.dart';
import '../widgets/customers_confirm_dialog.dart';
import '../widgets/customers_list_card.dart';
import '../widgets/customers_pagination_bar.dart';
import '../widgets/customers_table.dart';
import '../widgets/customers_toolbar.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  final _searchDebouncer = Debouncer();

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _controller.setSearch(value);
    if (value.trim().length < 2 && value.isNotEmpty) {
      _searchDebouncer.cancel();
      return;
    }
    _searchDebouncer.run(_controller.submitSearch);
  }

  CustomersController get _controller =>
      ref.read(customersControllerProvider.notifier);

  Future<void> _addCustomer() async {
    final result = await context.push<bool>(Routes.customerNew);
    if (result == true && mounted) {
      AppSnackBar.success(context, 'Customer added.');
    }
  }

  Future<void> _handleRowAction(
    CustomerModel customer,
    CustomerRowAction action,
  ) async {
    switch (action) {
      case CustomerRowAction.viewDetails:
        context.push(Routes.customerDetail(customer.id));
        break;
      case CustomerRowAction.edit:
        final result = await context.push<bool>(
          Routes.customerEdit(customer.id),
          extra: customer,
        );
        if (result == true && mounted) {
          AppSnackBar.success(context, 'Customer updated.');
        }
        break;
      case CustomerRowAction.remove:
        final confirmed = await showCustomerConfirmDialog(
          context,
          title: 'Remove customer',
          message:
              '${customer.name} will be removed. This only works while nothing '
              'is recorded against them.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (confirmed != true) return;
        try {
          final message = await _controller.removeCustomer(customer.id);
          if (mounted) {
            AppSnackBar.success(
              context,
              _clearMessage(message, '${customer.name} has been removed.'),
            );
          }
        } on ApiException catch (e) {
          if (mounted) AppSnackBar.error(context, e.message);
        }
        break;
    }
  }

  static String _clearMessage(String backendMessage, String fallback) =>
      backendMessage.trim().isEmpty ? fallback : backendMessage;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersControllerProvider);
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
              CustomersToolbar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onSearchSubmitted: (value) {
                  _searchDebouncer.cancel();
                  _controller.setSearch(value);
                  _controller.submitSearch();
                },
                onAddPressed: _addCustomer,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildContent(state, isWide)),
              const SizedBox(height: AppSpacing.smMd),
              CustomersPaginationBar(
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

  Widget _buildContent(CustomersState state, bool isWide) {
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
        icon: Icons.people_outline,
        title: state.search.isEmpty ? 'No customers yet' : 'No results found',
        message: state.search.isEmpty
            ? 'Add your first customer to get started.'
            : 'Try a different search.',
        actionLabel: state.search.isEmpty ? 'Add customer' : null,
        onAction: state.search.isEmpty ? _addCustomer : null,
      );
    }

    if (isWide) {
      return SingleChildScrollView(
        child: CustomersTable(
          customers: state.customers,
          busyIds: state.busyIds,
          onAction: _handleRowAction,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.customers.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smMd),
      itemBuilder: (context, index) {
        final customer = state.customers[index];
        return CustomerListCard(
          customer: customer,
          isBusy: state.busyIds.contains(customer.id),
          onAction: (action) => _handleRowAction(customer, action),
        );
      },
    );
  }
}
