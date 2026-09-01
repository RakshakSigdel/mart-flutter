import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/inventory_units_datasource.dart';

/// Infra wiring for the inventory-units feature — kept separate from
/// [InventoryUnitsRemoteDataSource] itself so the datasource stays a plain,
/// easily constructed class and this file is the one place that assembles
/// it with its dependencies.
final inventoryUnitsRemoteDataSourceProvider = Provider<InventoryUnitsRemoteDataSource>((ref) {
  return InventoryUnitsRemoteDataSource(ref.watch(dioClientProvider));
});
