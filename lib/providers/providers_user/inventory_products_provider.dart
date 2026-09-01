import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/inventory_products_datasource.dart';

/// Infra wiring for the inventory-products feature — kept separate from
/// [InventoryProductsRemoteDataSource] itself so the datasource stays a
/// plain, easily constructed class and this file is the one place that
/// assembles it with its dependencies.
final inventoryProductsRemoteDataSourceProvider =
    Provider<InventoryProductsRemoteDataSource>((ref) {
  return InventoryProductsRemoteDataSource(ref.watch(dioClientProvider));
});
