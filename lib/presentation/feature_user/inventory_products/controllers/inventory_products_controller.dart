import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/inventory_products_datasource.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../../../../providers/providers_user/inventory_categories_provider.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';
import '../../../../providers/providers_user/inventory_units_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Sentinel so [InventoryProductsState.copyWith] can tell "leave a filter
/// alone" apart from "set it to null" (clearing the filter is a real state
/// the screen needs to reach).
const _unset = Object();

/// Screen-level state for the products list: the current page, the active
/// search/filters, pagination, which rows have an action in flight, and the
/// category/unit options the create-product form's pickers need.
///
/// A flat data class with [copyWith] rather than a sealed-variant style —
/// see `AdminManagementState` for why (many independent facets can all be
/// true at once here, which a sealed hierarchy would force into awkward
/// combined variants).
class InventoryProductsState {
  const InventoryProductsState({
    required this.products,
    required this.isLoading,
    required this.error,
    required this.search,
    required this.categoryFilter,
    required this.activeFilter,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.busyIds,
    required this.categoryOptions,
    required this.unitOptions,
  });

  factory InventoryProductsState.initial() => const InventoryProductsState(
    products: [],
    isLoading: true,
    error: null,
    search: '',
    categoryFilter: null,
    activeFilter: null,
    // The backend's pages are 1-indexed (page 1 is the first page) —
    // see the fix applied across every other list controller.
    pageNumber: 1,
    pageSize: 20,
    totalPages: 0,
    totalElements: 0,
    isLast: true,
    busyIds: {},
    categoryOptions: [],
    unitOptions: [],
  );

  final List<ProductModel> products;

  /// True while fetching the list (first load, refresh, page change, or a
  /// new search/filter). The screen shows a skeleton for this, not a
  /// spinner over stale data — a page navigation shouldn't flash content.
  final bool isLoading;

  /// Set when the list failed to load. Row-level action failures (retire)
  /// are surfaced by the screen via try/catch around the controller call
  /// instead — this field is only ever about the list.
  final String? error;

  final String search;
  final int? categoryFilter;
  final bool? activeFilter;

  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  /// Product ids with a retire call in flight, so the row can show its own
  /// inline spinner instead of blocking the page.
  final Set<int> busyIds;

  /// Categories for the toolbar's filter and the create-product form's
  /// category picker. Loaded eagerly in [InventoryProductsController.build]
  /// — unlike [unitOptions], the toolbar needs this immediately, not just
  /// when the form opens.
  final List<InventoryCategoryModel> categoryOptions;

  /// Units for the create-product form's base-unit picker. Loaded lazily —
  /// see `ensureUnitOptionsLoaded`. Empty until that call resolves.
  final List<InventoryUnitModel> unitOptions;

  bool get isEmpty => !isLoading && error == null && products.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 1;

  InventoryProductsState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    Object? error = _unset,
    String? search,
    Object? categoryFilter = _unset,
    Object? activeFilter = _unset,
    int? pageNumber,
    int? pageSize,
    int? totalPages,
    int? totalElements,
    bool? isLast,
    Set<int>? busyIds,
    List<InventoryCategoryModel>? categoryOptions,
    List<InventoryUnitModel>? unitOptions,
  }) {
    return InventoryProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      search: search ?? this.search,
      categoryFilter: identical(categoryFilter, _unset)
          ? this.categoryFilter
          : categoryFilter as int?,
      activeFilter: identical(activeFilter, _unset)
          ? this.activeFilter
          : activeFilter as bool?,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLast: isLast ?? this.isLast,
      busyIds: busyIds ?? this.busyIds,
      categoryOptions: categoryOptions ?? this.categoryOptions,
      unitOptions: unitOptions ?? this.unitOptions,
    );
  }
}

