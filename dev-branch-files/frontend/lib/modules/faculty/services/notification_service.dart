// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// NOTIFICATION SERVICE
/// ============================================================
/// Stores & retrieves notifications from Local Storage.
/// Future: replace body with HTTP calls to PostgreSQL REST API.
/// ============================================================
library;

import 'local_storage_base.dart';
import 'supabase_client.dart';

class NotificationService {
  static const String _key = 'notifications';
  static const String _table = 'notifications';

  static void seedIfEmpty() {
    // No mock data — start with an empty list.
    // Real data is fetched from Supabase via fetchFromSupabase().
    if (LocalStorageBase.readList(_key).isNotEmpty) return;
    LocalStorageBase.writeList(_key, []);
  }

  // ── Supabase Integration ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchFromSupabase({String facultyId = 'FAC73124'}) async {
    final local = getAll();
    final localReadMap = <String, bool>{};
    for (final l in local) {
      final id = (l['notificationId'] ?? l['id'])?.toString();
      if (id != null && id.isNotEmpty) {
        localReadMap[id] = (l['read'] == true || l['unread'] == false);
      }
    }

    List<Map<String, dynamic>> remote = [];
    try {
      remote = await SupabaseClientHelper.select(
        _table,
        schema: 'faculty',
        filterColumn: 'faculty_employee_id',
        filterValue: facultyId,
      );
      if (remote.isEmpty) {
        remote = await SupabaseClientHelper.select(_table, schema: 'faculty');
      }
    } catch (_) {}

    if (remote.isNotEmpty) {
      final converted = remote.map((n) {
        final id = (n['id'] ?? n['notification_id'])?.toString() ?? '';
        final isRemoteRead = (n['is_read'] == true || n['read'] == true);
        final isLocallyRead = localReadMap[id] ?? false;
        final isRead = isRemoteRead || isLocallyRead;

        return {
          'notificationId': id,
          'id': id,
          'facultyId': n['faculty_employee_id'] ?? facultyId,
          'title': n['title'] ?? '',
          'body': n['description'] ?? n['body'] ?? '',
          'time': n['created_at'] != null ? n['created_at'].toString().split('T').first : 'Today',
          'read': isRead,
          'unread': !isRead,
          'tag': n['category'] ?? 'Announcement',
          'priority': n['priority'] ?? 'MEDIUM',
          'type': n['category'] ?? 'general',
        };
      }).toList();

      final remoteIds = converted.map((r) => r['notificationId']).toSet();
      final localOnly = local.where((loc) {
        final locId = (loc['notificationId'] ?? loc['id'])?.toString() ?? '';
        return locId.isNotEmpty && !remoteIds.contains(locId);
      }).toList();

      final merged = [...converted, ...localOnly];
      LocalStorageBase.writeList(_key, merged);
      return merged;
    }
    return getAll();
  }

  static List<Map<String, dynamic>> getAll() => LocalStorageBase.readList(_key);

  static List<Map<String, dynamic>> getByFaculty(String facultyId) {
    final all = getAll();
    return all.where((n) {
      final fId = n['facultyId']?.toString();
      return fId == null || fId.isEmpty || fId == facultyId || fId == 'FAC73124' || fId == 'FAC002';
    }).toList();
  }

  static int getUnreadCount(String facultyId) {
    return getByFaculty(facultyId).where((n) => n['read'] != true).length;
  }

  static void push(Map<String, dynamic> notification) {
    final all = getAll();
    if (notification['notificationId'] == null || notification['notificationId'].toString().isEmpty) {
      notification['notificationId'] = LocalStorageBase.generateId('N');
    }
    notification['id'] ??= notification['notificationId'];
    notification['createdAt'] ??= DateTime.now().toIso8601String();
    notification['read'] ??= false;
    notification['unread'] ??= true;
    all.insert(0, notification);
    LocalStorageBase.writeList(_key, all);

    final payload = <String, dynamic>{
      'title': notification['title'] ?? 'Notification',
      'description': notification['body'] ?? '',
      'category': notification['tag'] ?? 'Announcement',
      'is_read': notification['read'] == true,
    };
    SupabaseClientHelper.insert(_table, payload);
  }

  static void markRead(String notificationId, {bool read = true}) {
    final all = getAll();
    for (final n in all) {
      if (n['notificationId'] == notificationId || n['id'] == notificationId) {
        n['read'] = read;
        n['unread'] = !read;
      }
    }
    LocalStorageBase.writeList(_key, all);
    SupabaseClientHelper.update(_table, {'is_read': read}, 'id', notificationId);
  }

  static void markAllRead(String facultyId) {
    final all = getAll();
    for (final n in all) {
      final fId = n['facultyId']?.toString();
      if (fId == null || fId.isEmpty || fId == facultyId || facultyId.isEmpty || fId == 'FAC002' || fId == 'FAC73124') {
        n['read'] = true;
        n['unread'] = false;
      }
    }
    LocalStorageBase.writeList(_key, all);
    SupabaseClientHelper.update(_table, {'is_read': true}, 'faculty_employee_id', facultyId);
  }

  static void delete(String notificationId) {
    final all = getAll();
    all.removeWhere((n) => n['notificationId'] == notificationId || n['id'] == notificationId);
    LocalStorageBase.writeList(_key, all);
    SupabaseClientHelper.delete(_table, 'id', notificationId);
  }
}
