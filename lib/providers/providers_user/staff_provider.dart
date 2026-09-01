import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/staff_datasource.dart';

/// Infra wiring for the staff-management feature — kept separate from
/// [StaffRemoteDataSource] itself so the datasource stays a plain, easily
/// constructed class and this file is the one place that assembles it with
/// its dependencies.
final staffRemoteDataSourceProvider = Provider<StaffRemoteDataSource>((ref) {
  return StaffRemoteDataSource(ref.watch(dioClientProvider));
});
