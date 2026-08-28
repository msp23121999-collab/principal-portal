import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../approvals/models/approval_request.dart';
import '../../approvals/providers/approvals_providers.dart' as approvals;
import '../../institution/providers/institution_providers.dart';
import '../../meetings/models/meeting.dart';
import '../../meetings/providers/meetings_providers.dart';
import '../data/dashboard_repository.dart';
import '../models/calendar_event.dart';
import '../models/dashboard_summary.dart';
import '../models/pending_approval_item.dart';
import '../models/recent_activity.dart';

final dashboardRepositoryProvider = Provider(
  (ref) => const DashboardRepository(),
);

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final departments = await ref.watch(departmentsProvider.future);
  return (await ref
          .watch(dashboardRepositoryProvider)
          .fetch(departments: departments))
      .value;
});

/// The pending queue, shared with the Approvals screen rather than kept
/// separately. Acting on an item there is reflected here, because both read
/// the same provider.
final pendingApprovalsProvider = Provider<List<PendingApprovalItem>>((ref) {
  // Aliased because the Approvals module exports a provider of the same name;
  // this one projects those requests into the Dashboard's smaller shape.
  final requests = ref.watch(approvals.pendingApprovalsProvider);

  return [
    for (final request in requests)
      PendingApprovalItem(
        id: request.id,
        requesterName: request.requesterName,
        requestType: request.category.label,
        dateRange: request.summary,
      ),
  ];
});

/// Recent activity, drawn from the audit trail.
///
/// The trail records what actually happened in the portal, which is precisely
/// what this panel is meant to show. Keeping a separate activity list would
/// mean two accounts of the same events.
final recentActivitiesProvider = FutureProvider<List<RecentActivity>>((
  ref,
) async {
  return (await ref.watch(dashboardRepositoryProvider).fetchRecentActivity())
      .value;
});

/// Upcoming calendar entries, from the shared academic calendar, merged with real meetings.
final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final entries = await ref.watch(calendarEntriesProvider.future);
  final meetings = await ref.watch(meetingsProvider.future);

  final events = <CalendarEvent>[];

  for (final entry in entries) {
    events.add(
      CalendarEvent(
        date: entry.from,
        title: entry.title,
        type: switch (entry.type) {
          CalendarEntryType.examination => CalendarEventType.exam,
          CalendarEntryType.holiday => CalendarEventType.holiday,
          CalendarEntryType.meeting => CalendarEventType.meeting,
          _ => CalendarEventType.event,
        },
      ),
    );
  }

  for (final meeting in meetings) {
    if (meeting.status != MeetingStatus.cancelled) {
      events.add(
        CalendarEvent(
          date: meeting.scheduledAt,
          title: meeting.title,
          type: CalendarEventType.meeting,
        ),
      );
    }
  }

  events.sort((a, b) => a.date.compareTo(b.date));
  return events;
});
