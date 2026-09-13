import '../../../core/utils/text_format.dart';

/// How a purchase or sale was paid for.
///
/// Best-effort: the backend's OpenAPI schema gives only one example value
/// (`"CASH"`) for this field on every endpoint that carries it, not a
/// documented closed list. These four are the safe, universal categories a
/// create form offers; [fromApiValue] returns `null` for anything else
/// rather than guessing, and [formatPaymentMethod] falls back to a plain
/// formatted string for *display* so an unrecognized value the backend
/// sends back still reads fine instead of vanishing.
enum PaymentMethod {
  cash('CASH'),
  card('CARD'),
  bankTransfer('BANK_TRANSFER'),
  credit('CREDIT');

  const PaymentMethod(this.apiValue);

  final String apiValue;

  static PaymentMethod? fromApiValue(String? value) {
    for (final method in values) {
      if (method.apiValue == value) return method;
    }
    return null;
  }

  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.bankTransfer => 'Bank transfer',
    PaymentMethod.credit => 'Credit',
  };
}

/// Display label for a `paymentMethod` string as returned by the backend —
/// uses [PaymentMethod.label] when recognized, otherwise falls back to a
/// formatted version of the raw value (see [formatSnakeCaseLabel]).
String formatPaymentMethod(String? value) =>
    PaymentMethod.fromApiValue(value)?.label ?? formatSnakeCaseLabel(value);

/// Whether a purchase/sale's amounts include VAT.
///
/// Best-effort, same reasoning as [PaymentMethod] — only `"VAT"` is given
/// as an example, so `exempt` is a reasonable guess for the other case a
/// tax scheme field like this normally distinguishes.
enum TaxScheme {
  vat('VAT'),
  nonVat('NON_VAT');

  const TaxScheme(this.apiValue);

  final String apiValue;

  static TaxScheme? fromApiValue(String? value) {
    for (final scheme in values) {
      if (scheme.apiValue == value) return scheme;
    }
    return null;
  }

  String get label => switch (this) {
    TaxScheme.vat => 'VAT',
    TaxScheme.nonVat => 'NON_VAT',
  };
}

String formatTaxScheme(String? value) =>
    TaxScheme.fromApiValue(value)?.label ?? formatSnakeCaseLabel(value);

/// A price/amount formatted to two decimal places for display.
String formatMoneyAmount(double? value) =>
    value == null ? '—' : value.toStringAsFixed(2);
