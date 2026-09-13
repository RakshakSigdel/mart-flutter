import 'package:flutter/material.dart';

import '../../../../core/routes/route_constants.dart';
import '../../../../data/models/models_shared/sidebar_model.dart';

/// A sidebar row ready to render — resolved from the backend's raw
/// [SidebarItemModel]/[SidebarSubItemModel]. Every entry the backend sends
/// is kept; one this build of the app has no screen for still renders,
/// just pointed at [Routes.notFound] instead of a dead path. See
/// [resolveSidebarSections].
sealed class ResolvedSidebarEntry {
  const ResolvedSidebarEntry({required this.name, required this.icon});

  final String name;
  final IconData? icon;
}

/// A direct link to [path].
class ResolvedSidebarLink extends ResolvedSidebarEntry {
  const ResolvedSidebarLink({
    required super.name,
    required super.icon,
    required this.path,
  });

  final String path;
}

/// A collapsible header nesting a run of [children] links — never itself
/// navigable, same as the sidebar's original static groups.
class ResolvedSidebarGroup extends ResolvedSidebarEntry {
  const ResolvedSidebarGroup({
    required super.name,
    required super.icon,
    required this.children,
  });

  final List<ResolvedSidebarLink> children;
}

class ResolvedSidebarSection {
  const ResolvedSidebarSection({required this.title, required this.entries});

  final String title;
  final List<ResolvedSidebarEntry> entries;
}

/// Maps a backend `menuKey` to the route this build of the app actually
/// registers for it.
///
/// The backend can — and, per the full example response, already does —
/// describe menu items this app hasn't built a screen for yet (POS, Sales,
/// Purchasing, …). [resolveSidebarSections] still renders those — the menu
/// should look like the role's real menu, not a subset — but points them at
/// [Routes.notFound] instead of a path [AppRouter] doesn't know, so tapping
/// one lands on a real (if unfinished) page instead of a silent no-op or a
/// router error. Add a line here the same day a new sidebar-linked screen
/// ships, and it starts working for whichever roles the backend grants it
/// to — no other UI change needed.
const Map<String, String> _menuKeyRoutes = {
  'DASHBOARD': Routes.dashboard,
  'UNITS': Routes.inventoryUnits,
  'CATEGORIES': Routes.inventoryCategories,
  'PRODUCTS': Routes.inventoryProducts,
  'STAFF': Routes.staff,
  'STAFF_DIRECTORY': Routes.staff,
  'VENDOR': Routes.vendors,
  'VENDORS': Routes.vendors,
  'CUSTOMER': Routes.customers,
  'CUSTOMERS': Routes.customers,
  // The example response reuses 'INVENTORY' for the Stock item itself
  // (distinct from PRODUCTS/CATEGORIES/UNITS above) — all three of its
  // sub-items resolve here too, so the group collapses to one link.
  'INVENTORY': Routes.stock,
  'STOCK_LEVELS': Routes.stockLevels,
  'STOCK_ADJUSTMENTS': Routes.stockAdjustments,
  'STOCK_WRITE_OFFS': Routes.stockAdjustments,
  // "Goods receipts" isn't a distinct step in this build — recording a
  // purchase already receives the goods, so both keys land on the same
  // screen and the group collapses to one link.
  'PURCHASE': Routes.purchases,
  'PURCHASES': Routes.purchases,
  'PURCHASE_ORDERS': Routes.purchases,
  'GOODS_RECEIPTS': Routes.purchases,
  // "Point of sale" and "Sales" both land on the sales list, which is
  // also where ringing up a new sale lives (the "New sale" button) —
  // there's no separate quick-scan terminal screen in this build.
  // "Invoices" is the same bill by another name here, so it resolves the
  // same way; "Returns" genuinely isn't built yet and stays unresolved.
  'POS': Routes.pos,
  'SALES': Routes.sales,
  'ORDERS': Routes.sales,
  'INVOICES': Routes.sales,
  'REPORTS': Routes.salesReports,
  'SALES_REPORTS': Routes.salesReports,
  'SETTINGS': Routes.settings,
  'MART_SETTINGS': Routes.settings,
  'ACCOUNT': Routes.profile,
};

