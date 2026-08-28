/// The standing bodies and forums the Principal convenes or attends.
enum MeetingType {
  governingCouncil,
  academicCouncil,
  boardOfStudies,
  iqac,
  departmental,
  staff,
  parentTeacher,
}

extension MeetingTypeX on MeetingType {
  String get label {
    switch (this) {
      case MeetingType.governingCouncil:
        return 'Governing Council';
      case MeetingType.academicCouncil:
        return 'Academic Council';
      case MeetingType.boardOfStudies:
        return 'Board of Studies';
      case MeetingType.iqac:
        return 'IQAC';
      case MeetingType.departmental:
        return 'Departmental';
      case MeetingType.staff:
        return 'Staff Meeting';
      case MeetingType.parentTeacher:
        return 'Parent-Teacher';
    }
  }
}

enum MeetingStatus { scheduled, completed, cancelled }

extension MeetingStatusX on MeetingStatus {
  String get label {
    switch (this) {
      case MeetingStatus.scheduled:
        return 'Scheduled';
      case MeetingStatus.completed:
        return 'Completed';
      case MeetingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// A single meeting on the Principal's calendar.
class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.type,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.venue,
    required this.chairperson,
    required this.attendeeCount,
    required this.agenda,
    required this.status,
    this.minutesRecorded = false,
  });

  final String id;
  final String title;
  final MeetingType type;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String venue;
  final String chairperson;
  final int attendeeCount;

  /// Agenda points to be taken up.
  final List<String> agenda;

  final MeetingStatus status;

  /// Whether minutes have been filed for a completed meeting.
  final bool minutesRecorded;

  Meeting copyWith({MeetingStatus? status, bool? minutesRecorded}) {
    return Meeting(
      id: id,
      title: title,
      type: type,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      venue: venue,
      chairperson: chairperson,
      attendeeCount: attendeeCount,
      agenda: agenda,
      status: status ?? this.status,
      minutesRecorded: minutesRecorded ?? this.minutesRecorded,
    );
  }
}

/// What an academic-calendar entry represents.
enum CalendarEntryType { instruction, examination, holiday, event, meeting }

extension CalendarEntryTypeX on CalendarEntryType {
  String get label {
    switch (this) {
      case CalendarEntryType.instruction:
        return 'Instruction';
      case CalendarEntryType.examination:
        return 'Examination';
      case CalendarEntryType.holiday:
        return 'Holiday';
      case CalendarEntryType.event:
        return 'Event';
      case CalendarEntryType.meeting:
        return 'Meeting';
    }
  }
}

/// A dated entry in the institutional academic calendar. Single-day
/// entries carry the same value in [from] and [to].
class AcademicCalendarEntry {
  const AcademicCalendarEntry({
    required this.title,
    required this.from,
    required this.to,
    required this.type,
    required this.description,
  });

  final String title;
  final DateTime from;
  final DateTime to;
  final CalendarEntryType type;
  final String description;

  int get dayCount => to.difference(from).inDays + 1;

  bool coversDay(DateTime day) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final target = DateTime(day.year, day.month, day.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }
}

/// Minutes filed against a completed meeting.
class MeetingMinutes {
  const MeetingMinutes({
    required this.meetingId,
    required this.meetingTitle,
    required this.heldOn,
    required this.recordedBy,
    required this.decisions,
    required this.openActionItems,
  });

  final String meetingId;
  final String meetingTitle;
  final DateTime heldOn;
  final String recordedBy;

  /// Resolutions passed at the meeting.
  final List<String> decisions;

  /// Action items still outstanding.
  final int openActionItems;
}
