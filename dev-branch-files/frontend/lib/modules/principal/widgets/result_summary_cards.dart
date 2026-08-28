import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_icons.dart';
import '../utils/responsive_utils.dart';
import './cards/statistics_card.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
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
              subtitle: result.semesterLabel,
            ),
            StatisticsCard(
              label: 'Top Department',
              value: '${best.passPercent.toStringAsFixed(1)}%',
              icon: AppIcons.trendUp,
              subtitle: best.departmentCode,
            ),
            StatisticsCard(
              label: 'Needs Attention',
              value: '${worst.passPercent.toStringAsFixed(1)}%',
              icon: AppIcons.warning,
              subtitle: worst.departmentCode,
              isTrendPositive: false,
            ),
          ],
        );
      },
    );
  }
}
