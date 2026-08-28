import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/charts/pie_chart_widget.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/academic_providers.dart';

/// Grade-band colours run from strongest to weakest, so the donut reads
/// as a performance gradient rather than an arbitrary palette.
const List<Color> _bandColors = [
  AppColors.success,
  AppColors.primaryBlue,
  AppColors.accentGold,
  AppColors.warning,
  AppColors.danger,
];

/// How the cohort's SGPA is distributed across grade bands.
class SgpaDistributionCard extends ConsumerWidget {
  const SgpaDistributionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionAsync = ref.watch(sgpaDistributionProvider);

    return distributionAsync.when(
      loading: () => const CardSkeleton(height: 240),
      error: (err, st) => const ErrorState(),
      data: (bands) {
        final total = bands.fold(0, (sum, band) => sum + band.studentCount);

        if (bands.isEmpty || total == 0) {
          return const AnalyticsCard(
            title: 'SGPA Distribution',
            subtitle: '0 students with published results',
            child: SizedBox(
              height: 120,
              child: EmptyState(message: 'No SGPA distribution data available'),
            ),
          );
        }

        return AnalyticsCard(
          title: 'SGPA Distribution',
          subtitle: '$total students with published results',
          child: SizedBox(
            height: 220,
            child: PieChartWidget(
              centerLabel: '$total',
              data: [
                for (int i = 0; i < bands.length; i++)
                  PieChartDatum(
                    label: bands[i].label,
                    value: bands[i].studentCount.toDouble(),
                    color: _bandColors[i % _bandColors.length],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
