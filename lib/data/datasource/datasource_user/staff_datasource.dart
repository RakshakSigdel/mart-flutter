import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_user/staff_model.dart';

/// The `/admin/staff` endpoints — the signed-in mart's own staff accounts.
///
/// Same contract as [AdminRemoteDataSource]: parses the response envelope
/// and only ever throws [ApiException].
class StaffRemoteDataSource {
  StaffRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResponse<StaffModel>> list({
    String? search,
    StaffRole? role,
    StaffStatus? status,
    int page = 0,
    int size = 20,
    String? sortBy,
    String? sortDirection,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/staff',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (role != null) 'role': role.apiValue,
          if (status != null) 'status': status.apiValue,
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
          StaffModel.fromJson,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<StaffModel> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/staff/$id');
      return _unwrap(
        response.data,
        (raw) => StaffModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The roles the signed-in admin is allowed to assign to staff — narrower
  /// than the full [StaffRole] set (e.g. an admin can't hire another
  /// `SUPER_ADMIN`).
  Future<List<StaffRole>> assignableRoles() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/staff/assignable-roles',
      );
      return _unwrap(
        response.data,
        (raw) => (raw as List<dynamic>)
            .map((e) => StaffRole.fromApiValue(e as String?))
            .whereType<StaffRole>()
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<StaffModel> hire(HireStaffRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/staff',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => StaffModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<StaffModel> update(String id, UpdateStaffRequest request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/staff/$id',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (raw) => StaffModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Retires the staff account — not a hard delete, per the same convention
  /// as `AdminRemoteDataSource.retire`.
  Future<String> retire(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/admin/staff/$id',
      );
      return _unwrap(response.data, (raw) => raw as String);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> resetPassword(String id, String newPassword) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/staff/$id/reset-password',
        data: {'newPassword': newPassword},
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
