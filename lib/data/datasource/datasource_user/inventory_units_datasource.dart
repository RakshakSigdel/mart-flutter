import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_user/inventory_units_model.dart';

/// The `/inventory/units` endpoints — the signed-in mart's unit-of-measure
/// dictionary.
///
/// Same contract as the other remote data sources: parses the response
/// envelope and only ever throws [ApiException].
class InventoryUnitsRemoteDataSource {
  InventoryUnitsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResponse<InventoryUnitModel>> list({
    String? search,
    UnitMeasurementType? measurementType,
    // 1-indexed — the backend's first page is page 1, not page 0.
    int page = 1,
    int size = 20,
    String? sortBy,
    String? sortDirection,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inventory/units',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (measurementType != null) 'measurementType': measurementType.apiValue,
          'page': page,
          'size': size,
          if (sortBy != null) 'sortBy': sortBy,
          if (sortDirection != null) 'sortDirection': sortDirection,
        },
      );
      return _unwrap(
        response.data,
        (raw) => PageResponse.fromJson(
          raw as Map<String, dynamic>,
          InventoryUnitModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<InventoryUnitModel> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/inventory/units/$id');
      return _unwrap(
        response.data,
        (raw) => InventoryUnitModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Every unit, unpaged — for pickers that choose one (e.g. a product's
  /// unit field). Not used by the units screen itself.
  Future<List<InventoryUnitModel>> selection({UnitMeasurementType? measurementType}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inventory/units/selection',
        queryParameters: {
          if (measurementType != null) 'measurementType': measurementType.apiValue,
        },
      );
      return _unwrap(
        response.data,
        (raw) => (raw as List<dynamic>)
            .map((e) => InventoryUnitModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<InventoryUnitModel> create(UpsertInventoryUnitRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventory/units',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => InventoryUnitModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<InventoryUnitModel> update(int id, UpsertInventoryUnitRequest request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/inventory/units/$id',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => InventoryUnitModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> remove(int id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>('/inventory/units/$id');
      return _unwrap(response.data, (raw) => raw as String);
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
