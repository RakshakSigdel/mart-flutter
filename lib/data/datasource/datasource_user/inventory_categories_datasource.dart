import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_user/inventory_categories_model.dart';
import '../../models/models_user/inventory_units_model.dart';

/// The `/inventory/categories` endpoints — the signed-in mart's product
/// category dictionary, plus the unit-permission policy on each one.
///
/// Same contract as the other remote data sources: parses the response
/// envelope and only ever throws [ApiException].
class InventoryCategoriesRemoteDataSource {
  InventoryCategoriesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResponse<InventoryCategoryModel>> list({
    String? search,
    // 1-indexed — the backend's first page is page 1, not page 0.
    int page = 1,
    int size = 20,
    String? sortBy,
    String? sortDirection,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inventory/categories',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
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
          InventoryCategoryModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<InventoryCategoryDetailModel> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/inventory/categories/$id');
      return _unwrap(
        response.data,
        (raw) => InventoryCategoryDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Every category, unpaged — for pickers that choose one (e.g. a
  /// product's category field). Not used by the categories screen itself.
  Future<List<InventoryCategoryModel>> selection() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inventory/categories/selection',
      );
      return _unwrap(
        response.data,
        (raw) => (raw as List<dynamic>)
            .map((e) => InventoryCategoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The units this category currently permits for one side of the trade.
  /// [getById] already returns both sides at once — this is for a caller
  /// that only needs one.
  Future<List<InventoryUnitModel>> unitsForUsage(int id, CategoryUnitUsage usage) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inventory/categories/$id/units',
        queryParameters: {'usage': usage.apiValue},
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

  Future<InventoryCategoryModel> create(UpsertInventoryCategoryRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventory/categories',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => InventoryCategoryModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<InventoryCategoryModel> update(
    int id,
    UpsertInventoryCategoryRequest request,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/inventory/categories/$id',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => InventoryCategoryModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Only succeeds for a category with no products in it — per the
  /// endpoint's own description ("Remove an *empty* category").
  Future<String> remove(int id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>('/inventory/categories/$id');
      return _unwrap(response.data, (raw) => raw as String);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Permits [unitId] for [usage] on this category — returns the category's
  /// full detail (updated unit lists) rather than just the one permission,
  /// so the caller can replace its whole detail state from the response.
  Future<InventoryCategoryDetailModel> assignUnit(
    int id,
    AssignCategoryUnitRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventory/categories/$id/units',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => InventoryCategoryDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Withdraws a previously granted unit permission. [unitId] is the same
  /// id [InventoryUnitModel.id] carries in [InventoryCategoryDetailModel]'s
  /// `purchaseUnits`/`sellingUnits` — the backend's path parameter is named
  /// `categoryUnitId`, but the permission list is a plain array of units,
  /// not a separate join-record shape, so it's the unit's own id.
  Future<String> withdrawUnit(int id, int unitId) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/inventory/categories/$id/units/$unitId',
      );
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
