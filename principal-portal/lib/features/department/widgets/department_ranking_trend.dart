import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/department_providers.dart';

/// Shows department ranking and performance trends
class DepartmentRankingTrend extends ConsumerWidget {
  const DepartmentRankingTrend({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(departmentInsightsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.md,
            top: AppSpacing.lg,
          ),
          child: Text(
            'Department Ranking & Trends',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        insightsAsync.when(
          loading: () => ResponsiveGrid(
            minTileWidth: 300,
            children: List.generate(4, (_) => const CardSkeleton(height: 120)),
          ),
          error: (err, st) => const ErrorState(),
          data: (insights) => ResponsiveGrid(
            minTileWidth: 300,
            children: [for (final d in insights) _RankingTrendCard(insight: d)],
          ),
        ),
      ],
    );
  }
}

class _RankingTrendCard extends StatelessWidget {
  const _RankingTrendCard({required this.insight});

  final DepartmentPerformanceInsights insight;

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
                child: Text(
                  insight.departmentCode,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGoldTint,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  'Rank #${insight.rank}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onAccentGoldTint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            insight.departmentName,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _TrendMetric(
                  label: 'Result (CGPA)',
                  direction: insight.cgpaTrend,
                ),
              ),
              Expanded(
                child: _TrendMetric(
                  label: 'Attendance',
                  direction: insight.attendanceTrend,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendMetric extends StatelessWidget {
  const _TrendMetric({required this.label, required this.direction});

  final String label;
  final TrendDirection direction;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String text;

    if (direction == TrendDirection.improving) {
      icon = AppIcons.trendUp;
      color = AppColors.success;
      text = 'Improving';
    } else if (direction == TrendDirection.declining) {
      icon = AppIcons.trendDown;
      color = AppColors.danger;
      text = 'Declining';
    } else {
      icon = AppIcons.horizontalRule;
      color = AppColors.secondaryText;
      text = 'Stable';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                // From the theme, not stated here — see the design-system rule
                // guarded by test/typography_consistency_test.dart.
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
