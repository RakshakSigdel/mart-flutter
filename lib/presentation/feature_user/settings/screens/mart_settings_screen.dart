import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/cbms_internal_model.dart';
import '../controllers/cbms_settings_controller.dart';

class MartSettingsScreen extends ConsumerStatefulWidget {
  const MartSettingsScreen({super.key});

  @override
  ConsumerState<MartSettingsScreen> createState() => _MartSettingsScreenState();
}

class _MartSettingsScreenState extends ConsumerState<MartSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  int? _loadedConfigId;
  TaxRegistration _taxRegistration = TaxRegistration.vatRegistered;
  bool _taxIncluded = true;
  String? _submitError;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _applyConfig(CbmsInternalConfig? config) {
    if (config == null || config.id == _loadedConfigId) return;
    _loadedConfigId = config.id;
    _username.text = config.cbmsUsername;
    _taxRegistration = config.taxRegistration;
    _taxIncluded = config.taxIncluded;
    // Passwords are never copied out of a server response into this form.
    _password.clear();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitError = null);
    try {
      final config = await ref
          .read(cbmsSettingsControllerProvider.notifier)
          .save(
            username: _username.text.trim(),
            password: _password.text,
            taxRegistration: _taxRegistration,
            taxIncluded: _taxIncluded,
          );
      if (!mounted) return;
      _password.clear();
      AppSnackBar.success(
        context,
        'CBMS settings saved for ${config.tenantSlug.isEmpty ? 'this mart' : config.tenantSlug}.',
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _submitError = e.message);
    } catch (_) {
      if (mounted)
        setState(() => _submitError = 'Could not save CBMS settings.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cbmsSettingsControllerProvider);
    _applyConfig(state.config);
    if (state.isLoading) return const AppLoader();
    if (state.error != null && state.config == null) {
      return AppEmptyState.error(
        message: state.error,
        onAction: () =>
            ref.read(cbmsSettingsControllerProvider.notifier).refresh(),
      );
    }

    final existing = state.config;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Mart Settings', style: AppTypography.heading),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Configure the CBMS credentials and tax behavior used for this mart.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.primaryDeep,
                          ),
                          const SizedBox(width: AppSpacing.smMd),
                          Expanded(
                            child: Text(
                              'CBMS configuration',
                              style: AppTypography.title,
                            ),
                          ),
                          if (existing != null)
                            const AppBadge(
                              label: 'Configured',
                              tone: AppBadgeTone.success,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        existing == null
                            ? 'Add this mart’s initial CBMS configuration.'
                            : 'Update the credentials or whether tax is included in prices.',
                        style: AppTypography.bodySmall,
                      ),
                      if (existing?.pan case final pan?
                          when pan.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text('PAN: $pan', style: AppTypography.caption),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _username,
                        label: 'CBMS username',
                        enabled: !state.isSaving,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter the CBMS username.'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _password,
                        label: existing == null
                            ? 'CBMS password'
                            : 'CBMS password (required to update)',
                        enabled: !state.isSaving,
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter the CBMS password.'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField<TaxRegistration>(
                        label: 'Tax registration',
                        value: _taxRegistration,
                        enabled: !state.isSaving && existing == null,
                        items: [
                          for (final registration in TaxRegistration.values)
                            DropdownMenuItem(
                              value: registration,
                              child: Text(registration.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null)
                            setState(() => _taxRegistration = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Prices include tax'),
                        subtitle: const Text(
                          'Enable when entered prices already include VAT or PAN tax.',
                        ),
                        value: _taxIncluded,
                        onChanged: state.isSaving
                            ? null
                            : (value) => setState(() => _taxIncluded = value),
                      ),
                      AppFormError(message: _submitError ?? state.error),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton.expanded(
                        label: existing == null
                            ? 'Save CBMS settings'
                            : 'Update CBMS settings',
                        isLoading: state.isSaving,
                        onPressed: state.isSaving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
