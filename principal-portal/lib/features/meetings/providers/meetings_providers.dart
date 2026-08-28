import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/meetings_repository.dart';
import '../models/meeting.dart';

final meetingsRepositoryProvider = Provider(
  (ref) => const MeetingsRepository(),
);

/// Every meeting, read from the database.
///
/// Previously an in-memory list seeded from a fixed reference date, so a
/// scheduled meeting vanished on refresh. Scheduling now writes through.
final meetingsProvider = FutureProvider<List<Meeting>>((ref) async {
  return (await ref.watch(meetingsRepositoryProvider).fetchMeetings()).value;
});

/// Schedules a meeting, then refreshes the list so the screen shows what was
/// actually stored.
final meetingSchedulerProvider = Provider((ref) => MeetingScheduler(ref));

class MeetingScheduler {
  const MeetingScheduler(this._ref);

  final Ref _ref;

  Future<void> schedule({
    required String title,
    required MeetingType type,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String venue,
    required String chairperson,
    List<String> agenda = const [],
  }) async {
    await _ref
        .read(meetingsRepositoryProvider)
        .schedule(
          title: title,
          type: type,
          scheduledAt: scheduledAt,
          durationMinutes: durationMinutes,
          venue: venue,
          chairperson: chairperson,
          agenda: agenda,
        );

    _ref.invalidate(meetingsProvider);
  }

  Future<void> cancel(String meetingId) async {
    await _ref.read(meetingsRepositoryProvider).cancel(meetingId);
    _ref.invalidate(meetingsProvider);
  }
}

/// Scheduled meetings still in the future, soonest first.
///
/// Compared against the actual current time rather than a fixed reference
/// date, so "upcoming" stays true tomorrow.
final upcomingMeetingsProvider = Provider<List<Meeting>>((ref) {
  final now = DateTime.now();
  final all = ref.watch(meetingsProvider).valueOrNull ?? const [];
  return all
      .where(
        (meeting) =>
            meeting.status == MeetingStatus.scheduled &&
            meeting.scheduledAt.isAfter(now),
      )
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
});

final pastMeetingsProvider = Provider<List<Meeting>>((ref) {
  final all = ref.watch(meetingsProvider).valueOrNull ?? const [];
  return all
      .where((meeting) => meeting.status != MeetingStatus.scheduled)
      .toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
});

/// Month currently shown in the calendar grid, normalised to its first day.
final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Day the user has selected in the grid, null until one is tapped.
final selectedCalendarDayProvider = StateProvider<DateTime?>((ref) => null);

/// The academic calendar, shared with the other portals.
final calendarEntriesProvider = FutureProvider<List<AcademicCalendarEntry>>((
  ref,
) async {
  final sourced = await ref.watch(meetingsRepositoryProvider).fetchCalendar();
  return [...sourced.value]..sort((a, b) => a.from.compareTo(b.from));
});

/// Calendar entries covering a given day, so the grid shows everything
/// happening that day in one place.
final entriesForDayProvider =
    Provider.family<List<AcademicCalendarEntry>, DateTime>((ref, day) {
      final entries =
          ref.watch(calendarEntriesProvider).valueOrNull ?? const [];
      return entries.where((entry) => entry.coversDay(day)).toList();
    });

final meetingMinutesProvider = FutureProvider<List<MeetingMinutes>>((
  ref,
) async {
  final sourced = await ref.watch(meetingsRepositoryProvider).fetchMinutes();
  return [...sourced.value]..sort((a, b) => b.heldOn.compareTo(a.heldOn));
});

/// Meetings that have been held but whose minutes have not been recorded.
///
/// Read off the meetings themselves rather than stored, so the count falls as
/// minutes are written up instead of needing to be maintained separately.
final minutesPendingProvider = Provider<int>((ref) {
  final all = ref.watch(meetingsProvider).valueOrNull ?? const [];
  return all
      .where(
        (meeting) =>
            meeting.status == MeetingStatus.completed &&
            !meeting.minutesRecorded,
      )
      .length;
});

/// Action items still open across every set of recorded minutes.
final openActionItemsProvider = Provider<int>((ref) {
  final minutes = ref.watch(meetingMinutesProvider).valueOrNull ?? const [];
  return minutes.fold(0, (sum, m) => sum + m.openActionItems);
});
