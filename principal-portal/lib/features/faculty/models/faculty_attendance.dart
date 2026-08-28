/// Present, absent and on-leave counts for one department on one day.
///
/// Read from `principal.v_faculty_attendance_today`, which reports against the
/// most recent date on the register rather than today's date — so the section
/// is never blank simply because nobody has marked it yet this morning.
class FacultyAttendanceStatus {
  const FacultyAttendanceStatus({
    required this.departmentCode,
    required this.attendanceDate,
    required this.total,
    required this.present,
    required this.absent,
    required this.onLeave,
  });

  final String departmentCode;
  final DateTime attendanceDate;
  final int total;
  final int present;
  final int absent;
  final int onLeave;

  double get presentPercent => total == 0 ? 0 : present / total * 100;

  /// Sums a set of departments into one institution-wide row.
  ///
  /// Kept here rather than in each widget so the Dashboard panel and the
  /// Faculty screen cannot arrive at different totals from the same rows.
  static FacultyAttendanceStatus combine(
    Iterable<FacultyAttendanceStatus> rows,
  ) {
    var total = 0, present = 0, absent = 0, onLeave = 0;
    DateTime? date;

    for (final row in rows) {
      total += row.total;
      present += row.present;
      absent += row.absent;
      onLeave += row.onLeave;
      date ??= row.attendanceDate;
    }

    return FacultyAttendanceStatus(
      departmentCode: 'ALL',
      attendanceDate: date ?? DateTime.now(),
      total: total,
      present: present,
      absent: absent,
      onLeave: onLeave,
    );
  }
}
