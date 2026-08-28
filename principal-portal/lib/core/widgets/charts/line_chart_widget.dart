import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'chart_semantics.dart';

/// A single named series for [LineChartWidget].
class LineChartSeries {
  const LineChartSeries({
    required this.label,
    required this.values,
    required this.color,
  });

  final String label;
  final List<double> values;
  final Color color;
}

/// Thin fl_chart LineChart wrapper for trend visualizations (admission
/// trends, academic growth, attendance over time).
class LineChartWidget extends StatelessWidget {
  const LineChartWidget({
    super.key,
    required this.xLabels,
    required this.series,
    this.maxY,
  });

  final List<String> xLabels;
  final List<LineChartSeries> series;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    final allValues = series.expand((s) => s.values);
    final resolvedMaxY =
        maxY ??
        (allValues.isEmpty
                ? 10.0
                : allValues.reduce((a, b) => a > b ? a : b) * 1.25)
            .clamp(10, double.infinity)
            .toDouble();

    return ChartSemantics.wrap(
      label: ChartSemantics.describeSeries('Line chart', xLabels, [
        for (final s in series) (label: s.label, values: s.values),
      ]),
      child: LineChart(
        LineChartData(
          maxY: resolvedMaxY,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: resolvedMaxY / 4,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                // Wide enough for a compacted four-figure value at the current
                // type size. At 34 the axis wrapped '4262' onto two lines and
                // rendered it as '426' above a stray '2'.
                reservedSize: 52,
                interval: resolvedMaxY / 4,
                getTitlesWidget: (value, meta) => Text(
                  _compact(value),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                // One label per data point. Without an interval fl_chart picks a
                // fractional one, calls this repeatedly between points, and each
                // call rounds to the same index — which is why six years of
                // admissions drew as '2026 2026 2026 2026 2026 2025 ...'.
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= xLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      xLabels[idx],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.darkBlue,
            ),
          ),
          lineBarsData: [
            for (final s in series)
              LineChartBarData(
                isCurved: true,
                curveSmoothness: 0.25,
                color: s.color,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: s.color.withValues(alpha: 0.08),
                ),
                spots: [
                  for (int i = 0; i < s.values.length; i++)
                    FlSpot(i.toDouble(), s.values[i]),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Axis labels in as few characters as the value allows.
///
/// A vertical axis that has to be wide enough for '4262' steals room from the
/// plot; '4.3K' says the same thing in half the space.
String _compact(double value) {
  if (value.abs() >= 10000) return '${(value / 1000).toStringAsFixed(0)}K';
  if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toInt().toString();
}
