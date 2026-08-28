import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/faculty.dart';
import '../models/faculty_detail.dart';

/// Reads faculty workload and appraisal from `principal.faculty_details`.
///
/// This detail existed nowhere before — `FacultyDetail.forFaculty` invented it
/// from the roster, so every figure on the workload tab was a formula rather
/// than a record. It is now stored, keyed by the employee id that
/// `faculty.faculties` uses, because that roster belongs to the Faculty Portal
/// and is not ours to extend.
///
/// Members with no stored row fall back to what their **roster row actually
/// says** — a real qualification, a real weekly workload, a real email — and
/// show an em dash for anything nobody records. The old fallback filled those
/// gaps from `id.hashCode`, which put invented hours, subjects, mentees and a
/// manufactured email address against four real members of staff.
class FacultyDetailRepository extends Repository {
  const FacultyDetailRepository();

  Future<Sourced<Map<String, FacultyDetail>>> fetchAll(List<Faculty> roster) {
    return load<Map<String, FacultyDetail>>(
      debugLabel: 'principal.faculty_details',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('faculty_details')
            .select('*, faculty_achievements(achievement, display_order)');

        final stored = <String, FacultyDetail>{};
        for (final raw in rows) {
          final row = Map<String, dynamic>.from(raw);
          final employeeId = row.strOr('employee_id', '');
          if (employeeId.isEmpty) continue;
          stored[employeeId] = _toDetail(row, employeeId);
        }

        if (roster.isEmpty) {
          return stored;
        }

        return {
          ...stored,
          for (final faculty in roster)
            faculty.id:
                stored[faculty.id] ?? FacultyDetail.fromRosterRow(faculty),
        };
      },
    );
  }

  FacultyDetail _toDetail(Map<String, dynamic> row, String employeeId) {
    final achievements = <({int order, String text})>[];
    final raw = row['faculty_achievements'];
    if (raw is List) {
      for (final item in raw) {
        final entry = Map<String, dynamic>.from(item as Map);
        final text = entry.strOr('achievement', '');
        if (text.isEmpty) continue;
        achievements.add((order: entry.intOr('display_order', 0), text: text));
      }
    }
    achievements.sort((a, b) => a.order.compareTo(b.order));

    // A blank column stays null rather than becoming 0. '0 mentees' and 'we do
    // not know how many mentees' are different statements, and the screen shows
    // them differently — a figure against an em dash.
    int? intOrNull(String key) => row[key] == null ? null : row.intOr(key, 0);
    double? doubleOrNull(String key) =>
        row[key] == null ? null : row.doubleOr(key, 0);

    return FacultyDetail(
      facultyId: employeeId,
      weeklyTeachingHours: intOrNull('weekly_teaching_hours'),
      subjectsHandled: intOrNull('subjects_handled'),
      mentees: intOrNull('mentees'),
      appraisalScore: doubleOrNull('appraisal_score'),
      feedbackScore: doubleOrNull('feedback_score'),
      fundedProjects: intOrNull('funded_projects'),
      achievements: [for (final a in achievements) a.text],
      qualification: row.str('qualification'),
      email: row.str('email'),
    );
  }
}
