import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/cbms_internal_model.dart';
import '../../../../providers/providers_user/cbms_internal_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';

class CbmsSettingsState {
  const CbmsSettingsState({
    required this.isLoading,
    required this.isSaving,
    required this.error,
    required this.config,
  });

  factory CbmsSettingsState.initial() => const CbmsSettingsState(
    isLoading: true,
    isSaving: false,
    error: null,
    config: null,
  );

  final bool isLoading;
  final bool isSaving;
  final String? error;
  final CbmsInternalConfig? config;

  CbmsSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    Object? error = _unset,
    Object? config = _unset,
  }) => CbmsSettingsState(
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    error: identical(error, _unset) ? this.error : error as String?,
    config: identical(config, _unset)
        ? this.config
        : config as CbmsInternalConfig?,
  );
}

const _unset = Object();

class CbmsSettingsController extends Notifier<CbmsSettingsState> {
  @override
  CbmsSettingsState build() {
    Future.microtask(refresh);
    return CbmsSettingsState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final source = ref.read(cbmsInternalRemoteDataSourceProvider);
      final records = await source.list();
      final config = records.isEmpty
          ? null
          : await source.getById(records.first.id);
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, config: config);
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      if (ref.mounted)
        state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load CBMS settings.',
        );
      }
    }
  }

  Future<CbmsInternalConfig> save({
    required String username,
    required String password,
    required TaxRegistration taxRegistration,
    required bool taxIncluded,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final source = ref.read(cbmsInternalRemoteDataSourceProvider);
      final current = state.config;
      final config = current == null
          ? await source.create(
              CreateCbmsInternalRequest(
                cbmsUsername: username,
                cbmsPassword: password,
                taxRegistration: taxRegistration,
                taxIncluded: taxIncluded,
              ),
            )
          : await source.update(
              current.id,
              UpdateCbmsInternalRequest(
                cbmsUsername: username,
                cbmsPassword: password,
                taxIncluded: taxIncluded,
              ),
            );
      if (ref.mounted) state = state.copyWith(isSaving: false, config: config);
      return config;
    } on ApiException catch (e) {
      await _handleUnauthorized(e);
      if (ref.mounted)
        state = state.copyWith(isSaving: false, error: e.message);
      rethrow;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          isSaving: false,
          error: 'Could not save CBMS settings.',
        );
      }
      rethrow;
    }
  }

  Future<void> _handleUnauthorized(ApiException error) async {
    if (error.type == ApiFailureType.unauthorized && ref.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

final cbmsSettingsControllerProvider =
    NotifierProvider.autoDispose<CbmsSettingsController, CbmsSettingsState>(
      CbmsSettingsController.new,
    );
