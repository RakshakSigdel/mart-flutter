import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/inventory_categories_datasource.dart';
import '../../../../data/datasource/datasource_user/inventory_units_datasource.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../../../../providers/providers_user/inventory_categories_provider.dart';
import '../../../../providers/providers_user/inventory_units_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Screen-level state for one category's detail page: the record itself
/// (unit policy, product count), the unit dictionary offered to the
/// "add a unit" picker, and which unit rows have a withdraw call in flight.
class InventoryCategoryDetailState {
  const InventoryCategoryDetailState({
    required this.isLoading,
    required this.error,
    required this.category,
    required this.assignableUnits,
    required this.isAssigning,
    required this.busyUnitIds,
  });

  factory InventoryCategoryDetailState.initial() => const InventoryCategoryDetailState(
        isLoading: true,
        error: null,
        category: null,
        assignableUnits: [],
        isAssigning: false,
        busyUnitIds: {},
      );

  /// True while (re)loading the category itself — a full-page load, not the
  /// unit picker's own list (see [assignableUnits]).
  final bool isLoading;

  final String? error;
  final InventoryCategoryDetailModel? category;

  /// The mart's full unit dictionary, for the "add a unit" picker. Loaded
  /// lazily — see `InventoryCategoryDetailController.ensureAssignableUnitsLoaded`.
  final List<InventoryUnitModel> assignableUnits;

  /// True while a unit permission is being granted — disables the picker's
  /// own submit control.
  final bool isAssigning;

  /// Unit ids with a withdraw call in flight.
  final Set<int> busyUnitIds;

  InventoryCategoryDetailState copyWith({
    bool? isLoading,
    String? error,
    InventoryCategoryDetailModel? category,
    List<InventoryUnitModel>? assignableUnits,
    bool? isAssigning,
    Set<int>? busyUnitIds,
  }) {
    return InventoryCategoryDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      category: category ?? this.category,
      assignableUnits: assignableUnits ?? this.assignableUnits,
      isAssigning: isAssigning ?? this.isAssigning,
      busyUnitIds: busyUnitIds ?? this.busyUnitIds,
    );
  }
}

/// Owns one category's detail page: (re)loading the record, the unit
/// picker's dictionary, and granting/withdrawing unit permissions.
///
/// One instance per category id — `categoryId` is fixed for the notifier's
/// lifetime (see the `.family` provider below), so unlike the list
/// controller this never needs to "switch" to a different category.
class InventoryCategoryDetailController extends Notifier<InventoryCategoryDetailState> {
  InventoryCategoryDetailController(this.categoryId);

  final int categoryId;

  @override
  InventoryCategoryDetailState build() {
    Future.microtask(refresh);
    return InventoryCategoryDetailState.initial();
  }

  InventoryCategoriesRemoteDataSource get _categoriesDataSource =>
      ref.read(inventoryCategoriesRemoteDataSourceProvider);

  InventoryUnitsRemoteDataSource get _unitsDataSource =>
      ref.read(inventoryUnitsRemoteDataSourceProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final category = await _categoriesDataSource.getById(categoryId);
      state = state.copyWith(isLoading: false, category: category);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Fetches the unit dictionary the "add a unit" picker needs — called
  /// from the picker itself rather than [build], so the request only ever
  /// fires when that picker actually opens. A no-op once
  /// [InventoryCategoryDetailState.assignableUnits] is populated, same
  /// reasoning as `StaffManagementController.ensureAssignableRolesLoaded`.
  Future<void> ensureAssignableUnitsLoaded() async {
    if (state.assignableUnits.isNotEmpty) return;
    try {
      final units = await _unitsDataSource.selection();
      state = state.copyWith(assignableUnits: units);
    } on ApiException {
      // Swallowed — the picker just shows an empty list if this never
      // resolves; not worth a screen-level error for a secondary action.
    }
  }

  Future<void> assignUnit(int unitId, CategoryUnitUsage usage) async {
    state = state.copyWith(isAssigning: true);
    try {
      final category = await _categoriesDataSource.assignUnit(
        categoryId,
        AssignCategoryUnitRequest(unitId: unitId, usage: usage),
      );
      state = state.copyWith(category: category);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    } finally {
      state = state.copyWith(isAssigning: false);
    }
  }

  Future<String> withdrawUnit(int unitId) async {
    state = state.copyWith(busyUnitIds: {...state.busyUnitIds, unitId});
    try {
      final message = await _categoriesDataSource.withdrawUnit(categoryId, unitId);
      await refresh();
      return message;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    } finally {
      state = state.copyWith(busyUnitIds: {...state.busyUnitIds}..remove(unitId));
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

/// `autoDispose.family`: one instance per category id, disposed as soon as
/// its detail page unmounts — see `inventoryCategoriesControllerProvider`
/// for why these screens don't keep session-scoped state alive past their
/// watchers.
final inventoryCategoryDetailControllerProvider = NotifierProvider.autoDispose
    .family<InventoryCategoryDetailController, InventoryCategoryDetailState, int>(
  InventoryCategoryDetailController.new,
);
