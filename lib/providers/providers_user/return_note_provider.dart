import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasource/datasource_user/return_note_datasource.dart';

final returnNoteRemoteDataSourceProvider = Provider<ReturnNoteRemoteDataSource>(
  (ref) => ReturnNoteRemoteDataSource(ref.watch(dioClientProvider)),
);