/// Every path [AdminShellScreen] renders as one of its own
/// `StatefulShellRoute` branches (see `AppRouter`) — switching between
/// these should replace the current branch location (`context.go`), the
/// same "tab-like" behavior as clicking between Dashboard/Units/Staff/…
/// always had.
///
/// A resolved path *not* in this set (e.g. [Routes.profile], or
/// [Routes.notFound] for a menu item this build doesn't implement yet) is
/// a full page that lives outside the shell entirely, with nothing else to
/// preserve underneath it — it belongs on top of the stack
/// (`context.push`) so the device/AppBar back action actually has
/// something to return to, the same way [ProfileAvatarButton] used to
/// reach it before the sidebar took over that job.
const Set<String> _shellBranchPaths = {
  Routes.dashboard,
  Routes.inventoryUnits,
  Routes.inventoryCategories,
  Routes.inventoryProducts,
  Routes.staff,
  Routes.vendors,
  Routes.customers,
  Routes.stock,
  Routes.stockLevels,
  Routes.stockAdjustments,
  Routes.purchases,
  Routes.sales,
  Routes.pos,
  Routes.salesReports,
  Routes.settings,
};

bool isSidebarShellBranch(String path) => _shellBranchPaths.contains(path);

/// Icon shown for a resolved menu key when the backend's own `icon` string
/// (a Lucide name, meant for a web client) doesn't match anything in
/// [_iconsByName] — e.g. a nested sub-item, which the schema never gives an
/// icon to at all.
const Map<String, IconData> _iconsByMenuKey = {
  'DASHBOARD': Icons.dashboard_outlined,
  'UNITS': Icons.straighten_outlined,
  'CATEGORIES': Icons.category_outlined,
  'PRODUCTS': Icons.inventory_outlined,
  'STAFF': Icons.people_outline_rounded,
  'STAFF_DIRECTORY': Icons.people_outline_rounded,
  'VENDOR': Icons.local_shipping_outlined,
  'CUSTOMER': Icons.person_outlined,
  'CUSTOMERS': Icons.people_outlined,
  'INVENTORY': Icons.inventory_outlined,
  'STOCK_LEVELS': Icons.inventory_outlined,
  'STOCK_ADJUSTMENTS': Icons.tune_rounded,
  'STOCK_WRITE_OFFS': Icons.remove_circle_outline_rounded,
  'PURCHASE': Icons.shopping_cart_outlined,
  'PURCHASE_ORDERS': Icons.shopping_cart_outlined,
  'GOODS_RECEIPTS': Icons.local_shipping_outlined,
  'POS': Icons.point_of_sale_outlined,
  'SALES': Icons.receipt_long_outlined,
  'ORDERS': Icons.receipt_long_outlined,
  'INVOICES': Icons.receipt_long_outlined,
  'ACCOUNT': Icons.account_circle_outlined,
};

/// Best-effort mapping from the backend's Lucide icon names to this app's
/// Material icon set. Covers every icon in the documented example response;
/// anything else falls back through [_iconsByMenuKey] and finally a generic
/// glyph in [sidebarIconFor].
const Map<String, IconData> _iconsByName = {
  'LayoutDashboard': Icons.dashboard_outlined,
  'ScanBarcode': Icons.qr_code_scanner_rounded,
  'ReceiptText': Icons.receipt_long_outlined,
  'Users': Icons.people_outline_rounded,
  'Package': Icons.inventory_2_outlined,
  'Scale': Icons.straighten_outlined,
  'Boxes': Icons.inventory_outlined,
  'ShoppingCart': Icons.shopping_cart_outlined,
  'Truck': Icons.local_shipping_outlined,
  'Landmark': Icons.account_balance_outlined,
  'ChartColumn': Icons.bar_chart_rounded,
  'UserCog': Icons.manage_accounts_outlined,
  'Settings': Icons.settings_outlined,
  'CircleUser': Icons.account_circle_outlined,
};

IconData sidebarIconFor(String iconName, {String? menuKey}) {
  final byName = _iconsByName[iconName];
  if (byName != null) return byName;
  final byMenuKey = menuKey == null ? null : _iconsByMenuKey[menuKey];
  if (byMenuKey != null) return byMenuKey;
  return Icons.apps_outlined;
}

/// Turns the backend's raw sidebar payload into what [AdminSidebar] renders
/// — every section/item/sub-item the backend sent, so the menu always
/// matches the role's real menu, grouped/sectioned the same way the
/// backend sent it.
///
/// - An item (or sub-item) whose `menuKey` isn't in [_menuKeyRoutes] still
///   renders, pointed at [Routes.notFound] instead of a dead path — see
///   that map's doc comment.
/// - An item with sub-items renders as a [ResolvedSidebarGroup] — unless
///   every one of them (however many) resolves to the very same path,
///   and that path is also where the item itself would land (or the item
///   itself is unresolved), in which case it collapses to a single
///   [ResolvedSidebarLink] rather than a group whose children all go to
///   the same place.
List<ResolvedSidebarSection> resolveSidebarSections(
  List<SidebarSectionModel> sections,
) {
  return [
    for (final section in sections)
      if (section.items.isNotEmpty)
        ResolvedSidebarSection(
          title: section.title,
          entries: [for (final item in section.items) _resolveItem(item)],
        ),
  ];
}

