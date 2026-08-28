import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/utils/program_level.dart';
import '../../institution/models/department.dart';
import '../../institution/providers/institution_providers.dart';
import '../../students/models/student.dart';
import '../data/department_admin_repository.dart';
import '../models/department_admin.dart';

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

final departmentAdminRepositoryProvider = Provider(
  (ref) => const DepartmentAdminRepository(),
);

/// Administrative metrics per department, highest budget utilisation first
/// so the departments spending to plan read at the top.
final departmentAdminMetricsProvider =
    FutureProvider<List<DepartmentAdminMetrics>>((ref) async {
      final sourced = await ref
          .watch(departmentAdminRepositoryProvider)
          .fetchAll();

      return [...sourced.value]..sort(
        (a, b) =>
            b.budgetUtilisationPercent.compareTo(a.budgetUtilisationPercent),
      );
    });

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

// ---------------------------------------------------------------------------
// Department summary by programme level — section 5
// ---------------------------------------------------------------------------

/// Head-count and performance for one department at one programme level.
typedef DepartmentProgramRow = ({
  String departmentCode,
  ProgramLevel level,
  int students,
  double averageAttendance,
  int atRisk,
});

/// Department summary split UG / PG / Diploma / PhD.
///
/// Section 5 asks for the split to come from the data rather than a fixed list
/// of levels, so this groups the filtered roll by the normalised degree. Only
/// levels somebody is enrolled at appear — the portal never shows a PhD column
/// for a department with no research scholars.
///
/// Grouping on the raw `degree` text would report four undergraduate
/// programmes instead of one; see [ProgramLevels].
final departmentProgramSummaryProvider =
    Provider<AsyncValue<List<DepartmentProgramRow>>>((ref) {
      return ref.watch(filteredStudentsProvider).whenData((students) {
        final grouped = <String, List<Student>>{};
        for (final student in students) {
          final level = student.programLevel;
          if (level == null) continue;
          final code = DepartmentNormalizer.codeFor(student.departmentId);
          grouped.putIfAbsent('$code|${level.name}', () => []).add(student);
        }

        final rows = <DepartmentProgramRow>[];
        for (final entry in grouped.entries) {
          final parts = entry.key.split('|');
          final recorded = entry.value
              .map((s) => s.attendancePercent)
              .where((v) => v > 0);

          rows.add((
            departmentCode: parts[0],
            level: ProgramLevel.values.byName(parts[1]),
            students: entry.value.length,
            averageAttendance: recorded.isEmpty
                ? 0
                : recorded.reduce((a, b) => a + b) / recorded.length,
            atRisk: entry.value.where((s) => s.isAtRisk).length,
          ));
        }

        rows.sort((a, b) {
          final byDept = a.departmentCode.compareTo(b.departmentCode);
          return byDept != 0 ? byDept : a.level.index.compareTo(b.level.index);
        });
        return rows;
      });
    });

// ---------------------------------------------------------------------------
// Department Performance Insights
// ---------------------------------------------------------------------------

enum TrendDirection { improving, stable, declining }

class DepartmentPerformanceInsights {
  const DepartmentPerformanceInsights({
    required this.departmentCode,
    required this.departmentName,
    required this.rank,
    required this.cgpa,
    required this.cgpaTrend,
    required this.cgpaDiff,
    required this.attendance,
    required this.attendanceTrend,
    required this.attendanceDiff,
    required this.placement,
    required this.status,
    required this.attentionRequired,
  });

  final String departmentCode;
  final String departmentName;
  final int rank;
  final double cgpa;
  final TrendDirection cgpaTrend;
  final double cgpaDiff;
  final double attendance;
  final TrendDirection attendanceTrend;
  final double attendanceDiff;
  final double placement;
  final String status;
  final List<String> attentionRequired;
}

