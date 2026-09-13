import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/sale_datasource.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/sale_model.dart';
import '../../../../providers/providers_user/sale_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

/// Screen-level state for one bill's detail page.
class SaleDetailState {
  const SaleDetailState({
    required this.isLoading,
    required this.error,
    required this.sale,
    required this.isSubmitting,
  });

  factory SaleDetailState.initial() => const SaleDetailState(
    isLoading: true,
    error: null,
    sale: null,
    isSubmitting: false,
  );

  final bool isLoading;
  final String? error;
  final SaleDetailModel? sale;

  /// True while a payment is being recorded — disables the "take payment"
  /// dialog's own submit control.
  final bool isSubmitting;

  SaleDetailState copyWith({
    bool? isLoading,
    String? error,
    SaleDetailModel? sale,
    bool? isSubmitting,
  }) {
    return SaleDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sale: sale ?? this.sale,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Owns one bill's detail page: loading the record and taking a payment
/// against it — the only mutation this resource has, since a rung-up bill
/// is otherwise immutable (the backend exposes no edit/remove for it).
///
/// One instance per sale id — `saleId` is fixed for the notifier's
/// lifetime (see the `.family` provider below).
class SaleDetailController extends Notifier<SaleDetailState> {
  SaleDetailController(this.saleId);

  final int saleId;

  @override
  SaleDetailState build() {
    Future.microtask(refresh);
    return SaleDetailState.initial();
  }

  SaleRemoteDataSource get _dataSource =>
      ref.read(saleRemoteDataSourceProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sale = await _dataSource.getById(saleId);
      state = state.copyWith(isLoading: false, sale: sale);
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

  Future<void> recordPayment(double amount, PaymentMethod paymentMethod) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final sale = await _dataSource.recordPayment(
        saleId,
        RecordSalePaymentRequest(amount: amount, paymentMethod: paymentMethod),
      );
      state = state.copyWith(sale: sale);
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

  /// Fetches the selected backend-rendered IRD tax invoice as PDF bytes.
  Future<List<int>> downloadTaxInvoice(TaxInvoicePaperType paperType) =>
      _dataSource.downloadTaxInvoice(saleId, paperType);

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

/// `autoDispose.family`: one instance per sale id, disposed as soon as its
/// detail page unmounts — see `vendorDetailControllerProvider` for why
/// these screens don't keep session-scoped state alive past their
/// watchers.
final saleDetailControllerProvider = NotifierProvider.autoDispose
    .family<SaleDetailController, SaleDetailState, int>(
      SaleDetailController.new,
    );
