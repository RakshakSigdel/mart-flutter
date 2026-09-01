import 'inventory_units_model.dart';

DateTime? _parseDate(Object? value) => value is String ? DateTime.tryParse(value) : null;

/// `default` and `isDefault` both show up for the same boolean in every
/// purchase/selling-unit payload — a Jackson bean-introspection artifact
/// from a field literally named `default` (a reserved word, so the getter
/// became `isDefault()`, and the serializer emitted both). `isDefault` wins
/// when both are present; either alone is honored.
bool _parseDefault(Map<String, dynamic> json) {
  final isDefault = json['isDefault'];
  if (isDefault is bool) return isDefault;
  return json['default'] as bool? ?? false;
}

/// `2026-09-01` -> [DateTime] — VAT rates use date-only fields, unlike the
/// timestamp fields (`createdAt`, etc.) elsewhere in this model.
DateTime? _parseDateOnly(Object? value) => _parseDate(value);

/// A price/rate formatted to two decimal places for display — every
/// currency-shaped field on this model (`sellingPrice`, `purchasePrice`,
/// `mrp`) goes through this so they read consistently.
String formatMoney(double? value) => value == null ? '—' : value.toStringAsFixed(2);

/// A [DateTime] formatted as the date-only string the backend expects for
/// `effectiveFrom` — see `staffDateOnly` for why a plain
/// `.toIso8601String()` would be wrong here (it carries a time component
/// this field doesn't take).
String productDateOnly(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

/// A product as returned by the list/create/edit endpoints — "summaries
/// only, no trading configuration" per the list endpoint's own description.
/// See [ProductDetailModel] for the full record.
class ProductModel {
  const ProductModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.name,
    this.productCode,
    this.brand,
    this.image,
    required this.active,
    this.categoryId,
    this.categoryName,
    this.sellingPrice,
    this.sellingUnitSymbol,
  });

  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String name;
  final String? productCode;
  final String? brand;

  /// A URL, if the mart has set one — this app doesn't upload images, it
  /// only stores/displays whatever URL the backend has on file.
  final String? image;

  final bool active;
  final int? categoryId;
  final String? categoryName;

  /// The price/unit shown on the list — sourced from the product's default
  /// selling unit, if it has one yet.
  final double? sellingPrice;
  final String? sellingUnitSymbol;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      name: json['name'] as String? ?? '',
      productCode: json['productCode'] as String?,
      brand: json['brand'] as String?,
      image: json['image'] as String?,
      active: json['active'] as bool? ?? true,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
      sellingUnitSymbol: json['sellingUnitSymbol'] as String?,
    );
  }
}

