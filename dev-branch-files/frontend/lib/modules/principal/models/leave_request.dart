enum LeaveStatus { pending, approved, rejected }

/// A single leave/on-duty request submitted for the Principal's approval.
class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.requesterName,
    required this.requesterRole,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    required this.submittedAt,
  });

  final String id;
  final String requesterName;
  final String requesterRole;
  final String leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final LeaveStatus status;
  final DateTime submittedAt;

  int get dayCount => toDate.difference(fromDate).inDays + 1;

  LeaveRequest copyWith({LeaveStatus? status}) => LeaveRequest(
    id: id,
    requesterName: requesterName,
    requesterRole: requesterRole,
    leaveType: leaveType,
    fromDate: fromDate,
    toDate: toDate,
    reason: reason,
    status: status ?? this.status,
    submittedAt: submittedAt,
  );
}
