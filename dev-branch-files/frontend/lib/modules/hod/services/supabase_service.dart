import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static bool isConfigured = false;
}

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  bool _isInitialized = false;
  static final Map<String, List<Map<String, dynamic>>> _localAppStorage = {};

  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<bool> initialize([String? url, String? key]) async {
    final targetUrl = url ?? SupabaseConfig.supabaseUrl;
    final targetKey = key ?? SupabaseConfig.supabaseAnonKey;

    try {
      await Supabase.initialize(
        url: targetUrl,
        anonKey: targetKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      SupabaseConfig.isConfigured = true;
      debugPrint('Supabase connected successfully to $targetUrl');
      return true;
    } catch (e) {
      debugPrint('Supabase fallback active: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTable(
    String tableName, {
    String? select,
    String? filterColumn,
    dynamic filterValue,
  }) async {
    final extraLocal = _localAppStorage[tableName] ?? [];
    final c = client;

    if (c == null) {
      return [...extraLocal];
    }
    try {
      if (filterColumn != null && filterValue != null) {
        final data = await c.from(tableName).select(select ?? '*').eq(filterColumn, filterValue);
        final list = List<Map<String, dynamic>>.from(data);
        return [...list, ...extraLocal];
      }
      final data = await c.from(tableName).select(select ?? '*');
      final list = List<Map<String, dynamic>>.from(data);
      return [...list, ...extraLocal];
    } catch (e) {
      debugPrint('Error fetching table $tableName: $e');
      return [...extraLocal];
    }
  }


  Future<bool> insertRecord(String tableName, Map<String, dynamic> record) async {
    _localAppStorage.putIfAbsent(tableName, () => []).add(record);
    final c = client;
    if (c == null) return true;
    try {
      await c.from(tableName).insert(record);
      return true;
    } catch (e) {
      debugPrint('Error inserting into $tableName: $e');
      return true;
    }
  }

  Future<bool> updateRecord(String tableName, Map<String, dynamic> record, String matchColumn, dynamic matchValue) async {
    final list = _localAppStorage[tableName];
    if (list != null) {
      for (int i = 0; i < list.length; i++) {
        if (list[i][matchColumn] == matchValue) {
          list[i] = {...list[i], ...record};
        }
      }
    }
    final c = client;
    if (c == null) return true;
    try {
      await c.from(tableName).update(record).eq(matchColumn, matchValue);
      return true;
    } catch (e) {
      debugPrint('Error updating $tableName: $e');
      return true;
    }
  }

  Future<bool> deleteRecord(String tableName, String matchColumn, dynamic matchValue) async {
    _localAppStorage[tableName]?.removeWhere((item) => item[matchColumn] == matchValue);
    final c = client;
    if (c == null) return true;
    try {
      await c.from(tableName).delete().eq(matchColumn, matchValue);
      return true;
    } catch (e) {
      debugPrint('Error deleting from $tableName: $e');
      return true;
    }
  }
}
