import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_user/vendor_model.dart';

/// The `/vendors` endpoints — supplier master data, plus each vendor's
/// running balance/ledger/settlements and purchase history.
///
/// Same contract as the other remote data sources: parses the response
/// envelope and only ever throws [ApiException].
class VendorRemoteDataSource {
  VendorRemoteDataSource(this._dio);

  final Dio _dio;

  // ─── Vendors ──────────────────────────────────────────────────────────

  Future<PageResponse<VendorModel>> list({
    String? search,
    int page = 1,
    int size = 20,
    String? sortBy,
    String? sortDirection,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vendors',
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
        // The type argument is explicit rather than inferred — inferring
        // it from `fromItem` alone here, inside a closure passed to a
        // second generic function (`_unwrap`), can leave `T` unresolved
        // and fall back to `Never`, so the parsed items fail to assign
        // into `PageResponse.content` at runtime.
        (raw) => PageResponse<VendorModel>.fromJson(
          raw as Map<String, dynamic>,
          VendorModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Every vendor, unpaged — for the pickers that choose one. Not used by
  /// the vendors screen itself.
  Future<List<VendorModel>> selection() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vendors/selection',
      );
      return _unwrap(
        response.data,
        (raw) => (raw as List<dynamic>)
            .map((e) => VendorModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<VendorModel> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/vendors/$id');
      return _unwrap(
        response.data,
        (raw) => VendorModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<VendorModel> create(UpsertVendorRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/vendors',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => VendorModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<VendorModel> update(int id, UpsertVendorRequest request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/vendors/$id',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => VendorModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// A hard delete — "remove a vendor nothing is recorded against" per the
  /// endpoint's own description, unlike the "retire"-style removes
  /// elsewhere in this app.
  Future<String> remove(int id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>('/vendors/$id');
      return _unwrap(response.data, (raw) => raw as String);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Balance ──────────────────────────────────────────────────────────

  Future<PageResponse<VendorLedgerEntryModel>> ledger(
    int vendorId, {
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vendors/$vendorId/ledger',
        queryParameters: {'page': page, 'size': size},
      );
      return _unwrap(
        response.data,
        // Explicit type argument — see the comment on the same pattern in
        // `list` above.
        (raw) => PageResponse<VendorLedgerEntryModel>.fromJson(
          raw as Map<String, dynamic>,
          VendorLedgerEntryModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<VendorBalanceModel> balance(int vendorId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vendors/$vendorId/balance',
      );
      return _unwrap(
        response.data,
        (raw) => VendorBalanceModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<VendorLedgerEntryModel> recordSettlement(
    int vendorId,
    RecordSettlementRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/vendors/$vendorId/settlements',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => VendorLedgerEntryModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<VendorLedgerEntryModel> postLedgerEntry(
    int vendorId,
    PostVendorLedgerEntryRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/vendors/$vendorId/ledger',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => VendorLedgerEntryModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── History ──────────────────────────────────────────────────────────

  Future<PageResponse<VendorHistoryModel>> history(
    int vendorId, {
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vendors/$vendorId/history',
        queryParameters: {'page': page, 'size': size},
      );
      return _unwrap(
        response.data,
        // Explicit type argument — see the comment on the same pattern in
        // `list` above.
        (raw) => PageResponse<VendorHistoryModel>.fromJson(
          raw as Map<String, dynamic>,
          VendorHistoryModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Every vendor's purchase trail, not scoped to one — not used by any
  /// screen today (the vendor detail screen uses the scoped [history]
  /// instead), implemented for completeness the same way `/selection`
  /// endpoints were before anything consumed them.
  Future<PageResponse<VendorHistoryModel>> allHistory({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vendors/history',
        queryParameters: {'page': page, 'size': size},
      );
      return _unwrap(
        response.data,
        // Explicit type argument — see the comment on the same pattern in
        // `list` above.
        (raw) => PageResponse<VendorHistoryModel>.fromJson(
          raw as Map<String, dynamic>,
          VendorHistoryModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Not used by any screen today — implemented for completeness, same
  /// reasoning as [allHistory].
  Future<VendorHistoryModel> historyById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vendors/history/$id',
      );
      return _unwrap(
        response.data,
        (raw) => VendorHistoryModel.fromJson(raw as Map<String, dynamic>),
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
