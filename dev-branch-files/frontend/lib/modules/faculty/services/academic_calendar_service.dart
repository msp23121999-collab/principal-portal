// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// ACADEMIC CALENDAR SERVICE — Supabase Integrated (No Mock Data)
/// ============================================================
library;

import 'local_storage_base.dart';
import 'supabase_client.dart';

class AcademicCalendarService {
  static const String _key = 'academic_calendar_events';
  static const String _table = 'academic_calendar_events';
  static const String _schema = 'public';

  static void seedIfEmpty() {}

  /// Fetches academic calendar events directly from Supabase DB
  static Future<List<CalEvent>> fetchFromSupabase() async {
    try {
      final remote = await SupabaseClientHelper.select(_table, schema: _schema);
      if (remote.isNotEmpty) {
        final converted = remote.map((e) => {
              'title': e['title'] ?? '',
              'date': e['event_date']?.toString() ?? '',
              'type': e['event_type'] ?? 'Event',
              'category': e['category'] ?? 'Academic',
              'eventType': e['event_scope'] ?? 'College Events',
              'department': e['department'] ?? 'CSE',
              'place': e['venue'] ?? '',
              'startTime': e['start_time']?.toString() ?? '',
              'endTime': e['end_time']?.toString() ?? '',
            }).toList();
        LocalStorageBase.writeList(_key, converted);
        return _toCalEventList(converted);
      }
    } catch (_) {}

    final local = LocalStorageBase.readList(_key);
    return _toCalEventList(local);
  }

  /// Gets all events from local storage
  static List<Map<String, dynamic>> getAll() =>
      LocalStorageBase.readList(_key);

  /// Converts a list of maps to a list of CalEvent objects
  static List<CalEvent> _toCalEventList(List<Map<String, dynamic>> events) {
    return events.map((e) {
      DateTime date;
      try {
        date = DateTime.parse(e['date'] as String);
      } catch (_) {
        date = DateTime.now();
      }

      return CalEvent(
        title: (e['title'] ?? '').toString(),
        date: date,
        type: (e['type'] ?? 'Event').toString(),
        category: (e['category'] ?? 'Academic').toString(),
        eventType: (e['eventType'] ?? 'College Events').toString(),
        department: (e['department'] ?? 'CSE').toString(),
        place: (e['place'] ?? '').toString(),
        startTime: (e['startTime'] ?? '').toString(),
        endTime: (e['endTime'] ?? '').toString(),
      );
    }).toList();
  }

  /// Gets events filtered by month
  static List<CalEvent> getByMonth(int year, int month) {
    return getAll().where((e) {
      try {
        final d = DateTime.parse(e['date'] as String);
        return d.year == year && d.month == month;
      } catch (_) {
        return false;
      }
    }).map((e) => _toCalEventList([e])[0]).toList();
  }

  /// Saves an event to Supabase and local storage
  static Future<void> save(CalEvent event) async {
    final all = getAll();
    all.add(event.toMap());

    LocalStorageBase.writeList(_key, all);

    final payload = {
      'title': event.title,
      'event_date': event.date.toIso8601String().split('T')[0],
      'event_type': event.type,
      'category': event.category,
      'event_scope': event.eventType,
      'department': event.department,
      'venue': event.place,
      'start_time': event.startTime.isNotEmpty ? event.startTime : null,
      'end_time': event.endTime.isNotEmpty ? event.endTime : null,
      'color_code': event.colorCode,
      'description': event.description,
    };

    await SupabaseClientHelper.insert(_table, payload);
  }

  /// Deletes an event by title and date
  static Future<void> deleteByTitleAndDate(String title, DateTime date) async {
    final all = getAll();
    final initialLength = all.length;

    all.removeWhere((e) =>
      e['title'] == title &&
      e['date'] == date.toIso8601String().split('T')[0]
    );

    if (all.length < initialLength) {
      LocalStorageBase.writeList(_key, all);
    }
  }
}

/// Event model used by AcademicCalendarView
class CalEvent {
  final String title;
  final DateTime date;
  final String type;
  final String category;
  final String eventType;
  final String department;
  final String place;
  final String startTime;
  final String endTime;

  CalEvent({
    required this.title,
    required this.date,
    required this.type,
    this.category = 'Academic',
    this.eventType = 'College Events',
    this.department = 'CSE',
    this.place = '',
    this.startTime = '',
    this.endTime = '',
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'date': date.toIso8601String().split('T')[0],
        'type': type,
        'category': category,
        'eventType': eventType,
        'department': department,
        'place': place,
        'startTime': startTime,
        'endTime': endTime,
      };

  String get colorCode {
    switch (category) {
      case 'Examination':
        return '#2563EB';
      case 'Holiday':
        return '#DC2626';
      case 'Workshop':
      case 'Seminar':
        return '#059669';
      case 'Meeting':
        return '#D97706';
      case 'Cultural':
      case 'Sports':
        return '#DC2626';
      default:
        return '#2563EB';
    }
  }

  String get description => '$type: $title';
}