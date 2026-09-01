import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/staff_datasource.dart';
import '../../../../data/models/models_user/staff_model.dart';
import '../../../../providers/providers_user/staff_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Sentinel so [StaffManagementState.copyWith] can tell "leave a filter
/// alone" apart from "set it to null" (clearing the filter is a real state
/// the screen needs to reach).
const _unset = Object();

/// Screen-level state for staff management: the current page of staff, the
/// active search/filters, pagination, which rows have an action in flight,
/// and the roles this admin may assign.
///
/// A flat data class with [copyWith] rather than a sealed-variant style —
/// see `AdminManagementState` for why (many independent facets can all be
/// true at once here, which a sealed hierarchy would force into awkward
/// combined variants).
class StaffManagementState {
  const StaffManagementState({
    required this.staff,
    required this.isLoading,
    required this.error,
    required this.search,
    required this.roleFilter,
    required this.statusFilter,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.busyIds,
    required this.assignableRoles,
  });

  factory StaffManagementState.initial() => const StaffManagementState(
        staff: [],
        isLoading: true,
        error: null,
        search: '',
        roleFilter: null,
        statusFilter: null,
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
        assignableRoles: [],
      );

  final List<StaffModel> staff;

  /// True while fetching the list (first load, refresh, page change, or a
  /// new search/filter). The screen shows a skeleton for this, not a
  /// spinner over stale data — a page navigation shouldn't flash content.
  final bool isLoading;

  /// Set when the list failed to load. Row-level action failures (retire,
  /// reset password, …) are surfaced by the screen via try/catch around the
  /// controller call instead — this field is only ever about the list.
  final String? error;

  final String search;
  final StaffRole? roleFilter;
  final StaffStatus? statusFilter;

  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  /// Staff ids with a retire/reset-password call in flight, so the row can
  /// show its own inline spinner instead of blocking the page.
  final Set<String> busyIds;

  /// The roles this admin may assign to staff — populated once on load, used
  /// by the hire/edit form's role picker. Empty until that call resolves.
  final List<StaffRole> assignableRoles;

  bool get isEmpty => !isLoading && error == null && staff.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 1;

  StaffManagementState copyWith({
    List<StaffModel>? staff,
    bool? isLoading,
    Object? error = _unset,
    String? search,
    Object? roleFilter = _unset,
    Object? statusFilter = _unset,
    int? pageNumber,
    int? pageSize,
    int? totalPages,
    int? totalElements,
    bool? isLast,
    Set<String>? busyIds,
    List<StaffRole>? assignableRoles,
  }) {
    return StaffManagementState(
      staff: staff ?? this.staff,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      search: search ?? this.search,
      roleFilter:
          identical(roleFilter, _unset) ? this.roleFilter : roleFilter as StaffRole?,
      statusFilter: identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as StaffStatus?,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLast: isLast ?? this.isLast,
      busyIds: busyIds ?? this.busyIds,
      assignableRoles: assignableRoles ?? this.assignableRoles,
    );
  }
}

/// Owns the staff-management screen's data: loading/paging/filtering the
/// staff list, the assignable-roles lookup, and every mutation (hire, edit,
/// retire, reset password).
///
/// Mutation methods rethrow [ApiException] rather than storing it in
/// [StaffManagementState.error] — each is triggered from a specific row or
/// dialog, and the caller is best placed to show that error where the user
/// is actually looking (a snackbar, a dialog's own inline error).
class StaffManagementController extends Notifier<StaffManagementState> {
  @override
  StaffManagementState build() {
    Future.microtask(refresh);
    return StaffManagementState.initial();
  }

  StaffRemoteDataSource get _dataSource => ref.read(staffRemoteDataSourceProvider);

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

  Future<void> setRoleFilter(StaffRole? role) {
    state = state.copyWith(roleFilter: role);
    return _load(page: 1);
  }

  Future<void> setStatusFilter(StaffStatus? status) {
    state = state.copyWith(statusFilter: status);
    return _load(page: 1);
  }

  Future<void> _load({required int page}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _dataSource.list(
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        role: state.roleFilter,
        status: state.statusFilter,
        page: page,
        size: state.pageSize,
      );
      state = state.copyWith(
        staff: result.content,
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

  /// Fetches the assignable-roles list the hire/edit form's role picker
  /// needs — called from `StaffForm` itself rather than [build], so the
  /// request only ever fires when a form is actually opened, not just from
  /// visiting the staff list.
  ///
  /// A no-op once [StaffManagementState.assignableRoles] is populated —
  /// it doesn't change within a session, so repeat visits to the form
  /// shouldn't re-request it.
  ///
  /// Failures are swallowed: the form falls back to every [StaffRole] value
  /// if this never resolves, so it's not worth surfacing as a screen-level
  /// error.
  Future<void> ensureAssignableRolesLoaded() async {
    if (state.assignableRoles.isNotEmpty) return;
    try {
      final roles = await _dataSource.assignableRoles();
      state = state.copyWith(assignableRoles: roles);
    } on ApiException {
      // Swallowed — see doc comment above.
    }
  }

  Future<StaffModel> hireStaff(HireStaffRequest request) async {
    try {
      final staff = await _dataSource.hire(request);
      await refresh();
      return staff;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<StaffModel> updateStaff(String id, UpdateStaffRequest request) async {
    try {
      final staff = await _dataSource.update(id, request);
      await refresh();
      return staff;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  /// Returns the backend's own confirmation text so the caller can show
  /// exactly what happened rather than a guessed message — the staff list is
  /// also refreshed so its row reflects the new status once this completes.
  Future<String> retireStaff(String id) => _withBusy(id, () async {
        final message = await _dataSource.retire(id);
        await refresh();
        return message;
      });

  /// Returns the backend's own confirmation text — see [retireStaff].
  Future<String> resetPassword(String id, String newPassword) =>
      _withBusy(id, () => _dataSource.resetPassword(id, newPassword));

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

/// `autoDispose`: this holds one signed-in admin's staff list/search/filters
/// — it must not survive past the screen(s) that watch it, or the next
/// admin to sign in (a different mart, a different staff list) would see
/// this one's cached state for a moment before a refresh overwrote it.
/// Disposing when the last watcher (the staff screens) unmounts — which
/// happens on logout, since the whole shell is torn down — guarantees a
/// clean slate instead.
final staffManagementControllerProvider =
    NotifierProvider.autoDispose<StaffManagementController, StaffManagementState>(
  StaffManagementController.new,
);
