/// One leaf entry nested under a [SidebarItemModel] — no icon of its own,
/// same as the backend's shape.
class SidebarSubItemModel {
  const SidebarSubItemModel({
    required this.name,
    required this.path,
    required this.menuKey,
  });

  final String name;
  final String path;
  final String menuKey;

  factory SidebarSubItemModel.fromJson(Map<String, dynamic> json) {
    return SidebarSubItemModel(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      menuKey: json['menuKey'] as String? ?? '',
    );
  }
}

/// One row in a sidebar section — a direct link on its own, or (with
/// [subItems]) a group header for a nested run of links.
class SidebarItemModel {
  const SidebarItemModel({
    required this.name,
    required this.path,
    required this.icon,
    required this.menuKey,
    required this.subItems,
  });

  final String name;
  final String path;
  final String icon;
  final String menuKey;
  final List<SidebarSubItemModel> subItems;

  factory SidebarItemModel.fromJson(Map<String, dynamic> json) {
    return SidebarItemModel(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      menuKey: json['menuKey'] as String? ?? '',
      subItems:
          (json['subItems'] as List<dynamic>?)
              ?.map(
                (e) => SidebarSubItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}

/// One titled group of [items] — the top-level shape of `GET /me/sidebar`'s
/// `data` array. The backend tailors this to the signed-in user's role, so
/// two users can see different sections/items without the app knowing why.
class SidebarSectionModel {
  const SidebarSectionModel({required this.title, required this.items});

  final String title;
  final List<SidebarItemModel> items;

  factory SidebarSectionModel.fromJson(Map<String, dynamic> json) {
    return SidebarSectionModel(
      title: json['title'] as String? ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => SidebarItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
