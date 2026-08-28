import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_icons.dart';
import '../utils/responsive_utils.dart';
import './cards/statistics_card.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';

/// Top-of-page KPI row: Institution Overview, Faculty/Student/Attendance/
/// Result/Placement summaries condensed into one glance-able grid. Deeper
/// detail for each lives in the sections further down the page.
class DashboardKpiGrid extends ConsumerWidget {
  const DashboardKpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(6, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (summary) {
        final overview = summary.institutionOverview;
        return ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Total Students',
              value: overview.totalStudents.toString(),
              icon: AppIcons.students,
              trendValue: overview.studentGrowthPercent,
            ),
            StatisticsCard(
              label: 'Total Faculty',
              value: overview.totalFaculty.toString(),
              icon: AppIcons.faculty,
              trendValue: overview.facultyGrowthPercent,
            ),
            StatisticsCard(
              label: 'Departments',
              value: overview.totalDepartments.toString(),
              icon: AppIcons.department,
              subtitle: 'Across engineering & technology',
            ),
            StatisticsCard(
              label: "Today's Attendance",
              value:
                  '${summary.attendanceSnapshot.todayPercent.toStringAsFixed(1)}%',
              icon: AppIcons.attendance,
              trendValue: '+1.2%',
            ),
            StatisticsCard(
              label: 'Result Pass %',
              value:
                  '${summary.resultSummary.overallPassPercent.toStringAsFixed(1)}%',
              icon: AppIcons.results,
              subtitle: summary.resultSummary.semesterLabel,
            ),
            StatisticsCard(
              label: 'Placement %',
              value:
                  '${summary.placementSummary.placementPercent.toStringAsFixed(1)}%',
              icon: AppIcons.placements,
              subtitle:
                  '${summary.placementSummary.totalPlaced} of ${summary.placementSummary.totalEligible} placed',
            ),
          ],
        );
      },
    );
  }
}
