import 'package:flutter/material.dart';
import 'leave_history_table.dart';
import 'leave_summary_cards.dart';
import 'pending_requests_list.dart';

/// Faculty leave and on-duty requests — the Leave tab of the Approvals
/// page. Composed from the leave module's own widgets, which continue to
/// read from the leave providers.
class LeaveApprovalTab extends StatelessWidget {
  const LeaveApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LeaveSummaryCards(),
        SizedBox(height: 20),
        PendingRequestsList(),
        SizedBox(height: 20),
        LeaveHistoryTable(),
      ],
    );
  }
}
