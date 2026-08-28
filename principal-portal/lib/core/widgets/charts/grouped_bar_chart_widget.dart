import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../feedback/empty_state.dart';
import 'chart_semantics.dart';

/// One category with a value per series, e.g. "UG" measured in both the
/// current and the previous academic year.
class GroupedBarDatum {
  const GroupedBarDatum({required this.label, required this.values});

  final String label;

  /// Positionally matched to the chart's series colours.
  final List<double> values;
}

/// Side-by-side bars per category — the year-over-year comparison shape
/// used for enrolment mix, research output, and revenue breakdowns.
///
/// [BarChartWidget] covers the single-series case; this handles two or
/// more series sharing one axis.
class GroupedBarChartWidget extends StatelessWidget {
  const GroupedBarChartWidget({
    super.key,
    required this.data,
    required this.seriesColors,
    this.maxY,
    this.showValues = true,
    this.emptyMessage = 'No comparison data available.',
  });

  final List<GroupedBarDatum> data;
  final List<Color> seriesColors;
  final double? maxY;
  final bool showValues;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || seriesColors.isEmpty) {
      return EmptyState(message: emptyMessage);
    }

    final peak = data
        .expand((d) => d.values)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final resolvedMaxY =
        maxY ?? (peak * 1.3).clamp(10, double.infinity).toDouble();
    final labelStyle = Theme.of(context).textTheme.bodySmall;

    // Each category carries one value per series, so the summary is read
    // series by series rather than as one flat run of numbers.
    return ChartSemantics.wrap(
      label: ChartSemantics.describeSeries(
        'Grouped bar chart',
        [for (final d in data) d.label],
        [
          for (var i = 0; i < seriesColors.length; i++)
            (
              label: 'Series ${i + 1}',
              values: [
                for (final d in data)
                  if (i < d.values.length) d.values[i],
              ],
            ),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: resolvedMaxY,
          alignment: BarChartAlignment.spaceAround,
          groupsSpace: 18,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: resolvedMaxY / 4,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 2,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (!showValues) return null;
                return BarTooltipItem(
                  _compact(rod.toY),
                  Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: AppColors.primaryText,
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
                reservedSize: 40,
                interval: resolvedMaxY / 4,
                getTitlesWidget: (value, meta) =>
                    Text(_compact(value), style: labelStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(data[index].label, style: labelStyle),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                // Only the last series carries a value label. Bars in a group
                // sit 4px apart, so labelling every one put '3.0K' and '3.2K'
                // on top of each other — two unreadable figures instead of one
                // readable one. The rest are available on hover.
                showingTooltipIndicators:
                    showValues && data[i].values.isNotEmpty
                    ? [data[i].values.length - 1]
                    : const [],
                barRods: [
                  for (int s = 0; s < data[i].values.length; s++)
                    BarChartRodData(
                      toY: data[i].values[s],
                      color: seriesColors[s % seriesColors.length],
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
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

/// Axis and bar labels stay narrow: 10500 renders as "10.5K".
String _compact(double value) {
  if (value.abs() >= 1000) {
    final thousands = value / 1000;
    final text = thousands.toStringAsFixed(
      thousands.truncateToDouble() == thousands ? 0 : 1,
    );
    return '${text}K';
  }
  return value.round().toString();
}
