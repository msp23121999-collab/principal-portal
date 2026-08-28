import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../feedback/empty_state.dart';
import 'chart_semantics.dart';

/// One category plotted twice: as a bar against the left axis and as a
/// line point against the right axis.
class ComboChartDatum {
  const ComboChartDatum({
    required this.label,
    required this.barValue,
    required this.lineValue,
  });

  final String label;
  final double barValue;
  final double lineValue;
}

/// Dual-axis chart: bars on the left scale with a trend line on the right
/// — the "pass percentage against average SGPA" pairing, where the two
/// series share categories but not units.
///
/// fl_chart draws one series type per chart, so this stacks a [BarChart]
/// under a [LineChart]. Both are given identical axis reservations, which
/// makes their plot rectangles line up exactly; the line's values are
/// rescaled onto the bar axis so the overlay reads as a single figure.
class ComboChartWidget extends StatelessWidget {
  const ComboChartWidget({
    super.key,
    required this.data,
    this.barMax = 100,
    this.lineMax = 10,
    this.barColor,
    this.lineColor,
    this.showBarValues = true,
    this.barValueSuffix = '%',
    this.emptyMessage = 'No performance data available.',
  });

  final List<ComboChartDatum> data;

  /// Upper bound of the left (bar) axis.
  final double barMax;

  /// Upper bound of the right (line) axis.
  final double lineMax;

  final Color? barColor;
  final Color? lineColor;
  final bool showBarValues;
  final String barValueSuffix;
  final String emptyMessage;

  // Identical on both layers — this is what keeps the plot areas aligned.
  static const double _leftReserved = 38;
  static const double _rightReserved = 34;
  static const double _bottomReserved = 30;
  static const double _topReserved = 22;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return EmptyState(message: emptyMessage);

    // Two painted layers, one summary. Labelling each separately would read
    // the category names twice and the two series as unrelated.
    return ChartSemantics.wrap(
      label: ChartSemantics.describeSeries(
        'Combined bar and line chart',
        [for (final d in data) d.label],
        [
          (label: 'Bars', values: [for (final d in data) d.barValue]),
          (label: 'Line', values: [for (final d in data) d.lineValue]),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _buildBars(context)),
          Positioned.fill(child: IgnorePointer(child: _buildLine(context))),
        ],
      ),
    );
  }

  Widget _buildBars(BuildContext context) {
    final resolvedBarColor = barColor ?? AppColors.primaryBlue;
    final labelStyle = Theme.of(context).textTheme.bodySmall;

    return BarChart(
      BarChartData(
        maxY: barMax,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: barMax / 5,
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
                '${item.label}\nPass Percentage: ${rod.toY.round()}$barValueSuffix\nAverage SGPA: ${item.lineValue}',
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
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _topReserved,
              getTitlesWidget: _blankTitle,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _rightReserved,
              getTitlesWidget: _blankTitle,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _leftReserved,
              interval: barMax / 5,
              getTitlesWidget: (value, meta) =>
                  Text('${value.round()}$barValueSuffix', style: labelStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _bottomReserved,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                final compactLabel = _formatCompactLabel(data[index].label, index);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    compactLabel,
                    style: labelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
              showingTooltipIndicators: const [],
              barRods: [
                BarChartRodData(
                  toY: data[i].barValue,
                  color: resolvedBarColor,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: barMax,
                    color: AppColors.background,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLine(BuildContext context) {
    final resolvedLineColor = lineColor ?? AppColors.success;
    final scale = lineMax <= 0 ? 0.0 : barMax / lineMax;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: barMax,
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _topReserved,
              getTitlesWidget: _blankTitle,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _leftReserved,
              getTitlesWidget: _blankTitle,
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _bottomReserved,
              getTitlesWidget: _blankTitle,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _rightReserved,
              interval: barMax / 5,
              getTitlesWidget: (value, meta) => Text(
                (value / scale).round().toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: resolvedLineColor,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: resolvedLineColor,
                    strokeWidth: 2,
                    strokeColor: AppColors.surface,
                  ),
            ),
            spots: [
              for (int i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i].lineValue * scale),
            ],
          ),
        ],
      ),
    );
  }
}

/// Occupies an axis slot without drawing, so the overlaid chart keeps the
/// same plot rectangle as the one beneath it.
Widget _blankTitle(double value, TitleMeta meta) => const SizedBox.shrink();

/// Formats full semester names (e.g. "Semester 1", "Semester 01 (TEST_PRINCIPAL_001)")
/// into compact labels (e.g. "Sem 1", "Sem 10").
String _formatCompactLabel(String label, [int? index]) {
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
  if (index != null) {
    return 'Sem ${index + 1}';
  }
  return text;
}
