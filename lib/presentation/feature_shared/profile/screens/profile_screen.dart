import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/profile_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/change_password_dialog.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// "Who am I, and which mart am I working in" — the signed-in user's own
/// account, with a gateway to changing their own password. Reachable from
/// [ProfileAvatarButton] for roles with no sidebar of their own (today:
/// superadmin), and from the "Account" sidebar entry for every other role.
///
/// Full page rather than a dropdown/popover — same reasoning as every other
/// detail screen in this app: there's real content here, not a couple of
/// menu items.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final message = await showChangePasswordDialog(context);
    if (message != null && context.mounted) {
      AppSnackBar.success(
        context,
        message.trim().isEmpty ? 'Password changed.' : message,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Profile'),
      ),
      body: _buildBody(context, ref, state, profile),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ProfileState state,
    ProfileModel? profile,
  ) {
    if (state.isLoading && profile == null) {
      return const AppLoader();
    }

    if (state.error != null && profile == null) {
      return AppEmptyState.error(
        message: state.error,
        onAction: () => ref.read(profileControllerProvider.notifier).refresh(),
      );
    }

    if (profile == null) return const SizedBox.shrink();

    final initial = profile.displayName.isNotEmpty
        ? profile.displayName[0].toUpperCase()
        : '?';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initial,
                        style: AppTypography.heading.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(profile.displayName, style: AppTypography.title),
                    if (profile.role != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      AppBadge(
                        label: profile.role!,
                        tone: AppBadgeTone.primary,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Username', value: profile.username),
                    _InfoRow(label: 'Email', value: profile.email ?? '—'),
                    _InfoRow(
                      label: 'Mobile number',
                      value: profile.mobileNumber ?? '—',
                    ),
                    _InfoRow(
                      label: 'Company',
                      value: profile.companyName ?? '—',
                    ),
                    _InfoRow(label: 'Status', value: profile.status ?? '—'),
                    _InfoRow(
                      label: 'Last login',
                      value: _formatDate(profile.lastLoginAt),
                    ),
                    _InfoRow(
                      label: 'Account expires',
                      value: _formatDate(profile.expiresAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Change password',
                variant: AppButtonVariant.secondary,
                leading: const Icon(Icons.lock_outline_rounded),
                onPressed: () => _changePassword(context, ref),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Log out',
                variant: AppButtonVariant.ghost,
                leading: const Icon(Icons.logout),
                onPressed: () => _logout(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(Routes.login);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