/// Provides a synthesized view of department performance by comparing the
/// currently filtered scope (e.g. a specific batch or program) against the
/// department's overall historical baseline to determine trends and health.
final departmentInsightsProvider = Provider<AsyncValue<List<DepartmentPerformanceInsights>>>((
  ref,
) {
  final departmentsAsync = ref.watch(departmentsProvider);
  final studentsAsync = ref.watch(filteredStudentsProvider);

  if (departmentsAsync.isLoading || studentsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (departmentsAsync.hasError) {
    return AsyncValue.error(
      departmentsAsync.error!,
      departmentsAsync.stackTrace!,
    );
  }
  if (studentsAsync.hasError) {
    return AsyncValue.error(studentsAsync.error!, studentsAsync.stackTrace!);
  }

  final departments = departmentsAsync.value!;
  final students = studentsAsync.value!;

  final studentsByDept = DepartmentNormalizer.groupByDepartment(
    students,
    (s) => s.departmentId,
  );

  final insights = <DepartmentPerformanceInsights>[];

  for (final dept in departments) {
    final code = DepartmentNormalizer.codeFor(dept.shortCode);
    final deptStudents = studentsByDept[code] ?? [];

    // Filtered performance
    final currentCgpa = deptStudents.isEmpty
        ? dept.avgCgpa
        : deptStudents.fold(0.0, (sum, s) => sum + s.cgpa) /
              deptStudents.length;
    final currentAtt = deptStudents.isEmpty
        ? dept.attendancePercent
        : deptStudents.fold(0.0, (sum, s) => sum + s.attendancePercent) /
              deptStudents.length;

    // Trend = Filtered - Overall Baseline
    final cgpaDiff = currentCgpa - dept.avgCgpa;
    final attDiff = currentAtt - dept.attendancePercent;

    final cgpaTrend = cgpaDiff > 0.1
        ? TrendDirection.improving
        : (cgpaDiff < -0.1 ? TrendDirection.declining : TrendDirection.stable);
    final attTrend = attDiff > 1.0
        ? TrendDirection.improving
        : (attDiff < -1.0 ? TrendDirection.declining : TrendDirection.stable);

    // Status logic based on normative thresholds
    String status = 'Strong';
    if (currentCgpa < 6.5 || currentAtt < 75.0) {
      status = 'Critical';
    } else if (currentCgpa < 7.5 ||
        currentAtt < 85.0 ||
        cgpaTrend == TrendDirection.declining) {
      status = 'Needs Attention';
    }

    // Auto-generate insights
    final messages = <String>[];
    if (cgpaTrend == TrendDirection.declining) {
      messages.add(
        '${dept.shortCode} result performance is tracking below its institutional baseline.',
      );
    }
    if (currentAtt < 75.0) {
      messages.add(
        '${dept.shortCode} attendance (${currentAtt.toStringAsFixed(1)}%) is critically below the 75% norm.',
      );
    }
    final atRiskCount = deptStudents.where((s) => s.isAtRisk).length;
    if (atRiskCount > 5) {
      messages.add(
        '${dept.shortCode} currently has $atRiskCount at-risk students requiring intervention.',
      );
    }
    if (attTrend == TrendDirection.improving &&
        cgpaTrend == TrendDirection.improving) {
      messages.add(
        '${dept.shortCode} shows strong improvement across both attendance and academic performance.',
      );
    }

    insights.add(
      DepartmentPerformanceInsights(
        departmentCode: dept.shortCode,
        departmentName: dept.name,
        rank: dept.rank,
        cgpa: currentCgpa,
        cgpaTrend: cgpaTrend,
        cgpaDiff: cgpaDiff,
        attendance: currentAtt,
        attendanceTrend: attTrend,
        attendanceDiff: attDiff,
        placement: dept.placementPercent,
        status: status,
        attentionRequired: messages,
      ),
    );
  }

  insights.sort((a, b) => a.rank.compareTo(b.rank));
  return AsyncValue.data(insights);
});
