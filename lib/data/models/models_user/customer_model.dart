import '../models_shared/commerce_model.dart';

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.panNumber,
    this.address,
    required this.creditLimit,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? panNumber;
  final String? address;
  final double creditLimit;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      panNumber: json['panNumber'] as String?,
      address: json['address'] as String?,
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      active: json['active'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class UpsertCustomerRequest {
  const UpsertCustomerRequest({
    required this.name,
    this.phone,
    this.email,
    this.panNumber,
    this.address,
    required this.creditLimit,
    required this.active,
  });

  final String name;
  final String? phone;
  final String? email;
  final String? panNumber;
  final String? address;
  final double creditLimit;
  final bool active;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (panNumber != null) 'panNumber': panNumber,
    if (address != null) 'address': address,
    'creditLimit': creditLimit,
    'active': active,
  };
}

/// A credit invoice as returned by `GET /customers/{id}/outstanding`.
class CustomerOutstandingSale {
  const CustomerOutstandingSale({
    required this.id,
    required this.invoiceNumber,
    this.soldAt,
    required this.netTotal,
    required this.paidAmount,
    required this.dueAmount,
    required this.paymentStatus,
  });

  final int id;
  final String invoiceNumber;
  final DateTime? soldAt;
  final double netTotal;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus;

  factory CustomerOutstandingSale.fromJson(Map<String, dynamic> json) =>
      CustomerOutstandingSale(
        id: json['id'] as int? ?? 0,
        invoiceNumber: json['invoiceNumber'] as String? ?? '—',
        soldAt: _parseDate(json['soldAt']),
        netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0,
        paymentStatus: json['paymentStatus'] as String? ?? 'UNPAID',
      );
}

class CustomerOutstandingModel {
  const CustomerOutstandingModel({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.creditLimit,
    required this.totalOutstanding,
    required this.availableCredit,
    required this.unpaidInvoiceCount,
    required this.unpaidSales,
  });

  final int customerId;
  final String customerName;
  final String? customerPhone;
  final double creditLimit;
  final double totalOutstanding;
  final double availableCredit;
  final int unpaidInvoiceCount;
  final List<CustomerOutstandingSale> unpaidSales;

  factory CustomerOutstandingModel.fromJson(Map<String, dynamic> json) =>
      CustomerOutstandingModel(
        customerId: json['customerId'] as int? ?? 0,
        customerName: json['customerName'] as String? ?? '',
        customerPhone: json['customerPhone'] as String?,
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
        totalOutstanding: (json['totalOutstanding'] as num?)?.toDouble() ?? 0,
        availableCredit: (json['availableCredit'] as num?)?.toDouble() ?? 0,
        unpaidInvoiceCount: json['unpaidInvoiceCount'] as int? ?? 0,
        unpaidSales: (json['unpaidSales'] as List<dynamic>? ?? [])
            .map(
              (item) => CustomerOutstandingSale.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
}

class SettleCustomerCreditRequest {
  const SettleCustomerCreditRequest({
    required this.amount,
    required this.paymentMethod,
    this.remark,
  });

  final double amount;
  final PaymentMethod paymentMethod;
  final String? remark;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'paymentMethod': paymentMethod.apiValue,
    if (remark != null && remark!.isNotEmpty) 'remark': remark,
  };
}

class SettledInvoiceModel {
  const SettledInvoiceModel({
    required this.saleId,
    required this.invoiceNumber,
    required this.invoiceNetTotal,
    required this.previouslyPaid,
    required this.amountApplied,
    required this.remainingDue,
    required this.paymentStatus,
  });

  final int saleId;
  final String invoiceNumber;
  final double invoiceNetTotal;
  final double previouslyPaid;
  final double amountApplied;
  final double remainingDue;
  final String paymentStatus;

  factory SettledInvoiceModel.fromJson(Map<String, dynamic> json) =>
      SettledInvoiceModel(
        saleId: json['saleId'] as int? ?? 0,
        invoiceNumber: json['invoiceNumber'] as String? ?? '—',
        invoiceNetTotal: (json['invoiceNetTotal'] as num?)?.toDouble() ?? 0,
        previouslyPaid: (json['previouslyPaid'] as num?)?.toDouble() ?? 0,
        amountApplied: (json['amountApplied'] as num?)?.toDouble() ?? 0,
        remainingDue: (json['remainingDue'] as num?)?.toDouble() ?? 0,
        paymentStatus: json['paymentStatus'] as String? ?? '',
      );
}

class CustomerSettlementModel {
  const CustomerSettlementModel({
    required this.customerId,
    required this.customerName,
    required this.amountSettled,
    required this.previousBalance,
    required this.remainingBalance,
    required this.paymentMethod,
    required this.settledInvoices,
  });

  final int customerId;
  final String customerName;
  final double amountSettled;
  final double previousBalance;
  final double remainingBalance;
  final String paymentMethod;
  final List<SettledInvoiceModel> settledInvoices;

  factory CustomerSettlementModel.fromJson(Map<String, dynamic> json) =>
      CustomerSettlementModel(
        customerId: json['customerId'] as int? ?? 0,
        customerName: json['customerName'] as String? ?? '',
        amountSettled: (json['amountSettled'] as num?)?.toDouble() ?? 0,
        previousBalance: (json['previousBalance'] as num?)?.toDouble() ?? 0,
        remainingBalance: (json['remainingBalance'] as num?)?.toDouble() ?? 0,
        paymentMethod: json['paymentMethod'] as String? ?? '',
        settledInvoices: (json['settledInvoices'] as List<dynamic>? ?? [])
            .map(
              (item) =>
                  SettledInvoiceModel.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}
