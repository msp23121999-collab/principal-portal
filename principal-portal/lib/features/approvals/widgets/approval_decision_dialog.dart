import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../models/approval_request.dart';

/// What the Principal chose, and the note recorded with it.
class ApprovalOutcome {
  const ApprovalOutcome({required this.decision, required this.remarks});

  final ApprovalDecision decision;
  final String remarks;
}

/// Full request detail with a remarks box — the approve/reject step for
/// anything weightier than a leave request, where the reasoning matters
/// as much as the decision.
class ApprovalDecisionDialog extends StatefulWidget {
  const ApprovalDecisionDialog({
    super.key,
    required this.request,
    required this.decision,
  });

  final ApprovalRequest request;

  /// Which button opened the dialog; the confirm action commits this.
  final ApprovalDecision decision;

  static Future<ApprovalOutcome?> show(
    BuildContext context, {
    required ApprovalRequest request,
    required ApprovalDecision decision,
  }) {
    return showDialog<ApprovalOutcome>(
      context: context,
      builder: (_) =>
          ApprovalDecisionDialog(request: request, decision: decision),
    );
  }

  @override
  State<ApprovalDecisionDialog> createState() => _ApprovalDecisionDialogState();
}

class _ApprovalDecisionDialogState extends State<ApprovalDecisionDialog> {
  final TextEditingController _remarks = TextEditingController();

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  bool get _isRejection => widget.decision == ApprovalDecision.rejected;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return AlertDialog(
      title: Text(
        _isRejection ? 'Reject Request' : 'Approve Request',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                request.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                request.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadius.smRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Request ID', value: request.id),
                    _DetailRow(
                      label: 'Raised by',
                      value:
                          '${request.requesterName} · ${request.requesterRole}',
                    ),
                    _DetailRow(
                      label: 'Department',
                      value: request.departmentCode,
                    ),
                    _DetailRow(
                      label: 'Submitted',
                      value: DateFormatter.shortDate(request.submittedAt),
                    ),
                    _DetailRow(
                      label: 'Priority',
                      value: request.priority.label,
                    ),
                    if (request.category.isFinancial)
                      _DetailRow(
                        label: 'Amount',
                        value: request.formattedAmount,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Remarks', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _remarks,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _isRejection
                      ? 'Reason for rejection (recorded against the request)'
                      : 'Any conditions or notes for the requester',
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        SecondaryButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.sm),
        PrimaryButton(
          label: _isRejection ? 'Confirm Rejection' : 'Confirm Approval',
          onPressed: () => Navigator.of(context).pop(
            ApprovalOutcome(
              decision: widget.decision,
              remarks: _remarks.text.trim(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}
