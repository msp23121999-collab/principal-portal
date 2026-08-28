import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/cards/ranked_progress_list.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/academic_providers.dart';

/// The five strongest departments by pass rate.
class TopDepartmentsCard extends ConsumerWidget {
  const TopDepartmentsCard({super.key});

  static const int _visibleCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(departmentPassRatesProvider);

    return ratesAsync.when(
      loading: () => const CardSkeleton(height: 200),
      error: (err, st) => const ErrorState(),
      data: (comparison) {
        if (comparison.rates.isEmpty) {
          return const AnalyticsCard(
            title: 'Top Performing Departments',
            subtitle: 'By pass percentage',
            child: SizedBox(
              height: 120,
              child: EmptyState(message: 'No top department data available'),
            ),
          );
        }

        return AnalyticsCard(
          title: 'Top Performing Departments',
          subtitle: comparison.currentLabel.isEmpty
              ? 'By pass percentage'
              : 'By pass percentage — ${comparison.currentLabel}',
          child: RankedProgressList(
            maxValue: 100,
            entries: [
              for (final rate in comparison.rates.take(_visibleCount))
                RankedEntry(
                  label: rate.department,
                  value: rate.currentPercent,
                  displayValue: '${rate.currentPercent.toStringAsFixed(2)}%',
                  color: AppColors.success,
                ),
            ],
          ),
        );
      },
    );
  }
}
