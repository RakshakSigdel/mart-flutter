import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/vendor_datasource.dart';

/// Infra wiring for the vendors feature — kept separate from
/// [VendorRemoteDataSource] itself so the datasource stays a plain, easily
/// constructed class and this file is the one place that assembles it with
/// its dependencies.
final vendorRemoteDataSourceProvider = Provider<VendorRemoteDataSource>((ref) {
  return VendorRemoteDataSource(ref.watch(dioClientProvider));
});
