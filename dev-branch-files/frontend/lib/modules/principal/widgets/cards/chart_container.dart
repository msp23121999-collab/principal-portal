import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';

/// A single legend entry rendered beneath a chart's title row.
class ChartLegendItem {
  const ChartLegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

/// Layout chrome around a chart: title, optional legend row, fixed height
/// content area. The chart itself (BarChartWidget/LineChartWidget/...) is
/// passed in as [chart] — this widget owns no chart-drawing logic.
class ChartContainer extends StatelessWidget {
  const ChartContainer({
    super.key,
    required this.title,
    required this.chart,
    this.subtitle,
    this.legend = const [],
    this.trailing,
    this.height = 240,
  });

  final String title;
  final String? subtitle;
  final Widget chart;
  final List<ChartLegendItem> legend;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (legend.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.md,
                  children: [
                    for (final item in legend)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            item.label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                  ],
                ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }
}
