/// `"PURCHASE_IN"` -> `"Purchase in"`, `"BANK_TRANSFER"` -> `"Bank transfer"`
/// — a generic display formatter for a backend enum-like string this app
/// doesn't enforce a closed Dart enum for (usually because the OpenAPI
/// schema only gave one example value, not a documented closed list), so
/// an unrecognized value still reads reasonably instead of being silently
/// dropped.
String formatSnakeCaseLabel(String? value) {
  if (value == null || value.isEmpty) return '—';
  final words = value.split('_');
  return words
      .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
      .join(' ');
}
