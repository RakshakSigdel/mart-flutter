import 'package:flutter/material.dart';

/// One entry in the admin sidebar — an icon/label pair mapped to a
/// [StatefulShellBranch] index in [AdminShellScreen]'s navigation shell.
class AdminNavItem {
  const AdminNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.group,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// The collapsible section header this item nests under in the sidebar
  /// (e.g. "Inventory") — null for top-level items like Dashboard/Staff.
  ///
  /// Items sharing a group must stay contiguous within [adminNavItems]; the
  /// sidebar renders one header per contiguous run and looks up its icon in
  /// [adminNavGroupIcons].
  final String? group;
}

/// Icon shown next to each group header named by [AdminNavItem.group].
const Map<String, IconData> adminNavGroupIcons = {
  'Inventory': Icons.inventory_2_outlined,
};

/// The admin area's nav destinations, in branch order — index N here must
/// match the Nth [StatefulShellBranch] in the router.
const List<AdminNavItem> adminNavItems = [
  AdminNavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
  ),
  AdminNavItem(
    label: 'Units',
    icon: Icons.straighten_outlined,
    activeIcon: Icons.straighten_rounded,
    group: 'Inventory',
  ),
  AdminNavItem(
    label: 'Categories',
    icon: Icons.category_outlined,
    activeIcon: Icons.category_rounded,
    group: 'Inventory',
  ),
  AdminNavItem(
    label: 'Products',
    icon: Icons.inventory_outlined,
    activeIcon: Icons.inventory_rounded,
    group: 'Inventory',
  ),
  AdminNavItem(
    label: 'Staff',
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_alt_rounded,
  ),
];
