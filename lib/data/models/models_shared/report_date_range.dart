/// Standard reporting windows accepted by sales and purchase report APIs.
enum ReportDateRange {
  today('TODAY', 'Today'),
  yesterday('YESTERDAY', 'Yesterday'),
  thisWeek('THIS_WEEK', 'This week'),
  thisMonth('THIS_MONTH', 'This month'),
  thisYear('THIS_YEAR', 'This year'),
  allTime('ALL_TIME', 'All time');

  const ReportDateRange(this.apiValue, this.label);
  final String apiValue;
  final String label;
}
