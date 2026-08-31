import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/auth_session_model.dart';

/// Everything the auth feature needs from the backend.
///
/// Parses responses into [AuthSessionModel] and only ever throws
/// [ApiException] — callers never see a raw [DioException], and never see
/// an [ApiEnvelope] with `success: false` returned as if it were a session.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthSessionModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/public/auth/login',
        data: {'username': username, 'password': password},
      );
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Parses the envelope and turns a logical failure (HTTP 200 but
  /// `success: false` — e.g. wrong password) into the same [ApiException]
  /// a bad HTTP status would produce, so callers only ever handle one kind
  /// of error.
  AuthSessionModel _unwrap(Map<String, dynamic>? json) {
    if (json == null) {
      throw const ApiException(
        ApiFailureType.unknownResponse,
        'Unexpected response from server.',
      );
    }

    final envelope = ApiEnvelope<AuthSessionModel>.fromJson(
      json,
      (raw) => AuthSessionModel.fromJson(raw as Map<String, dynamic>),
    );

    if (!envelope.success || envelope.data == null || !envelope.data!.isValid) {
      throw ApiException(
        ApiFailureType.unauthorized,
        envelope.firstErrorMessage ??
            envelope.message ??
            'Login failed. Please try again.',
      );
    }

    return envelope.data!;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioClientProvider));
});
