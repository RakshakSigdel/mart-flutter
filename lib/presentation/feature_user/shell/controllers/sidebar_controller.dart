import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/datasource/datasource_shared/sidebar_datasource.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';
import '../models/sidebar_menu_registry.dart';

/// Screen-level state for the admin shell's sidebar: the signed-in user's
/// own menu, as returned by `GET /me/sidebar`.
class SidebarState {
  const SidebarState({
    required this.sections,
    required this.isLoading,
    required this.error,
    required this.isCollapsed,
  });

  /// Starts pre-filled with [fallbackSidebarSections], already resolved —
  /// so the sidebar shows real, working navigation from the very first
  /// frame instead of an empty panel while the first fetch is in flight.
  factory SidebarState.initial() => SidebarState(
    sections: resolveSidebarSections(fallbackSidebarSections),
    isLoading: true,
    error: null,
    isCollapsed: false,
  );

  final List<ResolvedSidebarSection> sections;
  final bool isLoading;
  final bool isCollapsed;

  /// Set when the most recent fetch failed. [sections] still holds
  /// whatever it last resolved successfully (or the fallback, if this is
  /// the very first load) — a failure degrades the menu to "not refreshed"
  /// rather than "empty".
  final String? error;

  SidebarState copyWith({
    List<ResolvedSidebarSection>? sections,
    bool? isLoading,
    bool? isCollapsed,
    Object? error = _unset,
  }) {
    return SidebarState(
      sections: sections ?? this.sections,
      isLoading: isLoading ?? this.isLoading,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

const _unset = Object();

/// Owns the admin shell's sidebar: fetching the signed-in user's
/// role-specific menu and resolving it down to entries this app can
/// actually navigate to.
class SidebarController extends Notifier<SidebarState> {
  @override
  SidebarState build() {
    Future.microtask(refresh);
    return SidebarState.initial();
  }

  SidebarRemoteDataSource get _dataSource =>
      ref.read(sidebarRemoteDataSourceProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sections = await _dataSource.getSidebar();
      state = state.copyWith(
        isLoading: false,
        sections: resolveSidebarSections(sections),
      );
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Keeps the rail width stable while switching between shell branches.
  void setCollapsed(bool isCollapsed) {
    state = state.copyWith(isCollapsed: isCollapsed);
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

/// `autoDispose`: this holds one signed-in user's own menu. It must not
/// survive past [AdminShellScreen] — the sidebar's sole watcher, and
/// unreachable once signed out — or the next account to sign in on this
/// device would briefly see the previous one's cached (and possibly
/// role-mismatched) menu, same reasoning as every other session-scoped
/// controller in this app.
final sidebarControllerProvider =
    NotifierProvider.autoDispose<SidebarController, SidebarState>(
      SidebarController.new,
    );
