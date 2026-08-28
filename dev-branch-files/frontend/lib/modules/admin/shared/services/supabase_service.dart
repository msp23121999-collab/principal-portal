import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase service used across the admin module.
///
/// Provides a singleton instance and thin wrappers around the Supabase
/// client for common table operations (select / insert / update / delete).
class SupabaseService {
  SupabaseService._internal();

  static final SupabaseService _instance = SupabaseService._internal();

  static SupabaseService get instance => _instance;

  bool _initialized = false;

  /// Returns the underlying Supabase client.
  SupabaseClient get client => Supabase.instance.client;

  /// Returns whether Supabase has been initialized.
  bool get isInitialized => _initialized;

  /// Initialize Supabase with credentials from the environment.
  Future<void> initialize() async {
    if (_initialized) return;

    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      // No credentials configured - run in offline / fallback mode.
      _initialized = true;
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
  }

  /// Fetch rows from [tableName].
  ///
  /// [select] allows custom column selection (defaults to `*`).
  /// [filter] accepts a PostgREST filter string such as `id.eq.123`.
  Future<List<Map<String, dynamic>>> fetchTable(
    String tableName, {
    String select = '*',
    String? filter,
  }) async {
    try {
      var query = client.from(tableName).select(select);
      if (filter != null && filter.isNotEmpty) {
        query = query.filter(
          filter.split('.').first,
          filter.split('.')[1],
          filter.split('.').sublist(2).join('.'),
        );
      }
      final data = await query;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('SupabaseService.fetchTable error ($tableName): $e');
      return [];
    }
  }

  /// Insert a single row into [tableName].
  Future<Map<String, dynamic>?> insertData(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    try {
      final cleanData = Map<String, dynamic>.from(data);
      if (cleanData.containsKey('id')) {
        final idVal = cleanData['id']?.toString() ?? '';
        final isUuid = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(idVal);
        if (!isUuid) {
          cleanData.remove('id');
        }
      }
      final result = await client
          .from(tableName)
          .insert(cleanData)
          .select()
          .maybeSingle();
      return result != null ? Map<String, dynamic>.from(result) : cleanData;
    } catch (e) {
      debugPrint('SupabaseService.insertData error ($tableName): $e');
      return null;
    }
  }

  /// Update rows in [tableName] where the `id` column equals [filterId].
  Future<bool> updateData(
    String tableName,
    Map<String, dynamic> data,
    String filterId,
  ) async {
    try {
      await client.from(tableName).update(data).eq('id', filterId);
      return true;
    } catch (e) {
      debugPrint('SupabaseService.updateData error ($tableName): $e');
      return false;
    }
  }

  /// Delete rows in [tableName] where the `id` column equals [filterId].
  Future<bool> deleteData(String tableName, String filterId) async {
    try {
      await client.from(tableName).delete().eq('id', filterId);
      return true;
    } catch (e) {
      debugPrint('SupabaseService.deleteData error ($tableName): $e');
      return false;
    }
  }
}
