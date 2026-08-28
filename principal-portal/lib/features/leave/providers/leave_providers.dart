import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/repository.dart';
import '../data/leave_repository.dart';
import '../models/leave_request.dart';

final leaveRepositoryProvider = Provider((ref) => const LeaveRepository());

/// Applications as fetched, plus where they came from.
final leaveSourcedProvider = FutureProvider<Sourced<List<LeaveRequest>>>((ref) {
  return ref.watch(leaveRepositoryProvider).fetchAll();
});

/// The request queue, read from the database.
///
/// Refetched when a decision is made, so the Principal sees survivable updates.
final leaveRequestsProvider = Provider<List<LeaveRequest>>((ref) {
  return ref.watch(leaveSourcedProvider).valueOrNull?.value ?? const [];
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
