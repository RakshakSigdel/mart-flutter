import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../models/models_shared/api_response.dart';
import '../../models/models_user/summary_report_model.dart';

class SummaryReportRemoteDataSource {
  SummaryReportRemoteDataSource(this._dio);
  final Dio _dio;

  Future<SummaryReportModel> sales(ReportDateRange range) =>
      _get('/sales/report', range, SummaryReportModel.fromSalesJson);

  Future<SummaryReportModel> purchases(ReportDateRange range) =>
      _get('/purchases/report', range, SummaryReportModel.fromPurchasesJson);

  Future<SummaryReportModel> _get(
    String path,
    ReportDateRange range,
    SummaryReportModel Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {'dateRange': range.apiValue},
      );
      final json = response.data;
      if (json == null) {
        throw const ApiException(
          ApiFailureType.unknownResponse,
          'Unexpected response from server.',
        );
      }
      final envelope = ApiEnvelope<SummaryReportModel>.fromJson(
        json,
        (raw) => parse(raw as Map<String, dynamic>),
      );
      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          ApiFailureType.badRequest,
          envelope.firstErrorMessage ??
              envelope.message ??
              'Report unavailable.',
        );
      }
      return envelope.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
