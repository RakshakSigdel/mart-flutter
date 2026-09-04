import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_user/sale_model.dart';

/// The `/sales` endpoints — bills, the stock they move, and the payments
/// taken against them.
///
/// No edit or remove — a rung-up bill is immutable (matches the backend
/// not exposing `PUT`/`DELETE` for this resource) except for taking a
/// payment against it, which is its own endpoint.
///
/// Same contract as the other remote data sources: parses the response
/// envelope and only ever throws [ApiException].
class SaleRemoteDataSource {
  SaleRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResponse<SaleModel>> list({
    String? search,
    PaymentStatus? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sales',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null) 'status': status.apiValue,
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
          'page': page,
          'size': size,
        },
      );
      return _unwrap(
        response.data,
        (raw) => PageResponse<SaleModel>.fromJson(
          raw as Map<String, dynamic>,
          SaleModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SaleDetailModel> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/sales/$id');
      return _unwrap(
        response.data,
        (raw) => SaleDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SalesTotalsModel> totals({DateTime? from, DateTime? to}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sales/totals',
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      );
      return _unwrap(
        response.data,
        (raw) => SalesTotalsModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Not used by any screen today — implemented for completeness, same
  /// reasoning as the unpaged `/selection` endpoints elsewhere.
  Future<SaleDetailModel> getByInvoiceNumber(String invoiceNumber) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sales/by-invoice/$invoiceNumber',
      );
      return _unwrap(
        response.data,
        (raw) => SaleDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SaleDetailModel> create(CreateSaleRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sales',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => SaleDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SaleDetailModel> recordPayment(
    int id,
    RecordSalePaymentRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sales/$id/payments',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => SaleDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Parses the envelope and turns a logical failure (HTTP 200 but
  /// `success: false`) into the same [ApiException] a bad HTTP status would
  /// produce, so callers only ever handle one kind of error.
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
