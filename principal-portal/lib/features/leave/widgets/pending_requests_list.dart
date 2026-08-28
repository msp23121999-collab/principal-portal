import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/cards/approval_card.dart';
import '../../../core/widgets/feedback/confirmation_dialog.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../approvals/models/approval_request.dart';
import '../../approvals/providers/approvals_providers.dart';
import '../../approvals/widgets/decision_feedback.dart';
import '../models/leave_request.dart';
import '../providers/leave_providers.dart';

/// Pending leave requests awaiting the Principal's Approve/Reject decision.
class PendingRequestsList extends ConsumerWidget {
  const PendingRequestsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingLeaveRequestsProvider);

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
                      onApprove: () => _decide(
                        context,
                        ref,
                        request: r,
                        decision: ApprovalDecision.approved,
                        title: 'Approve Leave Request',
                        confirmLabel: 'Approve',
                      ),
                      onReject: () => _decide(
                        context,
                        ref,
                        request: r,
                        decision: ApprovalDecision.rejected,
                        title: 'Reject Leave Request',
                        confirmLabel: 'Reject',
                        isDestructive: true,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  /// Confirms, records, and reports what happened.
  ///
  /// Both buttons previously awaited the write with no `try` around it and no
  /// message afterwards. A refused update — the Faculty Portal's row, so a
  /// permission failure is entirely possible — threw out of the callback into
  /// nothing: the Principal saw the request sit unchanged with no explanation,
  /// and the same click could be repeated indefinitely.
  ///
  /// A leave decision is also two writes that cannot share a transaction (their
  /// status column, our audit trail), so success is not a yes/no answer either.
  /// [showDecisionResult] states which of the two happened.
  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required LeaveRequest request,
    required ApprovalDecision decision,
    required String title,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final verb = confirmLabel.toLowerCase();
    final confirmed = await ConfirmationDialog.show(
      context,
      title: title,
      message:
          '$confirmLabel ${request.requesterName}\'s '
          '${request.leaveType.toLowerCase()} request?',
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await ref
          .read(approvalDecisionProvider)
          .decideLeave(
            leaveId: request.id,
            decision: decision,
            previousStatus: request.status.name,
          );

      showDecisionResult(
        messenger,
        subject: '${request.requesterName}\'s leave request',
        action: '${verb}d',
        outcome: result,
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Could not $verb the leave request: $error'),
        ),
      );
    }
  }
}
