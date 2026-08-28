import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import './cards/chart_container.dart';
import './charts/bar_chart_widget.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';

/// Latest semester pass-percentage by department bar chart.
class ResultSummarySection extends ConsumerWidget {
  const ResultSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const CardSkeleton(height: 280),
      error: (err, st) => const ErrorState(),
      data: (summary) => ChartContainer(
        title: 'Result Summary',
        subtitle: summary.resultSummary.semesterLabel,
        chart: BarChartWidget(
          barColor: AppColors.success,
          maxY: 100,
          data: [
            for (final d in summary.resultSummary.byDepartment)
              BarChartDatum(label: d.departmentCode, value: d.passPercent),
          ],
        ),
      ),
    );
  }
}
