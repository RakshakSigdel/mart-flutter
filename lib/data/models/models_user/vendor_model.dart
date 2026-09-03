DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// A price/amount formatted to two decimal places for display.
String formatVendorMoney(double? value) =>
    value == null ? '—' : value.toStringAsFixed(2);

/// A supplier — master data only. Balance/ledger/settlements live on
/// [VendorBalanceModel]/[VendorLedgerEntryModel]; purchase trail on
/// [VendorHistoryModel] — both fetched separately by the detail screen
/// rather than embedded here, matching what their own endpoints return.
class VendorModel {
  const VendorModel({
    required this.id,
    required this.name,
    this.address,
    this.contactNumber,
    this.panNumber,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? address;
  final String? contactNumber;
  final String? panNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      contactNumber: json['contactNumber'] as String?,
      panNumber: json['panNumber'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

/// Body of both `POST /vendors` and `PUT /vendors/{id}` — identical shape,
/// same reasoning as `UpsertInventoryUnitRequest`.
class UpsertVendorRequest {
  const UpsertVendorRequest({
    required this.name,
    this.address,
    this.contactNumber,
    this.panNumber,
  });

  final String name;
  final String? address;
  final String? contactNumber;
  final String? panNumber;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (address != null) 'address': address,
    if (contactNumber != null) 'contactNumber': contactNumber,
    if (panNumber != null) 'panNumber': panNumber,
  };
}

/// Which side of the vendor's account an entry (or the running balance)
/// sits on. Values match exactly what the backend sends/expects for
/// `balanceType`.
enum VendorBalanceType {
  payable('PAYABLE'),
  receivable('RECEIVABLE');

  const VendorBalanceType(this.apiValue);

  /// The exact string the backend sends/expects.
  final String apiValue;

  static VendorBalanceType? fromApiValue(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }

  String get label => switch (this) {
    VendorBalanceType.payable => 'Payable',
    VendorBalanceType.receivable => 'Receivable',
  };
}

/// One posting in a vendor's ledger — what `GET /vendors/{id}/ledger`
/// lists, and what a settlement or a manual post
/// (`POST /vendors/{id}/settlements`, `POST /vendors/{id}/ledger`) returns.
class VendorLedgerEntryModel {
  const VendorLedgerEntryModel({
    required this.id,
    required this.vendorId,
    required this.amount,
    this.balanceType,
    this.createdAt,
  });

  final int id;
  final int vendorId;
  final double amount;
  final VendorBalanceType? balanceType;
  final DateTime? createdAt;

  factory VendorLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return VendorLedgerEntryModel(
      id: json['id'] as int? ?? 0,
      vendorId: json['vendorId'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceType: VendorBalanceType.fromApiValue(
        json['balanceType'] as String?,
      ),
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

/// Where a vendor's account stands right now — what
/// `GET /vendors/{id}/balance` returns.
class VendorBalanceModel {
  const VendorBalanceModel({
    required this.vendorId,
    required this.outstanding,
    this.balanceType,
    required this.totalPayable,
    required this.totalReceivable,
    required this.totalSettled,
  });

  final int vendorId;
  final double outstanding;
  final VendorBalanceType? balanceType;
  final double totalPayable;
  final double totalReceivable;
  final double totalSettled;

  factory VendorBalanceModel.fromJson(Map<String, dynamic> json) {
    return VendorBalanceModel(
      vendorId: json['vendorId'] as int? ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
      balanceType: VendorBalanceType.fromApiValue(
        json['balanceType'] as String?,
      ),
      totalPayable: (json['totalPayable'] as num?)?.toDouble() ?? 0,
      totalReceivable: (json['totalReceivable'] as num?)?.toDouble() ?? 0,
      totalSettled: (json['totalSettled'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Body of `POST /vendors/{vendorId}/settlements` — a payment made to the
/// vendor. Always reduces what's payable; the backend infers the ledger
/// side, unlike [PostVendorLedgerEntryRequest].
class RecordSettlementRequest {
  const RecordSettlementRequest({required this.amount});

  final double amount;

  Map<String, dynamic> toJson() => {'amount': amount};
}

/// Body of `POST /vendors/{vendorId}/ledger` — a manual payable or
/// receivable posted against the vendor (not tied to a purchase).
class PostVendorLedgerEntryRequest {
  const PostVendorLedgerEntryRequest({
    required this.amount,
    required this.balanceType,
  });

  final double amount;
  final VendorBalanceType balanceType;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'balanceType': balanceType.apiValue,
  };
}

/// One entry in a vendor's purchase trail — what both
/// `GET /vendors/{vendorId}/history` (scoped to one vendor) and
/// `GET /vendors/history` (every vendor) list.
class VendorHistoryModel {
  const VendorHistoryModel({
    required this.id,
    required this.vendorId,
    this.vendorName,
    required this.purchaseId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int vendorId;
  final String? vendorName;
  final int purchaseId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory VendorHistoryModel.fromJson(Map<String, dynamic> json) {
    return VendorHistoryModel(
      id: json['id'] as int? ?? 0,
      vendorId: json['vendorId'] as int? ?? 0,
      vendorName: json['vendorName'] as String?,
      purchaseId: json['purchaseId'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}
