import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/cards/chart_container.dart';
import '../../../../core/widgets/cards/statistics_card.dart';
import '../../../../core/widgets/charts/line_chart_widget.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../../core/widgets/layout/responsive_row.dart';
import '../../providers/academic_providers.dart';
import '../sgpa_distribution_card.dart';

/// Grade-point analysis: averages, the SGPA histogram, and how SGPA and
/// CGPA move against each other semester to semester.
class SgpaCgpaTab extends ConsumerWidget {
  const SgpaCgpaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(semesterSummariesProvider);
    final bands = ref.watch(sgpaDistributionProvider).valueOrNull ?? const [];
    // `sgpa_bands.display_order` runs 1 = highest band to 5 = lowest, and the
    // repository now sorts on it ascending, so the ends really are the two
    // extremes. They were not: the query sorted descending, so these two cards
    // showed each other's figure — 520 reported as distinctions and 486 as
    // needing support, when the truth was the other way round.
    //
    // The subtitles come from the band's own label rather than repeating the
    // boundary in code, so re-banding the histogram cannot leave a card
    // describing a range it no longer shows. Guarded: empty while loading.
    final distinction = bands.isEmpty ? 0 : bands.first.studentCount;
    final belowSix = bands.isEmpty ? 0 : bands.last.studentCount;
    final distinctionBand = bands.isEmpty ? '' : 'SGPA ${bands.first.label}';
    final belowSixBand = bands.isEmpty ? '' : 'SGPA ${bands.last.label}';

    // Averages are weighted by how many students sat each semester rather
    // than averaged across semesters, which would count a small cohort the
    // same as a large one.
    final summaries = ref.watch(semesterSummariesProvider).valueOrNull;
    final sat = summaries?.fold(0, (sum, s) => sum + s.appeared) ?? 0;
    final averageSgpa = sat == 0
        ? 0.0
        : summaries!.fold(0.0, (sum, s) => sum + s.averageSgpa * s.appeared) /
              sat;
    final averageCgpa = sat == 0
        ? 0.0
        : summaries!.fold(0.0, (sum, s) => sum + s.averageCgpa * s.appeared) /
              sat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Average SGPA',
              value: averageSgpa.toStringAsFixed(2),
              icon: AppIcons.trendUp,
              iconColor: AppChartPalette.at(0),
              iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
            ),
            StatisticsCard(
              label: 'Average CGPA',
              value: averageCgpa.toStringAsFixed(2),
              icon: AppIcons.award,
              iconColor: AppChartPalette.at(1),
              iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
            ),
            StatisticsCard(
              label: 'First Class with Distinction',
              value: '$distinction',
              icon: AppIcons.education,
              iconColor: AppColors.success,
              iconBackground: AppColors.successTint,
              subtitle: distinctionBand,
            ),
            StatisticsCard(
              label: 'Require Academic Support',
              value: '$belowSix',
              icon: AppIcons.warning,
              iconColor: AppColors.danger,
              iconBackground: AppColors.dangerTint,
              subtitle: belowSixBand,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ResponsiveRow(
          columns: [
            const ResponsiveColumn(flex: 4, child: SgpaDistributionCard()),
            ResponsiveColumn(
              flex: 6,
              child: summariesAsync.when(
                loading: () => const CardSkeleton(height: 340),
                error: (err, st) => const ErrorState(),
                data: (summaries) => ChartContainer(
                  title: 'SGPA vs CGPA by Semester',
                  subtitle: 'Semester average against cumulative average',
                  height: 250,
                  legend: const [
                    ChartLegendItem(
                      label: 'Average SGPA',
                      color: AppColors.primaryBlue,
                    ),
                    ChartLegendItem(
                      label: 'Average CGPA',
                      color: AppColors.success,
                    ),
                  ],
                  chart: LineChartWidget(
                    maxY: 10,
                    xLabels: [
                      for (final s in summaries) s.semester.split(' ').first,
                    ],
                    series: [
                      LineChartSeries(
                        label: 'Average SGPA',
                        color: AppColors.primaryBlue,
                        values: [for (final s in summaries) s.averageSgpa],
                      ),
                      LineChartSeries(
                        label: 'Average CGPA',
                        color: AppColors.success,
                        values: [for (final s in summaries) s.averageCgpa],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
