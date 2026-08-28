import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/cards/chart_container.dart';
import '../../../core/widgets/charts/bar_chart_widget.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/result_providers.dart';

/// Pass-percentage by department for the currently selected semester.
class DepartmentResultsChart extends ConsumerWidget {
  const DepartmentResultsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(semesterResultProvider);

    return resultAsync.when(
      loading: () => const CardSkeleton(height: 280),
      error: (err, st) => const ErrorState(),
      // Null when no semester has published results yet.
      data: (result) => result == null
          ? const AnalyticsCard(
              title: 'Department Results',
              child: EmptyState(message: 'No published results yet.'),
            )
          : ChartContainer(
              title: 'Department Results',
              subtitle: result.semesterLabel,
              chart: BarChartWidget(
                barColor: AppColors.success,
                maxY: 100,
                data: [
                  for (final d in result.byDepartment)
                    BarChartDatum(
                      label: d.departmentCode,
                      value: d.passPercent,
                    ),
                ],
              ),
            ),
    );
  }
}
