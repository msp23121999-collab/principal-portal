import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/department_admin.dart';

/// Reads department administration from `principal.v_department_rollup`.
///
/// Budget, room counts and sanctioned posts are stored facts — they cannot be
/// derived from anything — and live in `department_admin_metrics`. Everything
/// computed from them (utilisation, vacancies, staffing, faculty–student
/// ratio) comes from the view instead of being recalculated in Dart, so the
/// Department screen and the Institution screen cannot disagree.
class DepartmentAdminRepository extends Repository {
  const DepartmentAdminRepository();

  Future<Sourced<List<DepartmentAdminMetrics>>> fetchAll() {
    return load<List<DepartmentAdminMetrics>>(
      debugLabel: 'principal.v_department_rollup (admin)',
      // Departments always exist; a row with no admin metrics attached is the
      // real "not recorded yet" case, so an empty budget is not a failure.
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('v_department_rollup').select().order('code', ascending: true);

        return [
          for (final raw in rows) _toMetrics(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  DepartmentAdminMetrics _toMetrics(Map<String, dynamic> row) =>
      DepartmentAdminMetrics(
        departmentCode: row.strOr('code', ''),
        departmentName: row.strOr('name', ''),
        budgetAllocated: row.doubleOr('budget_allocated', 0),
        budgetUtilised: row.doubleOr('budget_utilised', 0),
        classrooms: row.intOr('classrooms', 0),
        laboratories: row.intOr('laboratories', 0),
        sanctionedPosts: row.intOr('sanctioned_posts', 0),
        filledPosts: row.intOr('filled_posts', 0),
        studentCount: row.intOr('student_count', 0),
        infrastructureScore: row.doubleOr('infrastructure_score', 0),
      );
}
