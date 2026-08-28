import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cards/approval_card.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../approvals/models/approval_request.dart';
import '../../approvals/providers/approvals_providers.dart';
import '../../approvals/widgets/decision_feedback.dart';
import 'dashboard_card.dart';

/// Approval rows the dashboard panel shows before it is cut off.
///
/// Fewer than [kDashboardActivityRows] because an approval carries a name, a
/// summary, a reference and two buttons, so each one is roughly twice the
/// height of an activity line. Matching the counts would not match the panels.
const int kDashboardApprovalRows = 3;

/// Activity rows shown beside them.
const int kDashboardActivityRows = 5;

/// Shared height floor for the pair.
///
/// Recent Activities and Pending Approvals sit in one row. Their content is
/// different shapes and will never end at the same point on its own, so the
/// cards are given a floor and the shorter one carries the slack inside its
/// own border. Two cards of different heights read as broken; one card with a
/// little room at the bottom does not.
const double kDashboardPairMinHeight = 470;

/// Requests still awaiting a decision.
///
/// Reads the Approvals module's queue directly rather than keeping its own
/// copy, so deciding here and deciding on the Approvals screen are the same
/// action against the same data. Previously this removed the item from a local
/// list, which looked like a decision and recorded nothing.
class PendingApprovalsSection extends ConsumerWidget {
  const PendingApprovalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRequests = ref.watch(approvalRequestsProvider);

    return asyncRequests.when(
      loading: () => const DashboardCard(
        title: 'Pending Approvals',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.warning,
        child: SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, st) => DashboardCard(
        title: 'Pending Approvals',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.warning,
        child: ErrorState(error: err),
      ),
      data: (_) {
        final pending = ref.watch(pendingApprovalsProvider);

        return DashboardCard(
          title: 'Pending Approvals',
          icon: Icons.check_circle_outline,
          iconColor: AppColors.warning,
          subtitle: pending.length > kDashboardApprovalRows
              ? '${pending.length} awaiting your decision · showing the first $kDashboardApprovalRows'
              : '${pending.length} awaiting your decision',
          child: pending.isEmpty
              ? const EmptyState(
                  message: 'All caught up — no pending approvals.',
                )
              : Column(
                  children: [
                    for (final request in pending.take(kDashboardApprovalRows))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ApprovalCard(
                          requesterName: request.requesterName,
                          requestType: request.category.label,
                          dateRange: request.title,
                          subtitle: request.summary,
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
        );
      },
    );
  }

  /// Records the decision and reports whether it actually saved.
  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    ApprovalRequest request,
    ApprovalDecision decision,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await ref
          .read(approvalDecisionProvider)
          .decide(
            request: request,
            decision: decision,
            remarks: 'Decided from the dashboard.',
          );

      showDecisionResult(
        messenger,
        subject: request.title,
        action: decision.label.toLowerCase(),
        outcome: result,
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save the decision: $error')),
      );
    }
  }
}
