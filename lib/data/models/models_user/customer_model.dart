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
