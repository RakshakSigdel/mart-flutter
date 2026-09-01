import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/inventory_categories_datasource.dart';

/// Infra wiring for the inventory-categories feature — kept separate from
/// [InventoryCategoriesRemoteDataSource] itself so the datasource stays a
/// plain, easily constructed class and this file is the one place that
/// assembles it with its dependencies.
final inventoryCategoriesRemoteDataSourceProvider =
    Provider<InventoryCategoriesRemoteDataSource>((ref) {
  return InventoryCategoriesRemoteDataSource(ref.watch(dioClientProvider));
});
