import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/stock_datasource.dart';

/// Infra wiring for the stock feature — kept separate from
/// [StockRemoteDataSource] itself so the datasource stays a plain, easily
/// constructed class and this file is the one place that assembles it with
/// its dependencies.
final stockRemoteDataSourceProvider = Provider<StockRemoteDataSource>((ref) {
  return StockRemoteDataSource(ref.watch(dioClientProvider));
});
