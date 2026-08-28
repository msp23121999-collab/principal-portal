/// A single pending-approval row shown on the Dashboard, linking through to
/// the Leave Approval screen for the full workflow.
class PendingApprovalItem {
  const PendingApprovalItem({
    required this.id,
    required this.requesterName,
    required this.requestType,
    required this.dateRange,
  });

  final String id;
  final String requesterName;
  final String requestType;
  final String dateRange;
}
