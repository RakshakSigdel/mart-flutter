enum ReturnKind {
  sale('/sales-returns', 'Credit note', 'Sales returns'),
  purchase('/purchase-returns', 'Debit note', 'Purchase returns');

  const ReturnKind(this.path, this.noteLabel, this.title);
  final String path;
  final String noteLabel;
  final String title;
}

class ReturnLineModel {
  const ReturnLineModel({
    required this.originalItemId,
    required this.productName,
    required this.quantity,
    required this.rate,
    required this.lineTotal,
    this.unitSymbol,
  });
  final int originalItemId;
  final String productName;
  final String? unitSymbol;
  final double quantity;
  final double rate;
  final double lineTotal;

  factory ReturnLineModel.fromJson(
    Map<String, dynamic> json,
    ReturnKind kind,
  ) => ReturnLineModel(
    originalItemId:
        json[kind == ReturnKind.sale ? 'saleItemId' : 'purchaseItemId']
            as int? ??
        0,
    productName: json['productName'] as String? ?? '',
    unitSymbol: json['unitSymbol'] as String?,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    rate: (json['rate'] as num?)?.toDouble() ?? 0,
    lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
  );
}

class ReturnNoteModel {
  const ReturnNoteModel({
    required this.id,
    required this.number,
    required this.originalId,
    required this.billNumber,
    required this.reason,
    required this.subTotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.vatAmount,
    required this.netTotal,
    required this.items,
    this.date,
    this.nepaliDate,
    this.partyName,
    this.partyPan,
    this.vendorId,
    this.fiscalYear,
    this.taxScheme,
    this.refundAmount,
    this.syncWithIrd,
    this.remark,
  });
  final int id;
  final String number;
  final int originalId;
  final String billNumber;
  final DateTime? date;
  final String? nepaliDate;
  final String reason;
  final String? partyName;
  final String? partyPan;
  final int? vendorId;
  final String? fiscalYear;
  final String? taxScheme;
  final double subTotal, discountAmount, taxableAmount, vatAmount, netTotal;
  final double? refundAmount;
  final bool? syncWithIrd;
  final String? remark;
  final List<ReturnLineModel> items;

  factory ReturnNoteModel.fromJson(Map<String, dynamic> json, ReturnKind kind) {
    final sale = kind == ReturnKind.sale;
    return ReturnNoteModel(
      id: json['id'] as int? ?? 0,
      number:
          json[sale ? 'creditNoteNumber' : 'debitNoteNumber'] as String? ?? '',
      originalId: json[sale ? 'saleId' : 'purchaseId'] as int? ?? 0,
      billNumber: json[sale ? 'invoiceNumber' : 'billNumber'] as String? ?? '',
      date: DateTime.tryParse(
        json[sale ? 'returnedAt' : 'returnDate'] as String? ?? '',
      ),
      nepaliDate: json['nepaliDate'] as String?,
      reason: json['reason'] as String? ?? '',
      partyName: json[sale ? 'customerName' : 'vendorName'] as String?,
      partyPan: json['customerPan'] as String?,
      vendorId: json['vendorId'] as int?,
      fiscalYear: json['fiscalYear'] as String?,
      taxScheme: json['taxScheme'] as String?,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      taxableAmount: (json['taxableAmount'] as num?)?.toDouble() ?? 0,
      vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0,
      netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      syncWithIrd: json['syncWithIrd'] as bool?,
      remark: json['remark'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((item) => ReturnLineModel.fromJson(item, kind))
              .toList() ??
          const [],
    );
  }
}

class CreateReturnRequest {
  const CreateReturnRequest({
    required this.originalId,
    required this.reason,
    required this.items,
    this.date,
    this.nepaliDate,
    this.remark,
  });
  final int originalId;
  final String reason;
  final DateTime? date;
  final String? nepaliDate;
  final String? remark;
  final List<ReturnQuantity> items;

  Map<String, dynamic> toJson(ReturnKind kind) => {
    kind == ReturnKind.sale ? 'saleId' : 'purchaseId': originalId,
    'reason': reason,
    if (kind == ReturnKind.sale && nepaliDate != null && nepaliDate!.isNotEmpty)
      'nepaliDate': nepaliDate,
    if (kind == ReturnKind.purchase && date != null)
      'returnDate':
          '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
    if (remark != null && remark!.isNotEmpty) 'remark': remark,
    'items': items
        .map(
          (item) => {
            kind == ReturnKind.sale ? 'saleItemId' : 'purchaseItemId':
                item.originalItemId,
            'quantity': item.quantity,
          },
        )
        .toList(),
  };
}

class ReturnQuantity {
  const ReturnQuantity(this.originalItemId, this.quantity);
  final int originalItemId;
  final double quantity;
}
