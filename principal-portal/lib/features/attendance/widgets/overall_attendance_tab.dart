import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/chart_container.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/charts/line_chart_widget.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/attendance_providers.dart';

/// Institution-wide attendance trend over the last two weeks.
class OverallAttendanceTab extends ConsumerWidget {
  const OverallAttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(overallAttendanceTrendProvider);
    final department = ref.watch(portalFiltersProvider).departmentCode;

    return trendAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(3, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (days) {
        // A department with nothing on the register returns no days, and
        // `last`, `reduce` and a division by length all throw on an empty
        // list — which took the whole tab down rather than showing that there
        // was nothing to show.
        if (days.isEmpty) {
          return EmptyState(
            message: department == null
                ? 'No attendance has been recorded yet.'
                : 'No attendance recorded for $department.',
          );
        }

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
                  iconColor: AppChartPalette.at(0),
                  iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: '2-Week Average',
                  value: '${average.toStringAsFixed(1)}%',
                  icon: AppIcons.trendUp,
                  iconColor: AppChartPalette.at(1),
                  iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Best Day',
                  value: '${best.percent.toStringAsFixed(1)}%',
                  icon: AppIcons.calendar,
                  iconColor: AppChartPalette.at(2),
                  iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
                  subtitle: best.label,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ChartContainer(
              title: 'Attendance Trend',
              subtitle: department == null
                  ? 'Last two weeks — institution-wide'
                  : 'Last two weeks — $department',
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
