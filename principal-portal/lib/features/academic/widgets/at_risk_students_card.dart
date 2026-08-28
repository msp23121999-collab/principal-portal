import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/charts/pie_chart_widget.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/academic_providers.dart';

const List<Color> _reasonColors = [
  AppColors.primaryBlue,
  AppColors.warning,
  AppColors.danger,
];

/// Why students are flagged at risk, split by cause.
class AtRiskStudentsCard extends ConsumerWidget {
  const AtRiskStudentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reasonsAsync = ref.watch(atRiskReasonsProvider);

    return reasonsAsync.when(
      loading: () => const CardSkeleton(height: 200),
      error: (err, st) => const ErrorState(),
      data: (reasons) {
        final total = reasons.fold(0, (sum, r) => sum + r.studentCount);

        if (reasons.isEmpty || total == 0) {
          return const AnalyticsCard(
            title: 'Students At Risk',
            subtitle: '0 students flagged for intervention',
            child: SizedBox(
              height: 120,
              child: EmptyState(message: 'No at-risk student data recorded'),
            ),
          );
        }

        return AnalyticsCard(
          title: 'Students At Risk',
          subtitle: '$total students flagged for intervention',
          child: SizedBox(
            height: 200,
            child: PieChartWidget(
              centerLabel: '$total',
              data: [
                for (int i = 0; i < reasons.length; i++)
                  PieChartDatum(
                    label: reasons[i].reason,
                    value: reasons[i].studentCount.toDouble(),
                    color: _reasonColors[i % _reasonColors.length],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
