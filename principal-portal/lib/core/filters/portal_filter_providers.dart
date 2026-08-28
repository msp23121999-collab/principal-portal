import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/institution/providers/institution_providers.dart';
import '../../features/students/models/student.dart';
import '../../features/students/providers/student_providers.dart';
import '../utils/department_normalizer.dart';
import '../utils/program_level.dart';
import 'portal_filters.dart';

/// The scope every filtered screen reads.
///
/// A single notifier rather than a provider per screen, so narrowing to
/// "CSE, III Year" on Student Performance is still in force when the Principal
/// moves to Attendance. Riverpod rebuilds the watchers, so no screen needs a
/// manual refresh.
class PortalFilterNotifier extends StateNotifier<PortalFilters> {
  PortalFilterNotifier() : super(const PortalFilters());

  // Every setter narrows for its own field, so changing one filter clears the
  // ones below it in the hierarchy. See [PortalFilters.narrowedFor] — without
  // this, choosing a batch and then switching department left a batch that
  // department never admitted still selected, and the dropdown asserted on a
  // value it no longer offered.

  void setAcademicYear(String? value) {
    final next = value == null
        ? state.copyWith(clearAcademicYear: true)
        : state.copyWith(academicYear: value);
    state = next.narrowedFor(PortalFilterField.academicYear);
  }

  void setDepartment(String? value) {
    final next = value == null
        ? state.copyWith(clearDepartment: true)
        : state.copyWith(departmentCode: value);
    state = next.narrowedFor(PortalFilterField.department);
  }

  void setProgramLevel(ProgramLevel? value) {
    final next = value == null
        ? state.copyWith(clearProgramLevel: true)
        : state.copyWith(programLevel: value);
    state = next.narrowedFor(PortalFilterField.programLevel);
  }

  void setBatch(String? value) {
    final next = value == null
        ? state.copyWith(clearBatch: true)
        : state.copyWith(batch: value);
    state = next.narrowedFor(PortalFilterField.batch);
  }

  void setYearOfStudy(String? value) {
    final next = value == null
        ? state.copyWith(clearYearOfStudy: true)
        : state.copyWith(yearOfStudy: value);
    state = next.narrowedFor(PortalFilterField.yearOfStudy);
  }

  void setSemester(int? value) {
    final next = value == null
        ? state.copyWith(clearSemester: true)
        : state.copyWith(semester: value);
    state = next.narrowedFor(PortalFilterField.semester);
  }

  /// The bottom of the hierarchy, so nothing is cleared below it.
  void setSubject(String? value) => state = value == null
      ? state.copyWith(clearSubject: true)
      : state.copyWith(subject: value);

  void clearAll() => state = const PortalFilters();
}

final portalFiltersProvider =
    StateNotifierProvider<PortalFilterNotifier, PortalFilters>(
      (ref) => PortalFilterNotifier(),
    );

// ---------------------------------------------------------------------------
// Option lists
// ---------------------------------------------------------------------------
// Every list below is derived from the rows that exist, never hardcoded, so
// the portal cannot offer a combination that returns nothing. Each one narrows
// as the filters above it are applied, which is the hierarchy section 15 asks
// for: pick CSE and only CSE's programmes, batches and years remain on offer.

/// The roll narrowed by every filter *above* [upTo] in the hierarchy.
///
/// This is what makes the row cascade in order. Each dropdown offers only what
/// survives the filters to its left, so Batch lists the batches that exist in
/// the chosen department **and** programme rather than every batch in the
/// institution — and the portal can never offer a combination that returns an
/// empty screen.
///
/// [upTo] is excluded deliberately: a filter must not narrow its own option
/// list, or choosing "Batch 2022" would leave 2022 as the only batch on offer
/// and there would be no way back.
///
/// Academic year is not applied. `student.students` records a student's current
/// state rather than a row per year, so filtering the roll by academic year
/// would empty it.
List<Student> _rollNarrowedTo(
  List<Student> students,
  PortalFilters filters,
  PortalFilterField upTo,
) {
  final limit = PortalFilters.hierarchy.indexOf(upTo);
  bool applies(PortalFilterField field) =>
      PortalFilters.hierarchy.indexOf(field) < limit;

  return students.where((s) {
    if (applies(PortalFilterField.department) &&
        filters.departmentCode != null &&
        DepartmentNormalizer.codeFor(s.departmentId) !=
            filters.departmentCode) {
      return false;
    }
    if (applies(PortalFilterField.programLevel) &&
        filters.programLevel != null &&
        s.programLevel != filters.programLevel) {
      return false;
    }
    if (applies(PortalFilterField.batch) &&
        filters.batch != null &&
        s.batch?.trim() != filters.batch) {
      return false;
    }
    if (applies(PortalFilterField.yearOfStudy) &&
        filters.yearOfStudy != null &&
        s.yearOfStudy?.trim() != filters.yearOfStudy) {
      return false;
    }
    if (applies(PortalFilterField.semester) &&
        filters.semester != null &&
        s.semester != filters.semester) {
      return false;
    }
    return true;
  }).toList();
}

/// The roll as narrowed for one filter's option list.
AsyncValue<List<Student>> _scopeFor(Ref ref, PortalFilterField field) {
  final filters = ref.watch(portalFiltersProvider);
  return ref
      .watch(studentListProvider)
      .whenData((students) => _rollNarrowedTo(students, filters, field));
}

