import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/chart_container.dart';
import '../../../core/widgets/charts/grouped_bar_chart_widget.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/institution_filter_providers.dart';
import '../providers/institution_providers.dart';

/// Enrolment by programme level for the selected academic year against the
/// comparison year.
class StudentsTrendSection extends ConsumerWidget {
  const StudentsTrendSection({super.key});

  static const double _chartHeight = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolmentAsync = ref.watch(enrolmentMixProvider);
    final year = ref.watch(academicYearProvider);
    final comparisonYear = ref.watch(comparisonYearProvider);

    return enrolmentAsync.when(
      loading: () => const CardSkeleton(height: _chartHeight + 96),
      error: (err, st) => const ErrorState(),
      // Recorded enrolment, not the live roll — two different figures, and
      // showing them unlabelled on one page is why this chart read as
      // contradicting the Total Students card. `program_enrolments` is the
      // registrar's count for an academic year; `student.students` is who is
      // on the roll today, and that table currently holds ten students across
      // two departments. The title says which this is.
      data: (enrolment) => ChartContainer(
        title: 'Recorded Enrolment',
        subtitle: 'By programme level, as registered for the academic year',
        height: _chartHeight,
        legend: [
          ChartLegendItem(label: comparisonYear, color: AppColors.border),
          ChartLegendItem(label: year, color: AppColors.primaryBlue),
        ],
        chart: GroupedBarChartWidget(
          seriesColors: AppChartPalette.comparison,
          data: [
            for (final level in enrolment)
              GroupedBarDatum(
                label: level.level,
                values: [
                  level.previousYear.toDouble(),
                  level.currentYear.toDouble(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
