import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/date_formatter.dart';
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
import '../../models/audit.dart';
import '../../providers/audit_providers.dart';

AppStatus _statusFor(ComplianceState state) {
  switch (state) {
    case ComplianceState.compliant:
      return AppStatus.approved;
    case ComplianceState.partial:
      return AppStatus.pending;
    case ComplianceState.atRisk:
      return AppStatus.onLeave;
    case ComplianceState.nonCompliant:
      return AppStatus.rejected;
  }
}

Color _colorFor(ComplianceState state) {
  switch (state) {
    case ComplianceState.compliant:
      return AppColors.success;
    case ComplianceState.partial:
      return AppColors.accentGold;
    case ComplianceState.atRisk:
      return AppColors.warning;
    case ComplianceState.nonCompliant:
      return AppColors.danger;
  }
}

/// Compliance scorecard across every obligation area, weakest first.
class ComplianceTab extends ConsumerWidget {
  const ComplianceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(complianceAreasProvider);
    final summary = ref.watch(auditSummaryProvider).valueOrNull;

    return areasAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (areas) {
        // Group by category so the rail summarises where risk concentrates.
        final byCategory = <String, List<ComplianceArea>>{};
        for (final area in areas) {
          byCategory.putIfAbsent(area.category, () => []).add(area);
        }
        final categoryScores = byCategory.entries.map((entry) {
          final average =
              entry.value.fold(0.0, (sum, a) => sum + a.scorePercent) /
              entry.value.length;
          return (category: entry.key, score: average);
        }).toList()..sort((a, b) => a.score.compareTo(b.score));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              children: [
                StatisticsCard(
                  label: 'Overall Compliance',
                  value:
                      '${summary?.averageComplianceScore.toStringAsFixed(1) ?? '—'}%',
                  icon: AppIcons.accreditation,
                  iconColor: AppChartPalette.at(0),
                  iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Areas Compliant',
                  value: '${summary?.compliantAreas ?? 0} of ${areas.length}',
                  icon: AppIcons.check,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successTint,
                ),
                StatisticsCard(
                  label: 'Needing Action',
                  value: '${summary?.areasNeedingAction ?? 0}',
                  icon: AppIcons.warning,
                  iconColor: AppColors.danger,
                  iconBackground: AppColors.dangerTint,
                  subtitle: 'At risk or non-compliant',
                ),
                StatisticsCard(
                  label: 'Open Inspection Findings',
                  value: '${summary?.openInspectionFindings ?? 0}',
                  icon: AppIcons.audit,
                  iconColor: AppColors.warning,
                  iconBackground: AppColors.warningTint,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ResponsiveRow(
              columns: [
                ResponsiveColumn(
                  flex: 7,
                  child: TableContainer(
                    title: 'Compliance Scorecard',
                    subtitle: 'Weakest areas listed first',
                    child: CustomDataTable(
                      emptyMessage: 'No compliance areas configured.',
                      columns: const [
                        DataColumnConfig(label: 'Area', size: ColumnSize.L),
                        DataColumnConfig(label: 'Category', size: ColumnSize.S),
                        DataColumnConfig(label: 'Owner', size: ColumnSize.M),
                        DataColumnConfig(label: 'Score', numeric: true),
                        DataColumnConfig(
                          label: 'Last Reviewed',
                          size: ColumnSize.M,
                        ),
                        DataColumnConfig(label: 'Status', size: ColumnSize.M),
                      ],
                      rows: [for (final area in areas) _areaRow(area)],
                    ),
                  ),
                ),
                ResponsiveColumn(
                  flex: 3,
                  child: AnalyticsCard(
                    title: 'Compliance by Category',
                    subtitle: 'Average score per obligation type',
                    child: RankedProgressList(
                      maxValue: 100,
                      entries: [
                        for (final entry in categoryScores)
                          RankedEntry(
                            label: entry.category,
                            value: entry.score,
                            displayValue: '${entry.score.toStringAsFixed(0)}%',
                            color: entry.score >= 85
                                ? AppColors.success
                                : (entry.score >= 70
                                      ? AppColors.accentGold
                                      : AppColors.danger),
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

  DataRow2 _areaRow(ComplianceArea area) {
    return DataRow2(
      cells: [
        DataCell(Text(area.name, overflow: TextOverflow.ellipsis)),
        DataCell(Text(area.category)),
        DataCell(Text(area.owner, overflow: TextOverflow.ellipsis)),
        DataCell(
          Text(
            '${area.scorePercent.toStringAsFixed(0)}%',
            style: TextStyle(
              color: _colorFor(area.state),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(Text(DateFormatter.shortDate(area.lastReviewed))),
        DataCell(
          StatusChip(
            status: _statusFor(area.state),
            customLabel: area.state.label,
          ),
        ),
      ],
    );
  }
}
