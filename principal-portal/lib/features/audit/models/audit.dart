/// The kinds of action recorded in the audit trail.
enum AuditAction {
  created,
  updated,
  deleted,
  approved,
  rejected,
  published,
  exported,
  signedIn,
}

extension AuditActionX on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.created:
        return 'Created';
      case AuditAction.updated:
        return 'Updated';
      case AuditAction.deleted:
        return 'Deleted';
      case AuditAction.approved:
        return 'Approved';
      case AuditAction.rejected:
        return 'Rejected';
      case AuditAction.published:
        return 'Published';
      case AuditAction.exported:
        return 'Exported';
      case AuditAction.signedIn:
        return 'Signed In';
    }
  }
}

/// How much attention an audit entry warrants on review.
enum AuditSeverity { routine, notable, critical }

extension AuditSeverityX on AuditSeverity {
  String get label {
    switch (this) {
      case AuditSeverity.routine:
        return 'Routine';
      case AuditSeverity.notable:
        return 'Notable';
      case AuditSeverity.critical:
        return 'Critical';
    }
  }
}

/// A single recorded action in the audit trail.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.actor,
    required this.actorRole,
    required this.action,
    required this.module,
    required this.description,
    required this.timestamp,
    required this.ipAddress,
    required this.severity,
  });

  final String id;
  final String actor;
  final String actorRole;
  final AuditAction action;

  /// Portal area the action took place in.
  final String module;

  final String description;
  final DateTime timestamp;
  final String ipAddress;
  final AuditSeverity severity;
}

/// Where a compliance area stands against its obligations.
enum ComplianceState { compliant, partial, atRisk, nonCompliant }

extension ComplianceStateX on ComplianceState {
  String get label {
    switch (this) {
      case ComplianceState.compliant:
        return 'Compliant';
      case ComplianceState.partial:
        return 'Partial';
      case ComplianceState.atRisk:
        return 'At Risk';
      case ComplianceState.nonCompliant:
        return 'Non-Compliant';
    }
  }
}

/// One area of institutional compliance and its current score.
class ComplianceArea {
  const ComplianceArea({
    required this.name,
    required this.category,
    required this.owner,
    required this.score,
    required this.maximumScore,
    required this.lastReviewed,
    required this.state,
  });

  final String name;

  /// Statutory, Academic, Financial, Safety, or Data.
  final String category;

  final String owner;
  final double score;
  final double maximumScore;
  final DateTime lastReviewed;
  final ComplianceState state;

  double get scorePercent => maximumScore == 0 ? 0 : score / maximumScore * 100;
}

/// Outcome of an external inspection.
enum InspectionOutcome {
  cleared,
  observationsRaised,
  actionRequired,
  scheduled,
}

extension InspectionOutcomeX on InspectionOutcome {
  String get label {
    switch (this) {
      case InspectionOutcome.cleared:
        return 'Cleared';
      case InspectionOutcome.observationsRaised:
        return 'Observations Raised';
      case InspectionOutcome.actionRequired:
        return 'Action Required';
      case InspectionOutcome.scheduled:
        return 'Scheduled';
    }
  }
}

/// A visit or audit carried out by an external body.
class InspectionReport {
  const InspectionReport({
    required this.title,
    required this.authority,
    required this.inspectedOn,
    required this.inspector,
    required this.majorFindings,
    required this.minorFindings,
    required this.observations,
    required this.outcome,
    this.closedOn,
  });

  final String title;

  /// The body that carried out the inspection.
  final String authority;

  final DateTime inspectedOn;
  final String inspector;
  final int majorFindings;
  final int minorFindings;
  final int observations;
  final InspectionOutcome outcome;

  /// Null while findings remain open.
  final DateTime? closedOn;

  int get totalFindings => majorFindings + minorFindings;
}

/// How closely a standing policy is being followed.
class PolicyAdherence {
  const PolicyAdherence({
    required this.policy,
    required this.owner,
    required this.lastReviewed,
    required this.nextReview,
    required this.adherencePercent,
    required this.openIssues,
  });

  final String policy;
  final String owner;
  final DateTime lastReviewed;
  final DateTime nextReview;
  final double adherencePercent;

  /// Deviations still to be closed out.
  final int openIssues;

  bool isReviewOverdue(DateTime asOf) => nextReview.isBefore(asOf);
}
