import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../../../core/utils/department_normalizer.dart';
import '../models/student.dart';

/// Reads the student roll through `principal.v_students`.
///
/// This used to read `student.students` directly, which meant the Students page
/// depended on this portal holding a privilege in a schema it does not own.
/// When that privilege was revoked the page failed outright with
/// `42501 permission denied for table students`.
///
/// `principal.v_students` is owner-run and gated on `principal.is_principal()`,
/// so it reads the roll on the Principal's behalf without the signed-in user
/// needing anything in the `student` schema. The Student Portal team can
/// tighten their own table — revoke `anon`, enable RLS — without breaking this
/// page. Read-only, like every other source this portal touches.
class StudentRepository extends Repository {
  const StudentRepository();

  static const String _table = 'v_students';

  /// A student is flagged at risk below either of these.
  ///
  /// ⚠️ **These three numbers are also written in SQL**, in
  /// `v_dashboard_summary` (migration `…0010_views.sql`), which counts
  /// `top_performer_count` and `at_risk_count` for the Dashboard. With no
  /// backend there is no way for Dart and Postgres to share one definition.
  ///
  /// **Change one and you must change the other**, or the Dashboard will
  /// disagree with the Student Performance screen about the same students.
  /// `test/threshold_drift_test.dart` fails if they stop matching — it is the
  /// only thing holding the two in step, so do not delete it.
  static const double atRiskCgpa = 6.5;
  static const double atRiskAttendance = 75;
  static const double topPerformerCgpa = 8.5;

  Future<Sourced<List<Student>>> fetchAll() {
    return load<List<Student>>(
      debugLabel: 'principal.v_students',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from(_table).select();

        return [
          for (final row in rows) _toStudent(Map<String, dynamic>.from(row)),
        ];
      },
    );
  }

  Student _toStudent(Map<String, dynamic> row) {
    final id = row.firstStr(['id', 'student_id']) ?? '';
    final name =
        row.firstStr(['full_name', 'name', 'student_name']) ??
        'Unnamed student';
    final rollNumber =
        row.firstStr(['roll_no', 'register_no', 'roll_number', 'student_id']) ??
        '—';

    final department = row.firstStr([
      'department',
      'dept',
      'department_name',
      'degree',
    ]);

    final cgpa = row.doubleOr('cgpa', 0);
    final attendance = row.doubleOr('attendance_percentage', 0) != 0
        ? row.doubleOr('attendance_percentage', 0)
        : row.doubleOr('attendance_percent', 0);

    return Student(
      id: id,
      name: name,
      rollNumber: rollNumber,
      departmentId: DepartmentNormalizer.codeFor(department),
      semester: row.intOr('semester', 0),
      cgpa: cgpa,
      attendancePercent: attendance,
      // The source schema carries no top/at-risk flags, so they are computed
      // from the thresholds above rather than read.
      isTopPerformer: cgpa >= topPerformerCgpa,
      isAtRisk:
          (cgpa > 0 && cgpa < atRiskCgpa) ||
          (attendance > 0 && attendance < atRiskAttendance),
      // Read as stored. These are what the portal's filters narrow on, so
      // they are carried through untouched rather than normalised here —
      // ProgramLevels and DepartmentNormalizer do that at the point of use.
      degree: row.firstStr(['degree', 'program', 'course']),
      batch: row.firstStr(['batch', 'batch_year']),
      yearOfStudy: row.firstStr(['year_of_study', 'year']),
      section: row.str('section'),
      admittedOn: row.str('date_of_admission') == null
          ? null
          : row.dateOr('date_of_admission', DateTime(1970)),
    );
  }
}
