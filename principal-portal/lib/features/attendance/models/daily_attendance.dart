/// A single day's institution-wide attendance percentage, used to draw the
/// Overall Attendance trend line.
class DailyAttendance {
  const DailyAttendance({required this.label, required this.percent});

  final String label;
  final double percent;
}
