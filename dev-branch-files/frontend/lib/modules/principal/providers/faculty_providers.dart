import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_delay.dart';
import '../data/faculty_mock_data.dart';
import '../models/faculty.dart';

final facultyListProvider = FutureProvider<List<Faculty>>((ref) {
  return mockDelay(() => FacultyMockData.all);
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

  return facultyAsync.whenData((list) {
    return list.where((f) {
      final matchesQuery =
          query.isEmpty || f.name.toLowerCase().contains(query);
      final matchesDepartment =
          departmentId == null || f.departmentId == departmentId;
      final matchesDesignation =
          designation == null || f.designation == designation;
      return matchesQuery && matchesDepartment && matchesDesignation;
    }).toList();
  });
});
