import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/approval_request.dart';

/// What actually happened when a decision was recorded.
///
/// A decision is two writes: the decision itself, and the audit entry that says
/// who made it. They cannot share a transaction from the client — see the note
/// on [ApprovalsRepository.decide] — so "no exception was thrown" is not the
/// same as "both landed".
///
/// The distinction matters more here than almost anywhere else in the portal:
/// an approval that took effect but was never recorded is precisely the case
/// the audit trail exists to answer, and it used to fail in complete silence.
@immutable
class DecisionOutcome {
  const DecisionOutcome({required this.recorded, this.auditError});

  /// True when the audit entry was written alongside the decision.
  final bool recorded;

  /// Why the trail write failed, in general terms. Null when it succeeded.
  final String? auditError;

  /// Plain-language result, safe to show the Principal.
  ///
  /// The decision itself always applied by the time this exists — a failure
  /// there throws instead — so the wording never casts doubt on that, only on
  /// the record of it.
  String get message => recorded
      ? 'Decision recorded.'
      : 'The decision was applied, but it could not be written to the audit '
            'trail. Tell your administrator before relying on the history.';
}

/// Reads and decides approval requests.
///
/// Budget, purchase, event and academic requests live in
/// `principal.approval_requests` and are ours to write freely.
///
/// Leave is different. It lives in `faculty.leave_applications`, which the
/// Faculty Portal owns. The agreed arrangement is that a decision updates the
/// `status` column on their row — a row write, so their table structure is
/// untouched and their portal sees the decision immediately — while the full
/// record of who decided, when, why, and what the status was before is written
/// to `principal.approval_decisions`. Their table has no column for any of
/// that, and adding one would mean altering a table we do not own.
class ApprovalsRepository extends Repository {
  const ApprovalsRepository();

  static ApprovalCategory _categoryFrom(String? value) {
    switch (value?.toLowerCase()) {
      case 'purchase':
        return ApprovalCategory.purchase;
      case 'event':
        return ApprovalCategory.event;
      case 'academic':
        return ApprovalCategory.academic;
      default:
        return ApprovalCategory.budget;
    }
  }

