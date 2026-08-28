import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/chart_container.dart';
import '../../../core/widgets/charts/grouped_bar_chart_widget.dart';
import '../../../core/widgets/charts/horizontal_bar_chart_widget.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../core/widgets/layout/responsive_row.dart';
import '../providers/institution_providers.dart';

/// Departments measured against each other on the metrics that matter —
/// academic outcome, attendance, placement, and grade average.
///
/// Lives on Institution Overview rather than standing alone on Department
/// Performance (requirement 11.2). Comparing departments is what the
/// institution-wide view is for; on the departmental screen it sat beside the
/// per-department detail it was meant to summarise.
class DepartmentComparisonSection extends ConsumerWidget {
  const DepartmentComparisonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsProvider);

    return departmentsAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (departments) {
        final byPass = [...departments]
          ..sort((a, b) => b.passPercent.compareTo(a.passPercent));

        // A horizontal bar chart is one row per department, so its height is a
        // function of how many there are. Fixed at 340 it fitted eight and
        // overflowed twelve by 68 pixels — and the count is not ours to
        // predict, it is however many departments the institution has.
        // Only departments with somebody on the roll. A department with no
        // students has no attendance to report, and drawing it at 0.00% says
        // its attendance is terrible rather than unrecorded.
        final withRoll = departments.where((d) => d.studentCount > 0).toList();

        // Each chart is sized by the rows it actually draws. Sharing one
        // height left the attendance chart, which has two rows, stretched
        // across space meant for twelve.
        double barChartHeight(int rows) =>
            (rows * 34.0 + 24).clamp(140.0, 620.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChartContainer(
              title: 'Departmental Performance Comparison',
              subtitle:
                  'Pass, attendance, and placement percentage side by side',
              height: 280,
              legend: const [
                ChartLegendItem(label: 'Pass %', color: AppColors.primaryBlue),
                ChartLegendItem(
                  label: 'Attendance %',
                  color: AppColors.success,
                ),
                ChartLegendItem(
                  label: 'Placement %',
                  color: AppColors.accentGold,
                ),
              ],
              chart: GroupedBarChartWidget(
                maxY: 100,
                showValues: false,
                seriesColors: AppChartPalette.take(3),
                data: [
                  for (final department in departments)
                    GroupedBarDatum(
                      label: department.shortCode,
                      values: [
                        department.passPercent,
                        department.attendancePercent,
                        department.placementPercent,
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ResponsiveRow(
              columns: [
                ResponsiveColumn(
                  flex: 5,
                  child: ChartContainer(
                    title: 'Pass Percentage',
                    subtitle: 'Ranked across all departments',
                    height: barChartHeight(departments.length),
                    chart: HorizontalBarChartWidget(
                      data: [
                        for (final department in byPass)
                          HorizontalBarDatum(
                            label: department.name,
                            value: department.passPercent,
                          ),
                      ],
                    ),
                  ),
                ),
                ResponsiveColumn(
                  flex: 5,
                  child: ChartContainer(
                    // Average CGPA was removed from this page (requirement
                    // 17.8). Attendance replaces it: it is measured for every
                    // department that has students, where the grade average
                    // was 0.00 for ten of the twelve and drew a row of empty
                    // bars.
                    title: 'Average Attendance',
                    subtitle: withRoll.length == departments.length
                        ? 'Attendance percentage by department'
                        : 'Departments with students on the roll '
                              '(${withRoll.length} of ${departments.length})',
                    height: barChartHeight(withRoll.length),
                    chart: HorizontalBarChartWidget(
                      emptyMessage: 'No department has attendance recorded.',
                      data: [
                        for (final department
                            in [...withRoll]..sort(
                              (a, b) => b.attendancePercent.compareTo(
                                a.attendancePercent,
                              ),
                            ))
                          HorizontalBarDatum(
                            label: department.name,
                            value: department.attendancePercent,
                            color: AppColors.success,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
