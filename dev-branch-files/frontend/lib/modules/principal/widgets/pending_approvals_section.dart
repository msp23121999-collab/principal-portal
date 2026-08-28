import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_spacing.dart';
import './cards/analytics_card.dart';
import './cards/approval_card.dart';
import './feedback/empty_state.dart';
import '../providers/dashboard_providers.dart';

/// Pending leave/document approvals awaiting the Principal's decision.
/// Approve/Reject mutates [pendingApprovalsProvider] directly — the same
/// interaction pattern the Leave Approval screen uses for its full history.
class PendingApprovalsSection extends ConsumerWidget {
  const PendingApprovalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvals = ref.watch(pendingApprovalsProvider);
    final notifier = ref.read(pendingApprovalsProvider.notifier);

    return AnalyticsCard(
      title: 'Pending Approvals',
      subtitle: '${approvals.length} awaiting your decision',
      child: approvals.isEmpty
          ? const EmptyState(message: 'All caught up — no pending approvals.')
          : Column(
              children: [
                for (final item in approvals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ApprovalCard(
                      requesterName: item.requesterName,
                      requestType: item.requestType,
                      dateRange: item.dateRange,
                      onApprove: () {
                        notifier.resolve(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${item.requesterName}\'s request approved.',
                            ),
                          ),
                        );
                      },
                      onReject: () {
                        notifier.resolve(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${item.requesterName}\'s request rejected.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
