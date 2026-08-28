import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../leave/providers/leave_providers.dart';
import '../data/approvals_repository.dart';
import '../models/approval_request.dart';

final approvalsRepositoryProvider = Provider(
  (ref) => const ApprovalsRepository(),
);

/// The request queue, read from the database.
///
/// Previously an in-memory list that reset on refresh. A decision now writes
/// through and the list is refetched, so what the Principal sees survives
/// reloading the page.
final approvalRequestsProvider = FutureProvider<List<ApprovalRequest>>((
  ref,
) async {
  final all = (await ref.watch(approvalsRepositoryProvider).fetchAll()).value;
  // Show all requests for Principal to have full oversight.
  return all;
});

/// Records a decision, then refreshes the queue so the screen reflects what
/// was actually persisted rather than what we assumed would be.
final approvalDecisionProvider = Provider(
  (ref) => ApprovalDecisionService(ref),
);

class ApprovalDecisionService {
  const ApprovalDecisionService(this._ref);

  final Ref _ref;

  /// Records a decision and returns what actually landed.
  ///
  /// The outcome is passed back to the caller rather than dropped, so the
  /// screen can tell the Principal that a decision applied without reaching the
  /// audit trail. The queue is invalidated either way: the decision itself has
  /// taken effect in both cases, and a list still showing it as pending would
  /// be wrong in the more dangerous direction.
  Future<DecisionOutcome> decide({
    required ApprovalRequest request,
    required ApprovalDecision decision,
    String? remarks,
  }) async {
    try {
      return await _ref
          .read(approvalsRepositoryProvider)
          .decide(
            requestId: request.id,
            decision: decision,
            previousDecision: request.decision,
            remarks: remarks,
          );
    } finally {
      _ref.invalidate(approvalRequestsProvider);
    }
  }

  Future<DecisionOutcome> decideLeave({
    required String leaveId,
    required ApprovalDecision decision,
    required String previousStatus,
    String? remarks,
  }) async {
    try {
      return await _ref
          .read(approvalsRepositoryProvider)
          .decideLeave(
            leaveId: leaveId,
            decision: decision,
            previousStatus: previousStatus,
            remarks: remarks,
          );
    } finally {
      // The status write reaches the Faculty Portal's table. Refresh even when
      // it threw: a failed update and a successful one that we then failed to
      // record look identical from here, and the refetch settles it.
      _ref.invalidate(leaveSourcedProvider);
    }
  }
}

/// Requests of one category, pending items first and newest first within
/// each group, so the queue always opens on what needs a decision.
final requestsByCategoryProvider =
    Provider.family<AsyncValue<List<ApprovalRequest>>, ApprovalCategory>((
      ref,
      category,
    ) {
      return ref.watch(approvalRequestsProvider).whenData((all) {
        final requests = all
            .where((request) => request.category == category)
            .toList();

        requests.sort((a, b) {
          if (a.decision != b.decision) {
            if (a.decision == ApprovalDecision.pending) return -1;
            if (b.decision == ApprovalDecision.pending) return 1;
          }
          return b.submittedAt.compareTo(a.submittedAt);
        });

        return requests;
      });
    });

final pendingApprovalsProvider = Provider<List<ApprovalRequest>>((ref) {
  final all = ref.watch(approvalRequestsProvider).valueOrNull ?? const [];
  return all
      .where((request) => request.decision == ApprovalDecision.pending)
      .toList();
});

/// Total value of everything still awaiting a financial decision.
final pendingApprovalValueProvider = Provider<double>((ref) {
  return ref
      .watch(pendingApprovalsProvider)
      .fold(0.0, (sum, request) => sum + (request.amount ?? 0));
});

/// Every pending item across the whole page, leave included — this is
/// what the sidebar badge counts.
final totalPendingApprovalsProvider = Provider<int>((ref) {
  return ref.watch(pendingApprovalsProvider).length +
      ref.watch(pendingLeaveRequestsProvider).length;
});
