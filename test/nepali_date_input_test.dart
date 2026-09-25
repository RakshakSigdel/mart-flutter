import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/presentation/feature_user/returns/widgets/nepali_date_input.dart';

void main() {
  test('accepts and normalizes a valid B.S. date', () {
    final date = parseReturnNepaliDate('2083-6-9');
    expect(date, isNotNull);
    expect(formatReturnNepaliDate(date!), '2083-06-09');
  });

  test('rejects impossible dates and malformed manual input', () {
    expect(parseReturnNepaliDate('2083-13-01'), isNull);
    expect(parseReturnNepaliDate('2083-01-99'), isNull);
    expect(parseReturnNepaliDate('2026-09-25T00:00:00'), isNull);
  });
}
