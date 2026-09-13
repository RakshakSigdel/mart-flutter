import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/cbms_internal_datasource.dart';

final cbmsInternalRemoteDataSourceProvider =
    Provider<CbmsInternalRemoteDataSource>(
      (ref) => CbmsInternalRemoteDataSource(ref.watch(dioClientProvider)),
    );
