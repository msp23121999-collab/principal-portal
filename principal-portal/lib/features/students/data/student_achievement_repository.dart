import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/student_achievement.dart';

/// Reads the Students screen's two supplementary tabs.
///
/// Achievements come from `principal.student_achievements` — prizes and
/// recognitions have no home in the Student Portal, which records marks and
/// attendance, so this table is the Principal's own.
///
/// The departmental placement position comes from
/// `principal.v_department_placement_summary`, a view rather than a table. It
/// counts real placement records against the live student roll, so it cannot
/// drift from either. Nothing here is stored twice.
class StudentAchievementRepository extends Repository {
  const StudentAchievementRepository();

  static AchievementCategory _categoryFrom(String? value) {
    switch (value) {
      case 'sports':
        return AchievementCategory.sports;
      case 'cultural':
        return AchievementCategory.cultural;
      case 'academic':
        return AchievementCategory.academic;
      case 'social':
        return AchievementCategory.social;
      default:
        return AchievementCategory.technical;
    }
  }

  static AchievementLevel _levelFrom(String? value) {
    switch (value) {
      case 'state':
        return AchievementLevel.state;
      case 'national':
        return AchievementLevel.national;
      case 'international':
        return AchievementLevel.international;
      default:
        return AchievementLevel.institutional;
    }
  }

  Future<Sourced<List<StudentAchievement>>> fetchAchievements() {
    return load<List<StudentAchievement>>(
      debugLabel: 'principal.student_achievements',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('student_achievements')
            .select('*, departments(code)')
            .order('achieved_on', ascending: false);

        return [
          for (final raw in rows)
            _toAchievement(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  StudentAchievement _toAchievement(Map<String, dynamic> row) {
    final dept = row['departments'];
    final code = dept is Map
        ? Map<String, dynamic>.from(dept).strOr('code', '—')
        : '—';

    return StudentAchievement(
      studentName: row.strOr('student_name', ''),
      departmentCode: code,
      title: row.strOr('title', ''),
      event: row.strOr('event', ''),
      category: _categoryFrom(row.str('category')),
      level: _levelFrom(row.str('level')),
      position: row.strOr('position', '—'),
      achievedOn: row.dateOr('achieved_on', DateTime.now()),
    );
  }

  /// Placement position per department, strongest first.
  ///
  /// `eligible` is the live student roll for the department, so the percentage
  /// on screen is against real head-count rather than a stored figure.
  Future<Sourced<List<DepartmentPlacementSummary>>> fetchPlacementSummaries() {
    return load<List<DepartmentPlacementSummary>>(
      debugLabel: 'principal.v_department_placement_summary',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('v_department_placement_summary')
            .select()
            .order('placement_percent', ascending: false);

        return [
          for (final raw in rows)
            () {
              final row = Map<String, dynamic>.from(raw);
              return DepartmentPlacementSummary(
                departmentCode: row.strOr('department_code', '—'),
                departmentName: row.strOr('department_name', '—'),
                eligible: row.intOr('eligible', 0),
                placed: row.intOr('placed', 0),
                highestPackageLpa: row.doubleOr('highest_package_lpa', 0),
                averagePackageLpa: row.doubleOr('average_package_lpa', 0),
              );
            }(),
        ];
      },
    );
  }
}
