import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_user/inventory_products_model.dart';

/// The `/inventory/products` endpoints — the signed-in mart's product
/// catalog, plus each product's purchase/selling-unit trading configuration
/// and VAT history.
///
/// Same contract as the other remote data sources: parses the response
/// envelope and only ever throws [ApiException].
class InventoryProductsRemoteDataSource {
  InventoryProductsRemoteDataSource(this._dio);

  final Dio _dio;

  // ─── Products ─────────────────────────────────────────────────────────

  Future<PageResponse<ProductModel>> list({
    String? search,
    int? categoryId,
    bool? active,
    int page = 1,
    int size = 20,
    String? sortBy,
    String? sortDirection,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inventory/products',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'categoryId': categoryId,
          if (active != null) 'active': active,
          'page': page,
          'size': size,
          if (sortBy != null) 'sortBy': sortBy,
          if (sortDirection != null) 'sortDirection': sortDirection,
        },
      );
      return _unwrap(
        response.data,
        (raw) =>
            PageResponse.fromJson(raw as Map<String, dynamic>, ProductModel.fromJson),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProductDetailModel> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/inventory/products/$id');
      return _unwrap(
        response.data,
        (raw) => ProductDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProductModel> create(CreateProductRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventory/products',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => ProductModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProductModel> update(int id, UpdateProductRequest request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/inventory/products/$id',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => ProductModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Not a hard delete — same "retire" semantics as staff/mart accounts.
  Future<String> retire(int id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>('/inventory/products/$id');
      return _unwrap(response.data, (raw) => raw as String);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Purchase units ───────────────────────────────────────────────────

  Future<List<ProductPurchaseUnitModel>> purchaseUnits(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inventory/products/$id/purchase-units',
      );
      return _unwrap(
        response.data,
        (raw) => (raw as List<dynamic>)
            .map((e) => ProductPurchaseUnitModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The one purchase unit, with its full VAT history — [getById] and
  /// [purchaseUnits] only ever carry `currentVatRate`, not the history.
  Future<ProductPurchaseUnitDetailModel> purchaseUnit(int id, int purchaseUnitId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inventory/products/$id/purchase-units/$purchaseUnitId',
      );
      return _unwrap(
        response.data,
        (raw) => ProductPurchaseUnitDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProductPurchaseUnitDetailModel> addPurchaseUnit(
    int id,
    CreatePurchaseUnitRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventory/products/$id/purchase-units',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => ProductPurchaseUnitDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProductPurchaseUnitDetailModel> updatePurchaseUnit(
    int id,
    int purchaseUnitId,
    UpdatePurchaseUnitRequest request,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/inventory/products/$id/purchase-units/$purchaseUnitId',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => ProductPurchaseUnitDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> removePurchaseUnit(int id, int purchaseUnitId) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/inventory/products/$id/purchase-units/$purchaseUnitId',
      );
      return _unwrap(response.data, (raw) => raw as String);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Opens a new VAT rate, closing whichever one is currently in force.
  Future<ProductPurchaseUnitDetailModel> openVatRate(
    int id,
    int purchaseUnitId,
    OpenVatRateRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventory/products/$id/purchase-units/$purchaseUnitId/vat',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => ProductPurchaseUnitDetailModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Selling units ────────────────────────────────────────────────────

  Future<List<ProductSellingUnitModel>> sellingUnits(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inventory/products/$id/selling-units',
      );
      return _unwrap(
        response.data,
        (raw) => (raw as List<dynamic>)
            .map((e) => ProductSellingUnitModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProductSellingUnitModel> addSellingUnit(
    int id,
    CreateSellingUnitRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventory/products/$id/selling-units',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => ProductSellingUnitModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProductSellingUnitModel> updateSellingUnit(
    int id,
    int sellingUnitId,
    UpdateSellingUnitRequest request,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/inventory/products/$id/selling-units/$sellingUnitId',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => ProductSellingUnitModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> removeSellingUnit(int id, int sellingUnitId) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/inventory/products/$id/selling-units/$sellingUnitId',
      );
      return _unwrap(response.data, (raw) => raw as String);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// What the till resolves a barcode scan to. Not used by any admin
  /// screen today — this is a POS/scan-resolution endpoint, implemented
  /// here for completeness the same way `/selection` endpoints were before
  /// anything consumed them.
  Future<ProductSellingUnitModel> getByBarcode(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inventory/products/by-barcode/$barcode',
      );
      return _unwrap(
        response.data,
        (raw) => ProductSellingUnitModel.fromJson(raw as Map<String, dynamic>),
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
