import 'package:flutter/foundation.dart';
import '../shared/services/supabase_service.dart';

/// Static helper for admin-specific Supabase operations.
///
/// Provides `select` / `insert` / `update` / `delete` wrappers used by the
/// admin pages. Supports an optional schema and ordering.
class AdminSupabaseClient {
  /// Fetch rows from [table].
  ///
  /// [schema] selects a PostgREST schema (e.g. `admin`, `public`).
  /// [orderBy] / [ascending] control the result ordering.
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? schema,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      dynamic query = schema != null
          ? SupabaseService.instance.client.schema(schema).from(table).select('*')
          : SupabaseService.instance.client.from(table).select('*');
      if (orderBy != null && orderBy.isNotEmpty) {
        query = query.order(orderBy, ascending: ascending);
      }
      final data = await query;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('AdminSupabaseClient.select error ($table): $e');
      return [];
    }
  }

  /// Insert a single row into [table].
  static Future<Map<String, dynamic>?> insert(
    String table,
    Map<String, dynamic> data,
    {String? schema}
  ) async {
    try {
      final from = schema != null ? SupabaseService.instance.client.schema(schema).from(table) : SupabaseService.instance.client.from(table);
      final result = await from
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('AdminSupabaseClient.insert error ($table): $e');
      return null;
    }
  }

  /// Update rows in [table] where [idColumn] equals [id].
  static Future<bool> update(
    String table,
    Map<String, dynamic> data,
    String idColumn,
    String id,
    {String? schema}
  ) async {
    try {
      final from = schema != null ? SupabaseService.instance.client.schema(schema).from(table) : SupabaseService.instance.client.from(table);
      await from.update(data)
          .eq(idColumn, id);
      return true;
    } catch (e) {
      debugPrint('AdminSupabaseClient.update error ($table): $e');
      return false;
    }
  }

  /// Delete rows in [table] where [idColumn] equals [id].
  static Future<bool> delete(
    String table,
    String idColumn,
    String id,
    {String? schema}
  ) async {
    try {
      final from = schema != null ? SupabaseService.instance.client.schema(schema).from(table) : SupabaseService.instance.client.from(table);
      await from.delete()
          .eq(idColumn, id);
      return true;
    } catch (e) {
      debugPrint('AdminSupabaseClient.delete error ($table): $e');
      return false;
    }
  }
}