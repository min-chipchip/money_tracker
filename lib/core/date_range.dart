/// A half-open range of calendar dates: [start, end).
///
/// "November 2026" is start = 2026-11-01, end = 2026-12-01. The end date is
/// NOT included, so there is no "last day of the month" math and ranges
/// placed back to back never overlap.
class DateRange {
  const DateRange(this.start, this.end);

  DateRange.day(DateTime d)
      : start = DateTime(d.year, d.month, d.day),
        end = DateTime(d.year, d.month, d.day + 1);

  DateRange.month(DateTime d)
      : start = DateTime(d.year, d.month),
        end = DateTime(d.year, d.month + 1);

  DateRange.year(DateTime d)
      : start = DateTime(d.year),
        end = DateTime(d.year + 1);

  final DateTime start;
  final DateTime end;

  /// 'YYYY-MM-DD' strings, the format stored in `occurred_on`.
  String get startKey => dateKey(start);
  String get endKey => dateKey(end);
}

/// Formats a date as 'YYYY-MM-DD'. ISO order means text sorting = date sorting.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
