import 'package:nepali_date_picker/nepali_date_picker.dart';

/// Calendar range supported by the picker package.
final firstReturnNepaliDate = NepaliDateTime(1970, 2, 5);
final lastReturnNepaliDate = NepaliDateTime(2250, 11, 6);

/// Parses a manually entered Bikram Sambat date without accepting rollover
/// dates such as day 32 in a 30-day month.
NepaliDateTime? parseReturnNepaliDate(String input) {
  final match = RegExp(
    r'^(\d{4})-(\d{1,2})-(\d{1,2})$',
  ).firstMatch(input.trim());
  if (match == null) return null;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  if (year < 1970 || year > 2250 || month < 1 || month > 12 || day < 1) {
    return null;
  }
  final date = NepaliDateTime(year, month, day);
  if (day > date.totalDays ||
      date.isBefore(firstReturnNepaliDate) ||
      date.isAfter(lastReturnNepaliDate)) {
    return null;
  }
  return date;
}

String formatReturnNepaliDate(NepaliDateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