/// Owns the products screen's data: loading/paging/filtering the product
/// list, create/edit/retire, and the category/unit dictionaries the
/// create-product form's pickers need.
///
/// A single product's purchase/selling-unit trading configuration belongs
/// to one product at a time and lives in `InventoryProductDetailController`
/// instead.
///
/// Mutation methods rethrow [ApiException] rather than storing it in
/// [InventoryProductsState.error] — each is triggered from a specific row
/// or form, and the caller is best placed to show that error where the
/// user is actually looking (a snackbar, a form's own inline error).
class InventoryProductsController extends Notifier<InventoryProductsState> {
  @override
  InventoryProductsState build() {
    Future.microtask(refresh);
    // Eager, unlike `ensureUnitOptionsLoaded` below — the toolbar's own
    // category filter needs this immediately, not just the create-product
    // form, so there's no "only when a form opens" case to defer it to.
    Future.microtask(_loadCategoryOptions);
    return InventoryProductsState.initial();
  }

  InventoryProductsRemoteDataSource get _dataSource =>
      ref.read(inventoryProductsRemoteDataSourceProvider);

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

  Future<void> setCategoryFilter(int? categoryId) {
    state = state.copyWith(categoryFilter: categoryId);
    return _load(page: 1);
  }

  Future<void> setActiveFilter(bool? active) {
    state = state.copyWith(activeFilter: active);
    return _load(page: 1);
  }

  Future<void> _load({required int page}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _dataSource.list(
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        categoryId: state.categoryFilter,
        active: state.activeFilter,
        page: page,
        size: state.pageSize,
      );
      state = state.copyWith(
        products: result.content,
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

  /// Feeds the toolbar's category filter — see the comment on the
  /// `Future.microtask` call in [build] for why this is eager rather than
  /// lazy like [ensureUnitOptionsLoaded]. Failures are swallowed: the
  /// filter just shows no categories if this never resolves, which isn't
  /// worth a screen-level error over.
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

  /// Fetches the unit dictionary the create-product form's base-unit
  /// picker needs — called from the form itself rather than [build], so
  /// the request only ever fires when that form actually opens. A no-op
  /// once [InventoryProductsState.unitOptions] is populated, same
  /// reasoning as `StaffManagementController.ensureAssignableRolesLoaded`.
  Future<void> ensureUnitOptionsLoaded() async {
    if (state.unitOptions.isNotEmpty) return;
    try {
      final units = await ref
          .read(inventoryUnitsRemoteDataSourceProvider)
          .selection();
      state = state.copyWith(unitOptions: units);
    } on ApiException {
      // Swallowed — the picker just shows an empty list if this never
      // resolves; not worth a screen-level error for a secondary action.
    }
  }

  Future<ProductModel> createProduct(CreateProductRequest request) async {
    try {
      final product = await _dataSource.create(request);
      await refresh();
      return product;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<ProductModel> updateProduct(
    int id,
    UpdateProductRequest request,
  ) async {
    try {
      final product = await _dataSource.update(id, request);
      await refresh();
      return product;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  /// Returns the backend's own confirmation text so the caller can show
  /// exactly what happened rather than a guessed message — the product
  /// list is also refreshed so its row reflects the new status once this
  /// completes.
  Future<String> retireProduct(int id) => _withBusy(id, () async {
    final message = await _dataSource.retire(id);
    await refresh();
    return message;
  });

  /// Resolves a scanned barcode to the selling-unit configuration used by
  /// the till. The catalogue exposes it as a quick lookup as well.
  Future<ProductSellingUnitModel> findByBarcode(String barcode) async {
    try {
      return await _dataSource.getByBarcode(barcode.trim());
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

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

/// `autoDispose`: this holds one signed-in mart's product list. It must
/// not survive past the screen(s) that watch it — see
/// `inventoryCategoriesControllerProvider` for the same reasoning (and the
/// bug it was fixing).
final inventoryProductsControllerProvider =
    NotifierProvider.autoDispose<
      InventoryProductsController,
      InventoryProductsState
    >(InventoryProductsController.new);
