import 'package:flutter/material.dart';
import '../widgets/layout/content_scaffold.dart';
import '../widgets/layout/page_header.dart';
import '../widgets/leave_history_table.dart';
import '../widgets/leave_summary_cards.dart';
import '../widgets/pending_requests_list.dart';

class LeaveApprovalScreen extends StatelessWidget {
  const LeaveApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentScaffold(
      children: [
        PageHeader(
          title: 'Leave Approval',
          breadcrumbSegments: ['Administration', 'Leave Approval'],
          subtitle: 'Review and act on faculty leave requests',
        ),
        LeaveSummaryCards(),
        PendingRequestsList(),
        LeaveHistoryTable(),
      ],
    );
  }
}
