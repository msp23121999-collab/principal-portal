import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/meeting.dart';

/// Reads and writes Meetings & Calendar.
///
/// Meetings and their minutes are the Principal's own records. The academic
/// calendar is not read from here — `public.academic_calendar_events` already
/// holds it and is shared across portals, so duplicating it would give the
/// institution two calendars that could disagree.
class MeetingsRepository extends Repository {
  const MeetingsRepository();

  static MeetingType _typeFrom(String? value) {
    switch (value) {
      case 'academic_council':
        return MeetingType.academicCouncil;
      case 'board_of_studies':
        return MeetingType.boardOfStudies;
      case 'iqac':
        return MeetingType.iqac;
      case 'departmental':
        return MeetingType.departmental;
      case 'staff':
        return MeetingType.staff;
      case 'parent_teacher':
        return MeetingType.parentTeacher;
      default:
        return MeetingType.governingCouncil;
    }
  }

  static String typeTo(MeetingType type) {
    switch (type) {
      case MeetingType.academicCouncil:
        return 'academic_council';
      case MeetingType.boardOfStudies:
        return 'board_of_studies';
      case MeetingType.iqac:
        return 'iqac';
      case MeetingType.departmental:
        return 'departmental';
      case MeetingType.staff:
        return 'staff';
      case MeetingType.parentTeacher:
        return 'parent_teacher';
      case MeetingType.governingCouncil:
        return 'governing_council';
    }
  }

  static MeetingStatus _statusFrom(String? value) {
    switch (value) {
      case 'completed':
        return MeetingStatus.completed;
      case 'cancelled':
        return MeetingStatus.cancelled;
      default:
        return MeetingStatus.scheduled;
    }
  }

  Future<Sourced<List<Meeting>>> fetchMeetings() {
    return load<List<Meeting>>(
      debugLabel: 'principal.meetings',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('meetings')
            .select('*, meeting_agenda_items(item, display_order)')
            .order('scheduled_at', ascending: false);

        return [
          for (final raw in rows) _toMeeting(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Future<Sourced<List<MeetingMinutes>>> fetchMinutes() {
    return load<List<MeetingMinutes>>(
      debugLabel: 'principal.meeting_minutes',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('meeting_minutes')
            .select(
              '*, meetings(title), '
              'meeting_minute_decisions(decision, display_order)',
            )
            .order('held_on', ascending: false);

        return [
          for (final raw in rows) _toMinutes(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  /// The academic calendar, read from `public.academic_calendar_events`.
  ///
  /// Not duplicated into `principal`: that table is shared across the portals,
  /// and a second copy would give the institution two calendars free to
  /// disagree about when term starts.
  ///
  /// Their table records a single `event_date`; the model carries a range. A
  /// one-day event is stored as a range starting and ending on the same day
  /// rather than inventing an end date.
  Future<Sourced<List<AcademicCalendarEntry>>> fetchCalendar() {
    return load<List<AcademicCalendarEntry>>(
      debugLabel: 'public.academic_calendar_events',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient
            .schema('public')
            .from('academic_calendar_events')
            .select()
            .order('event_date', ascending: true);

        return [
          for (final raw in rows)
            _toCalendarEntry(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  static CalendarEntryType _entryTypeFrom(String? value) {
    switch (value?.toLowerCase()) {
      case 'examination':
      case 'exam':
        return CalendarEntryType.examination;
      case 'holiday':
        return CalendarEntryType.holiday;
      case 'meeting':
        return CalendarEntryType.meeting;
      case 'instruction':
      case 'class':
        return CalendarEntryType.instruction;
      default:
        return CalendarEntryType.event;
    }
  }

  AcademicCalendarEntry _toCalendarEntry(Map<String, dynamic> row) {
    final date = row.dateOr('event_date', DateTime.now());
    return AcademicCalendarEntry(
      title: row.strOr('title', ''),
      from: date,
      to: date,
      type: _entryTypeFrom(row.str('event_type') ?? row.str('category')),
      description: row.strOr('description', ''),
    );
  }

  /// Schedules a meeting and its agenda.
  ///
  /// The agenda is a child table, so it is written after the parent exists.
  /// If an agenda item fails the meeting still stands — a meeting with a
  /// partial agenda is recoverable, a lost meeting is not.
  Future<void> schedule({
    required String title,
    required MeetingType type,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String venue,
    required String chairperson,
    required List<String> agenda,
  }) async {
    final meeting = await insertRow('meetings', {
      'title': title,
      'meeting_type': typeTo(type),
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'venue': venue,
      'chairperson': chairperson,
      'status': 'scheduled',
    });

    final meetingId = meeting.strOr('id', '');
    if (meetingId.isEmpty) return;

    for (var i = 0; i < agenda.length; i++) {
      final item = agenda[i].trim();
      if (item.isEmpty) continue;
      await insertRow('meeting_agenda_items', {
        'meeting_id': meetingId,
        'item': item,
        'display_order': i,
      });
    }
  }

  /// Cancels a meeting.
  ///
  /// The row is kept and its status changed rather than deleted — a cancelled
  /// meeting is a fact worth keeping, and its minutes and agenda would go with
  /// it under the cascade.
  Future<void> cancel(String meetingId) {
    return updateRow('meetings', meetingId, {'status': 'cancelled'});
  }

  /// Child rows arrive as a nested list; `display_order` is what makes them
  /// an agenda rather than a bag of strings.
  List<String> _orderedChildren(
    Map<String, dynamic> row,
    String table,
    String field,
  ) {
    final raw = row[table];
    if (raw is! List) return const [];

    final items = <({int order, String text})>[];
    for (final entry in raw) {
      final map = Map<String, dynamic>.from(entry as Map);
      final text = map.strOr(field, '');
      if (text.isEmpty) continue;
      items.add((order: map.intOr('display_order', 0), text: text));
    }
    items.sort((a, b) => a.order.compareTo(b.order));
    return [for (final item in items) item.text];
  }

  Meeting _toMeeting(Map<String, dynamic> row) => Meeting(
    id: row.strOr('id', ''),
    title: row.strOr('title', ''),
    type: _typeFrom(row.str('meeting_type')),
    scheduledAt: row.dateOr('scheduled_at', DateTime.now()),
    durationMinutes: row.intOr('duration_minutes', 60),
    venue: row.strOr('venue', '—'),
    chairperson: row.strOr('chairperson', '—'),
    attendeeCount: row.intOr('attendee_count', 0),
    agenda: _orderedChildren(row, 'meeting_agenda_items', 'item'),
    status: _statusFrom(row.str('status')),
    minutesRecorded: row.boolOr('minutes_recorded', false),
  );

  MeetingMinutes _toMinutes(Map<String, dynamic> row) {
    final meeting = row['meetings'];
    final title = meeting is Map
        ? Map<String, dynamic>.from(meeting).strOr('title', '')
        : '';

    return MeetingMinutes(
      meetingId: row.strOr('meeting_id', ''),
      meetingTitle: title,
      heldOn: row.dateOr('held_on', DateTime.now()),
      recordedBy: row.strOr('recorded_by', '—'),
      decisions: _orderedChildren(row, 'meeting_minute_decisions', 'decision'),
      openActionItems: row.intOr('open_action_items', 0),
    );
  }
}
