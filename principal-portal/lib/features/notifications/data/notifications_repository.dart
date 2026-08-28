import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/app_notification.dart';

/// Reads institution-wide alerts from `faculty.notifications`,
/// `student.student_notifications`, and Principal-owned `principal.circulars`,
/// merging existing records into one read-only feed for the Principal. Marking
/// an item read changes only this portal's in-memory copy.
class NotificationsRepository extends Repository {
  NotificationsRepository();

  Future<Sourced<List<AppNotification>>> fetchAll() {
    return load<List<AppNotification>>(
      debugLabel:
          'faculty.notifications + student.student_notifications + principal.circulars',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final result = await gatherWithReport<AppNotification>({
          'faculty.notifications': () =>
              _fetch(DbSchema.faculty, 'notifications'),
          'student.student_notifications': () =>
              _fetch(DbSchema.student, 'student_notifications'),
          'principal.circulars': () => _fetch(DbSchema.principal, 'circulars'),
        });

        // Store the warning for the UI to surface via the provider.
        _lastPartialWarning = result.partialWarning;

        // Deduplicate by title and approximate time since broadcast notices
        // go to both faculty and student tables.
        final seen = <String>{};
        final deduplicated = <AppNotification>[];
        for (final n in result.rows) {
          final key =
              '${n.title}_${n.createdAt.year}_${n.createdAt.month}_${n.createdAt.day}';
          if (seen.add(key)) {
            deduplicated.add(n);
          }
        }

        return deduplicated..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
    );
  }

  /// Warning text from the last fetch, or empty if all sources succeeded.
  String get lastPartialWarning => _lastPartialWarning;
  String _lastPartialWarning = '';

  Future<List<AppNotification>> _fetch(String schema, String table) async {
    final rows = await ApiClient.schema(schema).from(table).select();
    return [
      for (final row in rows)
        _toNotification(Map<String, dynamic>.from(row), schema),
    ];
  }

  AppNotification _toNotification(Map<String, dynamic> row, String schema) {
    return AppNotification(
      // Ids are only unique within their own table, so the schema is
      // prefixed to keep the merged feed free of collisions.
      id: '$schema:${row.firstStr(['id', 'notification_id', 'uuid']) ?? ''}',
      title: row.firstStr(['title', 'subject', 'heading']) ?? 'Notification',
      message:
          row.firstStr(['message', 'body', 'content', 'description']) ?? '',
      category: _categoryFrom(row.firstStr(['type', 'category', 'kind'])),
      createdAt: row.dateOr(
        'created_at',
        row.dateOr('published_at', row.dateOr('sent_at', DateTime.now())),
      ),
      isRead: row.boolOr('is_read', row.boolOr('read', false)),
    );
  }

  NotificationCategory _categoryFrom(String? raw) {
    final text = (raw ?? '').toLowerCase();
    if (text.contains('emergency') ||
        text.contains('urgent') ||
        text.contains('alert')) {
      return NotificationCategory.emergency;
    }
    if (text.contains('circular') || text.contains('notice')) {
      return NotificationCategory.circular;
    }
    if (text.contains('academic') ||
        text.contains('exam') ||
        text.contains('result') ||
        text.contains('attendance')) {
      return NotificationCategory.academic;
    }
    return NotificationCategory.announcement;
  }
}
