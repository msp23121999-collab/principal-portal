import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/buttons/icon_action_button.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/faculty.dart';
import '../models/faculty_detail.dart';
import '../providers/faculty_providers.dart';
import 'faculty_profile_dialog.dart';

/// Teaching load and appraisal for every roster member, with the profile
/// drill-down on each row.
class FacultyWorkloadTab extends ConsumerWidget {
  const FacultyWorkloadTab({super.key});

  // The 18-hour AICTE norm now lives on FacultyDetail.weeklyHoursNorm, beside
  // `isOverloaded`, so the "Over / Normal" chip and the card's subtitle cannot
  // drift apart.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyAsync = ref.watch(facultyListProvider);
    final details = ref.watch(facultyDetailsProvider);

    return facultyAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (roster) {
        final rows = [...roster]
          ..sort((a, b) {
            final aHours = details[a.id]?.weeklyTeachingHours ?? 0;
            final bHours = details[b.id]?.weeklyTeachingHours ?? 0;
            return bHours.compareTo(aHours);
          });

        /// Mean of the values actually on record.
        ///
        /// Null — not zero — when nothing is recorded, which is also what
        /// happens when the department filter matches nobody. These three
        /// cards used to divide by `roster.length` unconditionally, so
        /// choosing a department with no staff printed the literal text `NaN`
        /// on screen. Skipping unrecorded values matches every other average
        /// in the portal: a blank appraisal is not a score of zero.
        double? averageOf(double? Function(FacultyDetail) select) {
          final recorded = [
            for (final f in roster)
              if (details[f.id] != null && select(details[f.id]!) != null)
                select(details[f.id]!)!,
          ];
          if (recorded.isEmpty) return null;
          return recorded.reduce((a, b) => a + b) / recorded.length;
        }

        final overloaded = ref.watch(overloadedFacultyProvider).length;
        final averageHours = averageOf(
          (d) => d.weeklyTeachingHours?.toDouble(),
        );
        final averageAppraisal = averageOf((d) => d.appraisalScore);
        final averageFeedback = averageOf((d) => d.feedbackScore);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              children: [
                StatisticsCard(
                  label: 'Average Weekly Load',
                  value: NumberFormatter.orDash(
                    averageHours,
                    (hours) => '${hours.toStringAsFixed(1)} hrs',
                  ),
                  icon: AppIcons.clock,
                  iconColor: AppChartPalette.at(0),
                  iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
                  subtitle: 'Norm is ${FacultyDetail.weeklyHoursNorm} hours',
                ),
                StatisticsCard(
                  label: 'Above Workload Norm',
                  value: '$overloaded',
                  icon: AppIcons.warning,
                  iconColor: AppColors.warning,
                  iconBackground: AppColors.warningTint,
                  subtitle: 'Of ${roster.length} faculty',
                ),
                StatisticsCard(
                  label: 'Average Appraisal',
                  value: NumberFormatter.orDash(
                    averageAppraisal,
                    (score) => '${score.toStringAsFixed(1)} / 100',
                  ),
                  icon: AppIcons.award,
                  iconColor: AppChartPalette.at(2),
                  iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Student Feedback',
                  value: NumberFormatter.orDash(
                    averageFeedback,
                    (score) => '${score.toStringAsFixed(2)} / 5.0',
                  ),
                  icon: AppIcons.trendUp,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successTint,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TableContainer(
              title: 'Workload & Appraisal',
              subtitle: 'Heaviest teaching load first',
              child: CustomDataTable(
                emptyMessage: 'No faculty on the roster.',
                columns: const [
                  DataColumnConfig(label: 'Faculty', size: ColumnSize.L),
                  DataColumnConfig(label: 'Department', size: ColumnSize.M),
                  DataColumnConfig(label: 'Hours/Week', numeric: true),
                  DataColumnConfig(label: 'Subjects', numeric: true),
                  DataColumnConfig(label: 'Mentees', numeric: true),
                  DataColumnConfig(label: 'Appraisal', numeric: true),
                  DataColumnConfig(label: 'Feedback', numeric: true),
                  DataColumnConfig(label: 'Load', size: ColumnSize.S),
                  DataColumnConfig(label: '', size: ColumnSize.S),
                ],
                rows: [
                  for (final faculty in rows)
                    if (details[faculty.id] != null)
                      _workloadRow(context, faculty, details[faculty.id]!),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  DataRow2 _workloadRow(
    BuildContext context,
    Faculty faculty,
    FacultyDetail detail,
  ) {
    return DataRow2(
      cells: [
        DataCell(Text(faculty.name, overflow: TextOverflow.ellipsis)),
        DataCell(Text(DepartmentNormalizer.codeFor(faculty.departmentId))),
        DataCell(
          Text(
            NumberFormatter.orDash(detail.weeklyTeachingHours),
            style: TextStyle(
              color: detail.isOverloaded
                  ? AppColors.danger
                  : AppColors.primaryText,
              fontWeight: detail.isOverloaded
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
        DataCell(Text(NumberFormatter.orDash(detail.subjectsHandled))),
        DataCell(Text(NumberFormatter.orDash(detail.mentees))),
        DataCell(
          Text(
            NumberFormatter.orDash(
              detail.appraisalScore,
              (score) => score.toStringAsFixed(0),
            ),
          ),
        ),
        DataCell(
          Text(
            NumberFormatter.orDash(
              detail.feedbackScore,
              (score) => score.toStringAsFixed(1),
            ),
          ),
        ),
        DataCell(
          // An unrecorded workload gets no verdict — 'Normal' would be a
          // judgement on a figure nobody entered.
          detail.weeklyTeachingHours == null
              ? const Text(NumberFormatter.unrecorded)
              : StatusChip(
                  status: detail.isOverloaded
                      ? AppStatus.pending
                      : AppStatus.approved,
                  customLabel: detail.isOverloaded ? 'Over' : 'Normal',
                ),
        ),
        DataCell(
          IconActionButton(
            icon: AppIcons.chevronRight,
            tooltip: 'View ${faculty.name}',
            onPressed: () => FacultyProfileDialog.show(
              context,
              faculty: faculty,
              detail: detail,
            ),
          ),
        ),
      ],
    );
  }
}
