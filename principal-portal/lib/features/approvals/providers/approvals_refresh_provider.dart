import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../leave/providers/leave_providers.dart';
import 'approvals_providers.dart';

/// Refreshes every source the Approvals page reads.
///
/// The page shows three kinds of record that come from two independent
/// fetches — the approval queue (`approvalRequestsProvider`, covering the All,
/// Academic and Event tabs) and the leave queue (`leaveSourcedProvider`). A
/// refresh that reloaded only one of them would leave the tab beside it showing
/// figures from a different moment, and the sidebar's pending badge counts both,
/// so it would disagree with whichever tab was open.
///
/// Everything downstream — `requestsByCategoryProvider`,
/// `pendingApprovalsProvider`, `pendingApprovalValueProvider`,
/// `totalPendingApprovalsProvider`, `leaveRequestsProvider`,
/// `pendingLeaveRequestsProvider`, `leaveHistoryProvider` — is derived, so
/// invalidating the two roots refreshes the decision state on every tab and the
/// badge with it. There is no separate decision cache to clear.
class ApprovalsRefresh extends StateNotifier<bool> {
  ApprovalsRefresh(this._ref) : super(false);

  final Ref _ref;

  /// The fetch currently in flight, if any.
  ///
  /// Held so that a second trigger *joins* the running refresh instead of
  /// starting a rival one. The page offers two ways to ask — the header button
  /// and pull-to-refresh — and a plain `if (busy) return;` guard would hand the
  /// pull gesture an already-completed future, ending its spinner while the
  /// real fetch was still running.
  Future<void>? _inFlight;

  /// Refetches the approval and leave queues, completing when both have landed.
  ///
  /// Safe to call while a refresh is already running: the caller awaits the
  /// same operation and no additional request is issued.
  Future<void> run() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _run();
    _inFlight = future;
    return future;
  }

  Future<void> _run() async {
    if (mounted) state = true;
    try {
      // Invalidate first, then await both futures together, so the two round
      // trips overlap rather than running one after the other.
      _ref.invalidate(approvalRequestsProvider);
      _ref.invalidate(leaveSourcedProvider);

      await Future.wait<void>([
        _ref.read(approvalRequestsProvider.future),
        _ref.read(leaveSourcedProvider.future),
      ]);
    } catch (_) {
      // Deliberately not rethrown, and not swallowed either: a failed fetch is
      // already held as an AsyncError on the provider itself, and the tab
      // renders it through ErrorState with the real cause. Rethrowing here
      // would additionally surface it as an unhandled error out of a button
      // callback or RefreshIndicator.onRefresh, which reports the same failure
      // twice and leaves the pull gesture's spinner stuck.
    } finally {
      _inFlight = null;
      // The Approvals screen can be disposed mid-flight if the Principal
      // navigates away; writing state then would throw.
      if (mounted) state = false;
    }
  }
}

/// True while a refresh is in flight. Watch this to show progress.
final approvalsRefreshProvider = StateNotifierProvider<ApprovalsRefresh, bool>(
  ApprovalsRefresh.new,
);
