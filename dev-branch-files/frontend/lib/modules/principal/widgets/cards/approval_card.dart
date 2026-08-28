import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

/// A pending-approval row (leave request, document, event) with
/// requester/type/dates and Approve/Reject actions — used on the Dashboard
/// pending-approvals section and the Leave Approval screen.
class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    super.key,
    required this.requesterName,
    required this.requestType,
    required this.dateRange,
    this.subtitle,
    this.onApprove,
    this.onReject,
  });

  final String requesterName;
  final String requestType;
  final String dateRange;
  final String? subtitle;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warningTint,
              borderRadius: AppRadius.smRadius,
            ),
            child: const Icon(
              AppIcons.leave,
              size: 18,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requesterName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '$requestType${subtitle != null ? ' · $subtitle' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(dateRange, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SecondaryButton(label: 'Reject', onPressed: onReject),
          const SizedBox(width: AppSpacing.sm),
          PrimaryButton(label: 'Approve', onPressed: onApprove),
        ],
      ),
    );
  }
}
