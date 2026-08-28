import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/finance_providers.dart';

const List<IconData> _kpiIcons = [
  AppIcons.currency,
  AppIcons.check,
  AppIcons.warning,
  AppIcons.award,
  AppIcons.faculty,
  AppIcons.trendUp,
];

/// Headline financial position for the year to date.
class FinanceKpiGrid extends ConsumerWidget {
  const FinanceKpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(financeKpisProvider);

    return kpisAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(6, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (kpis) => ResponsiveGrid(
        children: [
          for (int i = 0; i < kpis.length; i++)
            StatisticsCard(
              label: kpis[i].label,
              value: kpis[i].value,
              icon: _kpiIcons[i % _kpiIcons.length],
              iconColor: kpis[i].isPositive
                  ? AppColors.primaryBlue
                  : AppColors.danger,
              iconBackground: kpis[i].isPositive
                  ? AppColors.primaryBlueTint
                  : AppColors.dangerTint,
              trendValue: kpis[i].trend,
              isTrendPositive: kpis[i].isPositive,
            ),
        ],
      ),
    );
  }
}
