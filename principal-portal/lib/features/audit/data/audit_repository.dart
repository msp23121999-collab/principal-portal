import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/audit.dart';

/// Reads Audit & Compliance from `principal`.
///
/// `hod.audit_logs` exists but is empty and scoped to a department. This is the
/// institution-wide log the Principal reviews.
///
/// The log is currently populated by seed data. Once the portal's own writes
/// settle — approvals, meetings, circulars — real entries should be inserted
/// here as those actions happen, so the log stops being decorative. Noted
/// rather than done, because writing an entry per action is a change in
/// behaviour that belongs with the audit requirements, not smuggled in here.
class AuditRepository extends Repository {
  const AuditRepository();

  static AuditAction _actionFrom(String? value) {
    switch (value) {
      case 'updated':
        return AuditAction.updated;
      case 'deleted':
        return AuditAction.deleted;
      case 'approved':
        return AuditAction.approved;
      case 'rejected':
        return AuditAction.rejected;
      case 'published':
        return AuditAction.published;
      case 'exported':
        return AuditAction.exported;
      case 'signed_in':
        return AuditAction.signedIn;
      default:
        return AuditAction.created;
    }
  }

  static AuditSeverity _severityFrom(String? value) {
    switch (value) {
      case 'notable':
        return AuditSeverity.notable;
      case 'critical':
        return AuditSeverity.critical;
      default:
        return AuditSeverity.routine;
    }
  }

  static ComplianceState _complianceFrom(String? value) {
    switch (value) {
      case 'partial':
        return ComplianceState.partial;
      case 'at_risk':
        return ComplianceState.atRisk;
      case 'non_compliant':
        return ComplianceState.nonCompliant;
      default:
        return ComplianceState.compliant;
    }
  }

  static InspectionOutcome _outcomeFrom(String? value) {
    switch (value) {
      case 'observations_raised':
        return InspectionOutcome.observationsRaised;
      case 'action_required':
        return InspectionOutcome.actionRequired;
      case 'scheduled':
        return InspectionOutcome.scheduled;
      default:
        return InspectionOutcome.cleared;
    }
  }

  Future<Sourced<List<AuditEntry>>> fetchEntries() {
    return load<List<AuditEntry>>(
      debugLabel: 'principal.audit_entries',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('audit_entries').select().order('occurred_at', ascending: false);

        return [
          for (final raw in rows)
            AuditEntry(
              id: Map<String, dynamic>.from(raw).strOr('id', ''),
              actor: Map<String, dynamic>.from(raw).strOr('actor', ''),
              actorRole: Map<String, dynamic>.from(raw).strOr('actor_role', ''),
              action: _actionFrom(Map<String, dynamic>.from(raw).str('action')),
              module: Map<String, dynamic>.from(raw).strOr('module', ''),
              description: Map<String, dynamic>.from(
                raw,
              ).strOr('description', ''),
              timestamp: Map<String, dynamic>.from(
                raw,
              ).dateOr('occurred_at', DateTime.now()),
              ipAddress: Map<String, dynamic>.from(
                raw,
              ).strOr('ip_address', '—'),
              severity: _severityFrom(
                Map<String, dynamic>.from(raw).str('severity'),
              ),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<ComplianceArea>>> fetchComplianceAreas() {
    return load<List<ComplianceArea>>(
      debugLabel: 'principal.compliance_areas',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('compliance_areas').select().order('name', ascending: true);

        return [
          for (final raw in rows)
            ComplianceArea(
              name: Map<String, dynamic>.from(raw).strOr('name', ''),
              category: Map<String, dynamic>.from(raw).strOr('category', ''),
              owner: Map<String, dynamic>.from(raw).strOr('owner_name', '—'),
              score: Map<String, dynamic>.from(raw).doubleOr('score', 0),
              maximumScore: Map<String, dynamic>.from(
                raw,
              ).doubleOr('maximum_score', 100),
              lastReviewed: Map<String, dynamic>.from(
                raw,
              ).dateOr('last_reviewed', DateTime.now()),
              state: _complianceFrom(
                Map<String, dynamic>.from(raw).str('state'),
              ),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<InspectionReport>>> fetchInspections() {
    return load<List<InspectionReport>>(
      debugLabel: 'principal.inspection_reports',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('inspection_reports')
            .select()
            .order('inspected_on', ascending: false);

        return [
          for (final raw in rows) _toInspection(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Future<Sourced<List<PolicyAdherence>>> fetchPolicies() {
    return load<List<PolicyAdherence>>(
      debugLabel: 'principal.policy_adherence',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('policy_adherence')
            .select()
            .order('next_review', ascending: true);

        return [
          for (final raw in rows)
            PolicyAdherence(
              policy: Map<String, dynamic>.from(raw).strOr('policy', ''),
              owner: Map<String, dynamic>.from(raw).strOr('owner_name', '—'),
              lastReviewed: Map<String, dynamic>.from(
                raw,
              ).dateOr('last_reviewed', DateTime.now()),
              nextReview: Map<String, dynamic>.from(
                raw,
              ).dateOr('next_review', DateTime.now()),
              adherencePercent: Map<String, dynamic>.from(
                raw,
              ).doubleOr('adherence_percent', 0),
              openIssues: Map<String, dynamic>.from(
                raw,
              ).intOr('open_issues', 0),
            ),
        ];
      },
    );
  }

  InspectionReport _toInspection(Map<String, dynamic> row) => InspectionReport(
    title: row.strOr('title', ''),
    authority: row.strOr('authority', ''),
    inspectedOn: row.dateOr('inspected_on', DateTime.now()),
    inspector: row.strOr('inspector', '—'),
    majorFindings: row.intOr('major_findings', 0),
    minorFindings: row.intOr('minor_findings', 0),
    observations: row.intOr('observations', 0),
    outcome: _outcomeFrom(row.str('outcome')),
    // Null while an inspection is still open, which is a different thing
    // from having been closed today.
    closedOn: row.str('closed_on') == null
        ? null
        : row.dateOr('closed_on', DateTime.now()),
  );
}
