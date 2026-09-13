import '../models_shared/commerce_model.dart';

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Whether a bill has been paid off. Values match exactly what
/// `/sales`'s own `status` filter documents.
enum PaymentStatus {
  unpaid('UNPAID'),
  partial('PARTIAL'),
  paid('PAID');

  const PaymentStatus(this.apiValue);

  final String apiValue;

  static PaymentStatus? fromApiValue(String? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }

  String get label => switch (this) {
    PaymentStatus.unpaid => 'Unpaid',
    PaymentStatus.partial => 'Partial',
    PaymentStatus.paid => 'Paid',
  };
}

/// A bill as returned by the list/create endpoints — the bill's own
/// totals, no line items. See [SaleDetailModel] for the full record.
class SaleModel {
  const SaleModel({
    required this.id,
    required this.invoiceNumber,
    this.soldAt,
    this.channel,
    this.taxScheme,
    this.customerName,
    required this.subTotal,
    required this.discountAmount,
    required this.vatAmount,
    required this.netTotal,
    required this.paidAmount,
    required this.dueAmount,
    this.paymentMethod,
    this.paymentStatus,
    required this.itemCount,
  });

  final int id;
  final String invoiceNumber;
  final DateTime? soldAt;
  final String? channel;
  final String? taxScheme;
  final String? customerName;
  final double subTotal;
  final double discountAmount;
  final double vatAmount;
  final double netTotal;
  final double paidAmount;
  final double dueAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final int itemCount;

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] as int? ?? 0,
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      soldAt: _parseDate(json['soldAt']),
      channel: json['channel'] as String?,
      taxScheme: json['taxScheme'] as String?,
      customerName: json['customerName'] as String?,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0,
      netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      itemCount: json['itemCount'] as int? ?? 0,
    );
  }
}

/// One bill in full — customer details and every line item. What
/// `GET /sales/{id}`, `GET /sales/by-invoice/{invoiceNumber}`,
/// `POST /sales` and `POST /sales/{id}/payments` all return.
class SaleDetailModel {
  const SaleDetailModel({
    required this.id,
    required this.invoiceNumber,
    this.soldAt,
    this.channel,
    this.taxScheme,
    this.customerName,
    this.customerPhone,
    this.customerPan,
    required this.subTotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.vatAmount,
    required this.netTotal,
    this.paymentMethod,
    this.paymentStatus,
    required this.paidAmount,
    required this.changeAmount,
    required this.dueAmount,
    this.remark,
    required this.items,
  });

  final int id;
  final String invoiceNumber;
  final DateTime? soldAt;
  final String? channel;
  final String? taxScheme;
  final String? customerName;
  final String? customerPhone;
  final String? customerPan;
  final double subTotal;
  final double discountAmount;
  final double taxableAmount;
  final double vatAmount;
  final double netTotal;
  final String? paymentMethod;
  final String? paymentStatus;
  final double paidAmount;
  final double changeAmount;
  final double dueAmount;
  final String? remark;
  final List<SaleItemModel> items;

