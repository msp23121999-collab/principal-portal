import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_spacing.dart';
import '../utils/date_formatter.dart';
import './cards/analytics_card.dart';
import './cards/approval_card.dart';
import './feedback/confirmation_dialog.dart';
import './feedback/empty_state.dart';
import '../models/leave_request.dart';
import '../providers/leave_providers.dart';

/// Pending leave requests awaiting the Principal's Approve/Reject decision.
class PendingRequestsList extends ConsumerWidget {
  const PendingRequestsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingLeaveRequestsProvider);
    final notifier = ref.read(leaveRequestsProvider.notifier);

    return AnalyticsCard(
      title: 'Pending Requests',
      subtitle: '${pending.length} awaiting decision',
      child: pending.isEmpty
          ? const EmptyState(
              message: 'All caught up — no pending leave requests.',
            )
          : Column(
              children: [
                for (final r in pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ApprovalCard(
                      requesterName: r.requesterName,
                      requestType: '${r.leaveType} · ${r.requesterRole}',
                      dateRange:
                          '${DateFormatter.shortDate(r.fromDate)} – ${DateFormatter.shortDate(r.toDate)} (${r.dayCount} day${r.dayCount > 1 ? 's' : ''})',
                      subtitle: r.reason,
                      onApprove: () async {
                        final confirmed = await ConfirmationDialog.show(
                          context,
                          title: 'Approve Leave Request',
                          message:
                              'Approve ${r.requesterName}\'s ${r.leaveType.toLowerCase()} request?',
                          confirmLabel: 'Approve',
                        );
                        if (confirmed == true) {
                          notifier.setStatus(r.id, LeaveStatus.approved);
                        }
                      },
                      onReject: () async {
                        final confirmed = await ConfirmationDialog.show(
                          context,
                          title: 'Reject Leave Request',
                          message:
                              'Reject ${r.requesterName}\'s ${r.leaveType.toLowerCase()} request?',
                          confirmLabel: 'Reject',
                          isDestructive: true,
                        );
                        if (confirmed == true) {
                          notifier.setStatus(r.id, LeaveStatus.rejected);
                        }
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
