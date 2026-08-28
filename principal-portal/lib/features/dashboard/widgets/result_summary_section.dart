import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/charts/bar_chart_widget.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_card.dart';

/// Latest semester pass-percentage by department.
///
/// A summary only — subject-level and rank-holder analysis lives on the Result
/// screen. This answers one question: which departments are behind?
class ResultSummarySection extends ConsumerWidget {
  const ResultSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final department = ref.watch(portalFiltersProvider).departmentCode;

    return summaryAsync.when(
      loading: () => const CardSkeleton(height: 280),
      error: (err, st) => const ErrorState(),
      data: (summary) {
        // Narrowed to the department in scope. The chart used to draw all
        // twelve bars whatever the filter row said, so choosing CSE left a
        // twelve-department chart underneath a filter claiming otherwise.
        final bars = [
          for (final d in summary.resultSummary.byDepartment)
            if (department == null || d.departmentCode == department) d,
        ];

        if (bars.isEmpty) {
          return const DashboardCard(
            title: 'Result',
            icon: AppIcons.results,
            iconColor: AppColors.success,
            subtitle: 'Pass percentage by department',
            child: SizedBox(
              height: 240,
              child: EmptyState(
                message: 'No result data for the selected filters.',
              ),
            ),
          );
        }

        return DashboardCard(
          title: 'Result',
          icon: AppIcons.results,
          iconColor: AppColors.success,
          subtitle: department == null
              ? summary.resultSummary.semesterLabel
              : '${summary.resultSummary.semesterLabel} · $department',
          child: SizedBox(
            height: 240,
            child: BarChartWidget(
              barColor: AppColors.success,
              maxY: 100,
              data: [
                for (final d in bars)
                  BarChartDatum(label: d.departmentCode, value: d.passPercent),
              ],
            ),
          ),
        );
      },
    );
  }
}
