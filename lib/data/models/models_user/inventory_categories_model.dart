import 'inventory_units_model.dart';

/// Which side of a trade a unit permission applies to. Values match exactly
/// what `/inventory/categories/{id}/units` accepts for the `usage` field.
enum CategoryUnitUsage {
  purchase('PURCHASE'),
  selling('SELLING');

  const CategoryUnitUsage(this.apiValue);

  final String apiValue;

  static CategoryUnitUsage? fromApiValue(String? value) {
    for (final usage in values) {
      if (usage.apiValue == value) return usage;
    }
    return null;
  }

  String get label => '${apiValue[0]}${apiValue.substring(1).toLowerCase()}';
}

/// A category as returned by the list/selection/create/edit endpoints —
/// "summaries only, no unit policy" per the list endpoint's own
/// description. See [InventoryCategoryDetailModel] for the full record.
class InventoryCategoryModel {
  const InventoryCategoryModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.name,
    this.description,
    this.image,
  });

  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String name;
  final String? description;

  /// A URL, if the mart has set one — this app doesn't upload images, it
  /// only stores/displays whatever URL the backend has on file.
  final String? image;

  factory InventoryCategoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryCategoryModel(
      id: json['id'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

/// One category with its permitted units and product count — what
/// `GET /inventory/categories/{id}` and the unit-permission endpoints
/// return, unlike the plain list which only returns
/// [InventoryCategoryModel].
class InventoryCategoryDetailModel {
  const InventoryCategoryDetailModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.name,
    this.description,
    this.image,
    required this.purchaseUnits,
    required this.sellingUnits,
    required this.productCount,
  });

  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String name;
  final String? description;
  final String? image;

  /// Units this category may be bought in.
  final List<InventoryUnitModel> purchaseUnits;

  /// Units this category may be sold in.
  final List<InventoryUnitModel> sellingUnits;

  final int productCount;

  factory InventoryCategoryDetailModel.fromJson(Map<String, dynamic> json) {
    return InventoryCategoryDetailModel(
      id: json['id'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      purchaseUnits: (json['purchaseUnits'] as List<dynamic>?)
              ?.map((e) => InventoryUnitModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sellingUnits: (json['sellingUnits'] as List<dynamic>?)
              ?.map((e) => InventoryUnitModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      productCount: json['productCount'] as int? ?? 0,
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// The backend only allows removing an *empty* category — see
  /// `DELETE /inventory/categories/{id}`'s own description.
  bool get isEmpty => productCount == 0;

  InventoryCategoryModel get summary => InventoryCategoryModel(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        name: name,
        description: description,
        image: image,
      );
}

/// Body of both `POST /inventory/categories` and
/// `PUT /inventory/categories/{id}` — the two requests are identical in
/// shape, so one class covers both.
class UpsertInventoryCategoryRequest {
  const UpsertInventoryCategoryRequest({
    required this.name,
    this.description,
    this.image,
  });

  final String name;
  final String? description;
  final String? image;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
      };
}

/// Body of `POST /inventory/categories/{id}/units` — grants a unit
/// permission for one side of the trade.
class AssignCategoryUnitRequest {
  const AssignCategoryUnitRequest({required this.unitId, required this.usage});

  final int unitId;
  final CategoryUnitUsage usage;

  Map<String, dynamic> toJson() => {
        'unitId': unitId,
        'usage': usage.apiValue,
      };
}
