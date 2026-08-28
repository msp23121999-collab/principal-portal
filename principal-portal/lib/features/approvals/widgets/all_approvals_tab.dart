import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../leave/widgets/pending_requests_list.dart';
import '../models/approval_request.dart';
import '../providers/approvals_providers.dart';
import 'approval_decision_dialog.dart';
import 'approval_request_card.dart';
import 'decision_feedback.dart';

/// The 'All' tab shows all pending Principal-relevant requests across
/// leave, academic, and event categories.
class AllApprovalsTab extends ConsumerWidget {
  const AllApprovalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRequests =
        ref.watch(approvalRequestsProvider).valueOrNull ?? const [];

    // Only Principal-relevant categories, and only pending ones.
    final pendingInstitutional = allRequests
        .where(
          (r) =>
              r.decision == ApprovalDecision.pending &&
              (r.category == ApprovalCategory.academic ||
                  r.category == ApprovalCategory.event),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PendingRequestsList(),
        const SizedBox(height: 18),
        AnalyticsCard(
          title: 'Pending Academic & Event Requests',
          subtitle: '${pendingInstitutional.length} awaiting decision',
          child: pendingInstitutional.isEmpty
              ? const EmptyState(
                  message: 'No pending academic or event requests.',
                )
              : Column(
                  children: [
                    for (final request in pendingInstitutional)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ApprovalRequestCard(
                          request: request,
                          onApprove: () => _decide(
                            context,
                            ref,
                            request,
                            ApprovalDecision.approved,
                          ),
                          onReject: () => _decide(
                            context,
                            ref,
                            request,
                            ApprovalDecision.rejected,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    ApprovalRequest request,
    ApprovalDecision decision,
  ) async {
    final outcome = await ApprovalDecisionDialog.show(
      context,
      request: request,
      decision: decision,
    );
    if (outcome == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await ref
          .read(approvalDecisionProvider)
          .decide(
            request: request,
            decision: outcome.decision,
            remarks: outcome.remarks.isEmpty
                ? 'No remarks recorded.'
                : outcome.remarks,
          );

      showDecisionResult(
        messenger,
        subject: request.title,
        action: outcome.decision.label.toLowerCase(),
        outcome: result,
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Could not save the decision: $error'),
        ),
      );
    }
  }
}
