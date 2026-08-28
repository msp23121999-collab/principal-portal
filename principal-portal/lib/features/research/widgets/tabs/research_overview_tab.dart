import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/cards/analytics_card.dart';
import '../../../../core/widgets/cards/chart_container.dart';
import '../../../../core/widgets/cards/ranked_progress_list.dart';
import '../../../../core/widgets/cards/statistics_card.dart';
import '../../../../core/widgets/charts/line_chart_widget.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../../core/widgets/layout/responsive_row.dart';
import '../../providers/research_providers.dart';

/// Institution-wide research position: output figures, the five-year
/// trend, and how departments compare.
class ResearchOverviewTab extends ConsumerWidget {
  const ResearchOverviewTab({super.key});

  // NO TREND BADGE ON THESE CARDS, deliberately.
  //
  // The Publications and Patents cards count `faculty.research_publications`
  // and `faculty.patents` — 8 and 0 today. The only year-on-year history in the
  // system is `research_year_output`, a separate institutional series running
  // 42→94 publications and 3→14 patents.
  //
  // A trend taken from the second and printed beside a value from the first
  // says "0 patents filed, up 27.3%", which is incoherent. It replaced a
  // hardcoded '26.3% vs 2023-24' that was equally wrong and less convincing.
  //
  // There is no prior-year figure for *these* counts, so there is no trend to
  // show. The five-year series is already drawn, correctly, by the Research
  // Output Trend chart below.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outputAsync = ref.watch(researchOutputProvider);
    final byDepartmentAsync = ref.watch(publicationsByDepartmentProvider);
    final summaryAsync = ref.watch(researchSummaryProvider);
    final summary = summaryAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Publications (YTD)',
              value: summary == null ? '—' : '${summary.publications}',
              icon: AppIcons.research,
              iconColor: AppChartPalette.at(0),
              iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
              subtitle: 'Papers on record',
            ),
            StatisticsCard(
              label: 'Patents Filed',
              value: summary == null ? '—' : '${summary.patents}',
              icon: AppIcons.innovation,
              iconColor: AppChartPalette.at(1),
              iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
              subtitle: summary == null ? 'Loading live data…' : '${summary.grantedPatents} granted to date',
            ),
            StatisticsCard(
              label: 'Funded Projects',
              value: summary == null ? '—' : '${summary.fundedProjects}',
              icon: AppIcons.academic,
              iconColor: AppChartPalette.at(2),
              iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
              subtitle: summary == null ? 'Loading live data…' : '${summary.ongoingProjects} currently running',
            ),
            StatisticsCard(
              label: 'Grant Funding',
              value: summary == null ? '—' : NumberFormatter.rupees(summary.totalFunding),
              icon: AppIcons.currency,
              iconColor: AppColors.success,
              iconBackground: AppColors.successTint,
            ),
            StatisticsCard(
              label: 'Consultancy Revenue',
              value: summary == null ? '—' : NumberFormatter.rupees(summary.consultancyRevenue),
              icon: AppIcons.company,
              iconColor: AppChartPalette.at(4),
              iconBackground: AppChartPalette.at(4).withValues(alpha: 0.10),
            ),
            StatisticsCard(
              label: 'Citations',
              value: summary == null ? '—' : '${summary.citations}',
              icon: AppIcons.award,
              iconColor: AppColors.accentGold,
              iconBackground: AppColors.accentGoldTint,
              subtitle: 'Across indexed publications',
            ),
          ],
        ),
        const SizedBox(height: 20),
        ResponsiveRow(
          columns: [
            ResponsiveColumn(
              flex: 6,
              child: outputAsync.when(
                loading: () => const CardSkeleton(height: 340),
                error: (err, st) => const ErrorState(),
                data: (output) => ChartContainer(
                  title: 'Research Output Trend',
                  subtitle: 'Five-year growth across all output types',
                  height: 250,
                  legend: const [
                    ChartLegendItem(
                      label: 'Publications',
                      color: AppColors.primaryBlue,
                    ),
                    ChartLegendItem(
                      label: 'Patents',
                      color: AppColors.accentGold,
                    ),
                    ChartLegendItem(
                      label: 'Funded Projects',
                      color: AppColors.success,
                    ),
                  ],
                  chart: LineChartWidget(
                    xLabels: [for (final year in output) year.year],
                    series: [
                      LineChartSeries(
                        label: 'Publications',
                        color: AppColors.primaryBlue,
                        values: [
                          for (final y in output) y.publications.toDouble(),
                        ],
                      ),
                      LineChartSeries(
                        label: 'Patents',
                        color: AppColors.accentGold,
                        values: [for (final y in output) y.patents.toDouble()],
                      ),
                      LineChartSeries(
                        label: 'Funded Projects',
                        color: AppColors.success,
                        values: [for (final y in output) y.projects.toDouble()],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ResponsiveColumn(
              flex: 4,
              child: byDepartmentAsync.when(
                loading: () => const CardSkeleton(height: 340),
                error: (err, st) => const ErrorState(),
                data: (counts) {
                  final ranked = counts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  return AnalyticsCard(
                    title: 'Publications by Department',
                    subtitle: 'Indexed output on record',
                    child: RankedProgressList(
                      entries: [
                        for (final entry in ranked)
                          RankedEntry(
                            label: entry.key,
                            value: entry.value.toDouble(),
                            displayValue: '${entry.value}',
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
