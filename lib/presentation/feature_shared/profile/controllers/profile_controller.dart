import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_shared/profile_datasource.dart';
import '../../../../data/models/models_shared/profile_model.dart';
import '../../auth/controller/auth_controller.dart';

/// Screen-level state for the profile page: the signed-in user's own
/// account, as returned by `GET /me`.
class ProfileState {
  const ProfileState({required this.profile, required this.isLoading, required this.error});

  factory ProfileState.initial() =>
      const ProfileState(profile: null, isLoading: true, error: null);

  final ProfileModel? profile;
  final bool isLoading;
  final String? error;

  ProfileState copyWith({ProfileModel? profile, bool? isLoading, String? error}) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Owns the profile page's data: loading the signed-in user's own account,
/// and changing their own password.
///
/// [changePassword] rethrows [ApiException] rather than storing it in
/// [ProfileState.error] — it's triggered from the change-password dialog,
/// and that dialog is best placed to show the error where the user is
/// actually looking (its own inline error), same reasoning as every other
/// mutation method in this app.
class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    Future.microtask(refresh);
    return ProfileState.initial();
  }

  ProfileRemoteDataSource get _dataSource => ref.read(profileRemoteDataSourceProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _dataSource.getMe();
      state = state.copyWith(isLoading: false, profile: profile);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Returns the backend's own confirmation text so the caller can show
  /// exactly what happened rather than a guessed message.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      return await _dataSource.changePassword(
        ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword),
      );
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      rethrow;
    }
  }

  /// A 401 means the session is dead — sign out everywhere rather than
  /// leaving this screen the only place that noticed. `routerProvider`'s
  /// redirect reacts to the resulting state change and sends the user back
  /// to login on its own.
  Future<void> _handleUnauthorized(ApiException e) async {
    if (e.type == ApiFailureType.unauthorized) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

/// `autoDispose`: this holds the signed-in user's own account. It must not
/// survive past the screen that watches it, or the next account to sign in
/// on this device would briefly see the previous one's cached profile —
/// same reasoning as every other session-scoped controller in this app.
final profileControllerProvider = NotifierProvider.autoDispose<ProfileController, ProfileState>(
  ProfileController.new,
);
