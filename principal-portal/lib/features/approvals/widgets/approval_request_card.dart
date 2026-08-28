import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../models/approval_request.dart';

/// One request in the queue: identity and detail on the left, decision
/// controls on the right, and the recorded remark once it is resolved.
///
/// The shared [ApprovalCard] handles the compact leave-request row; this
/// carries the extra weight these requests need — priority, value, the
/// request ID, and the decision note.
class ApprovalRequestCard extends StatelessWidget {
  const ApprovalRequestCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final ApprovalRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  /// Below this width the decision buttons no longer sit beside the
  /// detail block and move underneath it.
  static const double _stackBelow = 620;

  AppStatus get _decisionStatus {
    switch (request.decision) {
      case ApprovalDecision.approved:
        return AppStatus.approved;
      case ApprovalDecision.rejected:
        return AppStatus.rejected;
      case ApprovalDecision.pending:
        return AppStatus.pending;
    }
  }

  Color get _priorityColor {
    switch (request.priority) {
      case ApprovalPriority.urgent:
        return const Color(0xFFDC2626);
      case ApprovalPriority.high:
        return const Color(0xFFD97706);
      case ApprovalPriority.routine:
        return const Color(0xFF059669);
    }
  }

  Color get _priorityBgColor {
    switch (request.priority) {
      case ApprovalPriority.urgent:
        return const Color(0xFFFEF2F2);
      case ApprovalPriority.high:
        return const Color(0xFFFFFBEB);
      case ApprovalPriority.routine:
        return const Color(0xFFECFDF5);
    }
  }

  Color get _categoryColor {
    switch (request.category) {
      case ApprovalCategory.academic:
        return const Color(0xFF7C3AED);
      case ApprovalCategory.event:
        return const Color(0xFF0891B2);
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color get _categoryBgColor {
    switch (request.category) {
      case ApprovalCategory.academic:
        return const Color(0xFFF5F3FF);
      case ApprovalCategory.event:
        return const Color(0xFFECFEFF);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = request.decision == ApprovalDecision.pending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < _stackBelow;
          final actions = isPending
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RejectButton(onPressed: onReject),
                    const SizedBox(width: 8),
                    _ApproveButton(onPressed: onApprove),
                  ],
                )
              : StatusChip(status: _decisionStatus);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stacked) ...[
                _details(context),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: actions,
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _details(context)),
                    const SizedBox(width: 16),
                    actions,
                  ],
                ),
              if (request.remarks != null && request.remarks!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _RemarkNote(remarks: request.remarks!),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _details(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              request.id,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _priorityBgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                request.priority.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _priorityColor,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _categoryBgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                request.category.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _categoryColor,
                    ),
              ),
            ),
            if (request.category.isFinancial)
              Text(
                request.formattedAmount,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                    ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          request.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        const SizedBox(height: 3),
        Text(
          request.summary,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              AppIcons.faculty,
              size: 14,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${request.requesterName} · ${request.requesterRole} · '
                '${request.departmentCode} · '
                '${DateFormatter.shortDate(request.submittedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RemarkNote extends StatelessWidget {
  const _RemarkNote({required this.remarks});

  final String remarks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.edit, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              remarks,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF475569),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproveButton extends StatefulWidget {
  const _ApproveButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  State<_ApproveButton> createState() => _ApproveButtonState();
}

class _ApproveButtonState extends State<_ApproveButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isHovered
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: _isHovered ? 2 : 0,
            shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(80, 36),
          ),
          child: Text(
            'Approve',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class _RejectButton extends StatefulWidget {
  const _RejectButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  State<_RejectButton> createState() => _RejectButtonState();
}

class _RejectButtonState extends State<_RejectButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: OutlinedButton(
        onPressed: widget.onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              _isHovered ? const Color(0xFFFEF2F2) : Colors.white,
          foregroundColor:
              _isHovered ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
          side: BorderSide(
            color:
                _isHovered ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(80, 36),
        ),
        child: Text(
          'Reject',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
