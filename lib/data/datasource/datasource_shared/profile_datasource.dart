import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/profile_model.dart';

/// The `/me` endpoints — the signed-in user's own account, available to
/// any authenticated role.
///
/// Same contract as the other remote data sources: parses the response
/// envelope and only ever throws [ApiException].
class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ProfileModel> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/me');
      return _unwrap(
        response.data,
        (raw) => ProfileModel.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> changePassword(ChangePasswordRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/me/change-password',
        data: request.toJson(),
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

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(dioClientProvider));
});
