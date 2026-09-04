import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/sale_datasource.dart';
import '../../../../data/models/models_user/sale_model.dart';
import '../../../../providers/providers_user/sale_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Sentinel so [SalesState.copyWith] can tell "leave the status/date filter
/// alone" apart from "clear it" — clearing a filter is a real state the
/// screen needs to reach.
const _unset = Object();

/// Screen-level state for the sales list: the current page of bills, the
/// active search/status/date filters, pagination, and the headline totals
/// for the same window.
class SalesState {
  const SalesState({
    required this.sales,
    required this.isLoading,
    required this.error,
    required this.search,
    required this.statusFilter,
    required this.fromFilter,
    required this.toFilter,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.totals,
    required this.isTotalsLoading,
  });

  factory SalesState.initial() => const SalesState(
    sales: [],
    isLoading: true,
    error: null,
    search: '',
    statusFilter: null,
    fromFilter: null,
    toFilter: null,
    // The backend's pages are 1-indexed (page 1 is the first page) — see
    // the same fix applied across every other list controller.
    pageNumber: 1,
    pageSize: 20,
    totalPages: 0,
    totalElements: 0,
    isLast: true,
    totals: null,
    isTotalsLoading: true,
  );

  final List<SaleModel> sales;

  /// True while fetching the list (first load, refresh, page change, or a
  /// new search/filter). The screen shows a skeleton for this, not a
  /// spinner over stale data — a page navigation shouldn't flash content.
  final bool isLoading;

  final String? error;

  final String search;
  final PaymentStatus? statusFilter;
  final DateTime? fromFilter;
  final DateTime? toFilter;

  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  /// Headline totals for the same date range as [fromFilter]/[toFilter]
  /// (all-time when both are null). `null` until the first load resolves
  /// (or forever, if it fails — see [SalesController._loadTotals]).
  final SalesTotalsModel? totals;
  final bool isTotalsLoading;

  bool get isEmpty => !isLoading && error == null && sales.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 1;

  SalesState copyWith({
    List<SaleModel>? sales,
    bool? isLoading,
    Object? error = _unset,
    String? search,
    Object? statusFilter = _unset,
    Object? fromFilter = _unset,
    Object? toFilter = _unset,
    int? pageNumber,
    int? pageSize,
    int? totalPages,
    int? totalElements,
    bool? isLast,
    Object? totals = _unset,
    bool? isTotalsLoading,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      search: search ?? this.search,
      statusFilter: identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as PaymentStatus?,
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
      totals: identical(totals, _unset)
          ? this.totals
          : totals as SalesTotalsModel?,
      isTotalsLoading: isTotalsLoading ?? this.isTotalsLoading,
    );
  }
}

/// Owns the sales screen's data: loading/paging/filtering the bill list,
/// the headline totals for the same window, and ringing up a new sale.
///
/// [createSale] rethrows [ApiException] rather than storing it in
/// [SalesState.error] — it's triggered from the create form, and that form
/// is best placed to show the error where the user is actually looking
/// (its own inline error), same reasoning as every other mutation method
/// in this app.
class SalesController extends Notifier<SalesState> {
  @override
  SalesState build() {
    Future.microtask(refresh);
    return SalesState.initial();
  }

  SaleRemoteDataSource get _dataSource =>
      ref.read(saleRemoteDataSourceProvider);

  Future<void> refresh() => Future.wait([_load(page: 1), _loadTotals()]);

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

  Future<void> setStatusFilter(PaymentStatus? status) {
    state = state.copyWith(statusFilter: status);
    return _load(page: 1);
  }

  /// Sets the date-range filter and re-runs both the list and the totals
  /// strip for the same window, so they always describe the same range.
  Future<void> setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(fromFilter: from, toFilter: to);
    return Future.wait([_load(page: 1), _loadTotals()]);
  }

  Future<void> _load({required int page}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _dataSource.list(
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        status: state.statusFilter,
        from: state.fromFilter,
        to: state.toFilter,
        page: page,
        size: state.pageSize,
      );
      state = state.copyWith(
        sales: result.content,
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

  /// Failures here are swallowed beyond signing out on a 401 — the strip
  /// just shows nothing if this never resolves; not worth a screen-level
  /// error for a secondary summary the list itself doesn't depend on.
  Future<void> _loadTotals() async {
    state = state.copyWith(isTotalsLoading: true);
    try {
      final totals = await _dataSource.totals(
        from: state.fromFilter,
        to: state.toFilter,
      );
      state = state.copyWith(isTotalsLoading: false, totals: totals);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isTotalsLoading: false);
    }
  }

  Future<SaleDetailModel> createSale(CreateSaleRequest request) async {
    try {
      final sale = await _dataSource.create(request);
      await refresh();
      return sale;
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

/// `autoDispose`: this holds one signed-in mart's sales list. It must not
/// survive past the screen(s) that watch it — see
/// `purchasesControllerProvider` for the same reasoning.
final salesControllerProvider =
    NotifierProvider.autoDispose<SalesController, SalesState>(
      SalesController.new,
    );
