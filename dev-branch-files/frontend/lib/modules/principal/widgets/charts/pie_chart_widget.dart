import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';

/// A single labeled slice for [PieChartWidget].
class PieChartDatum {
  const PieChartDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Thin fl_chart PieChart wrapper with an adjacent legend — used for
/// composition breakdowns (gender ratio, pass/fail split, department share).
class PieChartWidget extends StatelessWidget {
  const PieChartWidget({super.key, required this.data, this.centerLabel});

  final List<PieChartDatum> data;
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (a, b) => a + b.value);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    sections: [
                      for (final d in data)
                        PieChartSectionData(
                          value: d.value,
                          color: d.color,
                          title: '',
                          radius: 26,
                        ),
                    ],
                  ),
                ),
                if (centerLabel != null)
                  Text(
                    centerLabel!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final d in data)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: d.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          d.label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        total == 0
                            ? '0%'
                            : '${(d.value / total * 100).round()}%',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
