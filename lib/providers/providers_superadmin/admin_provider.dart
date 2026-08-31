import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_superadmin/admin_datasource.dart';

/// Infra wiring for the superadmin admin-management feature — kept separate
/// from [AdminRemoteDataSource] itself so the datasource stays a plain,
/// easily-constructed class and this file is the one place that assembles
/// it with its dependencies.
final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.watch(dioClientProvider));
});
