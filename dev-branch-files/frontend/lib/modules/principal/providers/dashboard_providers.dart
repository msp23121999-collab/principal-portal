import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_delay.dart';
import '../data/dashboard_mock_data.dart';
import '../models/calendar_event.dart';
import '../models/dashboard_summary.dart';
import '../models/pending_approval_item.dart';
import '../models/quick_action.dart';
import '../models/recent_activity.dart';

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  return mockDelay(DashboardMockData.summary);
});

final recentActivitiesProvider = FutureProvider<List<RecentActivity>>((ref) {
  return mockDelay(DashboardMockData.recentActivities);
});

/// Mutable pending-approvals list — Approve/Reject on the Dashboard removes
/// the item locally (the mock stand-in for a write-backed API call). Seeded
/// synchronously since this is a small interactive list, not a long fetch.
class PendingApprovalsNotifier
    extends StateNotifier<List<PendingApprovalItem>> {
  PendingApprovalsNotifier() : super(DashboardMockData.pendingApprovals());

  void resolve(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

final pendingApprovalsProvider =
    StateNotifierProvider<PendingApprovalsNotifier, List<PendingApprovalItem>>((
      ref,
    ) {
      return PendingApprovalsNotifier();
    });

final quickActionsProvider = Provider<List<QuickAction>>((ref) {
  return DashboardMockData.quickActions();
});

final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) {
  return mockDelay(DashboardMockData.calendarEvents);
});
