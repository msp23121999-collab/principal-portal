import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'chart_semantics.dart';

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

    return ChartSemantics.wrap(
      label: ChartSemantics.describe('Bar chart', [
        for (final d in data) (label: d.label, value: d.value),
      ]),
      child: BarChart(
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
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primaryText,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < 0 || groupIndex >= data.length) return null;
                final item = data[groupIndex];
                return BarTooltipItem(
                  '${item.label}\nValue: ${rod.toY.round()}',
                  Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
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
                // type size; at 34 the axis wrapped '1482' onto two lines.
                reservedSize: 52,
                interval: resolvedMaxY / 4,
                getTitlesWidget: (value, meta) => Text(
                  _compact(value),
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                // One label per bar. Without this fl_chart picks a fractional
                // interval and repeats the same label between bars.
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final labelText = _formatCompactLabel(data[idx].label);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labelText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
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
      ),
    );
  }
}

/// Axis labels in as few characters as the value allows, so a wide figure
/// does not steal room from the plot or wrap onto a second line.
String _compact(double value) {
  if (value.abs() >= 10000) return '${(value / 1000).toStringAsFixed(0)}K';
  if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toInt().toString();
}

/// Formats full semester names (e.g. "Semester 1", "Semester 01 (TEST_PRINCIPAL_001)")
/// into compact labels (e.g. "Sem 1", "Sem 10").
String _formatCompactLabel(String label) {
  var text = label.trim();
  if (text.contains(' (')) {
    text = text.split(' (').first.trim();
  }
  final semMatch = RegExp(r'Semester\s*0*(\d+)', caseSensitive: false).firstMatch(text);
  if (semMatch != null) {
    return 'Sem ${semMatch.group(1)}';
  }
  final semShortMatch = RegExp(r'Sem\s*0*(\d+)', caseSensitive: false).firstMatch(text);
  if (semShortMatch != null) {
    return 'Sem ${semShortMatch.group(1)}';
  }
  return text;
}
