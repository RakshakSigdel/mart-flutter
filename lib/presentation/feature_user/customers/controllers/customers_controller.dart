import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_user/customer_datasource.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../../../../providers/providers_user/customer_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

const _unset = Object();

class CustomersState {
  const CustomersState({
    required this.customers,
    required this.isLoading,
    required this.error,
    required this.search,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.busyIds,
  });

  factory CustomersState.initial() => const CustomersState(
    customers: [],
    isLoading: true,
    error: null,
    search: '',
    pageNumber: 1,
    pageSize: 20,
    totalPages: 0,
    totalElements: 0,
    isLast: true,
    busyIds: {},
  );

  final List<CustomerModel> customers;
  final bool isLoading;
  final String? error;
  final String search;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isLast;
  final Set<int> busyIds;

  bool get isEmpty => !isLoading && error == null && customers.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 1;

  CustomersState copyWith({
    List<CustomerModel>? customers,
    bool? isLoading,
    Object? error = _unset,
    String? search,
    int? pageNumber,
    int? pageSize,
    int? totalPages,
    int? totalElements,
    bool? isLast,
    Set<int>? busyIds,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      search: search ?? this.search,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLast: isLast ?? this.isLast,
      busyIds: busyIds ?? this.busyIds,
    );
  }
}

class CustomersController extends Notifier<CustomersState> {
  @override
  CustomersState build() {
    Future.microtask(refresh);
    return CustomersState.initial();
  }

  CustomerRemoteDataSource get _dataSource =>
      ref.read(customerRemoteDataSourceProvider);

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

  Future<void> _load({required int page}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _dataSource.list(
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        page: page,
        size: state.pageSize,
      );
      state = state.copyWith(
        customers: result.content,
        isLoading: false,
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

  Future<CustomerModel> createCustomer(UpsertCustomerRequest request) async {
    try {
      final customer = await _dataSource.create(request);
      await refresh();
      return customer;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<CustomerModel> updateCustomer(
    int id,
    UpsertCustomerRequest request,
  ) async {
    try {
      final customer = await _dataSource.update(id, request);
      await refresh();
      return customer;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  Future<String> removeCustomer(int id) => _withBusy(id, () async {
    final message = await _dataSource.remove(id);
    await refresh();
    return message;
  });

  Future<T> _withBusy<T>(int id, Future<T> Function() action) async {
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

  Future<void> _handleUnauthorized(ApiException e) async {
    if (e.type == ApiFailureType.unauthorized) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

final customersControllerProvider =
    NotifierProvider.autoDispose<CustomersController, CustomersState>(
      CustomersController.new,
    );
