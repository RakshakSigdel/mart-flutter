import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../auth/controller/auth_controller.dart';

/// The signed-in user's initial, as a small tappable circle — the gateway
/// to [Routes.profile] from a top-level `AppBar` that has no sidebar of its
/// own to carry an "Account" link instead (today: only the superadmin
/// area's own screen — the mart-admin shell's sidebar handles this job for
/// every other role, see `SidebarController`/`AdminSidebar`).
class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;
    final name = session?.displayName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Tooltip(
        message: 'Your profile',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push(Routes.profile),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: AppTypography.subtitle.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
