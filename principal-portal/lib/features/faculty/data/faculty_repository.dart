import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../../../core/utils/department_normalizer.dart';
import '../models/faculty.dart';
import '../models/faculty_attendance.dart';

/// Reads the institution's teaching staff from `faculty.faculties`, which the
/// Faculty Portal owns. This portal only ever selects from it.
class FacultyRepository extends Repository {
  const FacultyRepository();

  static const String _table = 'faculties';

  Future<Sourced<List<Faculty>>> fetchAll() {
    return load<List<Faculty>>(
      debugLabel: 'faculty.faculties',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.faculty,
        ).from(_table).select();

        return [
          for (final row in rows) _toFaculty(Map<String, dynamic>.from(row)),
        ];
      },
    );
  }

  /// Maps one `faculty.faculties` row onto the portal's [Faculty] model.
  ///
  /// The live table splits some fields across several columns — `name` is
  /// null on every row while `full_name` is populated, and experience is
  /// recorded as `teaching_experience_years` — so each field is read from
  /// the first populated candidate.
  ///
  /// Attendance and an appraisal score are not recorded anywhere in the
  /// schema. They stay at zero rather than being fabricated; the screens
  /// show them as unrecorded.
  Faculty _toFaculty(Map<String, dynamic> row) {
    // employee_id first, not the uuid. It is the identifier a Principal
    // recognises on an exported report, and it is the key every other
    // table joins on — `faculty_attendance.faculty_employee_id` and
    // `research_publications.faculty_employee_id` both use it, so taking
    // the uuid here made those joins silently match nothing.
    final id = row.firstStr(['employee_id', 'faculty_id', 'id']) ?? '';
    final name =
        row.firstStr(['full_name', 'name', 'faculty_name']) ??
        'Unnamed faculty';

    final designationText =
        row.firstStr(['designation', 'role', 'position']) ?? '';

    final department = row.firstStr([
      'department',
      'dept',
      'department_id',
      'dept_code',
      'department_name',
    ]);

    // Teaching and administrative service are stored separately; total
    // service is what the roster reports.
    final experienceYears =
        row.intOr('teaching_experience_years', 0) +
        row.intOr('admin_experience_years', 0);

    // Research output is spread across four counters in the live table.
    final researchOutput =
        row.intOr('publication_count', 0) +
        row.intOr('conference_count', 0) +
        row.intOr('books_count', 0) +
        row.intOr('patents_count', 0);

    // Read, not derived. The detail layer used to guess a qualification from
    // the job title and build an email out of the person's name; both are
    // recorded here, and `official_email` is preferred over the personal one
    // because a Principal's report should carry the work address.
    final email = row.firstStr(['official_email', 'email', 'personal_email']);

    // `assigned_subjects` arrives as a list or a comma-separated string
    // depending on the row. Null when the column is blank — an unrecorded
    // teaching load is not the same as teaching nothing.
    final assigned = row['assigned_subjects'];
    final subjectsHandled = switch (assigned) {
      final List<dynamic> list => list.isEmpty ? null : list.length,
      final String text when text.trim().isNotEmpty =>
        text.split(',').where((s) => s.trim().isNotEmpty).length,
      _ => null,
    };

    final workloadHours = row['weekly_workload_hours'] == null
        ? null
        : row.intOr('weekly_workload_hours', 0);

    return Faculty(
      id: id,
      name: name,
      designation: _designationFrom(designationText),
      departmentId: DepartmentNormalizer.codeFor(department),
      experienceYears: experienceYears > 0
          ? experienceYears
          : row.intOr('experience', 0),
      attendancePercent: row.doubleOr('attendance_percent', 0),
      researchPapersCount: researchOutput,
      performanceScore: row.doubleOr('performance_score', 0),
      qualification: row.firstStr(['qualification', 'highest_qualification']),
      email: email,
      weeklyWorkloadHours: workloadHours,
      subjectsHandled: subjectsHandled,
    );
  }

  FacultyDesignation _designationFrom(String raw) {
    final text = raw.toLowerCase();
    if (text.contains('associate')) {
      return FacultyDesignation.associateProfessor;
    }
    if (text.contains('assistant')) {
      return FacultyDesignation.assistantProfessor;
    }
    if (text.contains('professor') || text.contains('prof')) {
      return FacultyDesignation.professor;
    }
    // Unlabelled staff are shown at the entry grade rather than being
    // promoted by a parsing accident.
    return FacultyDesignation.assistantProfessor;
  }

  /// Present, absent and on-leave counts per department.
  ///
  /// Reads `principal.v_faculty_attendance_today`. Nothing in the Faculty
  /// Portal records this — `faculty.faculties.status` says 'Active' for
  /// everyone, which is an employment state rather than whether somebody was
  /// in — so the register lives in `principal`. See migration 17.
  Future<Sourced<List<FacultyAttendanceStatus>>> fetchAttendanceStatus() {
    return load<List<FacultyAttendanceStatus>>(
      debugLabel: 'principal.v_faculty_attendance_today',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('v_faculty_attendance_today')
            .select()
            .order('department_code', ascending: true);

        return [
          for (final raw in rows)
            () {
              final row = Map<String, dynamic>.from(raw);
              return FacultyAttendanceStatus(
                departmentCode: row.strOr('department_code', '—'),
                attendanceDate: row.dateOr('attendance_date', DateTime.now()),
                total: row.intOr('total_faculty', 0),
                present: row.intOr('present_count', 0),
                absent: row.intOr('absent_count', 0),
                onLeave: row.intOr('on_leave_count', 0),
              );
            }(),
        ];
      },
    );
  }
}
