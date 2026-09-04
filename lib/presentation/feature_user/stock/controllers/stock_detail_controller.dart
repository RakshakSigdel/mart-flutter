import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/paged_sub_list.dart';
import '../../../../data/datasource/datasource_user/stock_datasource.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../../../../data/models/models_user/stock_model.dart';
import '../../../../providers/providers_user/inventory_units_provider.dart';
import '../../../../providers/providers_user/stock_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Screen-level state for one product's stock detail page: its level and
/// its movement ledger — everything the backend exposes about that one
/// product's stock, all surfaced on this one screen since there's only
/// ever one stock record per product to look at here.
class StockDetailState {
  const StockDetailState({
    required this.isLoading,
    required this.error,
    required this.level,
    required this.movements,
    required this.unitOptions,
    required this.isSubmitting,
  });

  factory StockDetailState.initial() => StockDetailState(
    isLoading: true,
    error: null,
    level: null,
    movements: PagedSubList<StockMovementModel>.initial(),
    unitOptions: const [],
    isSubmitting: false,
  );

  /// True while (re)loading the stock level itself — a full-page load, not
  /// the movements sub-list (see its own loading flag).
  final bool isLoading;

  final String? error;
  final StockLevelModel? level;

  final PagedSubList<StockMovementModel> movements;

  /// The mart's full unit dictionary, for the adjust/write-off dialogs'
  /// unit picker. Loaded lazily — see
  /// `StockDetailController.ensureUnitOptionsLoaded` — same reasoning as
  /// `InventoryProductDetailController.ensureUnitOptionsLoaded`.
  final List<InventoryUnitModel> unitOptions;

  /// True while an adjustment, write-off, or reorder-level update is being
  /// submitted — disables the action buttons/dialogs.
  final bool isSubmitting;

  StockDetailState copyWith({
    bool? isLoading,
    String? error,
    StockLevelModel? level,
    PagedSubList<StockMovementModel>? movements,
    List<InventoryUnitModel>? unitOptions,
    bool? isSubmitting,
  }) {
    return StockDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      level: level ?? this.level,
      movements: movements ?? this.movements,
      unitOptions: unitOptions ?? this.unitOptions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Owns one product's stock detail page: (re)loading its level, its
/// movement ledger (paged), and posting adjustments/write-offs/reorder-level
/// changes against it.
///
/// One instance per product id — `productId` is fixed for the notifier's
/// lifetime (see the `.family` provider below), same shape as
/// `VendorDetailController`.
class StockDetailController extends Notifier<StockDetailState> {
  StockDetailController(this.productId);

  final int productId;

  @override
  StockDetailState build() {
    Future.microtask(() async {
      await refresh();
      await loadMovements(page: 1);
    });
    return StockDetailState.initial();
  }

  StockRemoteDataSource get _dataSource =>
      ref.read(stockRemoteDataSourceProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final level = await _dataSource.getByProductId(productId);
      state = state.copyWith(isLoading: false, level: level);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> loadMovements({required int page}) async {
    state = state.copyWith(
      movements: state.movements.copyWith(isLoading: true, error: null),
    );
    try {
      final result = await _dataSource.movements(
        productId: productId,
        page: page,
      );
      state = state.copyWith(
        movements: state.movements.copyWith(
          items: result.content,
          isLoading: false,
          pageNumber: page,
          totalPages: result.totalPages,
          totalElements: result.totalElements,
          isLast: result.last,
        ),
      );
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(
        movements: state.movements.copyWith(isLoading: false, error: e.message),
      );
    } catch (_) {
      state = state.copyWith(
        movements: state.movements.copyWith(
          isLoading: false,
          error: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  /// Fetches the unit dictionary the adjust/write-off dialogs' pickers
  /// need — called from a dialog itself rather than [build], so the
  /// request only ever fires when one actually opens. A no-op once
  /// [StockDetailState.unitOptions] is populated, same reasoning as
  /// `StaffManagementController.ensureAssignableRolesLoaded`.
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

  Future<void> nextMovementsPage() {
    if (!state.movements.hasNextPage) return Future.value();
    return loadMovements(page: state.movements.pageNumber + 1);
  }

  Future<void> previousMovementsPage() {
    if (!state.movements.hasPreviousPage) return Future.value();
    return loadMovements(page: state.movements.pageNumber - 1);
  }

  /// Writes off a loss (expired, damaged, lost), then reloads the level and
  /// the movements' first page so both reflect it immediately.
  Future<void> writeOff({
    required double quantity,
    required int unitId,
    String? remark,
  }) => _submit(
    () => _dataSource.writeOff(
      RecordStockMovementRequest.writeOff(
        productId: productId,
        quantity: quantity,
        unitId: unitId,
        remark: remark,
      ),
    ),
  );

  /// Corrects the level after a physical count, then reloads the level and
  /// the movements' first page so both reflect it immediately.
  Future<void> adjust({
    required double quantity,
    required int unitId,
    required bool increase,
    String? remark,
  }) => _submit(
    () => _dataSource.adjust(
      RecordStockMovementRequest.adjustment(
        productId: productId,
        quantity: quantity,
        unitId: unitId,
        increase: increase,
        remark: remark,
      ),
    ),
  );

  Future<void> _submit(Future<StockMovementModel> Function() action) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await action();
      await Future.wait([refresh(), loadMovements(page: 1)]);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    } catch (_) {
      throw const ApiException(
        ApiFailureType.unknown,
        'Something went wrong. Please try again.',
      );
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<StockLevelModel> setReorderLevel(double reorderLevel) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final level = await _dataSource.setReorderLevel(
        productId,
        UpdateReorderLevelRequest(reorderLevel: reorderLevel),
      );
      state = state.copyWith(level: level);
      return level;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    } catch (_) {
      throw const ApiException(
        ApiFailureType.unknown,
        'Something went wrong. Please try again.',
      );
    } finally {
      state = state.copyWith(isSubmitting: false);
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

/// `autoDispose.family`: one instance per product id, disposed as soon as
/// its detail page unmounts — see `vendorDetailControllerProvider` for why
/// these screens don't keep session-scoped state alive past their
/// watchers.
final stockDetailControllerProvider = NotifierProvider.autoDispose
    .family<StockDetailController, StockDetailState, int>(
      StockDetailController.new,
    );
