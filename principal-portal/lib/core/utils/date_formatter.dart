import 'package:intl/intl.dart';

/// Centralized date/time formatting so every screen renders dates
/// identically (top bar clock, leave dates, report ranges, timestamps).
class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullDate = DateFormat('EEEE, MMM d, yyyy');
  static final DateFormat _shortDate = DateFormat('MMM d, yyyy');
  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _monthOnly = DateFormat('MMMM');
  static final DateFormat _monthShort = DateFormat('MMM');
  static final DateFormat _dayMonth = DateFormat('d MMM');

  static String fullDate(DateTime date) => _fullDate.format(date);
  static String shortDate(DateTime date) => _shortDate.format(date);
  static String time(DateTime date) => _time.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String monthShort(DateTime date) => _monthShort.format(date);
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  /// The period a set of dates spans: `April – May 2025`, or `May 2025` when
  /// they all fall in one month.
  ///
  /// Null for an empty list, so a caption can be left off rather than naming a
  /// period there is no data for. Several screens used to state their period in
  /// code — "End-semester examinations, April - May 2025" — which was wrong the
  /// moment the next session was loaded, and ignored any filter narrowing the
  /// table beneath it.
  static String? monthRange(Iterable<DateTime> dates) {
    if (dates.isEmpty) return null;

    final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = dates.reduce((a, b) => a.isAfter(b) ? a : b);

    if (earliest.year == latest.year && earliest.month == latest.month) {
      return _monthYear.format(earliest);
    }
    if (earliest.year == latest.year) {
      // The year is stated once, at the end: "April – May 2025".
      return '${_monthOnly.format(earliest)} – ${_monthYear.format(latest)}';
    }
    return '${_monthYear.format(earliest)} – ${_monthYear.format(latest)}';
  }

  /// `2026-08-10`, for stamping an exported file name.
  ///
  /// Sorts correctly in a downloads folder, which a display format like
  /// '10 Aug 2026' does not.
  static String fileStamp(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// "2h ago", "3d ago", "Just now" style relative timestamp for
  /// notifications / recent activity feeds.
  static String relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return shortDate(date);
  }
}
