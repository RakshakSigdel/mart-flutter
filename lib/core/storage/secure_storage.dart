import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  // Keep the current session in memory as well so a storage-policy failure
  // cannot abort an otherwise successful login halfway through. The session
  // will not survive a page reload in that situation, but authenticated API
  // calls in the current app session still receive their bearer token.
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
    } catch (_) {
      // HTTP-hosted web builds cannot use Web Crypto. The in-memory copy is
      // intentionally retained so login can continue for this page session.
    }
  }

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey) ?? _inMemoryToken;
    } catch (_) {
      return _inMemoryToken;
    }
  }

  /// The full session, JSON-encoded by the caller (`AuthSessionModel.toJson`)
  /// — lets a relaunch restore who's signed in and their role without
  /// another network round-trip.
  Future<void> writeSessionJson(String json) async {
    _inMemorySessionJson = json;
    try {
      await _storage.write(key: _sessionKey, value: json);
    } catch (_) {
      // See [writeToken].
    }
  }

  Future<String?> readSessionJson() async {
    try {
      return await _storage.read(key: _sessionKey) ?? _inMemorySessionJson;
    } catch (_) {
      return _inMemorySessionJson;
    }
  }

  /// Clears the whole session (called on logout, or when a stored token is
  /// rejected during restore).
  Future<void> clearSession() async {
    _inMemoryToken = null;
    _inMemorySessionJson = null;
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _sessionKey);
    } catch (_) {
      // Nothing further to clear when secure browser storage is unavailable.
    }
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(const FlutterSecureStorage());
});
