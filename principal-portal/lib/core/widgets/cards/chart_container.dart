import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

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
        // Charts sat on a hairline outline with no shadow, so a page of them
        // read as a wireframe. Lifting them onto the same shadow the KPI cards
        // use makes each chart a distinct object on the page.
        boxShadow: AppElevation.card,
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
                    // The brand rule marks a chart title as a section heading,
                    // matching the treatment PageHeader gives the page title.
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(letterSpacing: -0.2),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 3 + AppSpacing.sm),
                        child: Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Flexible so a long legend wraps onto a second run instead
              // of pushing the header past the card's edge.
              if (legend.isNotEmpty)
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final item in legend)
                        // A tinted pill rather than a loose dot and label: it
                        // binds the swatch to its name, so a four-series legend
                        // no longer reads as eight separate scraps of text.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(999),
                            ),
                          ),
                          child: Row(
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
                              Flexible(
                                child: Text(
                                  item.label,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
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
