import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/models_user/sales_book_model.dart';
import '../../../../providers/providers_user/sale_provider.dart';

class SalesBookController extends Notifier<SalesBookQuery> {
  @override
  SalesBookQuery build() => const SalesBookQuery();

  void update(SalesBookQuery query) => state = query;

  Future<List<int>> downloadPdf() =>
      ref.read(saleRemoteDataSourceProvider).downloadSalesBookPdf(state);
}

final salesBookControllerProvider =
    NotifierProvider.autoDispose<SalesBookController, SalesBookQuery>(
      SalesBookController.new,
    );

final salesBookProvider = FutureProvider.autoDispose
    .family<SalesBookModel, SalesBookQuery>(
      (ref, query) => ref.watch(saleRemoteDataSourceProvider).salesBook(query),
    );
