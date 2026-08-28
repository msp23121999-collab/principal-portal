import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/faculty/models/faculty.dart';
import '../../features/faculty/providers/faculty_providers.dart';
import '../../features/institution/models/department.dart';
import '../../features/institution/providers/institution_providers.dart';
import '../../features/students/models/student.dart';
import '../../features/students/providers/student_providers.dart';
import '../router/app_routes.dart';
import '../utils/department_normalizer.dart';

/// What a search hit points at.
enum SearchHitKind { student, faculty, department }

extension SearchHitKindX on SearchHitKind {
  String get label => switch (this) {
    SearchHitKind.student => 'Student',
    SearchHitKind.faculty => 'Faculty',
    SearchHitKind.department => 'Department',
  };

  /// Where selecting the hit takes the Principal.
  String get route => switch (this) {
    SearchHitKind.student => AppRoutes.studentPerformance,
    SearchHitKind.faculty => AppRoutes.facultyPerformance,
    SearchHitKind.department => AppRoutes.departmentPerformance,
  };
}

/// One row in the search results.
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.departmentCode,
  });

  final SearchHitKind kind;
  final String title;
  final String subtitle;

  /// Selecting a hit narrows the portal to its department, so the screen it
  /// opens is already scoped to what was searched for rather than showing the
  /// whole institution and leaving the Principal to find the row again.
  final String departmentCode;
}

/// What the Principal has typed into the top bar.
final globalSearchQueryProvider = StateProvider<String>((ref) => '');

/// Matches across the roll, the roster and the department list.
///
/// The top bar's search box sat on every screen with no handler behind it —
/// it invited typing and did nothing. This is what it now reads.
///
/// Deliberately capped: a dropdown is for recognising the thing you already
/// had in mind, not for browsing. Anyone wanting the full list has the
/// screens themselves.
final globalSearchResultsProvider = Provider<List<SearchHit>>((ref) {
  final query = ref.watch(globalSearchQueryProvider).trim().toLowerCase();
  // Two characters is where matching stops being every row in the database.
  if (query.length < 2) return const [];

  final hits = <SearchHit>[];

  for (final d
      in ref.watch(departmentsProvider).valueOrNull ?? const <Department>[]) {
    if (d.shortCode.toLowerCase().contains(query) ||
        d.name.toLowerCase().contains(query)) {
      hits.add(
        SearchHit(
          kind: SearchHitKind.department,
          title: d.name,
          subtitle: '${d.shortCode} · ${d.studentCount} students',
          departmentCode: d.shortCode,
        ),
      );
    }
  }

  for (final s
      in ref.watch(studentListProvider).valueOrNull ?? const <Student>[]) {
    if (s.name.toLowerCase().contains(query) ||
        s.rollNumber.toLowerCase().contains(query)) {
      final code = DepartmentNormalizer.codeFor(s.departmentId);
      hits.add(
        SearchHit(
          kind: SearchHitKind.student,
          title: s.name,
          subtitle: '${s.rollNumber} · $code',
          departmentCode: code,
        ),
      );
    }
  }

  for (final f
      in ref.watch(facultyListProvider).valueOrNull ?? const <Faculty>[]) {
    if (f.name.toLowerCase().contains(query) ||
        f.id.toLowerCase().contains(query)) {
      final code = DepartmentNormalizer.codeFor(f.departmentId);
      hits.add(
        SearchHit(
          kind: SearchHitKind.faculty,
          title: f.name,
          subtitle: '${f.designation.label} · $code',
          departmentCode: code,
        ),
      );
    }
  }

  return hits.take(8).toList();
});
