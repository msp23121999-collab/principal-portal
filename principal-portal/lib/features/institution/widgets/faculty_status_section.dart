import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/charts/pie_chart_widget.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/institution_providers.dart';

const List<Color> _sliceColors = [
  AppColors.primaryBlue,
  AppColors.success,
  AppColors.accentGold,
  AppColors.darkBlue,
];

/// Faculty headcount split by appointment type, with the institution's
/// total faculty in the donut centre.
class FacultyStatusSection extends ConsumerWidget {
  const FacultyStatusSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compositionAsync = ref.watch(facultyCompositionProvider);

    return compositionAsync.when(
      loading: () => const CardSkeleton(height: 336),
      error: (err, st) => const ErrorState(),
      data: (slices) {
        final total = slices.fold(0, (sum, slice) => sum + slice.count);

        return AnalyticsCard(
          title: 'Faculty Status',
          subtitle: '$total total faculty',
          child: SizedBox(
            height: 240,
            child: PieChartWidget(
              centerLabel: '$total',
              data: [
                for (int i = 0; i < slices.length; i++)
                  PieChartDatum(
                    label: slices[i].label,
                    value: slices[i].count.toDouble(),
                    color: _sliceColors[i % _sliceColors.length],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
