/// How far along a mart's schema provisioning is.
enum AdminProvisioningStatus {
  pending('PENDING'),
  ready('READY'),
  failed('FAILED');

  const AdminProvisioningStatus(this.apiValue);

  /// The exact string the backend sends/expects.
  final String apiValue;

  static AdminProvisioningStatus? fromApiValue(String? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}

/// One mart (tenant) admin account, as returned by every `/superadmin/admins`
/// endpoint except the plain-string ones (retire, reset-password).
class AdminModel {
  const AdminModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.mobileNumber,
    this.status,
    required this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.registrationNumber,
    required this.slug,
    this.subscriptionExpiresAt,
    this.provisioningStatus,
    this.provisioningError,
    this.provisionedAt,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? mobileNumber;

  /// Account status (e.g. `ACTIVE`). The backend doesn't publish a closed
  /// set of values for this field the way it does for [provisioningStatus],
  /// so it stays a free string rather than a guessed enum.
  final String? status;

  final String companyName;
  final String? companyAddress;
  final String? companyPhone;
  final String? registrationNumber;
  final String slug;
  final DateTime? subscriptionExpiresAt;
  final AdminProvisioningStatus? provisioningStatus;
  final String? provisioningError;
  final DateTime? provisionedAt;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      status: json['status'] as String?,
      companyName: json['companyName'] as String? ?? '',
      companyAddress: json['companyAddress'] as String?,
      companyPhone: json['companyPhone'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      slug: json['slug'] as String? ?? '',
      subscriptionExpiresAt: _parseDate(json['subscriptionExpiresAt']),
      provisioningStatus: AdminProvisioningStatus.fromApiValue(
        json['provisioningStatus'] as String?,
      ),
      provisioningError: json['provisioningError'] as String?,
      provisionedAt: _parseDate(json['provisionedAt']),
      lastLoginAt: _parseDate(json['lastLoginAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  bool get isActive => status == 'ACTIVE';
}

/// Body of `POST /superadmin/admins` — registers a mart and its first admin.
class CreateAdminRequest {
  const CreateAdminRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    this.mobileNumber,
    required this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.registrationNumber,
    required this.slug,
    this.subscriptionExpiresAt,
  });

  final String username;
  final String email;
  final String password;
  final String fullName;
  final String? mobileNumber;
  final String companyName;
  final String? companyAddress;
  final String? companyPhone;
  final String? registrationNumber;
  final String slug;
  final DateTime? subscriptionExpiresAt;

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
        if (mobileNumber != null) 'mobileNumber': mobileNumber,
        'companyName': companyName,
        if (companyAddress != null) 'companyAddress': companyAddress,
        if (companyPhone != null) 'companyPhone': companyPhone,
        if (registrationNumber != null) 'registrationNumber': registrationNumber,
        'slug': slug,
        // The backend deserializes this into a Java `Instant`, which needs
        // an explicit UTC/offset timestamp — `.toIso8601String()` on a
        // local (non-UTC) DateTime omits the zone entirely (a Dart
        // limitation: it only ever appends "Z", and only when the value is
        // already UTC), so `.toUtc()` first is required, not just tidiness.
        if (subscriptionExpiresAt != null)
          'subscriptionExpiresAt': subscriptionExpiresAt!.toUtc().toIso8601String(),
      };
}

/// Body of `PUT /superadmin/admins/{id}` — no password or slug; those have
/// their own endpoints (reset-password) or are immutable after creation.
class UpdateAdminRequest {
  const UpdateAdminRequest({
    required this.username,
    required this.email,
    required this.fullName,
    this.mobileNumber,
    required this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.registrationNumber,
    this.subscriptionExpiresAt,
  });

  final String username;
  final String email;
  final String fullName;
  final String? mobileNumber;
  final String companyName;
  final String? companyAddress;
  final String? companyPhone;
  final String? registrationNumber;
  final DateTime? subscriptionExpiresAt;

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'fullName': fullName,
        if (mobileNumber != null) 'mobileNumber': mobileNumber,
        'companyName': companyName,
        if (companyAddress != null) 'companyAddress': companyAddress,
        if (companyPhone != null) 'companyPhone': companyPhone,
        if (registrationNumber != null) 'registrationNumber': registrationNumber,
        if (subscriptionExpiresAt != null)
          'subscriptionExpiresAt': subscriptionExpiresAt!.toUtc().toIso8601String(),
      };
}
