import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/purchase_datasource.dart';

/// Infra wiring for the purchases feature — kept separate from
/// [PurchaseRemoteDataSource] itself so the datasource stays a plain,
/// easily constructed class and this file is the one place that assembles
/// it with its dependencies.
final purchaseRemoteDataSourceProvider = Provider<PurchaseRemoteDataSource>((
  ref,
) {
  return PurchaseRemoteDataSource(ref.watch(dioClientProvider));
});
