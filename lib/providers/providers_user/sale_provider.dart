import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/sale_datasource.dart';

/// Infra wiring for the sales feature — kept separate from
/// [SaleRemoteDataSource] itself so the datasource stays a plain, easily
/// constructed class and this file is the one place that assembles it
/// with its dependencies.
final saleRemoteDataSourceProvider = Provider<SaleRemoteDataSource>((ref) {
  return SaleRemoteDataSource(ref.watch(dioClientProvider));
});
