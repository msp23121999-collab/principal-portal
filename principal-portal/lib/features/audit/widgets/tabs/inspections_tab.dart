import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/status_chip.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../models/audit.dart';
import '../../providers/audit_providers.dart';

AppStatus _statusFor(InspectionOutcome outcome) {
  switch (outcome) {
    case InspectionOutcome.cleared:
      return AppStatus.approved;
    case InspectionOutcome.observationsRaised:
      return AppStatus.pending;
    case InspectionOutcome.actionRequired:
      return AppStatus.rejected;
    case InspectionOutcome.scheduled:
      return AppStatus.info;
  }
}

/// External inspections and audits, with findings and closure position.
class InspectionsTab extends ConsumerWidget {
  const InspectionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return inspectionsAsync.when(
      loading: () => const CardSkeleton(height: 420),
      error: (err, st) => const ErrorState(),
      data: (reports) {
        final open = reports
            .where(
              (report) =>
                  report.closedOn == null &&
                  report.outcome != InspectionOutcome.scheduled,
            )
            .length;

        return TableContainer(
          title: 'Inspection Reports',
          subtitle: open == 0
              ? 'All inspection findings have been closed out'
              : '$open inspection(s) with findings still open',
          child: CustomDataTable(
            emptyMessage: 'No inspections recorded.',
            columns: const [
              DataColumnConfig(label: 'Inspection', size: ColumnSize.L),
              DataColumnConfig(label: 'Authority', size: ColumnSize.L),
              DataColumnConfig(label: 'Date', size: ColumnSize.M),
              DataColumnConfig(label: 'Inspector', size: ColumnSize.M),
              DataColumnConfig(label: 'Major', numeric: true),
              DataColumnConfig(label: 'Minor', numeric: true),
              DataColumnConfig(label: 'Observations', numeric: true),
              DataColumnConfig(label: 'Closed', size: ColumnSize.M),
              DataColumnConfig(label: 'Outcome', size: ColumnSize.M),
            ],
            rows: [for (final report in reports) _reportRow(report)],
          ),
        );
      },
    );
  }

  DataRow2 _reportRow(InspectionReport report) {
    return DataRow2(
      cells: [
        DataCell(Text(report.title, overflow: TextOverflow.ellipsis)),
        DataCell(Text(report.authority, overflow: TextOverflow.ellipsis)),
        DataCell(Text(DateFormatter.shortDate(report.inspectedOn))),
        DataCell(Text(report.inspector, overflow: TextOverflow.ellipsis)),
        DataCell(
          Text(
            '${report.majorFindings}',
            style: TextStyle(
              color: report.majorFindings > 0
                  ? AppColors.danger
                  : AppColors.primaryText,
              fontWeight: report.majorFindings > 0
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
        DataCell(Text('${report.minorFindings}')),
        DataCell(Text('${report.observations}')),
        DataCell(
          Text(
            report.closedOn == null
                ? '—'
                : DateFormatter.shortDate(report.closedOn!),
          ),
        ),
        DataCell(
          StatusChip(
            status: _statusFor(report.outcome),
            customLabel: report.outcome.label,
          ),
        ),
      ],
    );
  }
}
