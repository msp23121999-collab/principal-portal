import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../models/leave_request.dart';
import '../providers/leave_providers.dart';

AppStatus _statusFor(LeaveStatus status) {
  switch (status) {
    case LeaveStatus.approved:
      return AppStatus.approved;
    case LeaveStatus.rejected:
      return AppStatus.rejected;
    case LeaveStatus.pending:
      return AppStatus.pending;
  }
}

/// Resolved (approved/rejected) leave request history, most recent first.
class LeaveHistoryTable extends ConsumerWidget {
  const LeaveHistoryTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(leaveHistoryProvider);

    return TableContainer(
      title: 'Request History',
      child: CustomDataTable(
        emptyMessage: 'No resolved leave requests yet.',
        columns: const [
          DataColumnConfig(label: 'Requester', size: ColumnSize.L),
          DataColumnConfig(label: 'Leave Type', size: ColumnSize.M),
          DataColumnConfig(label: 'Dates', size: ColumnSize.M),
          DataColumnConfig(label: 'Submitted', size: ColumnSize.S),
          DataColumnConfig(label: 'Status', size: ColumnSize.S),
        ],
        rows: [
          for (final r in history)
            DataRow2(
              cells: [
                DataCell(
                  Text(
                    r.requesterName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                DataCell(Text(r.leaveType)),
                DataCell(
                  Text(
                    '${DateFormatter.shortDate(r.fromDate)} – ${DateFormatter.shortDate(r.toDate)}',
                  ),
                ),
                DataCell(Text(DateFormatter.shortDate(r.submittedAt))),
                DataCell(StatusChip(status: _statusFor(r.status))),
              ],
            ),
        ],
      ),
    );
  }
}
