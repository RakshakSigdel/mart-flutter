import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_superadmin/admin_datasource.dart';
import '../../../../data/models/models_superadmin/admin_model.dart';
import '../../../../providers/providers_superadmin/admin_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Sentinel so [AdminManagementState.copyWith] can tell "leave [statusFilter]
/// alone" apart from "set it to null" (clearing the filter is a real state
/// the screen needs to reach).
const _unset = Object();

/// Screen-level state for admin management: the current page of marts, the
/// active search/filter, pagination, and which rows have an action in
/// flight.
///
/// This is a flat data class with [copyWith] rather than the sealed-variant
/// style [AuthState] uses — auth is genuinely "one mode at a time"
/// (unauthenticated XOR authenticating XOR ...), but this screen has many
/// independent facets (a loaded list AND a load error AND a busy row can
/// all be true together), which a sealed hierarchy would force into
/// awkward combined variants.
class AdminManagementState {
  const AdminManagementState({
    required this.admins,
    required this.isLoading,
    required this.error,
    required this.search,
    required this.statusFilter,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.busyIds,
    required this.isRunningMigrations,
  });

  factory AdminManagementState.initial() => const AdminManagementState(
        admins: [],
        isLoading: true,
        error: null,
        search: '',
        statusFilter: null,
        pageNumber: 0,
        pageSize: 20,
        totalPages: 0,
        totalElements: 0,
        isLast: true,
        busyIds: {},
        isRunningMigrations: false,
      );

  final List<AdminModel> admins;

  /// True while fetching the list (first load, refresh, page change, or a
  /// new search/filter). The screen shows a skeleton for this, not a
  /// spinner over stale data — a page navigation shouldn't flash content.
  final bool isLoading;

  /// Set when the list failed to load. Row-level action failures (delete,
  /// provision, …) are surfaced by the screen via try/catch around the
  /// controller call instead — this field is only ever about the list.
  final String? error;

  final String search;
  final AdminProvisioningStatus? statusFilter;

  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  /// Admin ids with a delete/reset-password/provision call in flight, so
  /// the row can show its own inline spinner instead of blocking the page.
  final Set<String> busyIds;

  final bool isRunningMigrations;

  bool get isEmpty => !isLoading && error == null && admins.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 0;

  AdminManagementState copyWith({
    List<AdminModel>? admins,
    bool? isLoading,
    Object? error = _unset,
    String? search,
    Object? statusFilter = _unset,
    int? pageNumber,
    int? pageSize,
    int? totalPages,
    int? totalElements,
    bool? isLast,
    Set<String>? busyIds,
    bool? isRunningMigrations,
  }) {
    return AdminManagementState(
      admins: admins ?? this.admins,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      search: search ?? this.search,
      statusFilter: identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as AdminProvisioningStatus?,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLast: isLast ?? this.isLast,
      busyIds: busyIds ?? this.busyIds,
      isRunningMigrations: isRunningMigrations ?? this.isRunningMigrations,
    );
  }
}

/// Owns the admin-management screen's data: loading/paging/filtering the
/// mart list, and every mutation (create, edit, retire, reset password,
/// re-provision, run migrations).
///
/// Mutation methods rethrow [ApiException] rather than storing it in
/// [AdminManagementState.error] — each is triggered from a specific row or
/// dialog, and the caller is best placed to show that error where the user
/// is actually looking (a snackbar, a dialog's own inline error).
class AdminManagementController extends Notifier<AdminManagementState> {
  @override
  AdminManagementState build() {
    Future.microtask(refresh);
    return AdminManagementState.initial();
  }

  AdminRemoteDataSource get _dataSource => ref.read(adminRemoteDataSourceProvider);

  Future<void> refresh() => _load(page: 0);

  Future<void> nextPage() {
    if (!state.hasNextPage) return Future.value();
    return _load(page: state.pageNumber + 1);
  }

  Future<void> previousPage() {
    if (!state.hasPreviousPage) return Future.value();
    return _load(page: state.pageNumber - 1);
  }

  void setSearch(String value) => state = state.copyWith(search: value);

  Future<void> submitSearch() => _load(page: 0);

  Future<void> setStatusFilter(AdminProvisioningStatus? status) {
    state = state.copyWith(statusFilter: status);
    return _load(page: 0);
  }

  Future<void> _load({required int page}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _dataSource.list(
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        provisioningStatus: state.statusFilter,
        page: page,
        size: state.pageSize,
      );
      state = state.copyWith(
        admins: result.content,
        isLoading: false,
        pageNumber: result.pageNumber,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
        isLast: result.last,
      );
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<AdminModel> createAdmin(CreateAdminRequest request) async {
    try {
      final admin = await _dataSource.create(request);
      await refresh();
      return admin;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<AdminModel> updateAdmin(String id, UpdateAdminRequest request) async {
    try {
      final admin = await _dataSource.update(id, request);
      await refresh();
      return admin;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  /// Returns the backend's own confirmation text (e.g. "Mart retired.") so
  /// the caller can show exactly what happened rather than a guessed
  /// message — the mart list is also refreshed so its row reflects the new
  /// status once this completes.
  Future<String> retireAdmin(String id) => _withBusy(id, () async {
        final message = await _dataSource.retire(id);
        await refresh();
        return message;
      });

  /// Returns the backend's own confirmation text — see [retireAdmin].
  Future<String> resetPassword(String id, String newPassword) =>
      _withBusy(id, () => _dataSource.resetPassword(id, newPassword));

  Future<void> provisionAdmin(String id) => _withBusy(id, () async {
        await _dataSource.provision(id);
        await refresh();
      });

  Future<List<String>> runMigrations() async {
    state = state.copyWith(isRunningMigrations: true);
    try {
      return await _dataSource.runMigrations();
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    } finally {
      state = state.copyWith(isRunningMigrations: false);
    }
  }

  Future<T> _withBusy<T>(String id, Future<T> Function() action) async {
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

final adminManagementControllerProvider =
    NotifierProvider<AdminManagementController, AdminManagementState>(
  AdminManagementController.new,
);
