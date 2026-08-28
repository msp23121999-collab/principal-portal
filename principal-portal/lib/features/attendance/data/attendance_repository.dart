import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/daily_attendance.dart';

/// Reads the institution-wide attendance trend.
///
/// Real attendance already exists: `student.attendance_table` records it per
/// student, per day, per period. Rather than storing a second, pre-aggregated
/// copy in `principal`, the view `v_attendance_daily` averages theirs on read.
///
/// That matters because a stored daily percentage drifts the moment a
/// correction is made to the underlying register, and nobody notices.
class AttendanceRepository extends Repository {
  const AttendanceRepository();

  /// The daily trend, optionally for one department.
  ///
  /// With no department the institution-wide view is read. With one, the
  /// per-department view is — `student.attendance_table` records a department
  /// per row, so the breakdown is real rather than apportioned. Before this
  /// the screen's headline figures and trend ignored the department filter
  /// sitting directly above them.
  Future<Sourced<List<DailyAttendance>>> fetchDailyTrend({
    String? departmentCode,
  }) {
    final view = departmentCode == null
        ? 'v_attendance_daily'
        : 'v_attendance_daily_by_department';

    return load<List<DailyAttendance>>(
      debugLabel: 'principal.$view',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        // Newest fourteen days, then reversed so the chart reads left to right.
        var query = ApiClient.schema(
          DbSchema.principal,
        ).from(view).select();
        if (departmentCode != null) {
          query = query.eq('department_code', departmentCode);
        }
        final rows = await query
            .order('entry_date', ascending: false)
            .limit(14);

        final days = [
          for (final raw in rows) _toDaily(Map<String, dynamic>.from(raw)),
        ];

        return days.reversed.toList();
      },
    );
  }

  DailyAttendance _toDaily(Map<String, dynamic> row) {
    final date = row.dateOr('entry_date', DateTime.now());
    return DailyAttendance(
      // The model carries a short label for the axis, not a date.
      label: '${date.day}/${date.month}',
      percent: row.doubleOr('overall_percent', 0),
    );
  }
}
