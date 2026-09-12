import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/customer_datasource.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../../../../providers/providers_user/customer_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

class CustomerDetailState {
  const CustomerDetailState({
    required this.isLoading,
    required this.error,
    required this.customer,
    required this.outstanding,
  });

  factory CustomerDetailState.initial() => const CustomerDetailState(
    isLoading: true,
    error: null,
    customer: null,
    outstanding: null,
  );

  final bool isLoading;
  final String? error;
  final CustomerModel? customer;
  final CustomerOutstandingModel? outstanding;

  CustomerDetailState copyWith({
    bool? isLoading,
    String? error,
    CustomerModel? customer,
    Object? outstanding = _unset,
  }) {
    return CustomerDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      customer: customer ?? this.customer,
      outstanding: identical(outstanding, _unset)
          ? this.outstanding
          : outstanding as CustomerOutstandingModel?,
    );
  }
}

const _unset = Object();

class CustomerDetailController extends Notifier<CustomerDetailState> {
  CustomerDetailController(this.customerId);

  final int customerId;

  @override
  CustomerDetailState build() {
    Future.microtask(refresh);
    return CustomerDetailState.initial();
  }

  CustomerRemoteDataSource get _dataSource =>
      ref.read(customerRemoteDataSourceProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _dataSource.getById(customerId),
        _dataSource.outstanding(customerId),
      ]);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        customer: results[0] as CustomerModel,
        outstanding: results[1] as CustomerOutstandingModel,
      );
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong: $e',
      );
    }
  }

  Future<CustomerSettlementModel> settle(
    SettleCustomerCreditRequest request,
  ) async {
    try {
      final settlement = await _dataSource.settle(customerId, request);
      await refresh();
      return settlement;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<void> _handleUnauthorized(ApiException e) async {
    if (e.type == ApiFailureType.unauthorized && ref.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

final customerDetailControllerProvider = NotifierProvider.autoDispose
    .family<CustomerDetailController, CustomerDetailState, int>(
      CustomerDetailController.new,
    );
