import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart'
    show formatUnitValue;
import '../controllers/inventory_products_controller.dart';
import '../widgets/inventory_products_confirm_dialog.dart';
import '../widgets/barcode_scanner_screen.dart';
import '../widgets/inventory_products_list_card.dart';
import '../widgets/inventory_products_pagination_bar.dart';
import '../widgets/inventory_products_row_actions.dart';
import '../widgets/inventory_products_table.dart';
import '../widgets/inventory_products_toolbar.dart';

/// Products landing screen: the signed-in mart's product catalog, with
/// search, filtering, pagination, and the full lifecycle of actions the
/// `/inventory/products` endpoints expose (add, edit, retire — trading
/// configuration lives on the detail screen).
///
/// Rendered as a branch of [AdminShellScreen] — no [Scaffold]/`AppBar` of
/// its own, those live on the shell.
class InventoryProductsScreen extends ConsumerStatefulWidget {
  const InventoryProductsScreen({super.key});

  @override
  ConsumerState<InventoryProductsScreen> createState() =>
      _InventoryProductsScreenState();
}

class _InventoryProductsScreenState
    extends ConsumerState<InventoryProductsScreen> {
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

  InventoryProductsController get _controller =>
      ref.read(inventoryProductsControllerProvider.notifier);

  Future<void> _addProduct() async {
    final result = await context.push<bool>(Routes.inventoryProductNew);
    if (result == true && mounted) {
      AppSnackBar.success(context, 'Product added and ready to sell.');
    }
  }

  Future<void> _findBarcode() async {
    final barcodeController = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Find barcode'),
        content: AppTextField(
          controller: barcodeController,
          label: 'Barcode',
          hint: 'Enter barcode manually',
          autofocus: true,
          textInputAction: TextInputAction.search,
          suffixIcon: Icons.qr_code_scanner_outlined,
          onSuffixTap: () async {
            final scanned = await showBarcodeScannerSheet(dialogContext);
            if (scanned != null) barcodeController.text = scanned;
          },
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AppButton(
            label: 'Find',
            onPressed: () =>
                Navigator.of(dialogContext).pop(barcodeController.text),
          ),
        ],
      ),
    );
    barcodeController.dispose();
    if (barcode == null || barcode.trim().isEmpty || !mounted) return;
    try {
      final unit = await _controller.findByBarcode(barcode);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Barcode match'),
          content: Text(
            '${unit.unit.name} (${unit.unit.symbol})\\n'
            'Selling price: ${formatMoney(unit.sellingPrice)}\\n'
            'Pack quantity: ${formatUnitValue(unit.packQuantity)}',
          ),
          actions: [
            AppButton(
              label: 'Close',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    }
  }

  Future<void> _handleRowAction(
    ProductModel product,
    InventoryProductRowAction action,
  ) async {
    switch (action) {
      case InventoryProductRowAction.viewDetails:
        context.push(Routes.inventoryProductDetail(product.id));
        break;
      case InventoryProductRowAction.edit:
        final result = await context.push<bool>(
          Routes.inventoryProductEdit(product.id),
        );
        if (result == true && mounted) {
          AppSnackBar.success(context, 'Product updated.');
        }
        break;
      case InventoryProductRowAction.retire:
        final confirmed = await showInventoryProductConfirmDialog(
          context,
          title: 'Retire product',
          message:
              '${product.name} will be retired and hidden from active listings.',
          confirmLabel: 'Retire',
          destructive: true,
        );
        if (confirmed != true) return;
        try {
          final message = await _controller.retireProduct(product.id);
          if (mounted) {
            AppSnackBar.success(
              context,
              _clearMessage(message, '${product.name} has been retired.'),
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
    final state = ref.watch(inventoryProductsControllerProvider);
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
              InventoryProductsToolbar(
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
                activeFilter: state.activeFilter,
                onActiveFilterChanged: _controller.setActiveFilter,
                onBarcodeLookupPressed: _findBarcode,
                onAddPressed: _addProduct,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildContent(state, isWide)),
              const SizedBox(height: AppSpacing.smMd),
              InventoryProductsPaginationBar(
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

  Widget _buildContent(InventoryProductsState state, bool isWide) {
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
        icon: Icons.inventory_outlined,
        title: state.search.isEmpty ? 'No products yet' : 'No results found',
        message: state.search.isEmpty
            ? 'Add your first product in a few simple steps.'
            : 'Try a different search or clear your filters.',
        actionLabel: state.search.isEmpty ? 'Quick add product' : null,
        onAction: state.search.isEmpty ? _addProduct : null,
      );
    }

    if (isWide) {
      return SingleChildScrollView(
        child: InventoryProductsTable(
          products: state.products,
          busyIds: state.busyIds,
          onAction: _handleRowAction,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.products.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smMd),
      itemBuilder: (context, index) {
        final product = state.products[index];
        return InventoryProductListCard(
          product: product,
          isBusy: state.busyIds.contains(product.id),
          onAction: (action) => _handleRowAction(product, action),
        );
      },
    );
  }
}
