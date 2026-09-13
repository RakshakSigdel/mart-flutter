import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/data/models/models_user/cbms_internal_model.dart';

void main() {
  test('parses CBMS configuration without retaining its password', () {
    final config = CbmsInternalConfig.fromJson({
      'id': 9,
      'tenantId': 'tenant-1',
      'tenantSlug': 'main-mart',
      'cbmsUsername': 'cbms-user',
      'cbmsPassword': 'should-not-be-modelled',
      'taxRegistration': 'PAN_REGISTERED',
      'taxIncluded': false,
      'pan': '123456789',
    });

    expect(config.id, 9);
    expect(config.taxRegistration, TaxRegistration.panRegistered);
    expect(config.taxIncluded, isFalse);
  });

  test('create and update requests retain their distinct API contracts', () {
    expect(
      const CreateCbmsInternalRequest(
        cbmsUsername: 'user',
        cbmsPassword: 'secret',
        taxRegistration: TaxRegistration.vatRegistered,
        taxIncluded: true,
      ).toJson(),
      {
        'cbmsUsername': 'user',
        'cbmsPassword': 'secret',
        'taxRegistration': 'VAT_REGISTERED',
        'taxIncluded': true,
      },
    );
    expect(
      const UpdateCbmsInternalRequest(
        cbmsUsername: 'user',
        cbmsPassword: 'next-secret',
        taxIncluded: false,
      ).toJson(),
      {
        'cbmsUsername': 'user',
        'cbmsPassword': 'next-secret',
        'taxIncluded': false,
      },
    );
  });
}
