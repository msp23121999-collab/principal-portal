import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import './cards/chart_container.dart';
import './charts/bar_chart_widget.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/student_providers.dart';

/// Average attendance % by department — CGPA comparison lives alongside it
/// on the same provider so both charts stay derived from one computation.
class DepartmentComparisonChart extends ConsumerWidget {
  const DepartmentComparisonChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(departmentComparisonProvider);

    return comparisonAsync.when(
      loading: () => const CardSkeleton(height: 280),
      error: (err, st) => const ErrorState(),
      data: (rows) => ChartContainer(
        title: 'Department Comparison',
        subtitle: 'Average attendance % by department',
        chart: BarChartWidget(
          barColor: AppColors.primaryBlue,
          maxY: 100,
          data: [
            for (final r in rows)
              BarChartDatum(label: r.code, value: r.avgAttendance),
          ],
        ),
      ),
    );
  }
}