  static ApprovalPriority _priorityFrom(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return ApprovalPriority.high;
      case 'urgent':
        return ApprovalPriority.urgent;
      default:
        return ApprovalPriority.routine;
    }
  }

  static ApprovalDecision _decisionFrom(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return ApprovalDecision.approved;
      case 'rejected':
        return ApprovalDecision.rejected;
      default:
        return ApprovalDecision.pending;
    }
  }

  static String _decisionTo(ApprovalDecision decision) {
    switch (decision) {
      case ApprovalDecision.approved:
        return 'approved';
      case ApprovalDecision.rejected:
        return 'rejected';
      case ApprovalDecision.pending:
        return 'pending';
    }
  }

  Future<Sourced<List<ApprovalRequest>>> fetchAll() {
    return load<List<ApprovalRequest>>(
      debugLabel: 'principal.approval_requests',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('approval_requests')
            .select('*, departments(code)')
            .order('submitted_at', ascending: false);

        return [
          for (final raw in rows) _toRequest(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  /// Records a decision on a `principal` request.
  ///
  /// Two writes, both in our own schema: the request's own decision column so
  /// the list reflects it, and an entry in the audit trail so the history
  /// survives a later change of mind.
  ///
  /// Now an atomic transaction using `principal.record_decision()`. Both writes
  /// happen together, guaranteeing no audit trails are lost during a network drop.
  Future<DecisionOutcome> decide({
    required String requestId,
    required ApprovalDecision decision,
    required ApprovalDecision previousDecision,
    String? remarks,
  }) async {
    // Throws on failure: nothing happened, and the caller must see that.
    await ApiClient.schema(DbSchema.principal).rpc('record_decision', params: {
      'p_request_id': requestId,
      'p_decision': _decisionTo(decision),
      'p_previous_status': _decisionTo(previousDecision),
      'p_remarks': remarks,
      'p_actor': _actor(),
    });

    return const DecisionOutcome(recorded: true);
  }

  /// Writes the audit entry, reporting rather than throwing on failure.
  ///
  /// The decision has already taken effect by the time this runs. Rethrowing
  /// would tell the Principal the whole operation failed and invite them to
  /// repeat it, which would apply the decision twice; returning the outcome
  /// lets the screen say what is actually true.
  Future<DecisionOutcome> _recordDecision({
    required String sourceType,
    required String sourceId,
    required String decision,
    required String previousStatus,
    String? remarks,
  }) async {
    try {
      await insertRow('approval_decisions', {
        'source_type': sourceType,
        'source_id': sourceId,
        'decision': decision,
        'previous_status': previousStatus,
        'remarks': remarks,
        'decided_by': _actor(),
      });
      return const DecisionOutcome(recorded: true);
    } catch (error) {
      // The driver message names the schema and the failing constraint, which
      // is not something to put in front of the Principal.
      if (kDebugMode) {
        debugPrint('Audit trail write failed ($sourceType $sourceId): $error');
      }
      return const DecisionOutcome(
        recorded: false,
        auditError: 'The audit trail refused the entry.',
      );
    }
  }

  /// The administrative actor recorded for a protected write.
  ///
  /// The public dashboard has no user session by design. Administrative writes
  /// are therefore authenticated at the server boundary with an API key and
  /// are attributed to the Principal portal service actor.
  String _actor() => 'principal';

  /// Records a decision on a leave application owned by the Faculty Portal.
  ///
  /// The status write reaches into `faculty.leave_applications`. It is the
  /// only write this portal makes outside `principal`, it changes one column
  /// on one row, and it alters nothing about their schema.
  ///
  /// Worth knowing: RLS is off on that table and the HOD Portal writes the
  /// same column, so there is no locking between them — last write wins. That
  /// is a property of the shared database, not something this method can fix.
  /// This one cannot become a transaction at all from here. The status column
  /// belongs to the Faculty Portal and the trail belongs to us, so an atomic
  /// version would be a function in *their* schema with permission to write
  /// ours — a cross-team change neither side has agreed. The Principal-side
  /// guarantee is therefore the same as [decide]: the decision is applied
  /// first, and a trail failure is reported rather than hidden.
  Future<DecisionOutcome> decideLeave({
    required String leaveId,
    required ApprovalDecision decision,
    required String previousStatus,
    String? remarks,
  }) async {
    final status = _decisionTo(decision);

    await ApiClient.schema(
      DbSchema.faculty,
    ).from('leave_applications').update({'status': status}).eq('id', leaveId);

    return _recordDecision(
      sourceType: 'faculty_leave',
      sourceId: leaveId,
      decision: status,
      previousStatus: previousStatus,
      remarks: remarks,
    );
  }

  ApprovalRequest _toRequest(Map<String, dynamic> row) {
    final dept = row['departments'];
    final code = dept is Map
        ? Map<String, dynamic>.from(dept).strOr('code', '')
        : '';

    return ApprovalRequest(
      id: row.strOr('id', ''),
      category: _categoryFrom(row.str('category')),
      title: row.strOr('title', ''),
      requesterName: row.strOr('requester_name', ''),
      requesterRole: row.strOr('requester_role', ''),
      departmentCode: code,
      submittedAt: row.dateOr('submitted_at', DateTime.now()),
      summary: row.strOr('summary', ''),
      priority: _priorityFrom(row.str('priority')),
      decision: _decisionFrom(row.str('decision')),
      // Null rather than zero: an event request genuinely has no amount, and
      // showing ₹0 would imply it costs nothing.
      amount: row.str('amount') == null ? null : row.doubleOr('amount', 0),
      remarks: row.str('remarks'),
    );
  }
}
