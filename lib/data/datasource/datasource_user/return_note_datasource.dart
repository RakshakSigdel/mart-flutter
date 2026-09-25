import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_shared/page_response.dart';
import '../../models/models_user/return_note_model.dart';

class ReturnNoteRemoteDataSource {
  const ReturnNoteRemoteDataSource(this._dio);
  final Dio _dio;

  Future<T> _request<T>(
    Future<Response<Map<String, dynamic>>> call,
    T Function(dynamic) parse,
  ) async {
    try {
      final response = await call;
      final json = response.data;
      if (json == null)
        throw const ApiException(
          ApiFailureType.unknownResponse,
          'Unexpected response from server.',
        );
      final envelope = ApiEnvelope<T>.fromJson(json, parse);
      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          ApiFailureType.badRequest,
          envelope.firstErrorMessage ?? envelope.message ?? 'Request failed.',
        );
      }
      return envelope.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PageResponse<ReturnNoteModel>> list(
    ReturnKind kind, {
    String? search,
    int? vendorId,
    String? dateRange,
    int page = 0,
    int size = 20,
  }) => _request(
    _dio.get<Map<String, dynamic>>(
      kind.path,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (kind == ReturnKind.purchase && vendorId != null)
          'vendorId': vendorId,
        if (dateRange != null && dateRange != 'ALL_TIME')
          'dateRange': dateRange,
        'page': page,
        'size': size,
      },
    ),
    (raw) => PageResponse<ReturnNoteModel>.fromJson(
      raw as Map<String, dynamic>,
      (json) => ReturnNoteModel.fromJson(json, kind),
    ),
  );

  Future<ReturnNoteModel> getById(ReturnKind kind, int id) => _request(
    _dio.get<Map<String, dynamic>>('${kind.path}/$id'),
    (raw) => ReturnNoteModel.fromJson(raw as Map<String, dynamic>, kind),
  );

  Future<List<ReturnNoteModel>> byOriginal(ReturnKind kind, int id) => _request(
    _dio.get<Map<String, dynamic>>(
      '${kind.path}/${kind == ReturnKind.sale ? 'by-sale' : 'by-purchase'}/$id',
    ),
    (raw) => (raw as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((json) => ReturnNoteModel.fromJson(json, kind))
        .toList(),
  );

  Future<ReturnNoteModel> create(
    ReturnKind kind,
    CreateReturnRequest request,
  ) => _request(
    _dio.post<Map<String, dynamic>>(kind.path, data: request.toJson(kind)),
    (raw) => ReturnNoteModel.fromJson(raw as Map<String, dynamic>, kind),
  );
}
