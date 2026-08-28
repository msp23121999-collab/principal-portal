import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/chart_container.dart';
import '../../../core/widgets/charts/line_chart_widget.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/institution_providers.dart';

/// Multi-year admission-count trend line chart.
class AdmissionTrendSection extends ConsumerWidget {
  const AdmissionTrendSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(admissionTrendProvider);

    return trendAsync.when(
      loading: () => const CardSkeleton(height: 280),
      error: (err, st) => const ErrorState(),
      data: (points) => ChartContainer(
        title: 'Admission Trends',
        subtitle: 'New student admissions over the last 6 academic years',
        legend: const [
          ChartLegendItem(label: 'Admissions', color: AppColors.primaryBlue),
        ],
        chart: LineChartWidget(
          xLabels: [for (final p in points) p.year],
          series: [
            LineChartSeries(
              label: 'Admissions',
              values: [for (final p in points) p.value],
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
