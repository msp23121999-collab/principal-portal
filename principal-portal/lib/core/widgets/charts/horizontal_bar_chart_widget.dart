import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../feedback/empty_state.dart';

/// One horizontal bar row, optionally paired with a prior-period value
/// drawn as a muted second bar beneath it.
class HorizontalBarDatum {
  const HorizontalBarDatum({
    required this.label,
    required this.value,
    this.comparisonValue,
    this.color,
  });

  final String label;
  final double value;
  final double? comparisonValue;
  final Color? color;
}

/// Ranked horizontal bars with the category name at the left and the
/// figure at the right — the "Pass % by Department" layout.
///
/// Built from layout primitives rather than fl_chart: with one long text
/// label per row, a Row/LinearProgressIndicator composition reflows
/// cleanly at narrow widths, where a rotated fl_chart canvas would clip
/// its axis labels instead.
class HorizontalBarChartWidget extends StatelessWidget {
  const HorizontalBarChartWidget({
    super.key,
    required this.data,
    this.maxValue = 100,
    this.valueSuffix = '%',
    this.comparisonColor,
    this.emptyMessage = 'No data to compare.',
  });

  final List<HorizontalBarDatum> data;
  final double maxValue;
  final String valueSuffix;
  final Color? comparisonColor;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return EmptyState(message: emptyMessage);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Give the label column a third of the width, bounded so it never
        // starves the bars on narrow viewports or sprawls on wide ones.
        final labelWidth = (constraints.maxWidth / 3).clamp(96.0, 200.0);

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final datum in data)
                _BarRow(
                  datum: datum,
                  maxValue: maxValue,
                  valueSuffix: valueSuffix,
                  labelWidth: labelWidth,
                  comparisonColor: comparisonColor ?? AppColors.border,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.datum,
    required this.maxValue,
    required this.valueSuffix,
    required this.labelWidth,
    required this.comparisonColor,
  });

  final HorizontalBarDatum datum;
  final double maxValue;
  final String valueSuffix;
  final double labelWidth;
  final Color comparisonColor;

  double _fraction(double value) =>
      maxValue <= 0 ? 0 : (value / maxValue).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final accent = datum.color ?? AppColors.primaryBlue;
    final comparison = datum.comparisonValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              datum.label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Bar(
                  fraction: _fraction(datum.value),
                  color: accent,
                  height: comparison == null ? 12 : 9,
                ),
                if (comparison != null) ...[
                  const SizedBox(height: 3),
                  _Bar(
                    fraction: _fraction(comparison),
                    color: comparisonColor,
                    height: 5,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            // Wide enough for '100.00%' at the current type size. At 56 the
            // value clipped to '92.0…', which is worse than no figure at all —
            // it reads as a number the chart could not finish.
            width: 84,
            child: Text(
              '${datum.value.toStringAsFixed(2)}$valueSuffix',
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.color,
    required this.height,
  });

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: height,
        backgroundColor: AppColors.background,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
