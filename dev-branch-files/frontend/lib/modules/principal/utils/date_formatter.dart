import 'package:intl/intl.dart';

/// Centralized date/time formatting so every screen renders dates
/// identically (top bar clock, leave dates, report ranges, timestamps).
class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullDate = DateFormat('EEEE, MMM d, yyyy');
  static final DateFormat _shortDate = DateFormat('MMM d, yyyy');
  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonth = DateFormat('d MMM');

  static String fullDate(DateTime date) => _fullDate.format(date);
  static String shortDate(DateTime date) => _shortDate.format(date);
  static String time(DateTime date) => _time.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String dayMonth(DateTime date) => _dayMonth.format(date);

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
