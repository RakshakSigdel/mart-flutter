import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/sidebar_model.dart';

/// `GET /me/sidebar` — the signed-in user's own navigation menu, shaped by
/// their role. Same contract as the other remote data sources: parses the
/// response envelope and only ever throws [ApiException].
class SidebarRemoteDataSource {
  SidebarRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SidebarSectionModel>> getSidebar() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/me/sidebar');
      return _unwrap(
        response.data,
        (raw) => (raw as List<dynamic>)
            .map((e) => SidebarSectionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
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

final sidebarRemoteDataSourceProvider = Provider<SidebarRemoteDataSource>((
  ref,
) {
  return SidebarRemoteDataSource(ref.watch(dioClientProvider));
});
