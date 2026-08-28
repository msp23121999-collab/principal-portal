import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/department.dart';
import '../providers/institution_providers.dart';

enum DepartmentSortMetric { rank, attendance, cgpa, placement }

extension DepartmentSortMetricX on DepartmentSortMetric {
  String get label {
    switch (this) {
      case DepartmentSortMetric.rank:
        return 'Overall Rank';
      case DepartmentSortMetric.attendance:
        return 'Attendance %';
      case DepartmentSortMetric.cgpa:
        return 'Avg. CGPA';
      case DepartmentSortMetric.placement:
        return 'Placement %';
    }
  }
}

/// Selected sort metric for the department ranking table — local UI state,
/// not part of the shared institution provider.
final departmentSortMetricProvider = StateProvider<DepartmentSortMetric>(
  (ref) => DepartmentSortMetric.rank,
);

/// Department list re-sorted by the currently selected metric. Reuses
/// [departmentsProvider] from the institution module rather than
/// re-fetching or duplicating department data.
final sortedDepartmentsProvider = Provider<AsyncValue<List<Department>>>((ref) {
  final departmentsAsync = ref.watch(departmentsProvider);
  final metric = ref.watch(departmentSortMetricProvider);

  return departmentsAsync.whenData((departments) {
    final sorted = [...departments];
    switch (metric) {
      case DepartmentSortMetric.rank:
        sorted.sort((a, b) => a.rank.compareTo(b.rank));
        break;
      case DepartmentSortMetric.attendance:
        sorted.sort(
          (a, b) => b.attendancePercent.compareTo(a.attendancePercent),
        );
        break;
      case DepartmentSortMetric.cgpa:
        sorted.sort((a, b) => b.avgCgpa.compareTo(a.avgCgpa));
        break;
      case DepartmentSortMetric.placement:
        sorted.sort((a, b) => b.placementPercent.compareTo(a.placementPercent));
        break;
    }
    return sorted;
  });
});
