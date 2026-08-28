import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/report_run.dart';
import '../providers/reports_providers.dart';

/// The record of reports the Principal has asked for.
///
/// This tab used to describe a background job queue: a **Size** column, a
/// **Status** of Queued / Generating / Ready / Failed, cards counting "Ready to
/// Download" and "In Progress", and a download button on the ready ones. There
/// was no queue, no generator and no file — `report_runs` only ever recorded
/// that somebody pressed Generate.
///
/// Reports are now written the moment they are requested, straight to the
/// browser. So this is a **history**, and it says so: who asked for what, and
/// when. Nothing here claims a file is waiting somewhere.
class GeneratedReportsTab extends ConsumerWidget {
  const GeneratedReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(reportRunsProvider)
        .when(
          loading: () => ResponsiveGrid(
            children: List.generate(3, (_) => const CardSkeleton()),
          ),
          error: (err, st) => const ErrorState(),
          data: (runs) => _buildBody(context, runs),
        );
  }

  Widget _buildBody(BuildContext context, List<ReportRun> runs) {
    final now = DateTime.now();
    final thisWeek = runs
        .where((r) => now.difference(r.requestedAt).inDays <= 7)
        .length;
    final modules = {for (final r in runs) r.module}.length;
    final latest = runs.isEmpty
        ? null
        : runs.map((r) => r.requestedAt).reduce((a, b) => a.isAfter(b) ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Reports Requested',
              value: '${runs.length}',
              icon: AppIcons.reports,
              iconColor: AppChartPalette.at(0),
              iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
              subtitle: 'All time',
            ),
            StatisticsCard(
              label: 'This Week',
              value: '$thisWeek',
              icon: AppIcons.calendar,
              iconColor: AppChartPalette.at(1),
              iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
            ),
            StatisticsCard(
              label: 'Modules Covered',
              value: '$modules',
              icon: AppIcons.academic,
              iconColor: AppChartPalette.at(2),
              iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
              subtitle: 'Of ${reportModules.length} available',
            ),
            StatisticsCard(
              label: 'Most Recent',
              // A dash, not a date, when nothing has been requested.
              value: latest == null ? '—' : DateFormatter.relative(latest),
              icon: AppIcons.clock,
              iconColor: AppChartPalette.at(3),
              iconBackground: AppChartPalette.at(3).withValues(alpha: 0.10),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TableContainer(
          title: 'Report History',
          subtitle: 'Most recent request first — each was downloaded when made',
          child: CustomDataTable(
            emptyMessage: 'No reports have been requested yet.',
            columns: const [
              DataColumnConfig(label: 'Reference', size: ColumnSize.M),
              DataColumnConfig(label: 'Report', size: ColumnSize.L),
              DataColumnConfig(label: 'Module', size: ColumnSize.M),
              DataColumnConfig(label: 'Period', size: ColumnSize.M),
              DataColumnConfig(label: 'Format', size: ColumnSize.S),
              DataColumnConfig(label: 'Requested By', size: ColumnSize.M),
              DataColumnConfig(label: 'Requested', size: ColumnSize.M),
            ],
            rows: [for (final run in runs) _runRow(run)],
          ),
        ),
      ],
    );
  }

  DataRow2 _runRow(ReportRun run) {
    return DataRow2(
      cells: [
        DataCell(Text(run.id)),
        DataCell(Text(run.title, overflow: TextOverflow.ellipsis)),
        DataCell(
          Text(reportModuleLabel(run.module), overflow: TextOverflow.ellipsis),
        ),
        DataCell(Text(run.period.label, overflow: TextOverflow.ellipsis)),
        DataCell(Text(run.format.label)),
        DataCell(Text(run.requestedBy, overflow: TextOverflow.ellipsis)),
        DataCell(Text(DateFormatter.relative(run.requestedAt))),
      ],
    );
  }
}
