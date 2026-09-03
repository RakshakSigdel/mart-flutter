import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/vendor_datasource.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../../../../providers/providers_user/vendor_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// One page of a vendor's ledger or purchase-history sub-list — the detail
/// screen owns two of these ([VendorDetailState.ledger]/`.history`),
/// paged independently of each other and of the vendor record itself.
class VendorSubPage<T> {
  const VendorSubPage({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.pageNumber,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
  });

  // `VendorSubPage<T>` explicit — same reasoning as the fix in
  // `PageResponse.fromJson`: the bare `VendorSubPage(...)` here relies on
  // Dart inferring `T` for this constructor call from the enclosing
  // factory's return type, which on web (DDC) can fall back to `Never`
  // instead. Since this runs immediately on `build()` — before any real
  // data arrives — a wrong binding here poisons `T` for every `copyWith`
  // call made against this object for the rest of its life, which is
  // exactly what was causing "List<X> is not a subtype of List<Never>"
  // the moment a real page of results tried to assign into `items`.
  factory VendorSubPage.initial() => VendorSubPage<T>(
    items: const [],
    isLoading: true,
    error: null,
    pageNumber: 1,
    totalPages: 0,
    totalElements: 0,
    isLast: true,
  );

  final List<T> items;
  final bool isLoading;
  final String? error;
  final int pageNumber;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  bool get isEmpty => !isLoading && error == null && items.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 1;

  VendorSubPage<T> copyWith({
    List<T>? items,
    bool? isLoading,
    String? error,
    int? pageNumber,
    int? totalPages,
    int? totalElements,
    bool? isLast,
  }) {
    return VendorSubPage<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLast: isLast ?? this.isLast,
    );
  }
}

/// Screen-level state for one vendor's detail page: the record itself, its
/// running balance, and the ledger/history sub-lists — everything the
/// backend exposes about that one vendor, all surfaced on this one screen
/// (tabs, not further navigation) since there's only ever one vendor to
/// look at here.
class VendorDetailState {
  const VendorDetailState({
    required this.isLoading,
    required this.error,
    required this.vendor,
    required this.balance,
    required this.isBalanceLoading,
    required this.ledger,
    required this.history,
    required this.isSubmitting,
  });

  factory VendorDetailState.initial() => VendorDetailState(
    isLoading: true,
    error: null,
    vendor: null,
    balance: null,
    isBalanceLoading: true,
    ledger: VendorSubPage<VendorLedgerEntryModel>.initial(),
    history: VendorSubPage<VendorHistoryModel>.initial(),
    isSubmitting: false,
  );

  /// True while (re)loading the vendor record itself — a full-page load,
  /// not the balance or either sub-list (see their own loading flags).
  final bool isLoading;

  final String? error;
  final VendorModel? vendor;

  final VendorBalanceModel? balance;
  final bool isBalanceLoading;

  final VendorSubPage<VendorLedgerEntryModel> ledger;
  final VendorSubPage<VendorHistoryModel> history;

  /// True while a settlement or manual ledger entry is being posted —
  /// disables the balance card's own action buttons/dialogs.
  final bool isSubmitting;