  factory SaleDetailModel.fromJson(Map<String, dynamic> json) {
    return SaleDetailModel(
      id: json['id'] as int? ?? 0,
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      soldAt: _parseDate(json['soldAt']),
      channel: json['channel'] as String?,
      taxScheme: json['taxScheme'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      customerPan: json['customerPan'] as String?,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      taxableAmount: (json['taxableAmount'] as num?)?.toDouble() ?? 0,
      vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0,
      netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0,
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0,
      remark: json['remark'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// One line of a bill — a product sold in one of its selling units.
class SaleItemModel {
  const SaleItemModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productCode,
    required this.sellingUnitId,
    this.unitSymbol,
    required this.quantity,
    required this.quantityInBaseUnits,
    required this.rate,
    this.mrp,
    required this.discountAmount,
    required this.lineTotal,
  });

  final int id;
  final int productId;
  final String? productName;
  final String? productCode;
  final int sellingUnitId;
  final String? unitSymbol;

  /// In [unitSymbol] — e.g. "3 pcs".
  final double quantity;

  /// The same quantity converted to the product's base unit.
  final double quantityInBaseUnits;

  final double rate;
  final double? mrp;
  final double discountAmount;
  final double lineTotal;

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String?,
      productCode: json['productCode'] as String?,
      sellingUnitId: json['sellingUnitId'] as int? ?? 0,
      unitSymbol: json['unitSymbol'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      quantityInBaseUnits:
          (json['quantityInBaseUnits'] as num?)?.toDouble() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      mrp: (json['mrp'] as num?)?.toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// What was sold over a window — what `GET /sales/totals` returns.
class SalesTotalsModel {
  const SalesTotalsModel({
    required this.billCount,
    required this.grossSales,
    required this.discountGiven,
    required this.vatCollected,
    required this.netSales,
    required this.collected,
    required this.outstanding,
  });

  final int billCount;
  final double grossSales;
  final double discountGiven;
  final double vatCollected;
  final double netSales;
  final double collected;
  final double outstanding;

  factory SalesTotalsModel.fromJson(Map<String, dynamic> json) {
    return SalesTotalsModel(
      billCount: json['billCount'] as int? ?? 0,
      grossSales: (json['grossSales'] as num?)?.toDouble() ?? 0,
      discountGiven: (json['discountGiven'] as num?)?.toDouble() ?? 0,
      vatCollected: (json['vatCollected'] as num?)?.toDouble() ?? 0,
      netSales: (json['netSales'] as num?)?.toDouble() ?? 0,
      collected: (json['collected'] as num?)?.toDouble() ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Body of `POST /sales`. `channel` is always `"POS"` — this app has no
/// separate storefront/online path, so there's nothing else it could be.
class CreateSaleRequest {
  const CreateSaleRequest({
    required this.taxScheme,
    required this.paymentMethod,
    this.channel = 'POS',
    this.tenderedAmount,
    this.discountAmount,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerPan,
    this.remark,
    required this.items,
  });

  final TaxScheme taxScheme;
  final PaymentMethod paymentMethod;
  final String channel;
  final double? tenderedAmount;
  final double? discountAmount;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerPan;
  final String? remark;
  final List<CreateSaleItemRequest> items;

  Map<String, dynamic> toJson() => {
    'taxScheme': taxScheme.apiValue,
    'paymentMethod': paymentMethod.apiValue,
    'channel': channel,
    if (tenderedAmount != null) 'tenderedAmount': tenderedAmount,
    if (discountAmount != null) 'discountAmount': discountAmount,
    if (customerId != null) 'customerId': customerId,
    if (customerName != null && customerName!.isNotEmpty)
      'customerName': customerName,
    if (customerPhone != null && customerPhone!.isNotEmpty)
      'customerPhone': customerPhone,
    if (customerPan != null && customerPan!.isNotEmpty)
      'customerPan': customerPan,
    if (remark != null && remark!.isNotEmpty) 'remark': remark,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

/// Paper formats accepted by the backend-rendered IRD tax-invoice endpoint.
enum TaxInvoicePaperType {
  mm80('MM80', '80 mm receipt'),
  mm75('MM75', '75 mm receipt'),
  a4('A4', 'A4'),
  a5('A5', 'A5'),
  a6('A6', 'A6');

  const TaxInvoicePaperType(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// One line of [CreateSaleRequest.items].
class CreateSaleItemRequest {
  const CreateSaleItemRequest({
    required this.productId,
    required this.sellingUnitId,
    required this.quantity,
    required this.rate,
    this.discountAmount,
  });

  final int productId;
  final int sellingUnitId;
  final double quantity;
  final double rate;
  final double? discountAmount;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'sellingUnitId': sellingUnitId,
    'quantity': quantity,
    'rate': rate,
    if (discountAmount != null) 'discountAmount': discountAmount,
  };
}

/// Body of `POST /sales/{id}/payments`.
class RecordSalePaymentRequest {
  const RecordSalePaymentRequest({
    required this.amount,
    required this.paymentMethod,
  });

  final double amount;
  final PaymentMethod paymentMethod;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'paymentMethod': paymentMethod.apiValue,
  };
}
