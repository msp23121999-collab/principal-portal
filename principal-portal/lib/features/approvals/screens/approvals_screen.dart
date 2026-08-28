import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/table_export.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/layout/active_tab.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../../leave/providers/leave_providers.dart';
import '../../leave/widgets/leave_approval_tab.dart';
import '../models/approval_request.dart';
import '../providers/approvals_providers.dart';
import '../providers/approvals_refresh_provider.dart';
import '../widgets/all_approvals_tab.dart';
import '../widgets/approval_category_tab.dart';
import '../widgets/approvals_refresh_button.dart';

/// Approvals — every major institutional request that needs the
/// Principal's decision, grouped by kind.
class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  /// The category behind each tab after the first two. "All" is tab 0, "Leave" is tab 1.
  static const List<ApprovalCategory> _categoryTabs = [
    ApprovalCategory.academic,
    ApprovalCategory.event,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabbedPage(
      title: 'Approvals',
      breadcrumbSegments: const ['Administration', 'Approvals'],
      subtitle:
          'Review and act on academic, event, and leave '
          'requests raised across the institution.',
      // Both entry points route through the same controller, so a pull during
      // a button refresh joins the running fetch rather than issuing a second.
      onRefresh: () => ref.read(approvalsRefreshProvider.notifier).run(),
      actions: [
        const ApprovalsRefreshButton(),
        PrimaryButton(
          label: 'Export Queue',
          icon: AppIcons.download,
          onPressed: () => _export(context, ref),
        ),
      ],
      onTabChanged: (index) =>
          ref.read(activeTabProvider(TabbedPageKeys.approvals).notifier).state =
              index,
      tabs: const [
        PageTab(label: 'All', content: AllApprovalsTab()),
        PageTab(label: 'Leave', content: LeaveApprovalTab()),
        PageTab(
          label: 'Academic',
          content: ApprovalCategoryTab(category: ApprovalCategory.academic),
        ),
        PageTab(
          label: 'Event & Activity',
          content: ApprovalCategoryTab(category: ApprovalCategory.event),
        ),
      ],
    );
  }

  void _export(BuildContext context, WidgetRef ref) {
    final tab = ref.read(activeTabProvider(TabbedPageKeys.approvals));

    if (tab == 0) {
      // For "All" tab, we just show a message or export both.
      // Easiest is to alert the user to select a specific tab for export.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a specific category tab to export.'),
        ),
      );
      return;
    }

    if (tab == 1) {
      final leave = ref.read(leaveRequestsProvider);
      TableExport.run(
        context,
        fileName: 'leave_requests',
        noun: 'request',
        headers: const [
          'Request ID',
          'Requester',
          'Role',
          'Leave Type',
          'From',
          'To',
          'Days',
          'Reason',
          'Submitted',
          'Status',
        ],
        rows: [
          for (final r in leave)
            [
              r.id,
              r.requesterName,
              r.requesterRole,
              r.leaveType,
              DateFormatter.shortDate(r.fromDate),
              DateFormatter.shortDate(r.toDate),
              r.toDate.difference(r.fromDate).inDays + 1,
              r.reason,
              DateFormatter.shortDate(r.submittedAt),
              r.status.name,
            ],
        ],
      );
      return;
    }

    final category = _categoryTabs[tab - 2];
    final requests =
        ref.read(requestsByCategoryProvider(category)).valueOrNull ?? const [];

    TableExport.run(
      context,
      fileName: 'approvals_${category.name}',
      noun: 'request',
      headers: const [
        'Request ID',
        'Title',
        'Category',
        'Requester',
        'Role',
        'Department',
        'Submitted',
        'Priority',
        'Decision',
        'Remarks',
      ],
      rows: [
        for (final r in requests)
          [
            r.id,
            r.title,
            r.category.label,
            r.requesterName,
            r.requesterRole,
            r.departmentCode,
            DateFormatter.shortDate(r.submittedAt),
            r.priority.label,
            r.decision.label,
            r.remarks ?? '',
          ],
      ],
    );
  }
}
