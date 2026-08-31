import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_superadmin/admin_model.dart';

/// The `/superadmin/admins` endpoints — every mart in the installation.
///
/// Same contract as [AuthRemoteDataSource]: parses the response envelope
/// and only ever throws [ApiException].
class AdminRemoteDataSource {
  AdminRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResponse<AdminModel>> list({
    String? search,
    AdminProvisioningStatus? provisioningStatus,
    int page = 0,
    int size = 20,
    String? sortBy,
    String? sortDirection,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/superadmin/admins',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (provisioningStatus != null)
            'provisioningStatus': provisioningStatus.apiValue,
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
          AdminModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminModel> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/superadmin/admins/$id',
      );
      return _unwrap(
        response.data,
        (raw) => AdminModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminModel> create(CreateAdminRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/superadmin/admins',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => AdminModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminModel> update(String id, UpdateAdminRequest request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/superadmin/admins/$id',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => AdminModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Retires the mart — its data and schema are left in place, per the
  /// endpoint's own description ("Retire a mart... schema and data are left
  /// in place"). Not a hard delete.
  Future<String> retire(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/superadmin/admins/$id',
      );
      return _unwrap(response.data, (raw) => raw as String);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> resetPassword(String id, String newPassword) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/superadmin/admins/$id/reset-password',
        data: {'newPassword': newPassword},
      );
      return _unwrap(response.data, (raw) => raw as String);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Re-runs schema creation/migration for one mart.
  Future<AdminModel> provision(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/superadmin/admins/$id/provision',
      );
      return _unwrap(
        response.data,
        (raw) => AdminModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Applies any new tenant migrations to every mart at once. Returns the
  /// backend's per-mart result lines.
  Future<List<String>> runMigrations() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/superadmin/admins/migrations',
      );
      return _unwrap(
        response.data,
        (raw) => (raw as List<dynamic>).map((e) => e.toString()).toList(),
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
