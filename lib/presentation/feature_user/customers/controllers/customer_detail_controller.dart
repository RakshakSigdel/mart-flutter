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
  });

  factory CustomerDetailState.initial() => const CustomerDetailState(
        isLoading: true,
        error: null,
        customer: null,
      );

  final bool isLoading;
  final String? error;
  final CustomerModel? customer;

  CustomerDetailState copyWith({
    bool? isLoading,
    String? error,
    CustomerModel? customer,
  }) {
    return CustomerDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      customer: customer ?? this.customer,
    );
  }
}

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
      final customer = await _dataSource.getById(customerId);
      state = state.copyWith(isLoading: false, customer: customer);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong: $e',
      );
    }
  }

  Future<void> _handleUnauthorized(ApiException e) async {
    if (e.type == ApiFailureType.unauthorized) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

final customerDetailControllerProvider = NotifierProvider.autoDispose
    .family<CustomerDetailController, CustomerDetailState, int>(
  CustomerDetailController.new,
);
