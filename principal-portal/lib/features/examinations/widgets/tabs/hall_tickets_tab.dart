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
import '../../models/examination.dart';
import '../../providers/examination_providers.dart';

/// Hall-ticket issue position: who has been cleared to sit the exams and
/// who is still held back.
class HallTicketsTab extends ConsumerWidget {
  const HallTicketsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(hallTicketStatusProvider);

    return statusAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (rows) {
        final eligible = rows.fold(0, (sum, r) => sum + r.eligible);
        final issued = rows.fold(0, (sum, r) => sum + r.issued);
        final withheld = rows.fold(0, (sum, r) => sum + r.withheld);
        final pending = rows.fold(0, (sum, r) => sum + r.pending);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              children: [
                StatisticsCard(
                  label: 'Eligible Candidates',
                  value: '$eligible',
                  icon: AppIcons.students,
                  iconColor: AppChartPalette.at(0),
                  iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Tickets Issued',
                  value: '$issued',
                  icon: AppIcons.check,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successTint,
                  subtitle:
                      '${(issued / eligible * 100).toStringAsFixed(1)}% of eligible',
                ),
                StatisticsCard(
                  label: 'Awaiting Issue',
                  value: '$pending',
                  icon: AppIcons.clock,
                  iconColor: AppColors.warning,
                  iconBackground: AppColors.warningTint,
                ),
                StatisticsCard(
                  label: 'Withheld',
                  value: '$withheld',
                  icon: AppIcons.warning,
                  iconColor: AppColors.danger,
                  iconBackground: AppColors.dangerTint,
                  subtitle: 'Attendance shortfall or dues',
                ),
              ],
            ),
            const SizedBox(height: 20),
            ResponsiveRow(
              columns: [
                ResponsiveColumn(
                  flex: 7,
                  child: TableContainer(
                    title: 'Hall Ticket Status by Department',
                    subtitle: 'Issue position for the current cycle',
                    child: CustomDataTable(
                      emptyMessage: 'No candidates registered yet.',
                      columns: const [
                        DataColumnConfig(
                          label: 'Department',
                          size: ColumnSize.L,
                        ),
                        DataColumnConfig(label: 'Eligible', numeric: true),
                        DataColumnConfig(label: 'Issued', numeric: true),
                        DataColumnConfig(label: 'Pending', numeric: true),
                        DataColumnConfig(label: 'Withheld', numeric: true),
                        DataColumnConfig(label: 'Issued %', numeric: true),
                        DataColumnConfig(label: 'Status', size: ColumnSize.S),
                      ],
                      rows: [for (final row in rows) _statusRow(row)],
                    ),
                  ),
                ),
                ResponsiveColumn(
                  flex: 3,
                  child: AnalyticsCard(
                    title: 'Issue Progress',
                    subtitle: 'Share of eligible candidates cleared',
                    child: RankedProgressList(
                      maxValue: 100,
                      entries: [
                        for (final row in rows)
                          RankedEntry(
                            label: row.departmentCode,
                            value: row.issuedPercent,
                            displayValue:
                                '${row.issuedPercent.toStringAsFixed(0)}%',
                            color: row.issuedPercent >= 95
                                ? AppColors.success
                                : AppColors.warning,
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

  DataRow2 _statusRow(HallTicketStatus row) {
    final cleared = row.pending == 0;

    return DataRow2(
      cells: [
        DataCell(Text(row.departmentName, overflow: TextOverflow.ellipsis)),
        DataCell(Text('${row.eligible}')),
        DataCell(Text('${row.issued}')),
        DataCell(Text('${row.pending}')),
        DataCell(Text('${row.withheld}')),
        DataCell(Text('${row.issuedPercent.toStringAsFixed(1)}%')),
        DataCell(
          StatusChip(
            status: cleared ? AppStatus.approved : AppStatus.pending,
            customLabel: cleared ? 'Complete' : 'In Progress',
          ),
        ),
      ],
    );
  }
}
