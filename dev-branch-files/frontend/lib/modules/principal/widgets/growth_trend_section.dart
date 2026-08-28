import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './cards/chart_container.dart';
import './charts/line_chart_widget.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../models/institution_trend.dart';

/// One growth trend chart (academic / faculty / student) — parameterized
/// so Academic Growth, Faculty Growth, and Student Growth all reuse this
/// exact widget instead of three near-identical implementations.
class GrowthTrendSection extends ConsumerWidget {
  const GrowthTrendSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.provider,
  });

  final String title;
  final String subtitle;
  final Color color;
  final ProviderListenable<AsyncValue<List<YearlyMetric>>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(provider);

    return trendAsync.when(
      loading: () => const CardSkeleton(height: 260),
      error: (err, st) => const ErrorState(),
      data: (points) => ChartContainer(
        title: title,
        subtitle: subtitle,
        height: 200,
        legend: [ChartLegendItem(label: title, color: color)],
        chart: LineChartWidget(
          xLabels: [for (final p in points) p.year],
          series: [
            LineChartSeries(
              label: title,
              values: [for (final p in points) p.value],
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
