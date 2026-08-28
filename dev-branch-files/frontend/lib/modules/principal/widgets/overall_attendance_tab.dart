import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../utils/responsive_utils.dart';
import './cards/chart_container.dart';
import './cards/statistics_card.dart';
import './charts/line_chart_widget.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/attendance_providers.dart';

/// Institution-wide attendance trend over the last two weeks.
class OverallAttendanceTab extends ConsumerWidget {
  const OverallAttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(overallAttendanceTrendProvider);

    return trendAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(3, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (days) {
        final latest = days.last.percent;
        final average =
            days.fold(0.0, (sum, d) => sum + d.percent) / days.length;
        final best = days.reduce((a, b) => a.percent > b.percent ? a : b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              children: [
                StatisticsCard(
                  label: "Today's Attendance",
                  value: '${latest.toStringAsFixed(1)}%',
                  icon: AppIcons.attendance,
                ),
                StatisticsCard(
                  label: '2-Week Average',
                  value: '${average.toStringAsFixed(1)}%',
                  icon: AppIcons.trendUp,
                ),
                StatisticsCard(
                  label: 'Best Day',
                  value: '${best.percent.toStringAsFixed(1)}%',
                  icon: AppIcons.calendar,
                  subtitle: best.label,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ChartContainer(
              title: 'Attendance Trend',
              subtitle: 'Last two weeks — institution-wide',
              legend: const [
                ChartLegendItem(
                  label: 'Attendance %',
                  color: AppColors.primaryBlue,
                ),
              ],
              chart: LineChartWidget(
                xLabels: [for (final d in days) d.label],
                series: [
                  LineChartSeries(
                    label: 'Attendance %',
                    values: [for (final d in days) d.percent],
                    color: AppColors.primaryBlue,
                  ),
                ],
                maxY: 100,
              ),
            ),
          ],
        );
      },
    );
  }
}
