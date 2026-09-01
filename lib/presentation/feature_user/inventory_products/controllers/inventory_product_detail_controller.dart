import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/inventory_products_datasource.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';
import '../../../../providers/providers_user/inventory_units_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Screen-level state for one product's detail page: the record itself
/// (base info, purchase units, selling units), the unit dictionary offered
/// to the "add a unit" pickers, and which unit rows have a remove call in
/// flight.
class InventoryProductDetailState {
  const InventoryProductDetailState({
    required this.isLoading,
    required this.error,
    required this.product,
    required this.unitOptions,
    required this.busyPurchaseUnitIds,
    required this.busySellingUnitIds,
  });

  factory InventoryProductDetailState.initial() => const InventoryProductDetailState(
        isLoading: true,
        error: null,
        product: null,
        unitOptions: [],
        busyPurchaseUnitIds: {},
        busySellingUnitIds: {},
      );

  /// True while (re)loading the product itself — a full-page load, not the
  /// unit pickers' own list (see [unitOptions]).
  final bool isLoading;

  final String? error;
  final ProductDetailModel? product;

  /// The mart's full unit dictionary, for the purchase/selling-unit "add"
  /// pickers. Loaded lazily — see
  /// `InventoryProductDetailController.ensureUnitOptionsLoaded`.
  final List<InventoryUnitModel> unitOptions;

  /// Purchase/selling-unit ids with a remove call in flight.
  final Set<int> busyPurchaseUnitIds;
  final Set<int> busySellingUnitIds;

  InventoryProductDetailState copyWith({
    bool? isLoading,
    String? error,
    ProductDetailModel? product,
    List<InventoryUnitModel>? unitOptions,
    Set<int>? busyPurchaseUnitIds,
    Set<int>? busySellingUnitIds,
  }) {
    return InventoryProductDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      product: product ?? this.product,
      unitOptions: unitOptions ?? this.unitOptions,
      busyPurchaseUnitIds: busyPurchaseUnitIds ?? this.busyPurchaseUnitIds,
      busySellingUnitIds: busySellingUnitIds ?? this.busySellingUnitIds,
    );
  }
}

/// Owns one product's detail page: (re)loading the record, the unit
/// pickers' dictionary, and every purchase/selling-unit and VAT mutation.
///
/// One instance per product id — `productId` is fixed for the notifier's
/// lifetime (see the `.family` provider below), same shape as
/// `InventoryCategoryDetailController`.
///
/// Every mutation reloads the full product afterward rather than trying to
/// patch pieces of it locally — the purchase/selling-unit endpoints return
/// just the one unit they touched, not the product's other derived fields
/// (e.g. `sellingPrice`/`sellingUnitSymbol`, sourced from the default
/// selling unit), so a full reload is the only way to keep those correct.
class InventoryProductDetailController extends Notifier<InventoryProductDetailState> {
  InventoryProductDetailController(this.productId);

  final int productId;

  @override
  InventoryProductDetailState build() {
    Future.microtask(refresh);
    return InventoryProductDetailState.initial();
  }

  InventoryProductsRemoteDataSource get _dataSource =>
      ref.read(inventoryProductsRemoteDataSourceProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final product = await _dataSource.getById(productId);
      state = state.copyWith(isLoading: false, product: product);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Fetches the unit dictionary the "add a unit" pickers need — called
  /// from a picker itself rather than [build], so the request only ever
  /// fires when a picker actually opens. A no-op once
  /// [InventoryProductDetailState.unitOptions] is populated, same
  /// reasoning as `StaffManagementController.ensureAssignableRolesLoaded`.
  Future<void> ensureUnitOptionsLoaded() async {
    if (state.unitOptions.isNotEmpty) return;
    try {
      final units = await ref.read(inventoryUnitsRemoteDataSourceProvider).selection();
      state = state.copyWith(unitOptions: units);
    } on ApiException {
      // Swallowed — the picker just shows an empty list if this never
      // resolves; not worth a screen-level error for a secondary action.
    }
  }

  // ─── Purchase units ───────────────────────────────────────────────────

  Future<void> addPurchaseUnit(CreatePurchaseUnitRequest request) async {
    try {
      await _dataSource.addPurchaseUnit(productId, request);
      await refresh();
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<void> updatePurchaseUnit(
    int purchaseUnitId,
    UpdatePurchaseUnitRequest request,
  ) async {
    try {
      await _dataSource.updatePurchaseUnit(productId, purchaseUnitId, request);
      await refresh();
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<String> removePurchaseUnit(int purchaseUnitId) => _withBusy(
        purchaseUnitId,
        () => state.busyPurchaseUnitIds,
        (ids) => state = state.copyWith(busyPurchaseUnitIds: ids),
        () async {
          final message = await _dataSource.removePurchaseUnit(productId, purchaseUnitId);
          await refresh();
          return message;
        },
      );

  /// The one purchase unit with its full VAT history — proxies straight to
  /// the datasource rather than caching it in this screen's own state,
  /// since it's the VAT-history dialog's own transient concern, not
  /// something the rest of the detail page needs to react to.
  Future<ProductPurchaseUnitDetailModel> loadPurchaseUnitDetail(int purchaseUnitId) {
    return _dataSource.purchaseUnit(productId, purchaseUnitId);
  }

  /// Opens a new VAT rate and reloads the product so the purchase unit's
  /// `currentVatRate` shown in the list stays correct. Returns the fresh
  /// purchase-unit detail (with the updated history) so the VAT dialog
  /// doesn't need a second fetch.
  Future<ProductPurchaseUnitDetailModel> openVatRate(
    int purchaseUnitId,
    OpenVatRateRequest request,
  ) async {
    try {
      final detail = await _dataSource.openVatRate(productId, purchaseUnitId, request);
      await refresh();
      return detail;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  // ─── Selling units ────────────────────────────────────────────────────

  Future<void> addSellingUnit(CreateSellingUnitRequest request) async {
    try {
      await _dataSource.addSellingUnit(productId, request);
      await refresh();
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<void> updateSellingUnit(
    int sellingUnitId,
    UpdateSellingUnitRequest request,
  ) async {
    try {
      await _dataSource.updateSellingUnit(productId, sellingUnitId, request);
      await refresh();
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<String> removeSellingUnit(int sellingUnitId) => _withBusy(
        sellingUnitId,
        () => state.busySellingUnitIds,
        (ids) => state = state.copyWith(busySellingUnitIds: ids),
        () async {
          final message = await _dataSource.removeSellingUnit(productId, sellingUnitId);
          await refresh();
          return message;
        },
      );

  /// [getIds]/[setIds] read and write the current state fresh at both the
  /// start and end of [action] (rather than snapshotting the set once) so
  /// two concurrent busy operations on the same list don't clobber each
  /// other's entry in the `finally` block.
  Future<T> _withBusy<T>(
    int id,
    Set<int> Function() getIds,
    void Function(Set<int> ids) setIds,
    Future<T> Function() action,
  ) async {
    setIds({...getIds(), id});
    try {
      return await action();
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    } finally {
      setIds({...getIds()}..remove(id));
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
/// its detail page unmounts — see `inventoryProductsControllerProvider`
/// for why these screens don't keep session-scoped state alive past their
/// watchers.
final inventoryProductDetailControllerProvider = NotifierProvider.autoDispose
    .family<InventoryProductDetailController, InventoryProductDetailState, int>(
  InventoryProductDetailController.new,
);
