/// A single highlighted date on the Dashboard's month calendar widget.
class CalendarEvent {
  const CalendarEvent({
    required this.date,
    required this.title,
    required this.type,
  });

  final DateTime date;
  final String title;
  final CalendarEventType type;
}

enum CalendarEventType { exam, holiday, event, meeting }
