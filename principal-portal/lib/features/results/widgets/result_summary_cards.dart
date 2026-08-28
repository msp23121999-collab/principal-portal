import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/result_providers.dart';

/// Headline pass-percentage KPIs for the currently selected semester.
class ResultSummaryCards extends ConsumerWidget {
  const ResultSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(semesterResultProvider);

    return resultAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(3, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (result) {
        // Null when nothing is published; empty when a semester is published
        // but carries no department breakdown. `reduce` throws on an empty
        // list, so both are handled before it is reached.
        if (result == null || result.byDepartment.isEmpty) {
          return const EmptyState(
            message: 'No published results for this semester yet.',
          );
        }

        final best = result.byDepartment.reduce(
          (a, b) => a.passPercent > b.passPercent ? a : b,
        );
        final worst = result.byDepartment.reduce(
          (a, b) => a.passPercent < b.passPercent ? a : b,
        );

        return ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Overall Pass %',
              value: '${result.overallPassPercent.toStringAsFixed(1)}%',
              icon: AppIcons.results,
              iconColor: AppChartPalette.at(0),
              iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
              subtitle: result.semesterLabel,
            ),
            StatisticsCard(
              label: 'Top Department',
              value: '${best.passPercent.toStringAsFixed(1)}%',
              icon: AppIcons.trendUp,
              iconColor: AppChartPalette.at(1),
              iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
              subtitle: best.departmentCode,
            ),
            StatisticsCard(
              label: 'Needs Attention',
              value: '${worst.passPercent.toStringAsFixed(1)}%',
              icon: AppIcons.warning,
              iconColor: AppChartPalette.at(2),
              iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
              subtitle: worst.departmentCode,
              isTrendPositive: false,
            ),
          ],
        );
      },
    );
  }
}
