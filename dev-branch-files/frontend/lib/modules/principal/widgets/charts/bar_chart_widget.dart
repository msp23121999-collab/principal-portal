import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';

/// Single named value plotted as a bar.
class BarChartDatum {
  const BarChartDatum({required this.label, required this.value, this.color});

  final String label;
  final double value;
  final Color? color;
}

/// Thin fl_chart BarChart wrapper taking a simple label/value data model.
/// Keeps chart internals isolated from ChartContainer (which only handles
/// layout chrome: title/legend/fixed height).
class BarChartWidget extends StatelessWidget {
  const BarChartWidget({
    super.key,
    required this.data,
    this.maxY,
    this.barColor,
    this.showValues = true,
  });

  final List<BarChartDatum> data;
  final double? maxY;
  final Color? barColor;
  final bool showValues;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxY =
        maxY ??
        (data.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b) *
                1.25)
            .clamp(10, double.infinity)
            .toDouble();

    return BarChart(
      BarChartData(
        maxY: resolvedMaxY,
        alignment: BarChartAlignment.spaceAround,
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
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[idx].label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].value,
                  color: data[i].color ?? barColor ?? AppColors.primaryBlue,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: resolvedMaxY,
                    color: AppColors.background,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
