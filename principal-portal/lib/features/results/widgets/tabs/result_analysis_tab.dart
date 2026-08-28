import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/cards/chart_container.dart';
import '../../../../core/widgets/cards/statistics_card.dart';
import '../../../../core/widgets/charts/bar_chart_widget.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../../core/widgets/layout/responsive_row.dart';
import '../../../academic/providers/academic_providers.dart';
import '../../../academic/widgets/performance_trend_card.dart';
import '../../../academic/widgets/semester_summary_table.dart';

/// Results in detail: outcome counts, grade spread, and the semester table.
class ResultAnalysisTab extends ConsumerWidget {
  const ResultAnalysisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradeDistributionProvider);
    // Headline counts are summed from the semester rows in the table below,
    // so the cards and the table can never disagree. They follow the semester
    // filter, which is what a Principal narrowing to one semester expects.
    final summaries = ref.watch(semesterSummariesProvider).valueOrNull;
    final appeared = summaries?.fold(0, (sum, s) => sum + s.appeared) ?? 0;
    final passed = summaries?.fold(0, (sum, s) => sum + s.passed) ?? 0;
    final backlogs = summaries?.fold(0, (sum, s) => sum + s.backlogs) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Students Appeared',
              value: '$appeared',
              icon: AppIcons.academic,
              iconColor: AppChartPalette.at(0),
              iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
            ),
            StatisticsCard(
              label: 'Students Passed',
              value: '$passed',
              icon: AppIcons.check,
              iconColor: AppColors.success,
              iconBackground: AppColors.successTint,
            ),
            StatisticsCard(
              label: 'Students Failed',
              value: '${appeared - passed}',
              icon: AppIcons.reject,
              iconColor: AppColors.danger,
              iconBackground: AppColors.dangerTint,
            ),
            StatisticsCard(
              label: 'Active Backlogs',
              value: '$backlogs',
              icon: AppIcons.warning,
              iconColor: AppColors.warning,
              iconBackground: AppColors.warningTint,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ResponsiveRow(
          columns: [
            ResponsiveColumn(
              flex: 6,
              child: gradesAsync.when(
                loading: () => const CardSkeleton(height: 320),
                error: (err, st) => const ErrorState(),
                data: (grades) => ChartContainer(
                  title: 'Grade Distribution',
                  subtitle: 'Students awarded each letter grade',
                  height: 240,
                  chart: BarChartWidget(
                    data: [
                      for (final slice in grades)
                        BarChartDatum(
                          label: slice.grade,
                          value: slice.studentCount.toDouble(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const ResponsiveColumn(flex: 4, child: PerformanceTrendCard()),
          ],
        ),
        const SizedBox(height: 20),
        const SemesterSummaryTable(),
      ],
    );
  }
}
