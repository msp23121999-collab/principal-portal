import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../faculty/models/faculty.dart';
import '../../faculty/providers/faculty_providers.dart';
import '../../institution/models/department.dart';
import '../../institution/providers/institution_providers.dart';
import '../../students/models/student.dart';
import '../data/attendance_repository.dart';
import '../models/daily_attendance.dart';

final attendanceRepositoryProvider = Provider(
  (ref) => const AttendanceRepository(),
);

/// The daily trend, averaged from the real per-period register in
/// `student.attendance_table`.
///
/// Scoped to the department in the shared filter, or the whole institution
/// when none is chosen, so the chart and the headline cards answer the filter
/// row above them rather than ignoring it.
final overallAttendanceTrendProvider = FutureProvider<List<DailyAttendance>>((
  ref,
) async {
  final department = ref.watch(portalFiltersProvider).departmentCode;
  return (await ref
          .watch(attendanceRepositoryProvider)
          .fetchDailyTrend(departmentCode: department))
      .value;
});

// The per-department, per-faculty and per-student tabs each read the same
// rolls the rest of the portal uses, rather than a separate attendance copy.
// One source, so the Attendance screen cannot disagree with the Department,
// Faculty or Student screens.

/// Departments in the current scope.
///
/// Narrowed by the shared filter rather than always the whole institution, so
/// the Department tab agrees with the filter row above it.
final departmentAttendanceProvider = Provider<AsyncValue<List<Department>>>((
  ref,
) {
  final code = ref.watch(portalFiltersProvider).departmentCode;
  return ref.watch(departmentsProvider).whenData((departments) {
    if (code == null) return departments;
    return departments.where((d) => d.shortCode == code).toList();
  });
});

/// Faculty in the current scope — the roster filter is shared with the
/// Faculty screen, so the two cannot disagree about who is in the department.
final facultyAttendanceProvider = Provider<AsyncValue<List<Faculty>>>((ref) {
  return ref.watch(scopedFacultyProvider);
});

/// Students in the current scope, honouring department, programme and year.
final studentAttendanceProvider = Provider<AsyncValue<List<Student>>>((ref) {
  return ref.watch(filteredStudentsProvider);
});

/// Average attendance for each year of study in the current scope.
///
/// Section 2.1: pick a year and read its average. Derived from the same
/// filtered roll the tables show, so the figure and the rows behind it cannot
/// disagree. Years with nobody on the roll are left out rather than reported
/// as 0%, which would read as terrible attendance instead of no data.
final attendanceByYearProvider =
    Provider<AsyncValue<List<({String year, int students, double average})>>>((
      ref,
    ) {
      const order = ['I', 'II', 'III', 'IV', 'V'];

      return ref.watch(filteredStudentsProvider).whenData((students) {
        final byYear = <String, List<Student>>{};
        for (final student in students) {
          final year = student.yearOfStudy?.trim();
          if (year == null || year.isEmpty) continue;
          byYear.putIfAbsent(year, () => []).add(student);
        }

        final rows = <({String year, int students, double average})>[];
        for (final entry in byYear.entries) {
          final recorded = entry.value
              .map((s) => s.attendancePercent)
              .where((v) => v > 0);
          rows.add((
            year: entry.key,
            students: entry.value.length,
            average: recorded.isEmpty
                ? 0
                : recorded.reduce((a, b) => a + b) / recorded.length,
          ));
        }

        rows.sort((a, b) {
          final ai = order.indexOf(a.year);
          final bi = order.indexOf(b.year);
          if (ai < 0 || bi < 0) return a.year.compareTo(b.year);
          return ai.compareTo(bi);
        });
        return rows;
      });
    });
