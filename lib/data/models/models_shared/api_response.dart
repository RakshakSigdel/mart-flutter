/// One entry of the `errors` array — a field-level validation failure.
class ApiFieldError {
  const ApiFieldError({this.field, this.message});

  final String? field;
  final String? message;

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field'] as String?,
      message: json['message'] as String?,
    );
  }
}

/// The envelope every endpoint on this backend wraps its response in:
/// ```json
/// {
///   "success": true,
///   "status": 0,
///   "message": "string",
///   "data": { ... },
///   "errors": [{ "field": "string", "message": "string" }],
///   "timestamp": "2026-08-31T09:02:31.400Z"
/// }
/// ```
/// `data` isn't always an object — some endpoints return a plain string
/// (`"data": "Mart retired."`) or a list (`"data": ["migration_x"]`), so
/// [fromJson] takes a raw-value converter rather than assuming a `Map`.
///
/// `success: false` can arrive with an HTTP 200 (e.g. wrong password), so
/// callers must check [success] themselves — a non-throwing [Dio] response
/// does not by itself mean the request succeeded.
class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    this.status,
    this.message,
    this.data,
    this.errors = const [],
    this.timestamp,
  });

  final bool success;
  final int? status;
  final String? message;
  final T? data;
  final List<ApiFieldError> errors;
  final DateTime? timestamp;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw) fromData,
  ) {
    final rawData = json['data'];
    final rawTimestamp = json['timestamp'];
    // `ApiEnvelope<T>` explicit — same reasoning as the fix in
    // `PageResponse.fromJson`/`VendorSubPage.initial`: the bare
    // `ApiEnvelope(...)` relies on inferring `T` for this constructor call
    // from the enclosing factory's return type, which on web (DDC) can
    // fall back to `Never` instead of the real type — and this envelope
    // backs every single datasource call in the app, so a wrong binding
    // here is a much wider blast radius than it looks.
    return ApiEnvelope<T>(
      success: json['success'] as bool? ?? false,
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: rawData == null ? null : fromData(rawData),
      errors:
          (json['errors'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ApiFieldError.fromJson)
              .toList() ??
          const [],
      timestamp: rawTimestamp is String
          ? DateTime.tryParse(rawTimestamp)
          : null,
    );
  }

  /// The first field error's message, if any — usually the most specific
  /// thing to show the user when [message] is generic ("Validation failed").
  String? get firstErrorMessage => errors.isEmpty ? null : errors.first.message;
}
