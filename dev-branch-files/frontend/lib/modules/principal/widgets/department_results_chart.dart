import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import './cards/chart_container.dart';
import './charts/bar_chart_widget.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
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
      data: (result) => ChartContainer(
        title: 'Department Results',
        subtitle: result.semesterLabel,
        chart: BarChartWidget(
          barColor: AppColors.success,
          maxY: 100,
          data: [
            for (final d in result.byDepartment)
              BarChartDatum(label: d.departmentCode, value: d.passPercent),
          ],
        ),
      ),
    );
  }
}
