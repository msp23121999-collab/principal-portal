import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/cards/analytics_card.dart';
import '../../../../core/widgets/cards/ranked_progress_list.dart';
import '../../../../core/widgets/cards/statistics_card.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/status_chip.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../../core/widgets/layout/responsive_row.dart';
import '../../../institution/models/department.dart';
import '../../../institution/providers/institution_providers.dart';
import '../../models/academic_performance.dart';
import '../../providers/academic_providers.dart';
import '../attainment_summary_card.dart';

/// Outcome attainment: how many course and programme outcomes reached
/// each level, and which departments are meeting the 0.80 target.
class CopoAttainmentTab extends ConsumerWidget {
  const CopoAttainmentTab({super.key});

  /// Attainment is scored on a 0-3 scale; departmental scores are derived
  /// from pass rate so this tab stays consistent with the rest of the page.
  static double _attainmentScore(double passPercent) =>
      (passPercent / 100 * 3).clamp(0, 3);

  /// The highest attainment band, found by its label rather than by position.
  ///
  /// `attainment_levels` has no `display_order` column, so the rows arrive in
  /// whatever order Postgres chooses. Reading `levels.first` returned whichever
  /// row happened to come back first — it matched Level 3 only by luck, and the
  /// card's subtitle claimed level 3 either way. Null when no level 3 row
  /// exists, so the card shows a dash instead of another level's figure.
  static AttainmentLevel? _levelThree(List<AttainmentLevel> levels) {
    for (final level in levels) {
      if (RegExp(r'\b3\b').hasMatch(level.label)) return level;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(attainmentLevelsProvider);
    // Empty while the roster loads; the cards below simply render nothing
    // rather than showing a department list that is not the real one.
    final departments =
        ref.watch(departmentsProvider).valueOrNull ?? const <Department>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        levelsAsync.when(
          loading: () => ResponsiveGrid(
            children: List.generate(3, (_) => const CardSkeleton()),
          ),
          error: (err, st) => const ErrorState(),
          data: (levels) {
            final high = _levelThree(levels);
            return ResponsiveGrid(
              children: [
                StatisticsCard(
                  label: 'Course Outcomes Measured',
                  value: '${levels.fold(0, (s, l) => s + l.courseOutcomes)}',
                  icon: AppIcons.academic,
                  iconColor: AppChartPalette.at(0),
                  iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Programme Outcomes Measured',
                  value: '${levels.fold(0, (s, l) => s + l.programOutcomes)}',
                  icon: AppIcons.accreditation,
                  iconColor: AppChartPalette.at(1),
                  iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Outcomes at High Attainment',
                  // A dash, not a zero: no level 3 row on record is missing
                  // data, while '0' would claim no outcome reached the top
                  // band.
                  value: high == null ? '—' : '${high.total}',
                  icon: AppIcons.check,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successTint,
                  subtitle: high?.label ?? 'Attainment level 3 not recorded',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        ResponsiveRow(
          columns: [
            const ResponsiveColumn(flex: 6, child: AttainmentSummaryCard()),
            ResponsiveColumn(
              flex: 4,
              child: AnalyticsCard(
                title: 'Attainment by Department',
                subtitle: 'Average outcome score, out of 3.0',
                child: RankedProgressList(
                  maxValue: 3,
                  entries: [
                    for (final department in departments.take(6))
                      RankedEntry(
                        label: department.shortCode,
                        value: _attainmentScore(department.passPercent),
                        displayValue: _attainmentScore(
                          department.passPercent,
                        ).toStringAsFixed(2),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TableContainer(
          title: 'Departmental Attainment Status',
          subtitle: 'Target attainment is 2.40 (0.80 on the normalised scale)',
          child: CustomDataTable(
            columns: const [
              DataColumnConfig(label: 'Department', size: ColumnSize.L),
              DataColumnConfig(label: 'Outcomes Mapped', numeric: true),
              DataColumnConfig(label: 'Attainment Score', numeric: true),
              DataColumnConfig(label: 'Target Met', size: ColumnSize.S),
            ],
            rows: [
              for (final department in departments)
                DataRow2(
                  cells: [
                    DataCell(
                      Text(department.name, overflow: TextOverflow.ellipsis),
                    ),
                    DataCell(Text('${department.programCount * 6}')),
                    DataCell(
                      Text(
                        _attainmentScore(
                          department.passPercent,
                        ).toStringAsFixed(2),
                      ),
                    ),
                    DataCell(
                      StatusChip(
                        status: _attainmentScore(department.passPercent) >= 2.40
                            ? AppStatus.passed
                            : AppStatus.pending,
                        customLabel:
                            _attainmentScore(department.passPercent) >= 2.40
                            ? 'Met'
                            : 'Below Target',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
