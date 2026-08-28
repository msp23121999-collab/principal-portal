import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/department.dart';

/// Reads the department list from `principal.v_department_rollup`.
///
/// The rollup is a view, not a table, and that is the point. Head counts,
/// attendance and CGPA are counted from the live `student.students` and
/// `faculty.faculties` rolls every time it is read, so the Principal's figures
/// always reconcile with the Faculty and Student Performance screens. Storing
/// those totals would let them drift the moment a student is enrolled.
///
/// The department list itself comes from `principal.departments`, because
/// `hod.hod_departments` — which ought to be the institution's official roster
/// — is still empty. See the drift note in migration 01.
class DepartmentRepository extends Repository {
  const DepartmentRepository();

  static const _view = 'v_department_rollup';

  Future<Sourced<List<Department>>> fetchAll() {
    return load<List<Department>>(
      debugLabel: 'principal.$_view',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from(_view).select().order('rank', ascending: true);

        return [
          for (final raw in rows) _toDepartment(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Department _toDepartment(Map<String, dynamic> row) {
    return Department(
      // The rest of the app keys departments by the lowercase code (`cse`),
      // so the natural key is lowercased rather than exposing the uuid.
      id: row.strOr('code', '').toLowerCase(),
      name: row.strOr('name', 'Unnamed department'),
      shortCode: row.strOr('code', '—'),
      hodName: row.strOr('hod_name', '—'),
      programCount: row.intOr('program_count', 0),
      facultyCount: row.intOr('faculty_count', 0),
      studentCount: row.intOr('student_count', 0),
      attendancePercent: row.doubleOr('attendance_percent', 0),
      passPercent: row.doubleOr('pass_percent', 0),
      avgCgpa: row.doubleOr('avg_cgpa', 0),
      placementPercent: row.doubleOr('placement_percent', 0),
      rank: row.intOr('rank', 0),
    );
  }
}
