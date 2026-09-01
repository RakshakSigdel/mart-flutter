/// A staff member's role within the mart. Values match exactly what
/// `/admin/staff` accepts/returns for the `role` field.
enum StaffRole {
  superAdmin('SUPER_ADMIN'),
  admin('ADMIN'),
  storeManager('STORE_MANAGER'),
  cashier('CASHIER'),
  salesExecutive('SALES_EXECUTIVE'),
  inventoryManager('INVENTORY_MANAGER'),
  storeKeeper('STORE_KEEPER'),
  purchaseOfficer('PURCHASE_OFFICER'),
  accountant('ACCOUNTANT'),
  hrManager('HR_MANAGER'),
  customerSupport('CUSTOMER_SUPPORT');

  const StaffRole(this.apiValue);

  /// The exact string the backend sends/expects.
  final String apiValue;

  static StaffRole? fromApiValue(String? value) {
    for (final role in values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }

  /// "STORE_MANAGER" -> "Store Manager", for display only. Short words
  /// (≤3 letters, e.g. "HR") stay fully capitalized instead of becoming
  /// "Hr" — they're acronyms, not ordinary words.
  String get label => apiValue
      .split('_')
      .map(
        (word) => word.length <= 3
            ? word
            : '${word[0]}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

/// A staff account's status. Values match exactly what `/admin/staff`
/// accepts/returns for the `status` field.
enum StaffStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  suspended('SUSPENDED');

  const StaffStatus(this.apiValue);

  final String apiValue;

  static StaffStatus? fromApiValue(String? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }

  String get label => '${apiValue[0]}${apiValue.substring(1).toLowerCase()}';
}

/// One staff account, as returned by every `/admin/staff` endpoint except
/// the plain-string ones (retire, reset-password).
class StaffModel {
  const StaffModel({
    required this.id,
    required this.username,
    required this.email,
    this.role,
    this.status,
    this.expiresAt,
    this.lastLoginAt,
    this.fullName,
    this.dob,
    this.gender,
    this.country,
    this.mobileNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String username;
  final String email;
  final StaffRole? role;
  final StaffStatus? status;
  final DateTime? expiresAt;
  final DateTime? lastLoginAt;
  final String? fullName;
  final DateTime? dob;

  /// Not a closed enum — the backend doesn't publish a fixed set of values
  /// for this field the way it does for [role] and [status].
  final String? gender;

  final String? country;
  final String? mobileNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: StaffRole.fromApiValue(json['role'] as String?),
      status: StaffStatus.fromApiValue(json['status'] as String?),
      expiresAt: _parseDate(json['expiresAt']),
      lastLoginAt: _parseDate(json['lastLoginAt']),
      fullName: json['fullName'] as String?,
      dob: _parseDate(json['dob']),
      gender: json['gender'] as String?,
      country: json['country'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      addressLine1: json['addressLine1'] as String?,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  bool get isActive => status == StaffStatus.active;

  /// Display fallback for when the backend doesn't send a full name.
  String get displayName =>
      (fullName == null || fullName!.isEmpty) ? username : fullName!;
}

/// A `DateTime` formatted as the date-only string (`2026-09-01`) the backend
/// expects for `dob` — a plain `.toIso8601String()` would include a time
/// component the field doesn't take.
String staffDateOnly(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

/// Body of `POST /admin/staff` — hires a new staff member.
class HireStaffRequest {
  const HireStaffRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.role,
    this.status,
    this.expiresAt,
    required this.fullName,
    this.dob,
    this.gender,
    this.country,
    this.mobileNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
  });

  final String username;
  final String password;
  final String email;
  final StaffRole role;
  final StaffStatus? status;
  final DateTime? expiresAt;
  final String fullName;
  final DateTime? dob;
  final String? gender;
  final String? country;
  final String? mobileNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'email': email,
        'role': role.apiValue,
        if (status != null) 'status': status!.apiValue,
        // The backend deserializes this into a Java `Instant`, which needs
        // an explicit UTC/offset timestamp — see UpdateAdminRequest for why
        // `.toUtc()` first is required, not just tidiness.
        if (expiresAt != null)
          'expiresAt': expiresAt!.toUtc().toIso8601String(),
        'fullName': fullName,
        if (dob != null) 'dob': staffDateOnly(dob!),
        if (gender != null) 'gender': gender,
        if (country != null) 'country': country,
        if (mobileNumber != null) 'mobileNumber': mobileNumber,
        if (addressLine1 != null) 'addressLine1': addressLine1,
        if (addressLine2 != null) 'addressLine2': addressLine2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (zipCode != null) 'zipCode': zipCode,
      };
}

/// Body of `PUT /admin/staff/{id}` — no password; that has its own endpoint
/// (reset-password).
class UpdateStaffRequest {
  const UpdateStaffRequest({
    required this.username,
    required this.email,
    required this.role,
    this.status,
    this.expiresAt,
    required this.fullName,
    this.dob,
    this.gender,
    this.country,
    this.mobileNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
  });

  final String username;
  final String email;
  final StaffRole role;
  final StaffStatus? status;
  final DateTime? expiresAt;
  final String fullName;
  final DateTime? dob;
  final String? gender;
  final String? country;
  final String? mobileNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'role': role.apiValue,
        if (status != null) 'status': status!.apiValue,
        if (expiresAt != null)
          'expiresAt': expiresAt!.toUtc().toIso8601String(),
        'fullName': fullName,
        if (dob != null) 'dob': staffDateOnly(dob!),
        if (gender != null) 'gender': gender,
        if (country != null) 'country': country,
        if (mobileNumber != null) 'mobileNumber': mobileNumber,
        if (addressLine1 != null) 'addressLine1': addressLine1,
        if (addressLine2 != null) 'addressLine2': addressLine2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (zipCode != null) 'zipCode': zipCode,
      };
}
