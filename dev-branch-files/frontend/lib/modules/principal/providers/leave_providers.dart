import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/leave_mock_data.dart';
import '../models/leave_request.dart';

/// Mutable leave-request list — Approve/Reject updates status in place.
/// This is the same in-memory "mock backend" pattern the Dashboard's
/// pending-approvals section uses for its own local list.
class LeaveRequestsNotifier extends StateNotifier<List<LeaveRequest>> {
  LeaveRequestsNotifier() : super(LeaveMockData.requests());

  void setStatus(String id, LeaveStatus status) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: status) else r,
    ];
  }
}

final leaveRequestsProvider =
    StateNotifierProvider<LeaveRequestsNotifier, List<LeaveRequest>>((ref) {
      return LeaveRequestsNotifier();
    });

final pendingLeaveRequestsProvider = Provider<List<LeaveRequest>>((ref) {
  return ref
      .watch(leaveRequestsProvider)
      .where((r) => r.status == LeaveStatus.pending)
      .toList();
});

final leaveHistoryProvider = Provider<List<LeaveRequest>>((ref) {
  final list =
      ref
          .watch(leaveRequestsProvider)
          .where((r) => r.status != LeaveStatus.pending)
          .toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  return list;
});
