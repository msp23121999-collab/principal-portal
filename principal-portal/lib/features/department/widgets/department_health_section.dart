import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/department_providers.dart';

/// Department Status / Health section
class DepartmentHealthSection extends ConsumerWidget {
  const DepartmentHealthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(departmentInsightsProvider);

    return insightsAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(3, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (insights) {
        int strong = 0;
        int needsAttention = 0;
        int critical = 0;

        for (final d in insights) {
          if (d.status == 'Strong') {
            strong++;
          } else if (d.status == 'Needs Attention') {
            needsAttention++;
          } else {
            critical++;
          }
        }

        return ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Strong Performers',
              value: '$strong',
              icon: AppIcons.approve,
              iconColor: AppColors.success,
              iconBackground: AppColors.successTint,
            ),
            StatisticsCard(
              label: 'Needs Attention',
              value: '$needsAttention',
              icon: AppIcons.clock,
              iconColor: AppColors.warning,
              iconBackground: AppColors.warningTint,
            ),
            StatisticsCard(
              label: 'Critical Status',
              value: '$critical',
              icon: AppIcons.reject,
              iconColor: AppColors.danger,
              iconBackground: AppColors.dangerTint,
            ),
          ],
        );
      },
    );
  }
}
