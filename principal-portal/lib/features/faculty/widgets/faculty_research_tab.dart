import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/cards/highlight_list_card.dart';
import '../../../core/widgets/cards/ranked_progress_list.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../core/widgets/layout/responsive_row.dart';
import '../models/faculty.dart';
import '../providers/faculty_providers.dart';

/// Research output per faculty member, and the recognitions on record.
class FacultyResearchTab extends ConsumerWidget {
  const FacultyResearchTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyAsync = ref.watch(facultyListProvider);
    final details = ref.watch(facultyDetailsProvider);

    return facultyAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (roster) {
        final byOutput = [...roster]
          ..sort(
            (a, b) => b.researchPapersCount.compareTo(a.researchPapersCount),
          );
        final totalPapers = roster.fold(
          0,
          (sum, f) => sum + f.researchPapersCount,
        );
        final withProjects = roster
            .where((f) => (details[f.id]?.fundedProjects ?? 0) > 0)
            .length;
        final decorated = roster
            .where((f) => (details[f.id]?.achievements ?? []).isNotEmpty)
            .toList();

        // Publications per department, counted from the roster itself.
        final byDepartment = <String, int>{};
        for (final faculty in roster) {
          final code = DepartmentNormalizer.codeFor(faculty.departmentId);
          byDepartment.update(
            code,
            (value) => value + faculty.researchPapersCount,
            ifAbsent: () => faculty.researchPapersCount,
          );
        }
        final rankedDepartments = byDepartment.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              children: [
                StatisticsCard(
                  label: 'Publications on Roster',
                  value: '$totalPapers',
                  icon: AppIcons.research,
                  iconColor: AppChartPalette.at(0),
                  iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Average per Faculty',
                  // Guarded: filtering to a department with no staff made this
                  // 0 / 0, and `NaN.toStringAsFixed(1)` printed the literal
                  // text 'NaN' on the card.
                  value: roster.isEmpty
                      ? NumberFormatter.unrecorded
                      : (totalPapers / roster.length).toStringAsFixed(1),
                  icon: AppIcons.trendUp,
                  iconColor: AppChartPalette.at(1),
                  iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Holding Funded Projects',
                  value: '$withProjects',
                  icon: AppIcons.academic,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successTint,
                ),
                StatisticsCard(
                  label: 'Faculty with Recognitions',
                  value: '${decorated.length}',
                  icon: AppIcons.award,
                  iconColor: AppColors.accentGold,
                  iconBackground: AppColors.accentGoldTint,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ResponsiveRow(
              columns: [
                ResponsiveColumn(
                  flex: 6,
                  child: TableContainer(
                    title: 'Research Output by Faculty',
                    subtitle: 'Most published first',
                    child: CustomDataTable(
                      emptyMessage: 'No research output recorded.',
                      columns: const [
                        DataColumnConfig(label: 'Faculty', size: ColumnSize.L),
                        DataColumnConfig(label: 'Dept', size: ColumnSize.S),
                        DataColumnConfig(
                          label: 'Designation',
                          size: ColumnSize.M,
                        ),
                        DataColumnConfig(label: 'Papers', numeric: true),
                        DataColumnConfig(label: 'Projects', numeric: true),
                      ],
                      rows: [
                        for (final faculty in byOutput.take(12))
                          DataRow2(
                            cells: [
                              DataCell(
                                Text(
                                  faculty.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(
                                Text(
                                  DepartmentNormalizer.codeFor(
                                    faculty.departmentId,
                                  ),
                                ),
                              ),
                              DataCell(Text(faculty.designation.label)),
                              DataCell(Text('${faculty.researchPapersCount}')),
                              DataCell(
                                Text(
                                  NumberFormatter.orDash(
                                    details[faculty.id]?.fundedProjects,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                ResponsiveColumn(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnalyticsCard(
                        title: 'Output by Department',
                        subtitle: 'Publications across the roster',
                        child: RankedProgressList(
                          entries: [
                            for (final entry in rankedDepartments)
                              RankedEntry(
                                label: entry.key,
                                value: entry.value.toDouble(),
                                displayValue: '${entry.value}',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      HighlightListCard(
                        title: 'Recognitions',
                        subtitle: 'Awards and commendations on record',
                        emptyMessage: 'No recognitions recorded this year.',
                        entries: [
                          for (final faculty in decorated.take(6))
                            HighlightEntry(
                              icon: AppIcons.award,
                              title: faculty.name,
                              detail: details[faculty.id]!.achievements.join(
                                ' · ',
                              ),
                              color: AppColors.accentGold,
                            ),
                        ],
                      ),
                    ],
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
