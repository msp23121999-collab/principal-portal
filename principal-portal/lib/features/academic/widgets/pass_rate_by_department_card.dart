import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/chart_container.dart';
import '../../../core/widgets/charts/horizontal_bar_chart_widget.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/academic_providers.dart';

/// Departments ranked by pass rate, each with the prior year beneath it.
class PassRateByDepartmentCard extends ConsumerWidget {
  const PassRateByDepartmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(departmentPassRatesProvider);

    return ratesAsync.when(
      loading: () => const CardSkeleton(height: 240),
      error: (err, st) => const ErrorState(),
      data: (comparison) {
        if (comparison.rates.isEmpty) {
          return const ChartContainer(
            title: 'Pass Percentage by Department',
            subtitle: 'Ranked by pass percentage',
            height: 120,
            chart: EmptyState(message: 'No department pass rate data available'),
          );
        }

        return ChartContainer(
          title: 'Pass Percentage by Department',
          subtitle: comparison.previousLabel == null
              ? 'Ranked by pass percentage'
              : 'Ranked, against the previous published semester',
          height: 240,
          legend: [
            if (comparison.currentLabel.isNotEmpty)
              ChartLegendItem(
                label: comparison.currentLabel,
                color: AppColors.primaryBlue,
              ),
            if (comparison.previousLabel != null)
              ChartLegendItem(
                label: comparison.previousLabel!,
                color: AppColors.border,
              ),
          ],
          chart: HorizontalBarChartWidget(
            data: [
              for (final rate in comparison.rates)
                HorizontalBarDatum(
                  label: rate.department,
                  value: rate.currentPercent,
                  comparisonValue: rate.previousPercent,
                ),
            ],
          ),
        );
      },
    );
  }
}
