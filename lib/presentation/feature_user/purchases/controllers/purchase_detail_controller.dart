import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/purchase_datasource.dart';
import '../../../../data/models/models_user/purchase_model.dart';
import '../../../../providers/providers_user/purchase_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Screen-level state for one purchase's (read-only) detail page.
class PurchaseDetailState {
  const PurchaseDetailState({
    required this.isLoading,
    required this.error,
    required this.purchase,
  });

  factory PurchaseDetailState.initial() =>
      const PurchaseDetailState(isLoading: true, error: null, purchase: null);

  final bool isLoading;
  final String? error;
  final PurchaseDetailModel? purchase;

  PurchaseDetailState copyWith({
    bool? isLoading,
    String? error,
    PurchaseDetailModel? purchase,
  }) {
    return PurchaseDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      purchase: purchase ?? this.purchase,
    );
  }
}

/// Owns one purchase's detail page: just loading the record — a purchase
/// is immutable once recorded (the backend exposes no edit/remove), so
/// there's nothing else for this controller to do.
///
/// One instance per purchase id — `purchaseId` is fixed for the notifier's
/// lifetime (see the `.family` provider below).
class PurchaseDetailController extends Notifier<PurchaseDetailState> {
  PurchaseDetailController(this.purchaseId);

  final int purchaseId;

  @override
  PurchaseDetailState build() {
    Future.microtask(refresh);
    return PurchaseDetailState.initial();
  }

  PurchaseRemoteDataSource get _dataSource =>
      ref.read(purchaseRemoteDataSourceProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final purchase = await _dataSource.getById(purchaseId);
      state = state.copyWith(isLoading: false, purchase: purchase);
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

/// `autoDispose.family`: one instance per purchase id, disposed as soon as
/// its detail page unmounts — see `vendorDetailControllerProvider` for why
/// these screens don't keep session-scoped state alive past their
/// watchers.
final purchaseDetailControllerProvider = NotifierProvider.autoDispose
    .family<PurchaseDetailController, PurchaseDetailState, int>(
      PurchaseDetailController.new,
    );
