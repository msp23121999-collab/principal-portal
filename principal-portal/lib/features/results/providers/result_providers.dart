import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../academic/models/academic_performance.dart';
import '../../academic/providers/academic_providers.dart';
import '../data/result_repository.dart';
import '../models/semester_result.dart';

final resultRepositoryProvider = Provider((ref) => const ResultRepository());

/// Semesters that have published results, newest first.
final availableSemestersProvider = FutureProvider<List<String>>((ref) async {
  return (await ref.watch(resultRepositoryProvider).fetchSemesters()).value;
});

/// The semester the screen is showing.
///
/// Null until the list loads, at which point the newest is selected. Holding
/// a hardcoded default would show an empty screen whenever that particular
/// label was not in the database.
final selectedSemesterProvider = StateProvider<String?>((ref) => null);

/// The semester actually in effect — the explicit choice, or the newest.
final effectiveSemesterProvider = FutureProvider<String?>((ref) async {
  final chosen = ref.watch(selectedSemesterProvider);
  if (chosen != null) return chosen;

  final semesters = await ref.watch(availableSemestersProvider.future);
  return semesters.isEmpty ? null : semesters.first;
});

final semesterResultProvider = FutureProvider<SemesterResult?>((ref) async {
  final semester = await ref.watch(effectiveSemesterProvider.future);
  if (semester == null) return null;
  return (await ref.watch(resultRepositoryProvider).fetchResult(semester))
      .value;
});

final rankHoldersProvider = FutureProvider<List<RankHolder>>((ref) async {
  final semester = await ref.watch(effectiveSemesterProvider.future);
  if (semester == null) return const [];
  return (await ref.watch(resultRepositoryProvider).fetchRankHolders(semester))
      .value;
});

// ---------------------------------------------------------------------------
// Filtered subject results — sections 8.1 and 8.2
// ---------------------------------------------------------------------------

/// Subjects that have results in the current department and semester scope.
///
/// Section 15 asks for the subject list to depend on what is above it, so
/// choosing "CSE, Semester 5" leaves only the subjects CSE actually teaches in
/// that semester. Derived from the result rows, so the dropdown can never
/// offer a subject with no marks behind it.
final resultSubjectOptionsProvider = Provider<List<String>>((ref) {
  final filters = ref.watch(portalFiltersProvider);
  final subjects =
      ref.watch(_allSubjectResultsProvider).valueOrNull ?? const [];

  final names = <String>{
    for (final s in subjects)
      if ((filters.departmentCode == null ||
              DepartmentNormalizer.codeFor(s.departmentCode) ==
                  filters.departmentCode) &&
          (filters.semester == null ||
              _semesterNumber(s.semester) == filters.semester))
        s.name,
  };

  return names.toList()..sort();
});

/// Free-text search across subject code, name and faculty.
///
/// Kept beside the other result filters rather than on the academic screen it
/// used to live on, so the search box and the table it narrows are owned by
/// the same feature.
final resultSubjectSearchProvider = StateProvider<String>((ref) => '');

/// Subject results after every filter that applies to them.
///
/// This is what section 8.1 describes: choosing CSE, Semester 5 and DBMS shows
/// only that subject's result for those students, rather than the whole table
/// with a highlight on it.
final filteredSubjectResultsProvider =
    Provider<AsyncValue<List<SubjectResult>>>((ref) {
      final filters = ref.watch(portalFiltersProvider);
      final query = ref.watch(resultSubjectSearchProvider).trim().toLowerCase();

      return ref.watch(_allSubjectResultsProvider).whenData((subjects) {
        return subjects.where((s) {
          if (query.isNotEmpty &&
              !s.name.toLowerCase().contains(query) &&
              !s.code.toLowerCase().contains(query) &&
              !s.faculty.toLowerCase().contains(query)) {
            return false;
          }
          if (filters.departmentCode != null &&
              DepartmentNormalizer.codeFor(s.departmentCode) !=
                  filters.departmentCode) {
            return false;
          }
          if (filters.semester != null &&
              _semesterNumber(s.semester) != filters.semester) {
            return false;
          }
          if (filters.subject != null && s.name != filters.subject) {
            return false;
          }
          return true;
        }).toList();
      });
    });

/// Every subject result, unfiltered — the source the two providers above read.
final _allSubjectResultsProvider = FutureProvider<List<SubjectResult>>((
  ref,
) async {
  return (await ref.watch(academicRepositoryProvider).fetchSubjectResults())
      .value;
});

/// Pulls the number out of a stored semester label.
///
/// `subject_results.semester` is text ('Semester 5'), while the filter holds an
/// integer. Comparing the two directly would silently match nothing.
int? _semesterNumber(String label) {
  final match = RegExp(r'(\d+)').firstMatch(label);
  return match == null ? null : int.parse(match.group(1)!);
}

// ---------------------------------------------------------------------------
// Department Pass Summary — section 6
// ---------------------------------------------------------------------------

/// Appeared, passed, failed and pass percentage for each department.
///
/// Summed from the subject results rather than stored, so the table cannot
/// drift from the papers behind it, and so it answers the same filters the
/// rest of the Result page does — pick a semester or a subject and the
/// summary narrows with it.
///
/// Pass % is passed / appeared × 100, as section 6 specifies.
typedef DepartmentPassRow = ({
  String departmentCode,
  int appeared,
  int passed,
  int failed,
  double passPercent,
});

final departmentPassSummaryProvider =
    Provider<AsyncValue<List<DepartmentPassRow>>>((ref) {
      return ref.watch(filteredSubjectResultsProvider).whenData((subjects) {
        final appeared = <String, int>{};
        final passed = <String, int>{};

        for (final subject in subjects) {
          final code = DepartmentNormalizer.codeFor(subject.departmentCode);
          appeared[code] = (appeared[code] ?? 0) + subject.appeared;
          passed[code] = (passed[code] ?? 0) + subject.passed;
        }

        final rows = <DepartmentPassRow>[];
        for (final entry in appeared.entries) {
          final sat = entry.value;
          final through = passed[entry.key] ?? 0;
          rows.add((
            departmentCode: entry.key,
            appeared: sat,
            passed: through,
            failed: sat - through,
            passPercent: sat == 0 ? 0 : through / sat * 100,
          ));
        }

        rows.sort((a, b) => b.passPercent.compareTo(a.passPercent));
        return rows;
      });
    });

/// Highest and lowest recorded mark per subject, for section 8.2.
final subjectMarkRangesProvider =
    FutureProvider<Map<String, ({double highest, double lowest})>>((ref) async {
      return (await ref
              .watch(resultRepositoryProvider)
              .fetchSubjectMarkRanges())
          .value;
    });
