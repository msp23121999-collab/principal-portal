import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/services/repository.dart';
import '../../../core/utils/department_normalizer.dart';
import '../data/faculty_detail_repository.dart';
import '../data/faculty_repository.dart';
import '../models/faculty.dart';
import '../models/faculty_attendance.dart';
import '../models/faculty_detail.dart';

final facultyRepositoryProvider = Provider((ref) => const FacultyRepository());

/// Roster plus its provenance.
final facultySourcedProvider = FutureProvider<Sourced<List<Faculty>>>((ref) {
  return ref.watch(facultyRepositoryProvider).fetchAll();
});

final facultyDetailRepositoryProvider = Provider(
  (ref) => const FacultyDetailRepository(),
);

/// Teaching, appraisal, and research detail keyed by employee id.
final facultyDetailsAsyncProvider = FutureProvider<Map<String, FacultyDetail>>((
  ref,
) async {
  final roster = (await ref.watch(facultySourcedProvider.future)).value;
  final sourced = await ref
      .watch(facultyDetailRepositoryProvider)
      .fetchAll(roster);
  return sourced.value;
});

final facultyListProvider = FutureProvider<List<Faculty>>((ref) async {
  final roster = (await ref.watch(facultySourcedProvider.future)).value;
  if (roster.isNotEmpty) return roster;

  // When base roster from faculty.faculties is empty, derive Faculty entries
  // directly from the stored principal.faculty_details records.
  final details = await ref.watch(facultyDetailsAsyncProvider.future);
  return [
    for (final d in details.values)
      Faculty(
        id: d.facultyId,
        name: d.facultyId,
        designation: FacultyDesignation.assistantProfessor,
        departmentId: DepartmentNormalizer.codeFor(
          d.facultyId.contains('-') ? d.facultyId.split('-')[1] : 'GEN',
        ),
        experienceYears: 0,
        attendancePercent: 0,
        researchPapersCount: 0,
        performanceScore: 0,
        qualification: d.qualification,
        email: d.email,
        weeklyWorkloadHours: d.weeklyTeachingHours,
        subjectsHandled: d.subjectsHandled,
      ),
  ];
});

/// Synchronous view of the above, for widgets already inside a resolved
/// roster. Empty until the fetch completes.
final facultyDetailsProvider = Provider<Map<String, FacultyDetail>>((ref) {
  return ref.watch(facultyDetailsAsyncProvider).valueOrNull ??
      const <String, FacultyDetail>{};
});

/// Roster members carrying more than the 18-hour weekly norm.
final overloadedFacultyProvider = Provider<List<Faculty>>((ref) {
  final roster =
      ref.watch(facultyListProvider).valueOrNull ?? const <Faculty>[];
  final details = ref.watch(facultyDetailsProvider);
  return roster
      .where((faculty) => details[faculty.id]?.isOverloaded ?? false)
      .toList();
});

final facultySearchQueryProvider = StateProvider<String>((ref) => '');

/// null = all departments.
final facultyDepartmentFilterProvider = StateProvider<String?>((ref) => null);

/// null = all designations.
final facultyDesignationFilterProvider = StateProvider<FacultyDesignation?>(
  (ref) => null,
);

/// Search + department + designation filters composed over
/// [facultyListProvider] — the Faculty Performance screen's table reads
/// only from this, never re-implementing filter logic itself.
final filteredFacultyProvider = Provider<AsyncValue<List<Faculty>>>((ref) {
  final facultyAsync = ref.watch(facultyListProvider);
  final query = ref.watch(facultySearchQueryProvider).trim().toLowerCase();
  final departmentId = ref.watch(facultyDepartmentFilterProvider);
  final designation = ref.watch(facultyDesignationFilterProvider);

  // The filter carries a seed-list id ('cse') while live rows carry a
  // normalised code ('CSE'), so both are normalised before comparison.
  final filterCode = departmentId == null
      ? null
      : DepartmentNormalizer.codeFor(departmentId);

  return facultyAsync.whenData((list) {
    return list.where((f) {
      final matchesQuery =
          query.isEmpty || f.name.toLowerCase().contains(query);
      final matchesDepartment =
          filterCode == null ||
          DepartmentNormalizer.codeFor(f.departmentId) == filterCode;
      final matchesDesignation =
          designation == null || f.designation == designation;
      return matchesQuery && matchesDepartment && matchesDesignation;
    }).toList();
  });
});

/// Faculty present, absent and on leave, per department.
final facultyAttendanceStatusProvider =
    FutureProvider<List<FacultyAttendanceStatus>>((ref) async {
      return (await ref
              .watch(facultyRepositoryProvider)
              .fetchAttendanceStatus())
          .value;
    });

/// The same figures for the current department scope.
///
/// Honours the department filter — section 4.2 asks for a present count "based
/// on the selected department" — and sums every department when none is
/// chosen, so the Dashboard panel and the Faculty screen agree.
final scopedFacultyAttendanceProvider =
    Provider<AsyncValue<FacultyAttendanceStatus>>((ref) {
      final department = ref.watch(portalFiltersProvider).departmentCode;

      return ref.watch(facultyAttendanceStatusProvider).whenData((rows) {
        final scoped = department == null
            ? rows
            : rows.where((r) => r.departmentCode == department);
        return FacultyAttendanceStatus.combine(scoped);
      });
    });

/// The roster narrowed to the department in scope.
///
/// The Dashboard's "Total Faculty" card read the whole roster while the
/// Faculty Status panel beside it read the filtered register, so selecting a
/// department showed 12 and 0 at the same time. Both now come from here.
final scopedFacultyProvider = Provider<AsyncValue<List<Faculty>>>((ref) {
  final department = ref.watch(portalFiltersProvider).departmentCode;

  return ref.watch(facultyListProvider).whenData((roster) {
    if (department == null) return roster;
    return roster
        .where(
          (f) => DepartmentNormalizer.codeFor(f.departmentId) == department,
        )
        .toList();
  });
});
