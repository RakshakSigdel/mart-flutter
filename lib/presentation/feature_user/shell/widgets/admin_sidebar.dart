import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../models/sidebar_menu_registry.dart';

/// The admin area's navigation — used both as a permanent panel on wide
/// screens and as the content of a [Drawer] on narrow ones.
///
/// Renders whatever [sections] the signed-in user's own `GET /me/sidebar`
/// resolved to (see [SidebarController]) — role-specific, and already
/// filtered down to entries this app can actually navigate to.
///
/// [isCollapsed] shrinks the panel to icons-only; pass `false` and leave
/// [onToggleCollapse] null when hosting this inside a [Drawer], since a
/// collapsed drawer defeats the point of overlaying the content.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.sections,
    required this.selectedPath,
    required this.onNavigate,
    required this.companyName,
    required this.onLogout,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.isRefreshing = false,
    this.refreshFailed = false,
    this.onRetry,
  });

  final List<ResolvedSidebarSection> sections;

  /// The current screen's route — compared against each entry's own path
  /// to decide which tile lights up as selected.
  final String? selectedPath;
  final ValueChanged<String> onNavigate;
  final String companyName;
  final VoidCallback onLogout;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  /// Whether a background refresh of the menu is in flight — a first-load
  /// skeleton never shows since [SidebarState] starts pre-filled with a
  /// working fallback menu (see `SidebarState.initial`), so this is only
  /// ever a subtle "still current?" hint, never a blocking spinner.
  final bool isRefreshing;

  /// Whether the most recent refresh failed — [sections] is still whatever
  /// loaded last (or the fallback), so this only surfaces a small
  /// tap-to-retry affordance rather than blocking navigation.
  final bool refreshFailed;
  final VoidCallback? onRetry;

  static const double expandedWidth = 248.0;
  static const double collapsedWidth = 80.0;
  static const IconData _fallbackIcon = Icons.circle_outlined;

  List<Widget> _buildRows() {
    final rows = <Widget>[];
    for (final section in sections) {
      if (!isCollapsed && section.title.isNotEmpty) {
        rows.add(_SectionHeader(title: section.title));
      }
      for (final entry in section.entries) {
        switch (entry) {
          case ResolvedSidebarLink():
            rows.add(
              _SidebarTile(
                label: entry.name,
                icon: entry.icon ?? _fallbackIcon,
                selected: entry.path == selectedPath,
                isCollapsed: isCollapsed,
                onTap: () => onNavigate(entry.path),
              ),
            );
          case ResolvedSidebarGroup():
            if (isCollapsed) {
              for (final child in entry.children) {
                rows.add(
                  _SidebarTile(
                    label: child.name,
                    icon: entry.icon ?? _fallbackIcon,
                    selected: child.path == selectedPath,
                    isCollapsed: true,
                    onTap: () => onNavigate(child.path),
                  ),
                );
              }
            } else {
              rows.add(
                _SidebarGroup(
                  label: entry.name,
                  icon: entry.icon ?? _fallbackIcon,
                  containsSelected: entry.children.any(
                    (child) => child.path == selectedPath,
                  ),
                  children: _withGaps([
                    for (final child in entry.children)
                      _SidebarTile(
                        label: child.name,
                        icon: child.icon ?? _fallbackIcon,
                        selected: child.path == selectedPath,
                        isCollapsed: false,
                        indented: true,
                        onTap: () => onNavigate(child.path),
                      ),
                  ]),
                ),
              );
            }
        }
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
            _Header(
              isCollapsed: isCollapsed,
              companyName: companyName,
              isRefreshing: isRefreshing,
              refreshFailed: refreshFailed,
              onRetry: onRetry,
            ),
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
  const _Header({
    required this.isCollapsed,
    required this.companyName,
    required this.isRefreshing,
    required this.refreshFailed,
    required this.onRetry,
  });

  final bool isCollapsed;
  final String companyName;
  final bool isRefreshing;
  final bool refreshFailed;
  final VoidCallback? onRetry;

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
              style: AppTypography.subtitle.copyWith(
                color: AppColors.textOnPrimary,
              ),
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
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.xs),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (refreshFailed)
            Tooltip(
              message: "Couldn't refresh menu — tap to retry",
              child: InkWell(
                onTap: onRetry,
                borderRadius: AppBorderRadius.radiusMD,
                child: const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xs),
                  child: Icon(
                    Icons.sync_problem_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.smMd,
        AppSpacing.sm,
        AppSpacing.smMd,
        AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.eyebrow.copyWith(
          letterSpacing: 0.4,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

/// A collapsible section header — e.g. "Inventory" — nesting a run of
/// related [_SidebarTile]s. Starts closed, except when the current page is
/// one of its children (so the active item isn't hidden on load); the
/// user's collapse/expand choice from there only lives for this widget's
/// lifetime (not persisted), same as the sidebar's own rail collapse state.
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
  late bool _expanded = widget.containsSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.containsSelected
        ? AppColors.primaryDeep
        : AppColors.textSecondary;

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
    required this.label,
    required this.icon,
    required this.selected,
    required this.isCollapsed,
    required this.onTap,
    this.indented = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isCollapsed;
  final VoidCallback onTap;

  /// Extra leading space for a tile nested under a [_SidebarGroup]. Ignored
  /// while [isCollapsed], since grouped items render as flat top-level
  /// tiles in that mode.
  final bool indented;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.primaryDeep
        : AppColors.textSecondary;

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
                if (indented && !isCollapsed)
                  const SizedBox(width: AppSpacing.lg),
                Icon(icon, size: 22, color: foreground),
                if (!isCollapsed) ...[
                  const SizedBox(width: AppSpacing.smMd),
                  Expanded(
                    child: Text(
                      label,
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

    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 400),
      child: tile,
    );
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
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!isCollapsed) return tile;

    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 400),
      child: tile,
    );
  }
}
