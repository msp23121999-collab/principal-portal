import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/services/repository.dart';
import '../data/department_repository.dart';
import '../data/institution_repository.dart';
import '../models/department.dart';
import '../models/institution_overview.dart';
import '../models/institution_trend.dart';

final departmentRepositoryProvider = Provider(
  (ref) => const DepartmentRepository(),
);

final institutionRepositoryProvider = Provider(
  (ref) => const InstitutionRepository(),
);

/// Department list plus where it came from.
///
/// Read from `principal.v_department_rollup`, which counts the live student
/// and faculty rolls on every read. Head counts therefore always reconcile
/// with the Faculty and Student Performance screens.
final departmentsSourcedProvider = FutureProvider<Sourced<List<Department>>>((
  ref,
) {
  return ref.watch(departmentRepositoryProvider).fetchAll();
});

final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  final sourced = await ref.watch(departmentsSourcedProvider.future);
  return sourced.value;
});

/// Institution headline figures, read from `principal.kpi_snapshots`.
final institutionKpisSourcedProvider =
    FutureProvider<Sourced<List<InstitutionKpi>>>((ref) {
      return ref.watch(institutionRepositoryProvider).fetchKpis();
    });

final institutionKpisProvider = FutureProvider<List<InstitutionKpi>>((
  ref,
) async {
  return (await ref.watch(institutionKpisSourcedProvider.future)).value;
});

/// Admission is the only trend series still shown. The academic, student and
/// faculty growth charts were removed; their rows remain in
/// `principal.institution_metrics` in case the trend is wanted again.
FutureProvider<List<YearlyMetric>> _trendProvider(String series) {
  return FutureProvider<List<YearlyMetric>>((ref) async {
    final sourced = await ref
        .watch(institutionRepositoryProvider)
        .fetchTrend(series);
    return sourced.value;
  });
}

final admissionTrendProvider = _trendProvider('admission');

final enrolmentMixProvider = FutureProvider<List<ProgramLevelEnrolment>>((
  ref,
) async {
  return (await ref.watch(institutionRepositoryProvider).fetchEnrolment())
      .value;
});

final semesterPerformanceProvider = FutureProvider<List<SemesterPerformance>>((
  ref,
) async {
  return (await ref
          .watch(institutionRepositoryProvider)
          .fetchSemesterPerformance())
      .value;
});

final institutionHighlightsProvider =
    FutureProvider<List<InstitutionHighlight>>((ref) async {
      return (await ref.watch(institutionRepositoryProvider).fetchHighlights())
          .value;
    });

final facilityStatsProvider = FutureProvider<List<FacilityStat>>((ref) async {
  return (await ref.watch(institutionRepositoryProvider).fetchFacilities())
      .value;
});

/// Faculty composition by employment status.
///
/// Still derived in Dart rather than read from a table: `faculty.faculties`
/// carries the status, and counting it here keeps the slice consistent with
/// the roster on the Faculty screen. There is nothing to store.
final facultyCompositionProvider = FutureProvider<List<FacultyStatusSlice>>((
  ref,
) async {
  return (await ref
          .watch(institutionRepositoryProvider)
          .fetchFacultyComposition())
      .value;
});

/// The academic years on record, most recent first.
final academicYearsProvider = FutureProvider<List<AcademicYear>>((ref) async {
  return (await ref.watch(institutionRepositoryProvider).fetchAcademicYears())
      .value;
});

/// Programme levels that actually have enrolment, for the filter dropdown.
final programLevelsProvider = FutureProvider<List<String>>((ref) async {
  final enrolment = await ref.watch(enrolmentMixProvider.future);
  return [for (final level in enrolment) level.level];
});

/// Semesters that have performance recorded, for the filter dropdown.
final institutionSemestersProvider = FutureProvider<List<String>>((ref) async {
  final performance = await ref.watch(semesterPerformanceProvider.future);
  return [for (final row in performance) row.semester];
});

/// The institution's headline figures, counted from live rows.
///
/// `principal.kpi_snapshots` stores these as text — '4,740' students, '328'
/// faculty — which is what the page used to render. Those figures were seeded
/// and never moved, so this screen reported 4,740 students while the Dashboard,
/// reading the same institution from `v_department_rollup`, reported 10. One of
/// the two was always going to be wrong, and a stored count is the one that
/// goes stale.
///
/// Only the ranking is still read from `kpi_snapshots`, because a NIRF position
/// is a fact somebody records rather than something countable from the rolls.
typedef InstitutionKpiFigures = ({
  int totalStudents,
  int totalFaculty,
  int departments,
  double averageAttendance,
  double averagePlacement,
  String? nirfRanking,
  String? nirfTrend,
});

final institutionLiveKpisProvider = Provider<AsyncValue<InstitutionKpiFigures>>(
  (ref) {
    final department = ref.watch(portalFiltersProvider).departmentCode;
    final snapshots =
        ref.watch(institutionKpisProvider).valueOrNull ?? const [];

    InstitutionKpi? ranking;
    for (final kpi in snapshots) {
      if (kpi.label.toLowerCase().contains('nirf')) ranking = kpi;
    }

    return ref.watch(departmentsProvider).whenData((departments) {
      final scoped = department == null
          ? departments
          : departments.where((d) => d.shortCode == department).toList();

      /// Weighted by head-count: a department of six students and one of six
      /// hundred must not count equally towards an institutional average.
      double weighted(double Function(Department) field) {
        final withStudents = scoped.where((d) => d.studentCount > 0);
        final heads = withStudents.fold(0, (sum, d) => sum + d.studentCount);
        if (heads == 0) return 0;
        return withStudents.fold(
              0.0,
              (sum, d) => sum + field(d) * d.studentCount,
            ) /
            heads;
      }

      return (
        totalStudents: scoped.fold(0, (sum, d) => sum + d.studentCount),
        totalFaculty: scoped.fold(0, (sum, d) => sum + d.facultyCount),
        departments: scoped.length,
        averageAttendance: weighted((d) => d.attendancePercent),
        averagePlacement: weighted((d) => d.placementPercent),
        nirfRanking: ranking?.value,
        nirfTrend: ranking?.trendPercent,
      );
    });
  },
);
