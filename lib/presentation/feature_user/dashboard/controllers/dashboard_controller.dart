import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/models_user/summary_report_model.dart';
import '../../../../data/models/models_user/stock_model.dart';
import '../../../../providers/providers_user/summary_report_provider.dart';
import '../../../../providers/providers_user/stock_provider.dart';

class DashboardController extends Notifier<ReportDateRange> {
  @override
  ReportDateRange build() => ReportDateRange.thisMonth;

  void selectRange(ReportDateRange range) => state = range;
}

final dashboardControllerProvider =
    NotifierProvider.autoDispose<DashboardController, ReportDateRange>(
      DashboardController.new,
    );

// Independent providers allow partial success. Changing range creates a new
// request identity, so a slower previous response cannot replace the new one.
final dashboardSalesProvider = FutureProvider.autoDispose
    .family<SummaryReportModel, ReportDateRange>(
      (ref, range) =>
          ref.watch(summaryReportRemoteDataSourceProvider).sales(range),
    );
final dashboardPurchasesProvider = FutureProvider.autoDispose
    .family<SummaryReportModel, ReportDateRange>(
      (ref, range) =>
          ref.watch(summaryReportRemoteDataSourceProvider).purchases(range),
    );
final dashboardStockProvider = FutureProvider.autoDispose<StockOverviewModel>(
  (ref) => ref.watch(stockRemoteDataSourceProvider).overview(),
);
