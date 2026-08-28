import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import './cards/chart_container.dart';
import './charts/bar_chart_widget.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';

/// This week's institution-wide attendance trend bar chart.
class AttendanceSnapshotSection extends ConsumerWidget {
  const AttendanceSnapshotSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const CardSkeleton(height: 280),
      error: (err, st) => const ErrorState(),
      data: (summary) => ChartContainer(
        title: 'Attendance Snapshot',
        subtitle: 'This week — institution-wide',
        chart: BarChartWidget(
          barColor: AppColors.primaryBlue,
          data: [
            for (final day in summary.attendanceSnapshot.weekTrend)
              BarChartDatum(label: day.label, value: day.percent),
          ],
        ),
      ),
    );
  }
}
