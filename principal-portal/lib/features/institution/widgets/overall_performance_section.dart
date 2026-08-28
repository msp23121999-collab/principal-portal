import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/chart_container.dart';
import '../../../core/widgets/charts/combo_chart_widget.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/institution_overview.dart';
import '../providers/institution_providers.dart';

/// Pass percentage bars against average SGPA on a secondary axis. Honours
/// the applied semester filter by narrowing to that single semester.
class OverallPerformanceSection extends ConsumerWidget {
  const OverallPerformanceSection({super.key});

  static const double _chartHeight = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(semesterPerformanceProvider);
    // `semester_performance.semester` is text ('Semester 5'); the shared
    // filter holds an integer, so the two are matched on the number.
    final semesterFilter = ref.watch(portalFiltersProvider).semester;

    return performanceAsync.when(
      loading: () => const CardSkeleton(height: _chartHeight + 96),
      error: (err, st) => const ErrorState(),
      data: (performance) {
        final rawFiltered = semesterFilter == null
            ? performance
            : performance
                  .where(
                    (p) =>
                        RegExp(r'(\d+)').firstMatch(p.semester)?.group(1) ==
                        '$semesterFilter',
                  )
                  .toList();

        int extractSemNum(String s) {
          final match = RegExp(r'(\d+)').firstMatch(s);
          return match != null ? (int.tryParse(match.group(1)!) ?? 0) : 0;
        }

        final Map<int, SemesterPerformance> uniqueSemesters = {};
        for (final p in rawFiltered) {
          final semNum = extractSemNum(p.semester);
          if (semNum > 0 && !uniqueSemesters.containsKey(semNum)) {
            uniqueSemesters[semNum] = p;
          } else if (semNum == 0) {
            uniqueSemesters[uniqueSemesters.length + 100] = p;
          }
        }

        final sortedEntries = uniqueSemesters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        final visible = sortedEntries.map((e) => e.value).toList();

        return ChartContainer(
          title: 'Overall Performance',
          subtitle: semesterFilter == null
              ? 'By semester'
              : 'Filtered to $semesterFilter',
          height: _chartHeight,
          legend: const [
            ChartLegendItem(
              label: 'Pass Percentage (%)',
              color: AppColors.primaryBlue,
            ),
            ChartLegendItem(
              label: 'Average SGPA (out of 10)',
              color: AppColors.success,
            ),
          ],
          chart: visible.isEmpty
              ? const EmptyState(
                  message: 'No results published for this semester yet.',
                )
              : ComboChartWidget(
                  barMax: 100,
                  lineMax: 10,
                  data: [
                    for (final item in visible)
                      ComboChartDatum(
                        label: item.semester,
                        barValue: item.passPercent,
                        lineValue: item.averageSgpa,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
