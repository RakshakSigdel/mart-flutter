import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../models/admin_nav_item.dart';

/// The admin area's navigation — used both as a permanent panel on wide
/// screens and as the content of a [Drawer] on narrow ones.
///
/// [isCollapsed] shrinks the panel to icons-only; pass `false` and leave
/// [onToggleCollapse] null when hosting this inside a [Drawer], since a
/// collapsed drawer defeats the point of overlaying the content.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.companyName,
    required this.onLogout,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String companyName;
  final VoidCallback onLogout;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  static const double expandedWidth = 248.0;
  static const double collapsedWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.normal,
      curve: AppAnimations.standard,
      width: isCollapsed ? collapsedWidth : expandedWidth,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _Header(isCollapsed: isCollapsed, companyName: companyName),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                itemCount: adminNavItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final item = adminNavItems[index];
                  final selected = index == selectedIndex;
                  return _SidebarTile(
                    item: item,
                    selected: selected,
                    isCollapsed: isCollapsed,
                    onTap: () => onItemSelected(index),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _SidebarActionTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              isCollapsed: isCollapsed,
              onTap: onLogout,
            ),
            if (onToggleCollapse case final onToggleCollapse?)
              _SidebarActionTile(
                icon: isCollapsed
                    ? Icons.keyboard_double_arrow_right_rounded
                    : Icons.keyboard_double_arrow_left_rounded,
                label: isCollapsed ? 'Expand' : 'Collapse',
                isCollapsed: isCollapsed,
                onTap: onToggleCollapse,
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isCollapsed, required this.companyName});

  final bool isCollapsed;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.smMd,
        AppSpacing.md,
        AppSpacing.smMd,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: AppTypography.subtitle.copyWith(color: AppColors.textOnPrimary),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.subtitle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.isCollapsed,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primaryDeep : AppColors.textSecondary;

    final tile = AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.standard,
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: AppBorderRadius.radiusMD,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppBorderRadius.radiusMD,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.radiusMD,
          splashColor: AppColors.pressedOverlay,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.smMd,
              vertical: AppSpacing.smMd,
            ),
            child: Row(
              mainAxisSize: isCollapsed ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: foreground,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: AppSpacing.smMd),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTypography.label.copyWith(color: foreground),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!isCollapsed) return tile;

    return Tooltip(message: item.label, waitDuration: const Duration(milliseconds: 400), child: tile);
  }
}

class _SidebarActionTile extends StatelessWidget {
  const _SidebarActionTile({
    required this.icon,
    required this.label,
    required this.isCollapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.pressedOverlay,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.smMd,
          ),
          child: Row(
            mainAxisSize: isCollapsed ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              if (!isCollapsed) ...[
                const SizedBox(width: AppSpacing.smMd),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!isCollapsed) return tile;

    return Tooltip(message: label, waitDuration: const Duration(milliseconds: 400), child: tile);
  }
}
