import '../shared/services/supabase_service.dart';

/// Lightweight helper for direct Supabase table queries.
class SupabaseClientHelper {
  /// Fetch rows from [table].
  ///
  /// [schema] selects a PostgREST schema (e.g. `public`, `admin`).
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? schema,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final query = schema != null && schema.isNotEmpty
          ? client.schema(schema).from(table).select('*')
          : client.from(table).select('*');
      final data = orderBy != null
          ? await query.order(orderBy, ascending: ascending)
          : await query;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('SupabaseClientHelper.select error ($table): $e');
      return [];
    }
  }
}
