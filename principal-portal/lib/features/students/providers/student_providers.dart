import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/services/repository.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../institution/providers/institution_providers.dart';
import '../data/student_achievement_repository.dart';
import '../data/student_repository.dart';
import '../models/student.dart';
import '../models/student_achievement.dart';

final studentRepositoryProvider = Provider((ref) => const StudentRepository());

final studentAchievementRepositoryProvider = Provider(
  (ref) => const StudentAchievementRepository(),
);

/// Roll plus its provenance.
final studentSourcedProvider = FutureProvider<Sourced<List<Student>>>((ref) {
  return ref.watch(studentRepositoryProvider).fetchAll();
});

final studentListProvider = FutureProvider<List<Student>>((ref) async {
  final sourced = await ref.watch(studentSourcedProvider.future);
  return sourced.value;
});

/// Departmental placement position, strongest first.
final departmentPlacementProvider =
    FutureProvider<List<DepartmentPlacementSummary>>((ref) async {
      return (await ref
              .watch(studentAchievementRepositoryProvider)
              .fetchPlacementSummaries())
          .value;
    });

/// Achievement category filter, null meaning every category.
final achievementCategoryFilterProvider = StateProvider<AchievementCategory?>(
  (ref) => null,
);

/// Every achievement on record, most recent first.
///
/// Kept separate from the filtered list because the KPI cards above the table
/// count the whole year regardless of which category is selected — filtering
/// them too would make the headline figures move as the user browses.
final allStudentAchievementsProvider = FutureProvider<List<StudentAchievement>>(
  (ref) async {
    final achievements =
        (await ref
                .watch(studentAchievementRepositoryProvider)
                .fetchAchievements())
            .value;

    return [...achievements]
      ..sort((a, b) => b.achievedOn.compareTo(a.achievedOn));
  },
);

/// Student achievements, most recent first, after the category filter.
final studentAchievementsProvider = FutureProvider<List<StudentAchievement>>((
  ref,
) async {
  final category = ref.watch(achievementCategoryFilterProvider);
  final achievements = await ref.watch(allStudentAchievementsProvider.future);

  if (category == null) return achievements;
  return achievements.where((a) => a.category == category).toList();
});

/// Top performers within the current filter scope.
///
/// Reads the filtered roll, so choosing "CSE, III Year" narrows the ranking
/// to those students rather than re-ranking the whole institution.
final topPerformersProvider = Provider<AsyncValue<List<Student>>>((ref) {
  final studentsAsync = ref.watch(filteredStudentsProvider);
  return studentsAsync.whenData((students) {
    final list = students.where((s) => s.isTopPerformer).toList()
      ..sort((a, b) => b.cgpa.compareTo(a.cgpa));
    return list;
  });
});

/// Students flagged for intervention within the current filter scope.
final atRiskStudentsProvider = Provider<AsyncValue<List<Student>>>((ref) {
  final studentsAsync = ref.watch(filteredStudentsProvider);
  return studentsAsync.whenData((students) {
    final list = students.where((s) => s.isAtRisk).toList()
      ..sort((a, b) => a.attendancePercent.compareTo(b.attendancePercent));
    return list;
  });
});

/// Per-department (avg CGPA, avg attendance) comparison for the chart.
///
/// The department list comes from `principal.departments` rather than from the
/// student rows, so a department with nobody on the roll still appears on the
/// chart as a gap instead of vanishing from it.
final departmentComparisonProvider =
    Provider<
      AsyncValue<List<({String code, double avgCgpa, double avgAttendance})>>
    >((ref) {
      final departmentsAsync = ref.watch(departmentsProvider);
      final studentsAsync = ref.watch(filteredStudentsProvider);

      final departments = departmentsAsync.valueOrNull;
      if (departments == null) {
        // Not data yet, so this only ever propagates loading or error.
        return departmentsAsync.whenData(
          (_) =>
              const <({String code, double avgCgpa, double avgAttendance})>[],
        );
      }

      return studentsAsync.whenData((students) {
        // Both sides are normalised before grouping: the raw department text is
        // spelt several ways across the source schemas, so grouping on the raw
        // value would split one department into several.
        final byCode = DepartmentNormalizer.groupByDepartment(
          students,
          (s) => s.departmentId,
        );

        return [
          for (final dept in departments)
            () {
              final code = DepartmentNormalizer.codeFor(dept.shortCode);
              final inDept = byCode[code] ?? const [];
              return (
                code: dept.shortCode,
                avgCgpa: inDept.isEmpty
                    ? dept.avgCgpa
                    : inDept.fold(0.0, (sum, s) => sum + s.cgpa) /
                          inDept.length,
                avgAttendance: inDept.isEmpty
                    ? dept.attendancePercent
                    : inDept.fold(0.0, (sum, s) => sum + s.attendancePercent) /
                          inDept.length,
              );
            }(),
        ];
      });
    });
