import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/inventory_categories_datasource.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../../providers/providers_user/inventory_categories_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';
import '../../inventory_products/controllers/inventory_products_controller.dart';

/// Sentinel so [InventoryCategoriesState.copyWith] can tell "leave [error]
/// alone" apart from "clear it" — clearing is a real state the screen needs
/// to reach.
const _unset = Object();

/// Screen-level state for the categories list: the current page, the active
/// search, pagination, and which rows have an action in flight.
///
/// A flat data class with [copyWith] rather than a sealed-variant style —
/// see `AdminManagementState` for why (many independent facets can all be
/// true at once here, which a sealed hierarchy would force into awkward
/// combined variants).
class InventoryCategoriesState {
  const InventoryCategoriesState({
    required this.categories,
    required this.isLoading,
    required this.error,
    required this.search,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.busyIds,
  });

  factory InventoryCategoriesState.initial() => const InventoryCategoriesState(
    categories: [],
    isLoading: true,
    error: null,
    search: '',
    // The backend's pages are 1-indexed (page 1 is the first page) — a
    // request for page 0 silently gets clamped to page 1 there, so
    // starting our own counter at 0 meant "next page" only ever asked
    // for page 1 again instead of advancing to page 2.
    pageNumber: 1,
    pageSize: 20,
    totalPages: 0,
    totalElements: 0,
    isLast: true,
    busyIds: {},
  );

  final List<InventoryCategoryModel> categories;

  /// True while fetching the list (first load, refresh, page change, or a
  /// new search). The screen shows a skeleton for this, not a spinner over
  /// stale data — a page navigation shouldn't flash content.
  final bool isLoading;

  /// Set when the list failed to load. Row-level action failures (remove)
  /// are surfaced by the screen via try/catch around the controller call
  /// instead — this field is only ever about the list.
  final String? error;

  final String search;

  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  /// Category ids with a remove call in flight, so the row can show its own
  /// inline spinner instead of blocking the page.
  final Set<int> busyIds;

  bool get isEmpty => !isLoading && error == null && categories.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 1;

  InventoryCategoriesState copyWith({
    List<InventoryCategoryModel>? categories,
    bool? isLoading,
    Object? error = _unset,
    String? search,
    int? pageNumber,
    int? pageSize,
    int? totalPages,
    int? totalElements,
    bool? isLast,
    Set<int>? busyIds,
  }) {
    return InventoryCategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      search: search ?? this.search,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLast: isLast ?? this.isLast,
      busyIds: busyIds ?? this.busyIds,
    );
  }
}

/// Owns the categories screen's data: loading/paging/searching the category
/// list, and create/edit/remove. Unit-policy management (assign/withdraw,
/// product count) belongs to one category at a time and lives in
/// `InventoryCategoryDetailController` instead.
///
/// Mutation methods rethrow [ApiException] rather than storing it in
/// [InventoryCategoriesState.error] — each is triggered from a specific row
/// or form, and the caller is best placed to show that error where the user
/// is actually looking (a snackbar, a form's own inline error).
class InventoryCategoriesController extends Notifier<InventoryCategoriesState> {
  @override
  InventoryCategoriesState build() {
    Future.microtask(refresh);
    return InventoryCategoriesState.initial();
  }

  InventoryCategoriesRemoteDataSource get _dataSource =>
      ref.read(inventoryCategoriesRemoteDataSourceProvider);

  Future<void> refresh() => _load(page: 1);

  Future<void> nextPage() {
    if (!state.hasNextPage) return Future.value();
    return _load(page: state.pageNumber + 1);
  }

  Future<void> previousPage() {
    if (!state.hasPreviousPage) return Future.value();
    return _load(page: state.pageNumber - 1);
  }

  void setSearch(String value) => state = state.copyWith(search: value);

  Future<void> submitSearch() => _load(page: 1);

  Future<void> _load({required int page}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _dataSource.list(
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        page: page,
        size: state.pageSize,
      );
      state = state.copyWith(
        categories: result.content,
        isLoading: false,
        // The page we asked for, not `result.pageNumber` — the backend's
        // own indexing for that field isn't reliable (see the comment on
        // `pageNumber` in `initial()`), but it always returns the page we
        // requested, so tracking that directly sidesteps the ambiguity.
        pageNumber: page,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
        isLast: result.last,
      );
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<InventoryCategoryModel> createCategory(
    UpsertInventoryCategoryRequest request,
  ) async {
    try {
      final category = await _dataSource.create(request);
      await refresh();
      // The product form's category picker is cached by its controller.
      // Recreate that controller so a category added here is immediately
      // available when the user switches to Products.
      ref.invalidate(inventoryProductsControllerProvider);
      return category;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<InventoryCategoryModel> updateCategory(
    int id,
    UpsertInventoryCategoryRequest request,
  ) async {
    try {
      final category = await _dataSource.update(id, request);
      await refresh();
      ref.invalidate(inventoryProductsControllerProvider);
      return category;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  /// Returns the backend's own confirmation text so the caller can show
  /// exactly what happened rather than a guessed message — the category
  /// list is also refreshed so the removed row disappears once this
  /// completes.
  Future<String> removeCategory(int id) => _withBusy(id, () async {
    final message = await _dataSource.remove(id);
    await refresh();
    ref.invalidate(inventoryProductsControllerProvider);
    return message;
  });

  Future<T> _withBusy<T>(int id, Future<T> Function() action) async {
    state = state.copyWith(busyIds: {...state.busyIds, id});
    try {
      return await action();
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    } finally {
      state = state.copyWith(busyIds: {...state.busyIds}..remove(id));
    }
  }

  /// A 401 means the session is dead — sign out everywhere rather than
  /// leaving this screen the only place that noticed. `routerProvider`'s
  /// redirect reacts to the resulting state change and sends the user back
  /// to login on its own.
  Future<void> _handleUnauthorized(ApiException e) async {
    if (e.type == ApiFailureType.unauthorized) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

/// `autoDispose`: this holds one signed-in mart's category list. It must
/// not survive past the screen(s) that watch it — see
/// `inventoryUnitsControllerProvider` for the same reasoning (and the bug
/// it was fixing).
final inventoryCategoriesControllerProvider =
    NotifierProvider.autoDispose<
      InventoryCategoriesController,
      InventoryCategoriesState
    >(InventoryCategoriesController.new);
