import 'package:dio/dio.dart';

/// Coarse classification of what went wrong on a network call.
///
/// Screens and controllers branch on this instead of inspecting a raw
/// [DioException] — the HTTP/transport details stop at the datasource layer.
enum ApiFailureType {
  /// No connection could be made at all (offline, DNS failure, connection
  /// refused — e.g. the backend isn't running).
  network,

  /// The request timed out (connect, send, or receive).
  timeout,

  /// 401 — missing or invalid credentials/token.
  unauthorized,

  /// 400/404/422 — the request itself was rejected.
  badRequest,

  /// 5xx — the server failed to handle a valid request.
  server,

  /// The server responded, but the body wasn't the shape a datasource
  /// expected (e.g. not a JSON object).
  unknownResponse,

  /// Anything that doesn't fit the categories above.
  unknown,
}

/// A typed, user-presentable failure. Every layer above a datasource works
/// with this — never a raw [DioException].
class ApiException implements Exception {
  const ApiException(this.type, this.message, {this.statusCode});

  final ApiFailureType type;

  /// Safe to show directly in the UI.
  final String message;

  final int? statusCode;

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
        return const ApiException(
          ApiFailureType.network,
          'Could not reach the server. Check your connection and try again.',
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          ApiFailureType.timeout,
          'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          ApiFailureType.network,
          'Could not establish a secure connection to the server.',
        );
      case DioExceptionType.cancel:
        return const ApiException(ApiFailureType.unknown, 'Request cancelled.');
      case DioExceptionType.badResponse:
        return _fromBadResponse(e.response);
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          ApiFailureType.unknown,
          'Something went wrong. Please try again.',
        );
    }
  }

  static ApiException _fromBadResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final type = _typeForStatusCode(statusCode);
    // The backend sends a real, user-facing message on the same response
    // that carries the error status (e.g. HTTP 400 with
    // `{"message": "Invalid username or password", "errors": []}`) — use
    // it verbatim rather than a generic "request failed" string whenever
    // it's there.
    final message = _extractBackendMessage(response?.data) ?? _defaultMessage(type);
    return ApiException(type, message, statusCode: statusCode);
  }

  static ApiFailureType _typeForStatusCode(int? statusCode) {
    if (statusCode == 401 || statusCode == 403) return ApiFailureType.unauthorized;
    if (statusCode != null && statusCode >= 500) return ApiFailureType.server;
    if (statusCode != null && statusCode >= 400) return ApiFailureType.badRequest;
    return ApiFailureType.unknown;
  }

  static String _defaultMessage(ApiFailureType type) => switch (type) {
        ApiFailureType.unauthorized => 'Incorrect username or password.',
        ApiFailureType.server =>
          'The server ran into a problem. Please try again shortly.',
        ApiFailureType.badRequest => 'That request could not be completed.',
        _ => 'Something went wrong. Please try again.',
      };

  /// Pulls the most specific message out of the envelope
  /// (`{ message, errors: [{ field, message }] }`) directly from the raw
  /// body — this runs on error responses, which don't parse as any
  /// particular success-path `T`, so it can't go through `ApiEnvelope`.
  static String? _extractBackendMessage(Object? data) {
    if (data is! Map<String, dynamic>) return null;

    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map<String, dynamic>) {
        final fieldMessage = first['message'];
        if (fieldMessage is String && fieldMessage.isNotEmpty) {
          return fieldMessage;
        }
      }
    }

    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;

    return null;
  }

  @override
  String toString() => 'ApiException($type, $message, statusCode: $statusCode)';
}
