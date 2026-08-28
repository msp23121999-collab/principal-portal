import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/approval_request.dart';
import '../providers/approvals_providers.dart';
import 'approval_decision_dialog.dart';
import 'approval_request_card.dart';
import 'decision_feedback.dart';

/// The queue for one request category: a short summary strip, then every
/// request with pending items first.
class ApprovalCategoryTab extends ConsumerWidget {
  const ApprovalCategoryTab({super.key, required this.category});

  final ApprovalCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(requestsByCategoryProvider(category))
        .when(
          loading: () => ResponsiveGrid(
            children: List.generate(3, (_) => const CardSkeleton()),
          ),
          error: (err, st) => const ErrorState(),
          data: (requests) => _buildQueue(context, ref, requests),
        );
  }

  Widget _buildQueue(
    BuildContext context,
    WidgetRef ref,
    List<ApprovalRequest> requests,
  ) {
    final pending = requests
        .where((r) => r.decision == ApprovalDecision.pending)
        .toList();
    final approved = requests
        .where((r) => r.decision == ApprovalDecision.approved)
        .length;
    final rejected = requests
        .where((r) => r.decision == ApprovalDecision.rejected)
        .length;
    final pendingValue = pending.fold(0.0, (sum, r) => sum + (r.amount ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Awaiting Decision',
              value: '${pending.length}',
              icon: AppIcons.clock,
              iconColor: AppColors.warning,
              iconBackground: AppColors.warningTint,
            ),
            StatisticsCard(
              label: 'Approved',
              value: '$approved',
              icon: AppIcons.approve,
              iconColor: AppColors.success,
              iconBackground: AppColors.successTint,
            ),
            StatisticsCard(
              label: 'Rejected',
              value: '$rejected',
              icon: AppIcons.reject,
              iconColor: AppColors.danger,
              iconBackground: AppColors.dangerTint,
            ),
            if (category.isFinancial)
              StatisticsCard(
                label: 'Value Awaiting Decision',
                value: pendingValue == 0
                    ? '—'
                    : NumberFormatter.rupees(pendingValue),
                icon: AppIcons.currency,
                iconColor: AppChartPalette.at(3),
                iconBackground: AppChartPalette.at(3).withValues(alpha: 0.10),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (requests.isEmpty)
          const EmptyState(
            message: 'No requests have been raised in this category.',
          )
        else
          for (final request in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ApprovalRequestCard(
                request: request,
                onApprove: () =>
                    _decide(context, ref, request, ApprovalDecision.approved),
                onReject: () =>
                    _decide(context, ref, request, ApprovalDecision.rejected),
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

    // The write can fail — no connection, a rejected policy. Reporting success
    // regardless would leave the Principal believing a decision was recorded
    // when it was not.
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
