import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_user/stock_model.dart';

/// The `/stock` endpoints — on-hand quantities and the movement ledger
/// behind them.
///
/// Same contract as the other remote data sources: parses the response
/// envelope and only ever throws [ApiException].
class StockRemoteDataSource {
  StockRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResponse<StockLevelModel>> list({
    String? search,
    int? categoryId,
    bool lowOnly = false,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/stock',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'categoryId': categoryId,
          'lowOnly': lowOnly,
          'page': page,
          'size': size,
        },
      );
      return _unwrap(
        response.data,
        // Explicit type argument — see the comment on `PageResponse.fromJson`
        // itself for why this shouldn't be left to inference.
        (raw) => PageResponse<StockLevelModel>.fromJson(
          raw as Map<String, dynamic>,
          StockLevelModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<StockLevelModel> getByProductId(int productId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/stock/products/$productId',
      );
      return _unwrap(
        response.data,
        (raw) => StockLevelModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<StockOverviewModel> overview() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/stock/overview');
      return _unwrap(
        response.data,
        (raw) => StockOverviewModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PageResponse<StockMovementModel>> movements({
    int? productId,
    StockReferenceType? referenceType,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/stock/movements',
        queryParameters: {
          if (productId != null) 'productId': productId,
          if (referenceType != null) 'referenceType': referenceType.apiValue,
          'page': page,
          'size': size,
        },
      );
      return _unwrap(
        response.data,
        (raw) => PageResponse<StockMovementModel>.fromJson(
          raw as Map<String, dynamic>,
          StockMovementModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<StockMovementModel> writeOff(
    RecordStockMovementRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/stock/write-offs',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => StockMovementModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<StockMovementModel> adjust(RecordStockMovementRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/stock/adjustments',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => StockMovementModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<StockLevelModel> setReorderLevel(
    int productId,
    UpdateReorderLevelRequest request,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/stock/products/$productId/reorder-level',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => StockLevelModel.fromJson(raw as Map<String, dynamic>),
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
