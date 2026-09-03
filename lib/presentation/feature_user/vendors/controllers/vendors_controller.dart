import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/vendor_datasource.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../../../../providers/providers_user/vendor_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Sentinel so [VendorsState.copyWith] can tell "leave the error alone"
/// apart from "clear it" — a call that doesn't touch the error (e.g.
/// setting `busyIds`) must not silently wipe a real one.
const _unset = Object();

/// Screen-level state for the vendors list: the current page of vendors,
/// the active search, pagination, and which rows have a remove call in
/// flight.
class VendorsState {
  const VendorsState({
    required this.vendors,
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

  factory VendorsState.initial() => const VendorsState(
    vendors: [],
    isLoading: true,
    error: null,
    search: '',
    // The backend's pages are 1-indexed (page 1 is the first page) —
    // see the same fix applied across every other list controller.
    pageNumber: 1,
    pageSize: 20,
    totalPages: 0,
    totalElements: 0,
    isLast: true,
    busyIds: {},
  );

  final List<VendorModel> vendors;

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

  /// Vendor ids with a remove call in flight, so the row can show its own
  /// inline spinner instead of blocking the page.
  final Set<int> busyIds;

  bool get isEmpty => !isLoading && error == null && vendors.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 1;

  VendorsState copyWith({
    List<VendorModel>? vendors,
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
    return VendorsState(
      vendors: vendors ?? this.vendors,
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

/// Owns the vendors screen's data: loading/paging/searching the vendor
/// list and every mutation (create, edit, remove).
///
/// Mutation methods rethrow [ApiException] rather than storing it in
/// [VendorsState.error] — each is triggered from a specific row or form,
/// and the caller is best placed to show that error where the user is
/// actually looking (a snackbar, a form's own inline error).
class VendorsController extends Notifier<VendorsState> {
  @override
  VendorsState build() {
    Future.microtask(refresh);
    return VendorsState.initial();
  }

  VendorRemoteDataSource get _dataSource =>
      ref.read(vendorRemoteDataSourceProvider);

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
        vendors: result.content,
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

  Future<VendorModel> createVendor(UpsertVendorRequest request) async {
    try {
      final vendor = await _dataSource.create(request);
      await refresh();
      return vendor;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<VendorModel> updateVendor(int id, UpsertVendorRequest request) async {
    try {
      final vendor = await _dataSource.update(id, request);
      await refresh();
      return vendor;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  /// Returns the backend's own confirmation text so the caller can show
  /// exactly what happened — the vendor list is also refreshed so the
  /// removed row disappears once this completes.
  Future<String> removeVendor(int id) => _withBusy(id, () async {
    final message = await _dataSource.remove(id);
    await refresh();
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

/// `autoDispose`: this holds one signed-in mart's vendor list. It must not
/// survive past the screen(s) that watch it — see
/// `inventoryProductsControllerProvider` for the same reasoning (and the
/// bug it was fixing).
final vendorsControllerProvider =
    NotifierProvider.autoDispose<VendorsController, VendorsState>(
      VendorsController.new,
    );
