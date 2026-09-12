import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/summary_report_datasource.dart';

final summaryReportRemoteDataSourceProvider =
    Provider<SummaryReportRemoteDataSource>(
      (ref) => SummaryReportRemoteDataSource(ref.watch(dioClientProvider)),
    );