/// Academic years on record, most recent first.
/// Academic years on record, most recent first — the top of the hierarchy, so
/// nothing narrows it.
final filterAcademicYearsProvider = Provider<List<String>>((ref) {
  final years = ref.watch(academicYearsProvider).valueOrNull ?? const [];
  return [for (final y in years) y.label]..sort((a, b) => b.compareTo(a));
});

/// Departments that actually have rows, by normalised code, alphabetically.
///
/// Not narrowed by academic year: `student.students` holds a student's current
/// state rather than a row per year, so there is nothing to narrow on.
final filterDepartmentsProvider = Provider<List<({String code, String name})>>((
  ref,
) {
  final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
  return [for (final d in departments) (code: d.shortCode, name: d.name)]
    ..sort((a, b) => a.code.compareTo(b.code));
});

/// Programme levels present in the current department scope.
///
/// Only the levels somebody is actually enrolled at, so the dropdown never
/// offers "PhD" at a department with no research scholars. It grows on its own
/// as those students are admitted.
final filterProgramLevelsProvider = Provider<List<ProgramLevel>>((ref) {
  final scoped =
      _scopeFor(ref, PortalFilterField.programLevel).valueOrNull ??
      const <Student>[];
  // presentIn returns them in enum order: UG, PG, Diploma, PhD.
  return ProgramLevels.presentIn([for (final s in scoped) s.degree]);
});

/// Admission batches present in the current scope, most recent first.
final filterBatchesProvider = Provider<List<String>>((ref) {
  final scoped =
      _scopeFor(ref, PortalFilterField.batch).valueOrNull ?? const <Student>[];
  final batches = <String>{
    for (final s in scoped)
      if (s.batch != null && s.batch!.trim().isNotEmpty) s.batch!.trim(),
  };
  return batches.toList()..sort((a, b) => b.compareTo(a));
});

/// Years of study present in the current scope, in academic order.
///
/// Sorted by the Roman numeral's meaning rather than alphabetically, which
/// would put II before I and IV before III.
final filterYearsOfStudyProvider = Provider<List<String>>((ref) {
  const order = ['I', 'II', 'III', 'IV', 'V'];
  final scoped =
      _scopeFor(ref, PortalFilterField.yearOfStudy).valueOrNull ??
      const <Student>[];
  final years = <String>{
    for (final s in scoped)
      if (s.yearOfStudy != null && s.yearOfStudy!.trim().isNotEmpty)
        s.yearOfStudy!.trim(),
  };
  return years.toList()..sort((a, b) {
    final ai = order.indexOf(a);
    final bi = order.indexOf(b);
    if (ai < 0 || bi < 0) return a.compareTo(b);
    return ai.compareTo(bi);
  });
});

/// Semesters present in the current scope, ascending.
final filterSemestersProvider = Provider<List<int>>((ref) {
  final scoped =
      _scopeFor(ref, PortalFilterField.semester).valueOrNull ??
      const <Student>[];
  final semesters = <int>{
    for (final s in scoped)
      if (s.semester > 0) s.semester,
  };
  return semesters.toList()..sort();
});

// ---------------------------------------------------------------------------
// The filtered roll
// ---------------------------------------------------------------------------

/// The students matching every active filter.
///
/// This is the one place the filter rules are applied. Every section that
/// counts, averages or ranks students reads it rather than filtering the roll
/// itself, so Attendance, Student Performance, Top Performers and Department
/// Summary cannot end up disagreeing about who is in scope.
///
/// Academic year is deliberately not applied here: `student.students` records
/// a student's current state rather than a row per year, so filtering the roll
/// by academic year would empty it. Sections whose data is genuinely
/// year-stamped — results, KPIs, admissions — apply it themselves.
final filteredStudentsProvider = Provider<AsyncValue<List<Student>>>((ref) {
  final filters = ref.watch(portalFiltersProvider);

  return ref.watch(studentListProvider).whenData((students) {
    return students.where((student) {
      if (filters.departmentCode != null &&
          DepartmentNormalizer.codeFor(student.departmentId) !=
              filters.departmentCode) {
        return false;
      }
      if (filters.programLevel != null &&
          student.programLevel != filters.programLevel) {
        return false;
      }
      if (filters.batch != null && student.batch?.trim() != filters.batch) {
        return false;
      }
      if (filters.yearOfStudy != null &&
          student.yearOfStudy?.trim() != filters.yearOfStudy) {
        return false;
      }
      if (filters.semester != null && student.semester != filters.semester) {
        return false;
      }
      return true;
    }).toList();
  });
});

/// Headline figures for the filtered roll.
///
/// Averages skip unrecorded (zero) values, so a student whose CGPA has not
/// been entered does not drag the average towards zero.
typedef StudentScopeSummary = ({
  int total,
  double averageAttendance,
  int atRisk,
  int topPerformers,
});

final filteredStudentSummaryProvider =
    Provider<AsyncValue<StudentScopeSummary>>((ref) {
      return ref.watch(filteredStudentsProvider).whenData((students) {
        double average(Iterable<double> values) {
          final recorded = values.where((v) => v > 0);
          if (recorded.isEmpty) return 0;
          return recorded.reduce((a, b) => a + b) / recorded.length;
        }

        return (
          total: students.length,
          averageAttendance: average(students.map((s) => s.attendancePercent)),
          atRisk: students.where((s) => s.isAtRisk).length,
          topPerformers: students.where((s) => s.isTopPerformer).length,
        );
      });
    });
