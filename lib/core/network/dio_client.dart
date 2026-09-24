import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';

/// Where the backend lives, per platform.
///
/// An Android device can't resolve `localhost` back to the host machine —
/// it needs the host's LAN IP instead. Every other target (including the
/// browser, which resolves `localhost` from the user's own machine) uses it
/// as-is.
class ApiConfig {
  ApiConfig._();

  /// Toggle this when building against the deployed retail API. Keeping the
  /// switch here makes every datasource use the same environment.
  static const bool isProduction = true;
  static const String _productionBaseUrl = 'https://sitoulatechsolution.com.np/retail-api/';

  static final String baseUrl = () {
    if (kIsWeb) return 'https://sitoulatechsolution.com.np/retail-api/';
    if (Platform.isAndroid) return 'https://sitoulatechsolution.com.np/retail-api/';
    return 'https://sitoulatechsolution.com.np/retail-api/';
  }();
}

/// Builds the app's single configured [Dio] instance.
///
/// Kept separate from the provider below so the construction logic itself
/// stays plain and testable — the provider is just wiring.
class DioClient {
  DioClient(this._storage);

  final SecureStorage _storage;

  Dio build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        // Attaches the stored token, if any, to every outgoing request.
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        // A 401 means the stored token is dead (expired, revoked, backend
        // restarted with a new secret, …) — drop it so the next app launch
        // doesn't try to restore a session that will just fail again.
        //
        // This only clears storage; it deliberately does NOT reach into
        // riverpod to flip AuthController's state, which would need this
        // file to depend on the auth feature (a core/ -> presentation/
        // dependency this app avoids). Whichever controller made the call
        // still receives the resulting ApiException(unauthorized) and is
        // responsible for calling authControllerProvider.notifier.logout()
        // — see AdminManagementController for the pattern.
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.clearSession();
          }
          handler.next(error);
        },
      ),
    );
    //Print every request response and everything - used for debugging
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
       responseBody: true,
       responseHeader: true,
       error: true,
      ),
    );

    return dio;
  }
}

/// The app-wide [Dio] instance. A provider (not a static singleton) so it
/// can be overridden with a fake in tests.
final dioClientProvider = Provider<Dio>((ref) {
  return DioClient(ref.watch(secureStorageProvider)).build();
});
