import '../../../core/utils/text_format.dart';

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// `0.000001` -> `"0.000001"`, `1000.0` -> `"1000"` — mirrors
/// `formatConversionFactor` in `inventory_units_model.dart`; used here for
/// quantities, which are just as prone to floating-point noise.
String formatStockQuantity(double value) {
  if (value == value.truncateToDouble() && value.abs() < 1e15) {
    return value.truncate().toString();
  }
  final fixed = value.toStringAsFixed(3);
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Whether a product's on-hand quantity needs attention. Values match
/// exactly what `/stock` and `/stock/products/{id}` send for `status`.
enum StockStatus {
  inStock('IN_STOCK'),
  lowStock('LOW_STOCK'),
  outOfStock('OUT_OF_STOCK');

  const StockStatus(this.apiValue);

  final String apiValue;

  static StockStatus? fromApiValue(String? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }

  String get label => switch (this) {
    StockStatus.inStock => 'In stock',
    StockStatus.lowStock => 'Low stock',
    StockStatus.outOfStock => 'Out of stock',
  };
}

/// One product's stock level — what both the `/stock` list and
/// `/stock/products/{id}` return.
class StockLevelModel {
  const StockLevelModel({
    required this.productId,
    required this.productName,
    this.productCode,
    this.categoryName,
    required this.quantity,
    required this.reorderLevel,
    this.status,
    this.baseUnitName,
    this.baseUnitSymbol,
    this.updatedAt,
  });

  final int productId;
  final String productName;
  final String? productCode;
  final String? categoryName;
  final double quantity;
  final double reorderLevel;
  final StockStatus? status;
  final String? baseUnitName;
  final String? baseUnitSymbol;
  final DateTime? updatedAt;

  factory StockLevelModel.fromJson(Map<String, dynamic> json) {
    return StockLevelModel(
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      productCode: json['productCode'] as String?,
      categoryName: json['categoryName'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0,
      status: StockStatus.fromApiValue(json['status'] as String?),
      baseUnitName: json['baseUnitName'] as String?,
      baseUnitSymbol: json['baseUnitSymbol'] as String?,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

/// Headline counts for the stock dashboard — what `/stock/overview` returns.
class StockOverviewModel {
  const StockOverviewModel({
    required this.trackedProducts,
    required this.needingAttention,
  });

  final int trackedProducts;
  final int needingAttention;

  factory StockOverviewModel.fromJson(Map<String, dynamic> json) {
    return StockOverviewModel(
      trackedProducts: json['trackedProducts'] as int? ?? 0,
      needingAttention: json['needingAttention'] as int? ?? 0,
    );
  }
}

/// What originated a stock movement. A closed set per `/stock/movements`'
/// own documented `referenceType` values — unlike `movementType` below,
/// which the backend doesn't publish a closed list for.
enum StockReferenceType {
  purchase('PURCHASE'),
  sale('SALE'),
  adjustment('ADJUSTMENT'),
  writeOff('WRITE_OFF');

  const StockReferenceType(this.apiValue);

  final String apiValue;

  static StockReferenceType? fromApiValue(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }

  String get label => switch (this) {
    StockReferenceType.purchase => 'Purchase',
    StockReferenceType.sale => 'Sale',
    StockReferenceType.adjustment => 'Adjustment',
    StockReferenceType.writeOff => 'Write-off',
  };
}

/// `"PURCHASE_IN"` -> `"Purchase in"` — `movementType` doesn't have a
/// documented closed set of values (only one example, `PURCHASE_IN`, is
/// given), so this formats whatever the backend sends for display instead
/// of risking silently dropping a value a closed enum doesn't recognize.
String formatMovementType(String? value) => formatSnakeCaseLabel(value);

/// One entry in a product's movement ledger — what `/stock/movements`
/// lists, and what a write-off/adjustment returns.
class StockMovementModel {
  const StockMovementModel({
    required this.id,
    required this.productId,
    this.productName,
    this.movementType,
    required this.direction,
    required this.quantity,
    required this.balanceAfter,
    this.enteredQuantity,
    this.enteredUnitSymbol,
    this.referenceId,
    this.referenceType,
    this.remark,
    this.createdAt,
  });

  final int id;
  final int productId;
  final String? productName;

  /// Free-form — see [formatMovementType].
  final String? movementType;

  /// `1` for an increase, `-1` for a decrease (per the example payload) —
  /// used to pick the arrow/tone shown next to [quantity], not displayed
  /// on its own.
  final int direction;

  /// In the product's base unit — always positive; [direction] carries the
  /// sign.
  final double quantity;
  final double balanceAfter;

  /// The quantity as entered, in [enteredUnitSymbol] — e.g. "2 boxes" where
  /// [quantity] is the same amount converted to base units.
  final double? enteredQuantity;
  final String? enteredUnitSymbol;

  final int? referenceId;
  final StockReferenceType? referenceType;
  final String? remark;
  final DateTime? createdAt;

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String?,
      movementType: json['movementType'] as String?,
      direction: json['direction'] as int? ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      enteredQuantity: (json['enteredQuantity'] as num?)?.toDouble(),
      enteredUnitSymbol: json['enteredUnitSymbol'] as String?,
      referenceId: json['referenceId'] as int?,
      referenceType: StockReferenceType.fromApiValue(
        json['referenceType'] as String?,
      ),
      remark: json['remark'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

/// Body of both `POST /stock/write-offs` and `POST /stock/adjustments` —
/// identical shape, same reasoning as `UpsertInventoryUnitRequest`.
///
/// `movementType` isn't user-chosen free text — the two named
/// constructors set it to the one value each endpoint actually expects
/// (best-effort: the backend doesn't publish a closed list, only the
/// `PURCHASE_IN` example on the movement-ledger response, so these follow
/// that same `<REASON>_<DIRECTION>` shape, and adjustment's own two
/// directions rather than a raw string) — see `stock_movement_dialog.dart`
/// for where a wrong guess would need correcting.
class RecordStockMovementRequest {
  const RecordStockMovementRequest({
    required this.productId,
    required this.quantity,
    required this.unitId,
    required this.movementType,
    this.remark,
  });

  /// A loss — expired, damaged, lost. Always a decrease.
  const RecordStockMovementRequest.writeOff({
    required int productId,
    required double quantity,
    required int unitId,
    String? remark,
  }) : this(
         productId: productId,
         quantity: quantity,
         unitId: unitId,
         movementType: 'WRITE_OFF',
         remark: remark,
       );

  /// A correction after a physical count, in either direction.
  const RecordStockMovementRequest.adjustment({
    required int productId,
    required double quantity,
    required int unitId,
    required bool increase,
    String? remark,
  }) : this(
         productId: productId,
         quantity: quantity,
         unitId: unitId,
         movementType: increase ? 'ADJUSTMENT_IN' : 'ADJUSTMENT_OUT',
         remark: remark,
       );

  final int productId;
  final double quantity;
  final int unitId;
  final String movementType;
  final String? remark;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'unitId': unitId,
    'movementType': movementType,
    if (remark != null && remark!.isNotEmpty) 'remark': remark,
  };
}

/// Body of `PUT /stock/products/{productId}/reorder-level`.
class UpdateReorderLevelRequest {
  const UpdateReorderLevelRequest({required this.reorderLevel});

  final double reorderLevel;

  Map<String, dynamic> toJson() => {'reorderLevel': reorderLevel};
}
