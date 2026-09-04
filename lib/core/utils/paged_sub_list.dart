/// One page of a sub-resource's list — for a detail controller that owns
/// its own record plus one or more independently-paged lists nested under
/// it (a vendor's ledger, a product's stock movements, …), each held in one
/// of these rather than duplicating page-tracking fields per list.
class PagedSubList<T> {
  const PagedSubList({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.pageNumber,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
  });

  // `PagedSubList<T>` explicit rather than left to inference — the bare
  // `PagedSubList(...)` here would ask Dart to infer `T` for this
  // constructor call from the enclosing factory's return type, which on
  // web (DDC) can fall back to `Never` instead of the real type. Since
  // `.initial()` runs before any real data arrives, a wrong binding here
  // poisons `T` for every `copyWith` call made against the object for the
  // rest of its life — see `page_response.dart`/`api_response.dart` for
  // the other two places this exact bug turned up.
  factory PagedSubList.initial() => PagedSubList<T>(
    items: const [],
    isLoading: true,
    error: null,
    pageNumber: 1,
    totalPages: 0,
    totalElements: 0,
    isLast: true,
  );

  final List<T> items;
  final bool isLoading;
  final String? error;
  final int pageNumber;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  bool get isEmpty => !isLoading && error == null && items.isEmpty;
  bool get hasNextPage => !isLast;
  bool get hasPreviousPage => pageNumber > 1;

  PagedSubList<T> copyWith({
    List<T>? items,
    bool? isLoading,
    String? error,
    int? pageNumber,
    int? totalPages,
    int? totalElements,
    bool? isLast,
  }) {
    return PagedSubList<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLast: isLast ?? this.isLast,
    );
  }
}
