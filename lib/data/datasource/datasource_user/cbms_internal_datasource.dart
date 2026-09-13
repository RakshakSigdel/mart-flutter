import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_user/cbms_internal_model.dart';

class CbmsInternalRemoteDataSource {
  CbmsInternalRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<CbmsInternalConfig>> list() async {
    try {
      final response = await _dio.get<dynamic>('/cbms-internal');
      return await _decode(
        response.data,
        (raw) => (raw as List<dynamic>)
            .map(
              (item) =>
                  CbmsInternalConfig.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CbmsInternalConfig> getById(int id) async {
    try {
      final response = await _dio.get<dynamic>('/cbms-internal/$id');
      return await _decode(
        response.data,
        (raw) => CbmsInternalConfig.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CbmsInternalConfig> create(CreateCbmsInternalRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        '/cbms-internal',
        data: request.toJson(),
      );
      return await _decode(
        response.data,
        (raw) => CbmsInternalConfig.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CbmsInternalConfig> update(
    int id,
    UpdateCbmsInternalRequest request,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '/cbms-internal/$id',
        data: request.toJson(),
      );
      return await _decode(
        response.data,
        (raw) => CbmsInternalConfig.fromJson(raw as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  T _decode<T>(Object? body, T Function(dynamic raw) fromData) {
    if (body is Map<String, dynamic> && body.containsKey('success')) {
      final envelope = ApiEnvelope<T>.fromJson(body, fromData);
      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          ApiFailureType.badRequest,
          envelope.firstErrorMessage ?? envelope.message ?? 'Request failed.',
        );
      }
      return envelope.data!;
    }
    if (body == null) {
      throw const ApiException(
        ApiFailureType.unknownResponse,
        'Unexpected response from server.',
      );
    }
    return fromData(body);
  }
}
