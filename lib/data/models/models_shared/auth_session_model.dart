/// The `data` object of a successful `/public/auth/login` response:
/// ```json
/// {
///   "userId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
///   "username": "string",
///   "email": "string",
///   "fullName": "string",
///   "role": "SUPER_ADMIN",
///   "tenantId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
///   "tenantSlug": "string",
///   "companyName": "string",
///   "token": "string",
///   "tokenExpiresAt": "2026-08-31T09:02:31.399Z",
///   "accountExpiresAt": "2026-08-31T09:02:31.399Z"
/// }
/// ```
class AuthSessionModel {
  const AuthSessionModel({
    required this.userId,
    required this.username,
    this.email,
    this.fullName,
    this.role,
    required this.tenantId,
    this.tenantSlug,
    this.companyName,
    required this.token,
    this.tokenExpiresAt,
    this.accountExpiresAt,
  });

  final String userId;
  final String username;
  final String? email;
  final String? fullName;
  final String? role;
  final String tenantId;
  final String? tenantSlug;
  final String? companyName;
  final String token;
  final DateTime? tokenExpiresAt;
  final DateTime? accountExpiresAt;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      role: json['role'] as String?,
      tenantId: json['tenantId'] as String? ?? '',
      tenantSlug: json['tenantSlug'] as String?,
      companyName: json['companyName'] as String?,
      token: json['token'] as String? ?? '',
      tokenExpiresAt: _parseDate(json['tokenExpiresAt']),
      accountExpiresAt: _parseDate(json['accountExpiresAt']),
    );
  }

  /// Round-trips through [SecureStorage] so a session can be restored on
  /// launch without another network call — see `AuthController.restoreSession`.
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'email': email,
        'fullName': fullName,
        'role': role,
        'tenantId': tenantId,
        'tenantSlug': tenantSlug,
        'companyName': companyName,
        'token': token,
        'tokenExpiresAt': tokenExpiresAt?.toIso8601String(),
        'accountExpiresAt': accountExpiresAt?.toIso8601String(),
      };

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  bool get isValid => token.isNotEmpty;

  /// The backend's role strings are free-form; this is the one value that
  /// changes navigation, so it gets a named check instead of scattering
  /// `role == 'SUPER_ADMIN'` string comparisons across the app.
  bool get isSuperAdmin => role == 'SUPER_ADMIN';

  /// Display fallback for when the backend doesn't send a full name.
  String get displayName =>
      (fullName == null || fullName!.isEmpty) ? username : fullName!;
}
