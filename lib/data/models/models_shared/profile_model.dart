/// The signed-in user's own account — "who am I, and which mart am I
/// working in" per `GET /me`'s own description. Available to any
/// authenticated role (superadmin or mart admin/staff), unlike the
/// role-specific admin/staff models elsewhere.
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    this.mobileNumber,
    this.role,
    this.status,
    required this.tenantId,
    this.tenantSlug,
    this.companyName,
    this.expiresAt,
    this.lastLoginAt,
  });

  final String id;
  final String username;
  final String? email;
  final String? fullName;
  final String? mobileNumber;

  /// Free-form, like `AuthSessionModel.role` — the backend doesn't publish
  /// a closed set of values for every possible role/status this can hold.
  final String? role;
  final String? status;

  final String tenantId;
  final String? tenantSlug;
  final String? companyName;
  final DateTime? expiresAt;
  final DateTime? lastLoginAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
      tenantId: json['tenantId'] as String? ?? '',
      tenantSlug: json['tenantSlug'] as String?,
      companyName: json['companyName'] as String?,
      expiresAt: _parseDate(json['expiresAt']),
      lastLoginAt: _parseDate(json['lastLoginAt']),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// Display fallback for when the backend doesn't send a full name.
  String get displayName =>
      (fullName == null || fullName!.isEmpty) ? username : fullName!;
}

/// Body of `POST /me/change-password`.
class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
}
