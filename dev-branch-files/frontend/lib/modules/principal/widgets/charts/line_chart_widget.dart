import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';

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

    return LineChart(
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
              reservedSize: 34,
              interval: resolvedMaxY / 4,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
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
    );
  }
}
