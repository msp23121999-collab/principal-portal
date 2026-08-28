// ignore_for_file: dangling_library_doc_comments, avoid_web_libraries_in_flutter, deprecated_member_use
/// ============================================================
/// LOCAL STORAGE BASE  — shared by all services
/// ============================================================
/// When migrating to PostgreSQL, replace the implementations
/// in each service. This file can be deleted / replaced by an
/// HTTP client factory.
/// ============================================================
library;

import 'dart:convert';
import 'dart:html' as html;

abstract class LocalStorageBase {
  // ── primitive read / write ──────────────────────────────────
  static String? read(String key) {
    try {
      return html.window.localStorage[key];
    } catch (_) {}
    return null;
  }

  static void write(String key, String value) {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }

  static void delete(String key) {
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
  }

  // ── typed helpers ──────────────────────────────────────────
  static List<Map<String, dynamic>> readList(String key) {
    final raw = read(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) {
          if (e is Map) {
            return Map<String, dynamic>.from(e);
          }
          return <String, dynamic>{};
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  static void writeList(String key, List<Map<String, dynamic>> list) {
    write(key, jsonEncode(list));
  }

  static Map<String, dynamic> readMap(String key) {
    final raw = read(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  static void writeMap(String key, Map<String, dynamic> map) {
    write(key, jsonEncode(map));
  }

  // ── ID generator ───────────────────────────────────────────
  static String readString(String key) {
    return read(key) ?? '';
  }

  static void writeString(String key, String value) {
    write(key, value);
  }

  static String generateId(String prefix) {
    return '$prefix${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Clears localStorage keys that previously held mock-seeded data.
  /// Call this once on app startup to ensure stale mock entries are purged
  /// so real Supabase data is always used.
  static void clearStaleMockSeeds() {
    const staleSeedKeys = [
      'leaveApplications',
      'notifications',
      'syllabusUploads',
      'syllabusTopics',
      'assignments',
    ];
    final version = read('_mockSeedVersion');
    if (version != '3') {
      for (final k in staleSeedKeys) {
        delete(k);
      }
      write('_mockSeedVersion', '3');
    }
  }
}
