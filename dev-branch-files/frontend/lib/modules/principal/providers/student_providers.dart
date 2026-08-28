import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_delay.dart';
import '../data/department_mock_data.dart';
import '../data/student_mock_data.dart';
import '../models/student.dart';

final studentListProvider = FutureProvider<List<Student>>((ref) {
  return mockDelay(() => StudentMockData.all);
});

final topPerformersProvider = Provider<AsyncValue<List<Student>>>((ref) {
  final studentsAsync = ref.watch(studentListProvider);
  return studentsAsync.whenData((students) {
    final list = students.where((s) => s.isTopPerformer).toList()
      ..sort((a, b) => b.cgpa.compareTo(a.cgpa));
    return list;
  });
});

final atRiskStudentsProvider = Provider<AsyncValue<List<Student>>>((ref) {
  final studentsAsync = ref.watch(studentListProvider);
  return studentsAsync.whenData((students) {
    final list = students.where((s) => s.isAtRisk).toList()
      ..sort((a, b) => a.attendancePercent.compareTo(b.attendancePercent));
    return list;
  });
});

/// Per-department (avg CGPA, avg attendance) comparison for the chart —
/// department composition reused from [DepartmentMockData] rather than
/// re-deriving department identity from the student list alone.
final departmentComparisonProvider =
    Provider<
      AsyncValue<List<({String code, double avgCgpa, double avgAttendance})>>
    >((ref) {
      final studentsAsync = ref.watch(studentListProvider);
      return studentsAsync.whenData((students) {
        return [
          for (final dept in DepartmentMockData.all)
            (
              code: dept.shortCode,
              avgCgpa: () {
                final inDept = students
                    .where((s) => s.departmentId == dept.id)
                    .toList();
                if (inDept.isEmpty) return dept.avgCgpa;
                return inDept.fold(0.0, (sum, s) => sum + s.cgpa) /
                    inDept.length;
              }(),
              avgAttendance: () {
                final inDept = students
                    .where((s) => s.departmentId == dept.id)
                    .toList();
                if (inDept.isEmpty) return dept.attendancePercent;
                return inDept.fold(0.0, (sum, s) => sum + s.attendancePercent) /
                    inDept.length;
              }(),
            ),
        ];
      });
    });
