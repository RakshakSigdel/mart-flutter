import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_user/purchase_model.dart';

/// The `/purchases` endpoints — goods received from vendors, and the stock
/// and balances they move.
///
/// No edit or remove — a recorded purchase is immutable (matches the
/// backend not exposing `PUT`/`DELETE` for this resource at all).
///
/// Same contract as the other remote data sources: parses the response
/// envelope and only ever throws [ApiException].
class PurchaseRemoteDataSource {
  PurchaseRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResponse<PurchaseModel>> list({
    String? search,
    int? vendorId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/purchases',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (vendorId != null) 'vendorId': vendorId,
          if (from != null) 'from': _dateOnly(from),
          if (to != null) 'to': _dateOnly(to),
          'page': page,
          'size': size,
        },
      );
      return _unwrap(
        response.data,
        (raw) => PageResponse<PurchaseModel>.fromJson(
          raw as Map<String, dynamic>,
          PurchaseModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PurchaseDetailModel> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/purchases/$id');
      return _unwrap(
        response.data,
        (raw) => PurchaseDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PurchaseDetailModel> create(CreatePurchaseRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/purchases',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => PurchaseDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static String _dateOnly(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
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
