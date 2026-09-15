import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'browser_storage.dart';

/// Encrypted key-value storage for anything that must survive an app
/// restart but shouldn't sit in plain text — today the auth token and the
/// full session payload it came with.
///
/// Cross-cutting infra, not auth-specific — a later feature (device id,
/// cached PIN, etc.) can depend on this without pulling in the auth feature.
class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  // `flutter_secure_storage` on web relies on Web Crypto, which is only
  // available in a secure browser context (HTTPS, apart from localhost).
  // Fall back to browser local storage in that case so an HTTP-hosted web
  // build can restore a session after refresh. This fallback only exists on
  // web; native targets continue to use encrypted secure storage exclusively.
  String? _inMemoryToken;
  String? _inMemorySessionJson;

  static const _tokenKey = 'auth_token';
  static const _sessionKey = 'auth_session';

  /// The bare token, kept separate from [writeSessionJson] so the request
  /// interceptor can read just this on every call instead of decoding the
  /// whole session each time.
  Future<void> writeToken(String token) async {
    _inMemoryToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
      _deleteBrowserFallback(_tokenKey);
    } catch (_) {
      _writeBrowserFallback(_tokenKey, token);
    }
  }

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey) ??
          _readBrowserFallback(_tokenKey) ??
          _inMemoryToken;
    } catch (_) {
      return _readBrowserFallback(_tokenKey) ?? _inMemoryToken;
    }
  }

  /// The full session, JSON-encoded by the caller (`AuthSessionModel.toJson`)
  /// — lets a relaunch restore who's signed in and their role without
  /// another network round-trip.
  Future<void> writeSessionJson(String json) async {
    _inMemorySessionJson = json;
    try {
      await _storage.write(key: _sessionKey, value: json);
      _deleteBrowserFallback(_sessionKey);
    } catch (_) {
      _writeBrowserFallback(_sessionKey, json);
    }
  }

  Future<String?> readSessionJson() async {
    try {
      return await _storage.read(key: _sessionKey) ??
          _readBrowserFallback(_sessionKey) ??
          _inMemorySessionJson;
    } catch (_) {
      return _readBrowserFallback(_sessionKey) ?? _inMemorySessionJson;
    }
  }

  /// Clears the whole session (called on logout, or when a stored token is
  /// rejected during restore).
  Future<void> clearSession() async {
    _inMemoryToken = null;
    _inMemorySessionJson = null;
    _deleteBrowserFallback(_tokenKey);
    _deleteBrowserFallback(_sessionKey);
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _sessionKey);
    } catch (_) {
      // Nothing further to clear when secure browser storage is unavailable.
    }
  }

  static String? _readBrowserFallback(String key) {
    try {
      return BrowserStorage.read(key);
    } catch (_) {
      return null;
    }
  }

  static void _writeBrowserFallback(String key, String value) {
    try {
      BrowserStorage.write(key, value);
    } catch (_) {
      // Private browsing or restrictive browser policies can block this too.
    }
  }

  static void _deleteBrowserFallback(String key) {
    try {
      BrowserStorage.delete(key);
    } catch (_) {
      // The in-memory copy has still been cleared.
    }
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(const FlutterSecureStorage());
});
