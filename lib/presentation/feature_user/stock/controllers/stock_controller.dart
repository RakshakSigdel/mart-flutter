import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/stock_datasource.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../../data/models/models_user/stock_model.dart';
import '../../../../providers/providers_user/inventory_categories_provider.dart';
import '../../../../providers/providers_user/stock_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Sentinel so [StockState.copyWith] can tell "leave the category filter
/// alone" apart from "set it to null" (clearing the filter is a real state
/// the screen needs to reach).
const _unset = Object();

/// Screen-level state for the stock list: the current page of levels, the
/// active search/filters, pagination, the headline overview counts, and
/// the category dictionary offered to the filter dropdown.
class StockState {
  const StockState({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.search,
    required this.categoryFilter,
    required this.lowOnly,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.categoryOptions,
    required this.overview,
    required this.isOverviewLoading,
    required this.busyIds,
  });

  factory StockState.initial() => const StockState(
    items: [],
    isLoading: true,
    error: null,
    search: '',
    categoryFilter: null,
    lowOnly: false,
    // The backend's pages are 1-indexed (page 1 is the first page) — see
    // the same fix applied across every other list controller.
    pageNumber: 1,
    pageSize: 20,
    totalPages: 0,
    totalElements: 0,
    isLast: true,
    categoryOptions: [],
    overview: null,
    isOverviewLoading: true,
    busyIds: {},
  );

  final List<StockLevelModel> items;

  /// True while fetching the list (first load, refresh, page change, or a
  /// new search/filter). The screen shows a skeleton for this, not a
  /// spinner over stale data — a page navigation shouldn't flash content.
  final bool isLoading;

  final String? error;

  final String search;
  final int? categoryFilter;
  final bool lowOnly;

  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  /// For the category filter dropdown. Loaded eagerly, same reasoning as
  /// `InventoryProductsState.categoryOptions`.
  final List<InventoryCategoryModel> categoryOptions;

  /// Headline counts shown above the list. `null` until the first load
  /// resolves (or forever, if it fails — see [StockController._loadOverview]).
  final StockOverviewModel? overview;
  final bool isOverviewLoading;

  /// Product ids with a reorder-level update in flight, so the row can
  /// show its own inline spinner instead of blocking the page.
  final Set<int> busyIds;

  bool get isEmpty => !isLoading && error == null && items.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 1;

  StockState copyWith({
    List<StockLevelModel>? items,
    bool? isLoading,
    Object? error = _unset,
    String? search,
    Object? categoryFilter = _unset,
    bool? lowOnly,
    int? pageNumber,
    int? pageSize,
    int? totalPages,
    int? totalElements,
    bool? isLast,
    List<InventoryCategoryModel>? categoryOptions,
    Object? overview = _unset,
    bool? isOverviewLoading,
    Set<int>? busyIds,
  }) {
    return StockState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      search: search ?? this.search,
      categoryFilter: identical(categoryFilter, _unset)
          ? this.categoryFilter
          : categoryFilter as int?,
      lowOnly: lowOnly ?? this.lowOnly,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLast: isLast ?? this.isLast,
      categoryOptions: categoryOptions ?? this.categoryOptions,
      overview: identical(overview, _unset)
          ? this.overview
          : overview as StockOverviewModel?,
      isOverviewLoading: isOverviewLoading ?? this.isOverviewLoading,
      busyIds: busyIds ?? this.busyIds,
    );
  }
}

/// Owns the stock screen's data: loading/paging/filtering the stock list,
/// the headline overview counts, the category filter's dictionary, and the
/// one mutation quick enough to trigger straight from a row — setting the
/// reorder level. Adjusting or writing off stock needs a fuller form (unit,
/// remark) and lives on `StockDetailController` instead.
class StockController extends Notifier<StockState> {
  @override
  StockState build() {
    Future.microtask(refresh);
    Future.microtask(_loadCategoryOptions);
    Future.microtask(_loadOverview);
    return StockState.initial();
  }

  StockRemoteDataSource get _dataSource =>
      ref.read(stockRemoteDataSourceProvider);

  Future<void> refresh() => _load(page: 1);

  Future<void> refreshOverviewAndStock() =>
      Future.wait([refresh(), _loadOverview()]);

  Future<void> clearFilters() {
    state = state.copyWith(search: '', categoryFilter: null, lowOnly: false);
    return _load(page: 1);
  }

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

  Future<void> setCategoryFilter(int? categoryId) {
    state = state.copyWith(categoryFilter: categoryId);
    return _load(page: 1);
  }

  Future<void> setLowOnly(bool value) {
    state = state.copyWith(lowOnly: value);
    return _load(page: 1);
  }

  Future<void> _load({required int page}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _dataSource.list(
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        categoryId: state.categoryFilter,
        lowOnly: state.lowOnly,
        page: page,
        size: state.pageSize,
      );
      state = state.copyWith(
        items: result.content,
        isLoading: false,
        // The page we asked for, not `result.pageNumber` — the backend's
        // own indexing for that field isn't reliable, but it always
        // returns the page we requested, so tracking that directly
        // sidesteps the ambiguity.
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

  /// Feeds the toolbar's category filter. Failures are swallowed: the
  /// filter just shows no categories if this never resolves, same
  /// reasoning as `InventoryProductsController._loadCategoryOptions`.
  Future<void> _loadCategoryOptions() async {
    try {
      final categories = await ref
          .read(inventoryCategoriesRemoteDataSourceProvider)
          .selection();
      state = state.copyWith(categoryOptions: categories);
    } on ApiException {
      // Swallowed — see doc comment above.
    }
  }

  /// Failures here are swallowed beyond signing out on a 401 — the strip
  /// just shows nothing if this never resolves; not worth a screen-level
  /// error for a secondary summary the list itself doesn't depend on.
  Future<void> _loadOverview() async {
    state = state.copyWith(isOverviewLoading: true);
    try {
      final overview = await _dataSource.overview();
      state = state.copyWith(isOverviewLoading: false, overview: overview);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isOverviewLoading: false);
    }
  }

  /// Returns the updated level so the caller can show its new reorder
  /// figure without waiting on a full list refresh, which still happens
  /// underneath for the row's own display.
  Future<StockLevelModel> setReorderLevel(int productId, double reorderLevel) =>
      _withBusy(productId, () async {
        final level = await _dataSource.setReorderLevel(
          productId,
          UpdateReorderLevelRequest(reorderLevel: reorderLevel),
        );
        await refresh();
        return level;
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

/// `autoDispose`: this holds one signed-in mart's stock list. It must not
/// survive past the screen(s) that watch it — see
/// `inventoryProductsControllerProvider` for the same reasoning.
final stockControllerProvider =
    NotifierProvider.autoDispose<StockController, StockState>(
      StockController.new,
    );
