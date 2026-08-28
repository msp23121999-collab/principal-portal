import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/academic_providers.dart';

const List<IconData> _kpiIcons = [
  AppIcons.education,
  AppIcons.trendUp,
  AppIcons.award,
  AppIcons.academic,
  AppIcons.check,
  AppIcons.warning,
];

/// Headline academic figures — pass rate, grade averages, cohort sizes,
/// and the at-risk count.
class AcademicKpiGrid extends ConsumerWidget {
  const AcademicKpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(academicKpisProvider);

    return kpisAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(6, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (kpis) {
        if (kpis.isEmpty) return const SizedBox.shrink();
        return ResponsiveGrid(
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
        );
      },
    );
  }
}
