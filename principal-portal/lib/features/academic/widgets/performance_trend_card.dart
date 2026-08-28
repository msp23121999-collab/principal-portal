import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/chart_container.dart';
import '../../../core/widgets/charts/line_chart_widget.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/academic_providers.dart';

/// Institution pass percentage over the last five academic years.
class PerformanceTrendCard extends ConsumerWidget {
  const PerformanceTrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(passRateTrendProvider);

    return trendAsync.when(
      loading: () => const CardSkeleton(height: 220),
      error: (err, st) => const ErrorState(),
      data: (trend) {
        if (trend.isEmpty) {
          return const ChartContainer(
            title: 'Performance Trend',
            subtitle: 'Overall pass percentage by year',
            height: 120,
            chart: EmptyState(message: 'No performance trend data available'),
          );
        }

        return ChartContainer(
          title: 'Performance Trend',
          subtitle: 'Overall pass percentage by year',
          height: 220,
          legend: const [
            ChartLegendItem(label: 'Pass %', color: AppColors.primaryBlue),
          ],
          chart: LineChartWidget(
            maxY: 100,
            xLabels: [for (final point in trend) point.year],
            series: [
              LineChartSeries(
                label: 'Pass %',
                values: [for (final point in trend) point.passPercent],
                color: AppColors.primaryBlue,
              ),
            ],
          ),
        );
      },
    );
  }
}
