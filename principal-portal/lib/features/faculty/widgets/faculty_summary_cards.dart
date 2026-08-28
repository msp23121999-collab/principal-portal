import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/faculty_providers.dart';

/// Headline KPI row for the Faculty Performance screen.
class FacultySummaryCards extends ConsumerWidget {
  const FacultySummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyAsync = ref.watch(facultyListProvider);

    return facultyAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(4, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (faculty) {
        // Averages skip unrecorded (zero) values so a member whose figures
        // have not been entered yet does not drag the institution average
        // towards zero.
        double average(Iterable<double> values) {
          final recorded = values.where((v) => v > 0);
          if (recorded.isEmpty) return 0;
          return recorded.reduce((a, b) => a + b) / recorded.length;
        }

        return ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Total Faculty',
              value: faculty.length.toString(),
              icon: AppIcons.faculty,
              iconColor: AppChartPalette.at(0),
              iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
            ),
            StatisticsCard(
              label: 'Avg. Attendance',
              value:
                  '${average(faculty.map((f) => f.attendancePercent)).toStringAsFixed(1)}%',
              icon: AppIcons.attendance,
              iconColor: AppChartPalette.at(1),
              iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
            ),
            StatisticsCard(
              label: 'Research Papers',
              value: faculty
                  .fold(0, (sum, f) => sum + f.researchPapersCount)
                  .toString(),
              icon: AppIcons.research,
              iconColor: AppChartPalette.at(2),
              iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
            ),
          ],
        );
      },
    );
  }
}