ResolvedSidebarEntry _resolveItem(SidebarItemModel item) {
  final ownRawPath = _menuKeyRoutes[item.menuKey];
  final ownPath = ownRawPath ?? Routes.notFound;
  final icon = sidebarIconFor(item.icon, menuKey: item.menuKey);

  if (item.subItems.isEmpty) {
    return ResolvedSidebarLink(name: item.name, icon: icon, path: ownPath);
  }

  final children = <ResolvedSidebarLink>[];
  final seenPaths = <String>{};
  // API entries with separate menu keys must retain their own routes so
  // selection is exclusive even when their screens share implementation.
  for (final sub in item.subItems) {
    final path = _menuKeyRoutes[sub.menuKey] ?? Routes.notFound;
    // Don't deduplicate notFound paths, let them all show up so we know what's missing.
    // Do deduplicate everything else so we don't get 4 links pointing to /sales.
    if (path != Routes.notFound && seenPaths.contains(path)) {
      continue;
    }
    seenPaths.add(path);
    children.add(ResolvedSidebarLink(name: sub.name, icon: null, path: path));
  }

  final distinctChildPaths = children.map((c) => c.path).toSet();
  if (distinctChildPaths.length == 1 &&
      (ownRawPath == null || ownRawPath == distinctChildPaths.first)) {
    return ResolvedSidebarLink(
      name: item.name,
      icon: icon,
      path: distinctChildPaths.first,
    );
  }

  return ResolvedSidebarGroup(name: item.name, icon: icon, children: children);
}

/// Shown while the real menu is loading and — since it goes through the same
/// [resolveSidebarSections] pipeline as the live response — as a
/// still-useful sidebar if `/me/sidebar` fails outright (offline, a
/// mid-session backend hiccup). Mirrors the sidebar's previous static
/// layout, so a fetch failure degrades to "the menu doesn't refresh" rather
/// than "navigation stops working".
final List<SidebarSectionModel> fallbackSidebarSections = [
  const SidebarSectionModel(
    title: 'Overview',
    items: [
      SidebarItemModel(
        name: 'Dashboard',
        path: Routes.dashboard,
        icon: 'LayoutDashboard',
        menuKey: 'DASHBOARD',
        subItems: [],
      ),
    ],
  ),
  const SidebarSectionModel(
    title: 'Inventory',
    items: [
      SidebarItemModel(
        name: 'Inventory',
        path: Routes.inventoryProducts,
        icon: 'Boxes',
        menuKey: '',
        subItems: [
          SidebarSubItemModel(
            name: 'Units',
            path: Routes.inventoryUnits,
            menuKey: 'UNITS',
          ),
          SidebarSubItemModel(
            name: 'Categories',
            path: Routes.inventoryCategories,
            menuKey: 'CATEGORIES',
          ),
          SidebarSubItemModel(
            name: 'Products',
            path: Routes.inventoryProducts,
            menuKey: 'PRODUCTS',
          ),
        ],
      ),
    ],
  ),
  const SidebarSectionModel(
    title: 'Stock',
    items: [
      SidebarItemModel(
        name: 'Stock',
        path: Routes.stock,
        icon: 'Boxes',
        menuKey: 'INVENTORY',
        subItems: [],
      ),
    ],
  ),
  const SidebarSectionModel(
    title: 'People',
    items: [
      SidebarItemModel(
        name: 'Staff',
        path: Routes.staff,
        icon: 'UserCog',
        menuKey: 'STAFF',
        subItems: [],
      ),
    ],
  ),
  const SidebarSectionModel(
    title: 'Sales',
    items: [
      SidebarItemModel(
        name: 'Sales',
        path: Routes.sales,
        icon: 'ReceiptText',
        menuKey: 'SALES',
        subItems: [],
      ),
    ],
  ),
  const SidebarSectionModel(
    title: 'Purchasing',
    items: [
      SidebarItemModel(
        name: 'Purchases',
        path: Routes.purchases,
        icon: 'ShoppingCart',
        menuKey: 'PURCHASE',
        subItems: [],
      ),
      SidebarItemModel(
        name: 'Vendors',
        path: Routes.vendors,
        icon: 'Truck',
        menuKey: 'VENDOR',
        subItems: [],
      ),
    ],
  ),
  const SidebarSectionModel(
    title: 'Account',
    items: [
      SidebarItemModel(
        name: 'My Account',
        path: Routes.profile,
        icon: 'CircleUser',
        menuKey: 'ACCOUNT',
        subItems: [],
      ),
    ],
  ),
];
