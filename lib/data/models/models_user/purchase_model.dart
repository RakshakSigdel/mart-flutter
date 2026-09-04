import '../models_shared/commerce_model.dart';

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// A purchase as returned by the list/create endpoints — the bill's own
/// totals, no line items. See [PurchaseDetailModel] for the full record.
class PurchaseModel {
  const PurchaseModel({
    required this.id,
    required this.billNumber,
    this.purchaseDate,
    required this.vendorId,
    this.vendorName,
    this.paymentMethod,
    this.taxScheme,
    required this.subTotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.vatAmount,
    required this.netTotal,
    required this.itemCount,
    this.createdAt,
  });

  final int id;
  final String billNumber;
  final DateTime? purchaseDate;
  final int vendorId;
  final String? vendorName;
  final String? paymentMethod;
  final String? taxScheme;
  final double subTotal;
  final double discountAmount;
  final double taxableAmount;
  final double vatAmount;
  final double netTotal;
  final int itemCount;
  final DateTime? createdAt;

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as int? ?? 0,
      billNumber: json['billNumber'] as String? ?? '',
      purchaseDate: _parseDate(json['purchaseDate']),
      vendorId: json['vendorId'] as int? ?? 0,
      vendorName: json['vendorName'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      taxScheme: json['taxScheme'] as String?,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      taxableAmount: (json['taxableAmount'] as num?)?.toDouble() ?? 0,
      vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0,
      netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
      itemCount: json['itemCount'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

/// One purchase in full — vendor details and every line item. What both
/// `GET /purchases/{id}` and `POST /purchases` return.
class PurchaseDetailModel {
  const PurchaseDetailModel({
    required this.id,
    required this.billNumber,
    this.purchaseDate,
    required this.vendorId,
    this.vendorName,
    this.vendorPanNumber,
    this.vendorAddress,
    this.paymentMethod,
    this.taxScheme,
    required this.subTotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.vatAmount,
    required this.netTotal,
    this.remark,
    required this.items,
    this.createdAt,
  });

  final int id;
  final String billNumber;
  final DateTime? purchaseDate;
  final int vendorId;
  final String? vendorName;
  final String? vendorPanNumber;
  final String? vendorAddress;
  final String? paymentMethod;
  final String? taxScheme;
  final double subTotal;
  final double discountAmount;
  final double taxableAmount;
  final double vatAmount;
  final double netTotal;
  final String? remark;
  final List<PurchaseItemModel> items;
  final DateTime? createdAt;

  factory PurchaseDetailModel.fromJson(Map<String, dynamic> json) {
    return PurchaseDetailModel(
      id: json['id'] as int? ?? 0,
      billNumber: json['billNumber'] as String? ?? '',
      purchaseDate: _parseDate(json['purchaseDate']),
      vendorId: json['vendorId'] as int? ?? 0,
      vendorName: json['vendorName'] as String?,
      vendorPanNumber: json['vendorPanNumber'] as String?,
      vendorAddress: json['vendorAddress'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      taxScheme: json['taxScheme'] as String?,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      taxableAmount: (json['taxableAmount'] as num?)?.toDouble() ?? 0,
      vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0,
      netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
      remark: json['remark'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => PurchaseItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

/// One line of a purchase — a product bought in one of its purchase units.
class PurchaseItemModel {
  const PurchaseItemModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productCode,
    required this.purchaseUnitId,
    this.purchaseUnitName,
    this.purchaseUnitSymbol,
    required this.quantity,
    required this.packQuantity,
    required this.quantityInBaseUnits,
    this.baseUnitSymbol,
    required this.rate,
    required this.lineTotal,
  });

  final int id;
  final int productId;
  final String? productName;
  final String? productCode;
  final int purchaseUnitId;
  final String? purchaseUnitName;
  final String? purchaseUnitSymbol;

  /// In [purchaseUnitSymbol] — e.g. "2 boxes".
  final double quantity;
  final double packQuantity;

  /// The same quantity converted to the product's base unit — e.g. "24 pcs"
  /// for 2 boxes of a pack-of-12.
  final double quantityInBaseUnits;
  final String? baseUnitSymbol;

  final double rate;
  final double lineTotal;

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String?,
      productCode: json['productCode'] as String?,
      purchaseUnitId: json['purchaseUnitId'] as int? ?? 0,
      purchaseUnitName: json['purchaseUnitName'] as String?,
      purchaseUnitSymbol: json['purchaseUnitSymbol'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      packQuantity: (json['packQuantity'] as num?)?.toDouble() ?? 0,
      quantityInBaseUnits:
          (json['quantityInBaseUnits'] as num?)?.toDouble() ?? 0,
      baseUnitSymbol: json['baseUnitSymbol'] as String?,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Body of `POST /purchases`.
class CreatePurchaseRequest {
  const CreatePurchaseRequest({
    required this.vendorId,
    required this.billNumber,
    required this.purchaseDate,
    required this.paymentMethod,
    required this.taxScheme,
    this.discountAmount,
    this.remark,
    required this.items,
  });

  final int vendorId;
  final String billNumber;
  final DateTime purchaseDate;
  final PaymentMethod paymentMethod;
  final TaxScheme taxScheme;
  final double? discountAmount;
  final String? remark;
  final List<CreatePurchaseItemRequest> items;

  Map<String, dynamic> toJson() => {
    'vendorId': vendorId,
    'billNumber': billNumber,
    'purchaseDate': _dateOnly(purchaseDate),
    'paymentMethod': paymentMethod.apiValue,
    'taxScheme': taxScheme.apiValue,
    if (discountAmount != null) 'discountAmount': discountAmount,
    if (remark != null && remark!.isNotEmpty) 'remark': remark,
    'items': items.map((e) => e.toJson()).toList(),
  };

  static String _dateOnly(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

/// One line of [CreatePurchaseRequest.items].
class CreatePurchaseItemRequest {
  const CreatePurchaseItemRequest({
    required this.productId,
    required this.purchaseUnitId,
    required this.quantity,
    required this.rate,
  });

  final int productId;
  final int purchaseUnitId;
  final double quantity;
  final double rate;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'purchaseUnitId': purchaseUnitId,
    'quantity': quantity,
    'rate': rate,
  };
}
