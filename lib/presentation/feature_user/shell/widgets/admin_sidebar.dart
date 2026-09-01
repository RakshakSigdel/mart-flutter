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

  /// Flattens [adminNavItems] into sidebar rows: a plain tile for ungrouped
  /// items, or one collapsible [_SidebarGroup] per contiguous run of items
  /// sharing a [AdminNavItem.group].
  ///
  /// While the sidebar itself is icon-only ([isCollapsed]), groups are
  /// skipped and their children rendered as flat tiles instead — there's no
  /// room for a nested header in a rail that narrow, and each tile's own
  /// tooltip already carries its label.
  List<Widget> _buildRows() {
    final rows = <Widget>[];
    var i = 0;
    while (i < adminNavItems.length) {
      final item = adminNavItems[i];
      final group = item.group;
      if (group == null) {
        final index = i;
        rows.add(
          _SidebarTile(
            item: item,
            selected: index == selectedIndex,
            isCollapsed: isCollapsed,
            onTap: () => onItemSelected(index),
          ),
        );
        i++;
        continue;
      }

      final indices = <int>[];
      while (i < adminNavItems.length && adminNavItems[i].group == group) {
        indices.add(i);
        i++;
      }

      if (isCollapsed) {
        for (final index in indices) {
          rows.add(
            _SidebarTile(
              item: adminNavItems[index],
              selected: index == selectedIndex,
              isCollapsed: true,
              onTap: () => onItemSelected(index),
            ),
          );
        }
      } else {
        rows.add(
          _SidebarGroup(
            label: group,
            icon: adminNavGroupIcons[group] ?? Icons.folder_outlined,
            containsSelected: indices.contains(selectedIndex),
            children: _withGaps([
              for (final index in indices)
                _SidebarTile(
                  item: adminNavItems[index],
                  selected: index == selectedIndex,
                  isCollapsed: false,
                  indented: true,
                  onTap: () => onItemSelected(index),
                ),
            ]),
          ),
        );
      }
    }
    return _withGaps(rows);
  }

  static List<Widget> _withGaps(List<Widget> widgets) => [
        for (var i = 0; i < widgets.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          widgets[i],
        ],
      ];

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
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                children: _buildRows(),
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

/// A collapsible section header — e.g. "Inventory" — nesting a run of
/// related [_SidebarTile]s. Defaults open; the user's collapse/expand choice
/// only lives for this widget's lifetime (not persisted), same as the
/// sidebar's own rail collapse state.
class _SidebarGroup extends StatefulWidget {
  const _SidebarGroup({
    required this.label,
    required this.icon,
    required this.containsSelected,
    required this.children,
  });

  final String label;
  final IconData icon;

  /// Whether the currently active nav item lives inside this group — used
  /// only to tint the header, so the active section stays visible even
  /// while its own tile styling is out of view.
  final bool containsSelected;

  final List<Widget> children;

  @override
  State<_SidebarGroup> createState() => _SidebarGroupState();
}

class _SidebarGroupState extends State<_SidebarGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.containsSelected ? AppColors.primaryDeep : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: AppBorderRadius.radiusMD,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: AppBorderRadius.radiusMD,
            splashColor: AppColors.pressedOverlay,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.smMd,
                vertical: AppSpacing.smMd,
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: foreground),
                  const SizedBox(width: AppSpacing.smMd),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: AppTypography.label.copyWith(color: foreground),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: AppAnimations.fast,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) Column(children: widget.children),
      ],
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.isCollapsed,
    required this.onTap,
    this.indented = false,
  });

  final AdminNavItem item;
  final bool selected;
  final bool isCollapsed;
  final VoidCallback onTap;

  /// Extra leading space for a tile nested under a [_SidebarGroup]. Ignored
  /// while [isCollapsed], since grouped items render as flat top-level
  /// tiles in that mode.
  final bool indented;

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
                if (indented && !isCollapsed) const SizedBox(width: AppSpacing.lg),
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
