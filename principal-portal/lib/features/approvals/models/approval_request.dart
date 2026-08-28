import '../../../core/utils/number_formatter.dart';

/// The kinds of institutional request that reach the Principal, beyond
/// leave — which the leave module already owns end to end.
enum ApprovalCategory { budget, purchase, event, academic }

extension ApprovalCategoryX on ApprovalCategory {
  String get label {
    switch (this) {
      case ApprovalCategory.budget:
        return 'Budget';
      case ApprovalCategory.purchase:
        return 'Purchase';
      case ApprovalCategory.event:
        return 'Event & Activity';
      case ApprovalCategory.academic:
        return 'Academic';
    }
  }

  /// Whether requests of this kind carry a monetary value.
  bool get isFinancial =>
      this == ApprovalCategory.budget || this == ApprovalCategory.purchase;
}

enum ApprovalDecision { pending, approved, rejected }

extension ApprovalDecisionX on ApprovalDecision {
  String get label {
    switch (this) {
      case ApprovalDecision.pending:
        return 'Pending';
      case ApprovalDecision.approved:
        return 'Approved';
      case ApprovalDecision.rejected:
        return 'Rejected';
    }
  }
}

enum ApprovalPriority { routine, high, urgent }

extension ApprovalPriorityX on ApprovalPriority {
  String get label {
    switch (this) {
      case ApprovalPriority.routine:
        return 'Routine';
      case ApprovalPriority.high:
        return 'High';
      case ApprovalPriority.urgent:
        return 'Urgent';
    }
  }
}

/// A single institutional request awaiting the Principal's decision.
class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.category,
    required this.title,
    required this.requesterName,
    required this.requesterRole,
    required this.departmentCode,
    required this.submittedAt,
    required this.summary,
    required this.priority,
    required this.decision,
    this.amount,
    this.remarks,
  });

  final String id;
  final ApprovalCategory category;
  final String title;
  final String requesterName;
  final String requesterRole;
  final String departmentCode;
  final DateTime submittedAt;
  final String summary;
  final ApprovalPriority priority;
  final ApprovalDecision decision;

  /// Rupee value, null for requests with no financial component.
  final double? amount;

  /// The Principal's note recorded with the decision.
  final String? remarks;

  ApprovalRequest copyWith({ApprovalDecision? decision, String? remarks}) {
    return ApprovalRequest(
      id: id,
      category: category,
      title: title,
      requesterName: requesterName,
      requesterRole: requesterRole,
      departmentCode: departmentCode,
      submittedAt: submittedAt,
      summary: summary,
      priority: priority,
      decision: decision ?? this.decision,
      amount: amount,
      remarks: remarks ?? this.remarks,
    );
  }

  /// "₹2.45 L" / "₹1.20 Cr", or an em dash where there is no value.
  String get formattedAmount =>
      amount == null ? '—' : NumberFormatter.rupees(amount!);
}
