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

  static const _tokenKey = 'auth_token';
  static const _sessionKey = 'auth_session';

  /// The bare token, kept separate from [writeSessionJson] so the request
  /// interceptor can read just this on every call instead of decoding the
  /// whole session each time.
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  /// The full session, JSON-encoded by the caller (`AuthSessionModel.toJson`)
  /// — lets a relaunch restore who's signed in and their role without
  /// another network round-trip.
  Future<void> writeSessionJson(String json) =>
      _storage.write(key: _sessionKey, value: json);

  Future<String?> readSessionJson() => _storage.read(key: _sessionKey);

  /// Clears the whole session (called on logout, or when a stored token is
  /// rejected during restore).
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _sessionKey);
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(const FlutterSecureStorage());
});
