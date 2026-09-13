import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_user/customer_model.dart';

class CustomerRemoteDataSource {
  CustomerRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResponse<CustomerModel>> list({
    String? search,
    int page = 1,
    int size = 20,
    String? sortBy,
    String? sortDirection,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/customers',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'size': size,
          if (sortBy != null) 'sortBy': sortBy,
          if (sortDirection != null) 'sortDirection': sortDirection,
        },
      );
      return await _unwrap(
        response.data,
        (raw) => PageResponse<CustomerModel>.fromJson(
          raw as Map<String, dynamic>,
          CustomerModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<CustomerModel>> selection() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/customers/selection',
      );
      return await _unwrap(
        response.data,
        (raw) => (raw as List<dynamic>)
            .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerModel> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/customers/$id');
      return await _unwrap(
        response.data,
        (raw) => CustomerModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerOutstandingModel> outstanding(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/customers/$id/outstanding',
      );
      return await _unwrap(
        response.data,
        (raw) => CustomerOutstandingModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerSettlementModel> settle(
    int id,
    SettleCustomerCreditRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/customers/$id/settle',
        data: request.toJson(),
      );
      return await _unwrap(
        response.data,
        (raw) => CustomerSettlementModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerModel> create(UpsertCustomerRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/customers',
        data: request.toJson(),
      );
      return await _unwrap(
        response.data,
        (raw) => CustomerModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CustomerModel> update(int id, UpsertCustomerRequest request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/customers/$id',
        data: request.toJson(),
      );
      return await _unwrap(
        response.data,
        (raw) => CustomerModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> remove(int id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/customers/$id',
      );
      return await _unwrap(response.data, (raw) => raw as String);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  T _unwrap<T>(Map<String, dynamic>? json, T Function(dynamic raw) fromData) {
    if (json == null) {
      throw const ApiException(
        ApiFailureType.unknownResponse,
        'Unexpected response from server.',
      );
    }

    final envelope = ApiEnvelope<T>.fromJson(json, fromData);

    if (!envelope.success || envelope.data == null) {
      throw ApiException(
        ApiFailureType.badRequest,
        envelope.firstErrorMessage ?? envelope.message ?? 'Request failed.',
      );
    }

    return envelope.data as T;
  }
}
