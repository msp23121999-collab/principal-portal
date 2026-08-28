import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/services/repository.dart';
import '../../institution/providers/institution_providers.dart';
import '../data/academic_repository.dart';
import '../models/academic_performance.dart';

final academicRepositoryProvider = Provider(
  (ref) => const AcademicRepository(),
);

/// Kept sourced so the screen can show whether it is on live data.
final academicKpisSourcedProvider = FutureProvider<Sourced<List<AcademicKpi>>>((
  ref,
) {
  return ref.watch(academicRepositoryProvider).fetchKpis();
});

final academicKpisProvider = FutureProvider<List<AcademicKpi>>((ref) async {
  return (await ref.watch(academicKpisSourcedProvider.future)).value;
});

/// Pass rates per department, with the two semesters they compare.
///
/// Carries the semester labels so the chart legend names what is plotted; see
/// [DepartmentPassComparison].
final departmentPassRatesProvider = FutureProvider<DepartmentPassComparison>((
  ref,
) async {
  return (await ref
          .watch(academicRepositoryProvider)
          .fetchDepartmentPassRates())
      .value;
});

final sgpaDistributionProvider = FutureProvider<List<SgpaBand>>((ref) async {
  return (await ref.watch(academicRepositoryProvider).fetchSgpaBands()).value;
});

final attainmentLevelsProvider = FutureProvider<List<AttainmentLevel>>((
  ref,
) async {
  return (await ref.watch(academicRepositoryProvider).fetchAttainmentLevels())
      .value;
});

final passRateTrendProvider = FutureProvider<List<YearlyPassRate>>((ref) async {
  return (await ref.watch(academicRepositoryProvider).fetchYearlyPassRates())
      .value;
});

final atRiskReasonsProvider = FutureProvider<List<AtRiskReason>>((ref) async {
  return (await ref.watch(academicRepositoryProvider).fetchAtRiskReasons())
      .value;
});

final gradeDistributionProvider = FutureProvider<List<GradeSlice>>((ref) async {
  return (await ref.watch(academicRepositoryProvider).fetchGradeSlices()).value;
});

/// The user's explicit academic-year choice, null until they pick one.
final academicYearSelectionProvider = StateProvider<String?>((ref) => null);

/// Academic year the whole page is scoped to.
///
/// Resolved against `principal.academic_years` rather than a hardcoded list.
/// The two had drifted apart: the default was '2025 - 2026' while the list
/// offered '2024 - 2025' downwards, so the dropdown asserted on every build of
/// this screen because its value matched none of its items.
final academicYearFilterProvider = Provider<String>((ref) {
  final chosen = ref.watch(academicYearSelectionProvider);
  if (chosen != null) return chosen;

  final years = ref.watch(academicYearsProvider).valueOrNull ?? const [];
  if (years.isEmpty) return '';
  return years.firstWhere((y) => y.isCurrent, orElse: () => years.first).label;
});

/// All semester summaries, unfiltered — the source the filtered view reads.
final _allSemesterSummariesProvider = FutureProvider<List<SemesterSummary>>((
  ref,
) async {
  return (await ref.watch(academicRepositoryProvider).fetchSemesterSummaries())
      .value;
});

/// Semester summaries narrowed by the portal-wide semester filter.
///
/// Filtering happens in Dart rather than as a database query: the whole set is
/// eight rows, and refetching on every change of a dropdown would be a round
/// trip for nothing.
///
/// `semester_summaries.semester` is text ('Semester 5') while the filter holds
/// an integer, so the two are matched on the number rather than compared
/// directly — which would silently match nothing.
final semesterSummariesProvider = FutureProvider<List<SemesterSummary>>((
  ref,
) async {
  final semester = ref.watch(portalFiltersProvider).semester;
  final summaries = await ref.watch(_allSemesterSummariesProvider.future);
  if (semester == null) return summaries;
  return summaries.where((s) {
    final match = RegExp(r'(\d+)').firstMatch(s.semester);
    if (match == null) return true;
    final numVal = int.tryParse(match.group(1) ?? '');
    // If the number extracted is a year (e.g. 2024) or outside valid semester range 1..10,
    // preserve the record instead of incorrectly filtering it out.
    if (numVal == null || numVal > 10) return true;
    return numVal == semester;
  }).toList();
});

/// The semesters that have summaries, for the header dropdown.
///
/// Read from the data rather than a fixed list, so the dropdown can never offer
/// a semester with nothing behind it.
final academicSemestersProvider = FutureProvider<List<String>>((ref) async {
  final summaries = await ref.watch(_allSemesterSummariesProvider.future);
  return [for (final s in summaries) s.semester];
});
