import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cards/chart_container.dart';
import '../../../../core/widgets/charts/grouped_bar_chart_widget.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/status_chip.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../models/examination.dart';
import '../../providers/examination_providers.dart';

/// Continuous internal assessment progress by department: how much of
/// each CIA cycle is done, and how far mark entry has got.
class CiaProgressTab extends ConsumerWidget {
  const CiaProgressTab({super.key});

  /// Mark entry is expected to be essentially complete by this point.
  static const double _entryTarget = 90;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(ciaProgressProvider);

    return progressAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartContainer(
            title: 'CIA Completion by Department',
            subtitle: 'Percentage of each assessment cycle conducted',
            height: 260,
            legend: const [
              ChartLegendItem(label: 'CIA 1', color: AppColors.primaryBlue),
              ChartLegendItem(label: 'CIA 2', color: AppColors.success),
              ChartLegendItem(label: 'CIA 3', color: AppColors.accentGold),
            ],
            chart: GroupedBarChartWidget(
              maxY: 100,
              showValues: false,
              seriesColors: AppChartPalette.take(3),
              data: [
                for (final row in rows)
                  GroupedBarDatum(
                    label: row.departmentCode,
                    values: [row.cia1Percent, row.cia2Percent, row.cia3Percent],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TableContainer(
            title: 'Mark Entry Status',
            subtitle:
                'Internal marks recorded against expected entries, target '
                '${_entryTarget.round()}%',
            child: CustomDataTable(
              emptyMessage: 'No assessment data recorded yet.',
              columns: const [
                DataColumnConfig(label: 'Department', size: ColumnSize.L),
                DataColumnConfig(label: 'CIA 1', numeric: true),
                DataColumnConfig(label: 'CIA 2', numeric: true),
                DataColumnConfig(label: 'CIA 3', numeric: true),
                DataColumnConfig(label: 'Marks Entered', numeric: true),
                DataColumnConfig(label: 'Entry %', numeric: true),
                DataColumnConfig(label: 'Status', size: ColumnSize.S),
              ],
              rows: [for (final row in rows) _progressRow(row)],
            ),
          ),
        ],
      ),
    );
  }

  DataRow2 _progressRow(CiaProgress row) {
    final onTrack = row.entryPercent >= _entryTarget;

    return DataRow2(
      cells: [
        DataCell(Text(row.departmentName, overflow: TextOverflow.ellipsis)),
        DataCell(Text('${row.cia1Percent.toStringAsFixed(0)}%')),
        DataCell(Text('${row.cia2Percent.toStringAsFixed(0)}%')),
        DataCell(Text('${row.cia3Percent.toStringAsFixed(0)}%')),
        DataCell(Text('${row.marksEntered} / ${row.marksExpected}')),
        DataCell(Text('${row.entryPercent.toStringAsFixed(1)}%')),
        DataCell(
          StatusChip(
            status: onTrack ? AppStatus.approved : AppStatus.pending,
            customLabel: onTrack ? 'On Track' : 'Follow Up',
          ),
        ),
      ],
    );
  }
}