  VendorDetailState copyWith({
    bool? isLoading,
    String? error,
    VendorModel? vendor,
    VendorBalanceModel? balance,
    bool? isBalanceLoading,
    VendorSubPage<VendorLedgerEntryModel>? ledger,
    VendorSubPage<VendorHistoryModel>? history,
    bool? isSubmitting,
  }) {
    return VendorDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      vendor: vendor ?? this.vendor,
      balance: balance ?? this.balance,
      isBalanceLoading: isBalanceLoading ?? this.isBalanceLoading,
      ledger: ledger ?? this.ledger,
      history: history ?? this.history,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Owns one vendor's detail page: (re)loading the record, its balance, its
/// ledger/history sub-lists (each paged independently), and posting
/// settlements/manual ledger entries against it.
///
/// One instance per vendor id — `vendorId` is fixed for the notifier's
/// lifetime (see the `.family` provider below), same shape as
/// `InventoryProductDetailController`.
class VendorDetailController extends Notifier<VendorDetailState> {
  VendorDetailController(this.vendorId);

  final int vendorId;

  @override
  VendorDetailState build() {
    Future.microtask(() async {
      await refresh();
      await Future.wait([loadLedger(page: 1), loadHistory(page: 1)]);
    });
    return VendorDetailState.initial();
  }

  VendorRemoteDataSource get _dataSource =>
      ref.read(vendorRemoteDataSourceProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final vendor = await _dataSource.getById(vendorId);
      state = state.copyWith(isLoading: false, vendor: vendor);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isLoading: false, error: e.message);
      return;
    } catch (e) {
      // DIAGNOSTIC (per user request — leave the raw `$e` in place until
      // told to remove it): anything that isn't an ApiException (e.g. a
      // response shape this build doesn't expect) — surface it the same
      // way rather than leaving the page stuck on its loading skeleton
      // forever, and show the real error so a model mismatch is
      // diagnosable on-screen instead of needing a debug-console round
      // trip.
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong: $e',
      );
      return;
    }
    await _loadBalance();
  }

  /// Failures here are swallowed beyond signing out on a 401 — the balance
  /// card just shows "unavailable" if this never resolves; not worth
  /// blocking the whole page for a secondary summary the vendor record
  /// itself doesn't depend on.
  Future<void> _loadBalance() async {
    state = state.copyWith(isBalanceLoading: true);
    try {
      final balance = await _dataSource.balance(vendorId);
      state = state.copyWith(isBalanceLoading: false, balance: balance);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isBalanceLoading: false);
    } catch (_) {
      state = state.copyWith(isBalanceLoading: false);
    }
  }

  // ─── Ledger ───────────────────────────────────────────────────────────

  Future<void> loadLedger({required int page}) async {
    state = state.copyWith(
      ledger: state.ledger.copyWith(isLoading: true, error: null),
    );
    try {
      final result = await _dataSource.ledger(vendorId, page: page);
      state = state.copyWith(
        ledger: state.ledger.copyWith(
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
        ledger: state.ledger.copyWith(isLoading: false, error: e.message),
      );
    } catch (e) {
      // DIAGNOSTIC — see the note on the broad catch in `refresh`.
      state = state.copyWith(
        ledger: state.ledger.copyWith(
          isLoading: false,
          error: 'Something went wrong: $e',
        ),
      );
    }
  }

  Future<void> nextLedgerPage() {
    if (!state.ledger.hasNextPage) return Future.value();
    return loadLedger(page: state.ledger.pageNumber + 1);
  }

  Future<void> previousLedgerPage() {
    if (!state.ledger.hasPreviousPage) return Future.value();
    return loadLedger(page: state.ledger.pageNumber - 1);
  }

  // ─── History ──────────────────────────────────────────────────────────

  Future<void> loadHistory({required int page}) async {
    state = state.copyWith(
      history: state.history.copyWith(isLoading: true, error: null),
    );
    try {
      final result = await _dataSource.history(vendorId, page: page);
      state = state.copyWith(
        history: state.history.copyWith(
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
        history: state.history.copyWith(isLoading: false, error: e.message),
      );
    } catch (e) {
      // DIAGNOSTIC — see the note on the broad catch in `refresh`.
      state = state.copyWith(
        history: state.history.copyWith(
          isLoading: false,
          error: 'Something went wrong: $e',
        ),
      );
    }
  }

  Future<void> nextHistoryPage() {
    if (!state.history.hasNextPage) return Future.value();
    return loadHistory(page: state.history.pageNumber + 1);
  }

  Future<void> previousHistoryPage() {
    if (!state.history.hasPreviousPage) return Future.value();
    return loadHistory(page: state.history.pageNumber - 1);
  }

  // ─── Balance mutations ────────────────────────────────────────────────

  /// Records a payment made to the vendor, then reloads the balance and
  /// the ledger's first page so both reflect it immediately.
  Future<void> recordSettlement(double amount) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _dataSource.recordSettlement(
        vendorId,
        RecordSettlementRequest(amount: amount),
      );
      await Future.wait([_loadBalance(), loadLedger(page: 1)]);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    } catch (e) {
      // DIAGNOSTIC (per user request — leave in place until told to
      // remove it): `_loadBalance`/`loadLedger` never throw (they catch
      // everything themselves) — this only guards the settlement call
      // itself, so an unexpected error still reaches the dialog as an
      // ApiException instead of leaving it open with no message.
      throw ApiException(ApiFailureType.unknown, 'Something went wrong: $e');
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  /// Posts a manual payable/receivable against the vendor (not tied to a
  /// purchase), then reloads the balance and the ledger's first page so
  /// both reflect it immediately.
  Future<void> postLedgerEntry(
    double amount,
    VendorBalanceType balanceType,
  ) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _dataSource.postLedgerEntry(
        vendorId,
        PostVendorLedgerEntryRequest(amount: amount, balanceType: balanceType),
      );
      await Future.wait([_loadBalance(), loadLedger(page: 1)]);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    } catch (e) {
      // DIAGNOSTIC — see the note on the broad catch in `recordSettlement`.
      throw ApiException(ApiFailureType.unknown, 'Something went wrong: $e');
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

/// `autoDispose.family`: one instance per vendor id, disposed as soon as
/// its detail page unmounts — see `inventoryProductDetailControllerProvider`
/// for why these screens don't keep session-scoped state alive past their
/// watchers.
final vendorDetailControllerProvider = NotifierProvider.autoDispose
    .family<VendorDetailController, VendorDetailState, int>(
      VendorDetailController.new,
    );
