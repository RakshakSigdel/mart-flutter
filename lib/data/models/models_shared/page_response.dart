/// A Spring-style page of results:
/// ```json
/// {
///   "content": [ ... ],
///   "pageNumber": 0,
///   "pageSize": 20,
///   "totalElements": 42,
///   "totalPages": 3,
///   "last": false
/// }
/// ```
/// This is the shape of the `data` object on any paginated endpoint —
/// unwrap it via [ApiEnvelope] first, then parse the inner object with this.
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    return PageResponse(
      content: (json['content'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(fromItem)
              .toList() ??
          const [],
      pageNumber: json['pageNumber'] as int? ?? 0,
      pageSize: json['pageSize'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      last: json['last'] as bool? ?? true,
    );
  }

  static PageResponse<T> empty<T>() => PageResponse<T>(
        content: const [],
        pageNumber: 0,
        pageSize: 0,
        totalElements: 0,
        totalPages: 0,
        last: true,
      );
}
