import 'package:flutter/material.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_motion.dart';

/// A pending-approval row (leave request, document, event) with
/// requester/type/dates and Approve/Reject actions — used on the Dashboard
/// pending-approvals section and the Leave Approval screen.
class ApprovalCard extends StatefulWidget {
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

  static const double _stackActionsBelow = 440;

  @override
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppMotion.adaptive(context, AppMotion.normal),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFFD97706).withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: AppElevation.forHoverAccent(
            isHovered: _isHovered,
            accentColor: const Color(0xFFD97706),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < ApprovalCard._stackActionsBelow;
            final details = Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    AppIcons.leave,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: _details(context)),
              ],
            );

            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RejectButton(onPressed: widget.onReject),
                const SizedBox(width: 8),
                _ApproveButton(onPressed: widget.onApprove),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: actions,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 16),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _details(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.requesterName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${widget.requestType}${widget.subtitle != null ? ' · ${widget.subtitle}' : ''}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        const SizedBox(height: 3),
        Text(
          widget.dateRange,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