/// One product in full — base unit, purchase units, selling units. What
/// `GET /inventory/products/{id}` returns, unlike the plain list which only
/// returns [ProductModel].
class ProductDetailModel {
  const ProductDetailModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.name,
    this.productCode,
    this.brand,
    this.image,
    required this.active,
    this.categoryId,
    this.categoryName,
    this.sellingPrice,
    this.sellingUnitSymbol,
    this.description,
    this.baseCode,
    required this.baseUnit,
    required this.purchaseUnits,
    required this.sellingUnits,
  });

  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String name;
  final String? productCode;
  final String? brand;
  final String? image;
  final bool active;
  final int? categoryId;
  final String? categoryName;
  final double? sellingPrice;
  final String? sellingUnitSymbol;

  final String? description;
  final String? baseCode;

  /// Fixed at creation — never sent in an edit request.
  final InventoryUnitModel? baseUnit;

  final List<ProductPurchaseUnitModel> purchaseUnits;
  final List<ProductSellingUnitModel> sellingUnits;

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      id: json['id'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      name: json['name'] as String? ?? '',
      productCode: json['productCode'] as String?,
      brand: json['brand'] as String?,
      image: json['image'] as String?,
      active: json['active'] as bool? ?? true,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
      sellingUnitSymbol: json['sellingUnitSymbol'] as String?,
      description: json['description'] as String?,
      baseCode: json['baseCode'] as String?,
      baseUnit: json['baseUnit'] == null
          ? null
          : InventoryUnitModel.fromJson(json['baseUnit'] as Map<String, dynamic>),
      purchaseUnits: (json['purchaseUnits'] as List<dynamic>?)
              ?.map((e) => ProductPurchaseUnitModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sellingUnits: (json['sellingUnits'] as List<dynamic>?)
              ?.map((e) => ProductSellingUnitModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  ProductModel get summary => ProductModel(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        name: name,
        productCode: productCode,
        brand: brand,
        image: image,
        active: active,
        categoryId: categoryId,
        categoryName: categoryName,
        sellingPrice: sellingPrice,
        sellingUnitSymbol: sellingUnitSymbol,
      );
}

/// How this product is bought in one unit — as embedded in [ProductDetailModel]
/// and returned by the purchase-units list endpoint. No VAT history here —
/// see [ProductPurchaseUnitDetailModel] for that.
class ProductPurchaseUnitModel {
  const ProductPurchaseUnitModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.unit,
    required this.packQuantity,
    required this.purchasePrice,
    required this.active,
    this.currentVatRate,
    required this.isDefault,
  });

  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Fixed once created — never sent in an edit request.
  final InventoryUnitModel unit;

  final double packQuantity;
  final double purchasePrice;
  final bool active;
  final double? currentVatRate;
  final bool isDefault;

  factory ProductPurchaseUnitModel.fromJson(Map<String, dynamic> json) {
    return ProductPurchaseUnitModel(
      id: json['id'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      unit: InventoryUnitModel.fromJson(json['unit'] as Map<String, dynamic>? ?? const {}),
      packQuantity: (json['packQuantity'] as num?)?.toDouble() ?? 0,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
      active: json['active'] as bool? ?? true,
      currentVatRate: (json['currentVatRate'] as num?)?.toDouble(),
      isDefault: _parseDefault(json),
    );
  }
}

/// One purchase unit with its full VAT history — what
/// `GET /inventory/products/{id}/purchase-units/{purchaseUnitId}` returns.
class ProductPurchaseUnitDetailModel {
  const ProductPurchaseUnitDetailModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.unit,
    required this.packQuantity,
    required this.purchasePrice,
    required this.active,
    this.currentVatRate,
    required this.isDefault,
    required this.vatRates,
  });

  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final InventoryUnitModel unit;
  final double packQuantity;
  final double purchasePrice;
  final bool active;
  final double? currentVatRate;
  final bool isDefault;
  final List<VatRateModel> vatRates;

  factory ProductPurchaseUnitDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductPurchaseUnitDetailModel(
      id: json['id'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      unit: InventoryUnitModel.fromJson(json['unit'] as Map<String, dynamic>? ?? const {}),
      packQuantity: (json['packQuantity'] as num?)?.toDouble() ?? 0,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
      active: json['active'] as bool? ?? true,
      currentVatRate: (json['currentVatRate'] as num?)?.toDouble(),
      isDefault: _parseDefault(json),
      vatRates: (json['vatRates'] as List<dynamic>?)
              ?.map((e) => VatRateModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// How this product is sold in one unit — pricing, SKU, barcode.
class ProductSellingUnitModel {
  const ProductSellingUnitModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.unit,
    required this.packQuantity,
    required this.sellingPrice,
    this.mrp,
    this.sku,
    this.barcode,
    required this.active,
    required this.isDefault,
  });

  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Fixed once created — never sent in an edit request.
  final InventoryUnitModel unit;

  final double packQuantity;
  final double sellingPrice;
  final double? mrp;
  final String? sku;
  final String? barcode;
  final bool active;
  final bool isDefault;

  factory ProductSellingUnitModel.fromJson(Map<String, dynamic> json) {
    return ProductSellingUnitModel(
      id: json['id'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      unit: InventoryUnitModel.fromJson(json['unit'] as Map<String, dynamic>? ?? const {}),
      packQuantity: (json['packQuantity'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      mrp: (json['mrp'] as num?)?.toDouble(),
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      active: json['active'] as bool? ?? true,
      isDefault: _parseDefault(json),
    );
  }
}

/// One entry in a purchase unit's VAT history. `effectiveTo` is null for
/// whichever rate is currently in force — it's only set once a later rate
/// supersedes it.
class VatRateModel {
  const VatRateModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.rate,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double rate;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  factory VatRateModel.fromJson(Map<String, dynamic> json) {
    return VatRateModel(
      id: json['id'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      effectiveFrom: _parseDateOnly(json['effectiveFrom']),
      effectiveTo: _parseDateOnly(json['effectiveTo']),
    );
  }
}

/// Body of `POST /inventory/products`.
class CreateProductRequest {
  const CreateProductRequest({
    required this.name,
    this.productCode,
    this.baseCode,
    this.description,
    this.brand,
    this.image,
    required this.categoryId,
    required this.baseUnitId,
  });

  final String name;
  final String? productCode;
  final String? baseCode;
  final String? description;
  final String? brand;
  final String? image;
  final int categoryId;
  final int baseUnitId;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (productCode != null) 'productCode': productCode,
        if (baseCode != null) 'baseCode': baseCode,
        if (description != null) 'description': description,
        if (brand != null) 'brand': brand,
        if (image != null) 'image': image,
        'categoryId': categoryId,
        'baseUnitId': baseUnitId,
      };
}

/// Body of `PUT /inventory/products/{id}` — no category/base unit; those
/// are fixed at creation.
class UpdateProductRequest {
  const UpdateProductRequest({
    required this.name,
    this.productCode,
    this.baseCode,
    this.description,
    this.brand,
    this.image,
    required this.active,
  });

  final String name;
  final String? productCode;
  final String? baseCode;
  final String? description;
  final String? brand;
  final String? image;
  final bool active;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (productCode != null) 'productCode': productCode,
        if (baseCode != null) 'baseCode': baseCode,
        if (description != null) 'description': description,
        if (brand != null) 'brand': brand,
        if (image != null) 'image': image,
        'active': active,
      };
}

/// Body of `POST /inventory/products/{id}/purchase-units/{purchaseUnitId}/vat`
/// and the nested `vat` object on [CreatePurchaseUnitRequest].
class OpenVatRateRequest {
  const OpenVatRateRequest({required this.rate, required this.effectiveFrom});

  final double rate;
  final DateTime effectiveFrom;

  Map<String, dynamic> toJson() => {
        'rate': rate,
        'effectiveFrom': productDateOnly(effectiveFrom),
      };
}

/// Body of `POST /inventory/products/{id}/purchase-units`.
class CreatePurchaseUnitRequest {
  const CreatePurchaseUnitRequest({
    required this.unitId,
    required this.packQuantity,
    required this.purchasePrice,
    required this.active,
    required this.isDefault,
    required this.vat,
  });

  final int unitId;
  final double packQuantity;
  final double purchasePrice;
  final bool active;
  final bool isDefault;
  final OpenVatRateRequest vat;

  Map<String, dynamic> toJson() => {
        'unitId': unitId,
        'packQuantity': packQuantity,
        'purchasePrice': purchasePrice,
        'active': active,
        'default': isDefault,
        'isDefault': isDefault,
        'vat': vat.toJson(),
      };
}

/// Body of `PUT /inventory/products/{id}/purchase-units/{purchaseUnitId}` —
/// no unit (fixed) and no VAT (its own endpoint).
class UpdatePurchaseUnitRequest {
  const UpdatePurchaseUnitRequest({
    required this.packQuantity,
    required this.purchasePrice,
    required this.active,
    required this.isDefault,
  });

  final double packQuantity;
  final double purchasePrice;
  final bool active;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
        'packQuantity': packQuantity,
        'purchasePrice': purchasePrice,
        'active': active,
        'default': isDefault,
        'isDefault': isDefault,
      };
}

/// Body of `POST /inventory/products/{id}/selling-units`.
class CreateSellingUnitRequest {
  const CreateSellingUnitRequest({
    required this.unitId,
    required this.packQuantity,
    required this.sellingPrice,
    this.mrp,
    this.sku,
    this.barcode,
    required this.active,
    required this.isDefault,
  });

  final int unitId;
  final double packQuantity;
  final double sellingPrice;
  final double? mrp;
  final String? sku;
  final String? barcode;
  final bool active;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
        'unitId': unitId,
        'packQuantity': packQuantity,
        'sellingPrice': sellingPrice,
        if (mrp != null) 'mrp': mrp,
        if (sku != null) 'sku': sku,
        if (barcode != null) 'barcode': barcode,
        'active': active,
        'default': isDefault,
        'isDefault': isDefault,
      };
}

/// Body of `PUT /inventory/products/{id}/selling-units/{sellingUnitId}` —
/// no unit; that's fixed.
class UpdateSellingUnitRequest {
  const UpdateSellingUnitRequest({
    required this.packQuantity,
    required this.sellingPrice,
    this.mrp,
    this.sku,
    this.barcode,
    required this.active,
    required this.isDefault,
  });

  final double packQuantity;
  final double sellingPrice;
  final double? mrp;
  final String? sku;
  final String? barcode;
  final bool active;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
        'packQuantity': packQuantity,
        'sellingPrice': sellingPrice,
        if (mrp != null) 'mrp': mrp,
        if (sku != null) 'sku': sku,
        if (barcode != null) 'barcode': barcode,
        'active': active,
        'default': isDefault,
        'isDefault': isDefault,
      };
}
