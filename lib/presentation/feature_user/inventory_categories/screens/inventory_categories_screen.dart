import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../shared/widgets/section_ui.dart';
import '../controllers/inventory_categories_controller.dart';
import '../widgets/inventory_categories_confirm_dialog.dart';
import '../widgets/inventory_categories_list_card.dart';
import '../widgets/inventory_categories_pagination_bar.dart';
import '../widgets/inventory_categories_row_actions.dart';
import '../widgets/inventory_categories_table.dart';
import '../widgets/inventory_categories_toolbar.dart';

/// Categories landing screen: the signed-in mart's product category
/// dictionary, with search, pagination, and the full lifecycle of actions
/// the `/inventory/categories` endpoints expose (add, edit, remove, and —
/// from the detail screen — unit-permission management).
///
/// Rendered as a branch of [AdminShellScreen] — no [Scaffold]/`AppBar` of
/// its own, those live on the shell.
class InventoryCategoriesScreen extends ConsumerStatefulWidget {
  const InventoryCategoriesScreen({super.key});

  @override
  ConsumerState<InventoryCategoriesScreen> createState() =>
      _InventoryCategoriesScreenState();
}

class _InventoryCategoriesScreenState
    extends ConsumerState<InventoryCategoriesScreen> {
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

  InventoryCategoriesController get _controller =>
      ref.read(inventoryCategoriesControllerProvider.notifier);

  void _clearSearch() {
    _searchDebouncer.cancel();
    _searchController.clear();
    _controller.setSearch('');
    _controller.submitSearch();
  }

  Future<void> _addCategory() async {
    final result = await context.push<bool>(Routes.inventoryCategoryNew);
    if (result == true && mounted) {
      AppSnackBar.success(context, 'Category added.');
    }
  }

  Future<void> _handleRowAction(
    InventoryCategoryModel category,
    InventoryCategoryRowAction action,
  ) async {
    switch (action) {
      case InventoryCategoryRowAction.viewDetails:
        context.push(Routes.inventoryCategoryDetail(category.id));
        break;
      case InventoryCategoryRowAction.edit:
        final result = await context.push<bool>(
          Routes.inventoryCategoryEdit(category.id),
          extra: category,
        );
        if (result == true && mounted) {
          AppSnackBar.success(context, 'Category updated.');
        }
        break;
      case InventoryCategoryRowAction.remove:
        final confirmed = await showInventoryCategoryConfirmDialog(
          context,
          title: 'Remove category',
          message:
              '${category.name} will be removed. This only works while '
              'the category has no products in it.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (confirmed != true) return;
        try {
          final message = await _controller.removeCategory(category.id);
          if (mounted) {
            AppSnackBar.success(
              context,
              _clearMessage(message, '${category.name} has been removed.'),
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
    final state = ref.watch(inventoryCategoriesControllerProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: SectionPanel(
                    child: Column(
                      children: [
                        SectionPanelHeader(
                          icon: Icons.category_outlined,
                          eyebrow: 'PRODUCT CATEGORIES',
                          subtitle:
                              'Organize products and manage their allowed units',
                          trailing: IconButton(
                            tooltip: 'Refresh categories',
                            onPressed: state.isLoading
                                ? null
                                : _controller.refresh,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: InventoryCategoriesToolbar(
                            searchController: _searchController,
                            onSearchChanged: _onSearchChanged,
                            onSearchSubmitted: (value) {
                              _searchDebouncer.cancel();
                              _controller.setSearch(value);
                              _controller.submitSearch();
                            },
                            onAddPressed: _addCategory,
                            onClearSearch: _clearSearch,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: SectionPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionPanelHeader(
                    icon: Icons.format_list_bulleted_rounded,
                    eyebrow: state.search.isEmpty
                        ? 'ALL CATEGORIES'
                        : 'SEARCH RESULTS',
                    subtitle: 'Select a category to view its details and units',
                    trailing: SectionBadge(
                      label: state.isLoading
                          ? 'Loading…'
                          : '${state.totalElements} categories',
                    ),
                  ),
                  Expanded(child: _buildContent(state, isWide)),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: InventoryCategoriesPaginationBar(
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

  Widget _buildContent(InventoryCategoriesState state, bool isWide) {
    if (state.isLoading) {
      return AppListSkeleton(itemCount: isWide ? 6 : 4, hasThumbnail: true);
    }

    if (state.error != null) {
      return AppEmptyState.error(
        message: state.error,
        onAction: _controller.refresh,
      );
    }

    if (state.isEmpty) {
      return AppEmptyState(
        icon: Icons.category_outlined,
        title: state.search.isEmpty ? 'No categories yet' : 'No results found',
        message: state.search.isEmpty
            ? 'Add your first category to get started.'
            : 'Try a different search.',
        actionLabel: state.search.isEmpty ? 'Add category' : 'Clear search',
        onAction: state.search.isEmpty ? _addCategory : _clearSearch,
      );
    }

    if (isWide) {
      return SingleChildScrollView(
        child: InventoryCategoriesTable(
          categories: state.categories,
          busyIds: state.busyIds,
          onAction: _handleRowAction,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.smMd),
      itemCount: state.categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smMd),
      itemBuilder: (context, index) {
        final category = state.categories[index];
        return InventoryCategoryListCard(
          category: category,
          isBusy: state.busyIds.contains(category.id),
          onAction: (action) => _handleRowAction(category, action),
        );
      },
    );
  }
}
