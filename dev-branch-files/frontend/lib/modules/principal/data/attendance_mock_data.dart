import '../models/daily_attendance.dart';

/// Two-week institution-wide attendance trend for the Overall Attendance
/// tab. Department/Faculty/Student breakdowns are read directly from their
/// own canonical mock sources rather than duplicated here.
class AttendanceMockData {
  AttendanceMockData._();

  static const List<DailyAttendance> lastTwoWeeks = [
    DailyAttendance(label: 'Jul 17', percent: 89.4),
    DailyAttendance(label: 'Jul 18', percent: 90.1),
    DailyAttendance(label: 'Jul 19', percent: 91.2),
    DailyAttendance(label: 'Jul 20', percent: 88.7),
    DailyAttendance(label: 'Jul 21', percent: 90.5),
    DailyAttendance(label: 'Jul 22', percent: 92.0),
    DailyAttendance(label: 'Jul 23', percent: 91.6),
    DailyAttendance(label: 'Jul 24', percent: 89.9),
    DailyAttendance(label: 'Jul 25', percent: 90.8),
    DailyAttendance(label: 'Jul 27', percent: 91.4),
    DailyAttendance(label: 'Jul 28', percent: 92.3),
    DailyAttendance(label: 'Jul 29', percent: 90.6),
    DailyAttendance(label: 'Jul 30', percent: 91.1),
  ];
}
