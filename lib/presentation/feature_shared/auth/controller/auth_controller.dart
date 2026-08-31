import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../data/datasource/datasource_shared/auth_datasource.dart';
import '../../../../data/models/models_shared/auth_session_model.dart';

/// Where the current session stands.
sealed class AuthState {
  const AuthState();
}

/// App just booted — storage hasn't been checked yet. Distinct from
/// [AuthUnauthenticated] so the router can tell "not signed in" apart from
/// "don't know yet" and send the latter through the splash screen instead
/// of guessing and bouncing a returning user to login.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// No one is signed in — where [AuthController.logout] lands, and where a
/// failed [AuthController.restoreSession] settles.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// A login call is in flight.
class AuthAuthenticating extends AuthState {
  const AuthAuthenticating();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);
  final AuthSessionModel session;
}

/// The last login attempt failed. [message] is safe to show directly.
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

/// Owns the auth session: signing in, restoring a saved session on launch,
/// and signing out. Screens read [AuthState] and call these methods —
/// nothing above this controller touches the datasource or secure storage
/// directly.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInitial();

  AuthRemoteDataSource get _dataSource => ref.read(authRemoteDataSourceProvider);
  SecureStorage get _storage => ref.read(secureStorageProvider);

  Future<void> login(String username, String password) async {
    state = const AuthAuthenticating();
    try {
      final session = await _dataSource.login(
        username: username,
        password: password,
      );
      await _persist(session);
      state = AuthAuthenticated(session);
    } on ApiException catch (e) {
      state = AuthError(e.message);
    }
  }

  /// Called once on app start, from the splash screen.
  ///
  /// There's no server-side session-check endpoint to call, so this trusts
  /// the session saved at login time and only checks its `tokenExpiresAt`
  /// locally. A token the backend has since revoked for some other reason
  /// (not just expiry) won't be caught here — but any authenticated call
  /// that gets a 401 clears the stored session via the dio interceptor
  /// (see `DioClient`), so the user is signed out for real on their next
  /// action even if this local check let them in.
  ///
  /// Returns whether the session was restored.
  Future<bool> restoreSession() async {
    final raw = await _storage.readSessionJson();
    if (raw == null) {
      state = const AuthUnauthenticated();
      return false;
    }

    try {
      final session = AuthSessionModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final expiresAt = session.tokenExpiresAt;
      final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());
      if (!session.isValid || isExpired) {
        await _storage.clearSession();
        state = const AuthUnauthenticated();
        return false;
      }
      state = AuthAuthenticated(session);
      return true;
    } catch (_) {
      // Malformed stored JSON — treat like no session rather than crash.
      await _storage.clearSession();
      state = const AuthUnauthenticated();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
    state = const AuthUnauthenticated();
  }

  Future<void> _persist(AuthSessionModel session) async {
    await _storage.writeToken(session.token);
    await _storage.writeSessionJson(jsonEncode(session.toJson()));
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
