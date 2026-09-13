enum TaxRegistration {
  vatRegistered('VAT_REGISTERED', 'VAT registered'),
  panRegistered('PAN_REGISTERED', 'PAN registered');

  const TaxRegistration(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static TaxRegistration fromApiValue(String? value) => values.firstWhere(
    (registration) => registration.apiValue == value,
    orElse: () => TaxRegistration.vatRegistered,
  );
}

class CbmsInternalConfig {
  const CbmsInternalConfig({
    required this.id,
    required this.tenantId,
    required this.tenantSlug,
    required this.cbmsUsername,
    required this.taxRegistration,
    required this.taxIncluded,
    required this.pan,
  });

  final int id;
  final String tenantId;
  final String tenantSlug;
  final String cbmsUsername;
  final TaxRegistration taxRegistration;
  final bool taxIncluded;
  final String pan;

  factory CbmsInternalConfig.fromJson(Map<String, dynamic> json) =>
      CbmsInternalConfig(
        id: json['id'] as int? ?? 0,
        tenantId: json['tenantId'] as String? ?? '',
        tenantSlug: json['tenantSlug'] as String? ?? '',
        cbmsUsername: json['cbmsUsername'] as String? ?? '',
        taxRegistration: TaxRegistration.fromApiValue(
          json['taxRegistration'] as String?,
        ),
        taxIncluded: json['taxIncluded'] as bool? ?? false,
        pan: json['pan'] as String? ?? '',
      );
}

class CreateCbmsInternalRequest {
  const CreateCbmsInternalRequest({
    required this.cbmsUsername,
    required this.cbmsPassword,
    required this.taxRegistration,
    required this.taxIncluded,
  });

  final String cbmsUsername;
  final String cbmsPassword;
  final TaxRegistration taxRegistration;
  final bool taxIncluded;

  Map<String, dynamic> toJson() => {
    'cbmsUsername': cbmsUsername,
    'cbmsPassword': cbmsPassword,
    'taxRegistration': taxRegistration.apiValue,
    'taxIncluded': taxIncluded,
  };
}

class UpdateCbmsInternalRequest {
  const UpdateCbmsInternalRequest({
    required this.cbmsUsername,
    required this.cbmsPassword,
    required this.taxIncluded,
  });

  final String cbmsUsername;
  final String cbmsPassword;
  final bool taxIncluded;

  Map<String, dynamic> toJson() => {
    'cbmsUsername': cbmsUsername,
    'cbmsPassword': cbmsPassword,
    'taxIncluded': taxIncluded,
  };
}
