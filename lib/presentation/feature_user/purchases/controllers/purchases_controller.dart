import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/purchase_datasource.dart';
import '../../../../data/models/models_user/purchase_model.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../../../../providers/providers_user/purchase_provider.dart';
import '../../../../providers/providers_user/vendor_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Sentinel so [PurchasesState.copyWith] can tell "leave the vendor/date
/// filter alone" apart from "clear it" — clearing a filter is a real state
/// the screen needs to reach.
const _unset = Object();

/// Screen-level state for the purchases list: the current page of bills,
/// the active search/vendor/date filters, and pagination.
class PurchasesState {
  const PurchasesState({
    required this.purchases,
    required this.isLoading,
    required this.error,
    required this.search,
    required this.vendorFilter,
    required this.fromFilter,
    required this.toFilter,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.vendorOptions,
  });

  factory PurchasesState.initial() => const PurchasesState(
    purchases: [],
    isLoading: true,
    error: null,
    search: '',
    vendorFilter: null,
    fromFilter: null,
    toFilter: null,
    // The backend's pages are 1-indexed (page 1 is the first page) — see
    // the same fix applied across every other list controller.
    pageNumber: 1,
    pageSize: 20,
    totalPages: 0,
    totalElements: 0,
    isLast: true,
    vendorOptions: [],
  );

  final List<PurchaseModel> purchases;

  /// True while fetching the list (first load, refresh, page change, or a
  /// new search/filter). The screen shows a skeleton for this, not a
  /// spinner over stale data — a page navigation shouldn't flash content.
  final bool isLoading;

  final String? error;

  final String search;
  final int? vendorFilter;
  final DateTime? fromFilter;
  final DateTime? toFilter;

  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  /// For the vendor filter dropdown. Loaded eagerly, same reasoning as
  /// `InventoryProductsState.categoryOptions`.
  final List<VendorModel> vendorOptions;

  bool get isEmpty => !isLoading && error == null && purchases.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 1;

  PurchasesState copyWith({
    List<PurchaseModel>? purchases,
    bool? isLoading,
    Object? error = _unset,
    String? search,
    Object? vendorFilter = _unset,
    Object? fromFilter = _unset,
    Object? toFilter = _unset,
    int? pageNumber,
    int? pageSize,
    int? totalPages,
    int? totalElements,
    bool? isLast,
    List<VendorModel>? vendorOptions,
  }) {
    return PurchasesState(
      purchases: purchases ?? this.purchases,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      search: search ?? this.search,
      vendorFilter: identical(vendorFilter, _unset)
          ? this.vendorFilter
          : vendorFilter as int?,
      fromFilter: identical(fromFilter, _unset)
          ? this.fromFilter
          : fromFilter as DateTime?,
      toFilter: identical(toFilter, _unset)
          ? this.toFilter
          : toFilter as DateTime?,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLast: isLast ?? this.isLast,
      vendorOptions: vendorOptions ?? this.vendorOptions,
    );
  }
}

/// Owns the purchases screen's data: loading/paging/filtering the bill
/// list, and recording a new purchase.
///
/// [createPurchase] rethrows [ApiException] rather than storing it in
/// [PurchasesState.error] — it's triggered from the create form, and that
/// form is best placed to show the error where the user is actually
/// looking (its own inline error), same reasoning as every other mutation
/// method in this app.
class PurchasesController extends Notifier<PurchasesState> {
  @override
  PurchasesState build() {
    Future.microtask(refresh);
    Future.microtask(_loadVendorOptions);
    return PurchasesState.initial();
  }

  PurchaseRemoteDataSource get _dataSource =>
      ref.read(purchaseRemoteDataSourceProvider);

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

  Future<void> setVendorFilter(int? vendorId) {
    state = state.copyWith(vendorFilter: vendorId);
    return _load(page: 1);
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(fromFilter: from, toFilter: to);
    return _load(page: 1);
  }

  Future<void> _load({required int page}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _dataSource.list(
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        vendorId: state.vendorFilter,
        from: state.fromFilter,
        to: state.toFilter,
        page: page,
        size: state.pageSize,
      );
      state = state.copyWith(
        purchases: result.content,
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

  /// Feeds the toolbar's vendor filter. Failures are swallowed: the filter
  /// just shows no vendors if this never resolves, same reasoning as
  /// `InventoryProductsController._loadCategoryOptions`.
  Future<void> _loadVendorOptions() async {
    try {
      final vendors = await ref
          .read(vendorRemoteDataSourceProvider)
          .selection();
      state = state.copyWith(vendorOptions: vendors);
    } on ApiException {
      // Swallowed — see doc comment above.
    }
  }

  Future<PurchaseDetailModel> createPurchase(
    CreatePurchaseRequest request,
  ) async {
    try {
      final purchase = await _dataSource.create(request);
      await refresh();
      return purchase;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
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

/// `autoDispose`: this holds one signed-in mart's purchase list. It must
/// not survive past the screen(s) that watch it — see
/// `vendorsControllerProvider` for the same reasoning.
final purchasesControllerProvider =
    NotifierProvider.autoDispose<PurchasesController, PurchasesState>(
      PurchasesController.new,
    );
