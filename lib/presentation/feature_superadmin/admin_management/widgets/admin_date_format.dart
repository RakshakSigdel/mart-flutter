const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `12 Aug 2026` — short enough for a table cell, no `intl` dependency.
String formatAdminDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}
