import 'package:flutter/material.dart';

/// One entry in the admin sidebar — an icon/label pair mapped to a
/// [StatefulShellBranch] index in [AdminShellScreen]'s navigation shell.
class AdminNavItem {
  const AdminNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// The admin area's nav destinations, in branch order — index N here must
/// match the Nth [StatefulShellBranch] in the router. More are added here
/// as the corresponding feature screens land.
const List<AdminNavItem> adminNavItems = [
  AdminNavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
  ),
  AdminNavItem(
    label: 'Staff',
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_alt_rounded,
  ),
];
