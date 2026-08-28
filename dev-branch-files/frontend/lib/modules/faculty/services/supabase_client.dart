import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

class SupabaseClientHelper {
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String selectQuery = '*',
    String? filterColumn,
    String? filterValue,
    String? orderBy,
    bool ascending = true,
    String schema = 'faculty',
  }) async {
    try {
      var uri = Uri.parse('${FacultySupabaseConfig.supabaseUrl}/rest/v1/$table?select=$selectQuery');
      if (filterColumn != null && filterValue != null) {
        uri = Uri.parse('${FacultySupabaseConfig.supabaseUrl}/rest/v1/$table?select=$selectQuery&$filterColumn=eq.$filterValue');
      }
      if (orderBy != null) {
        final order = ascending ? 'asc' : 'desc';
        uri = Uri.parse('$uri&order=$orderBy.$order');
      }

      final headers = Map<String, String>.from(FacultySupabaseConfig.headers);
      if (schema.isNotEmpty) {
        headers['Accept-Profile'] = schema;
        headers['Content-Profile'] = schema;
      }

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
    } catch (_) {
      // Silently fall back to cached data without console clutter
    }
    return [];
  }

  static Future<Map<String, dynamic>?> insert(
    String table,
    Map<String, dynamic> data, {
    String schema = 'faculty',
  }) async {
    try {
      final uri = Uri.parse('${FacultySupabaseConfig.supabaseUrl}/rest/v1/$table');
      final headers = Map<String, String>.from(FacultySupabaseConfig.headers);
      if (schema.isNotEmpty) {
        headers['Accept-Profile'] = schema;
        headers['Content-Profile'] = schema;
      }
      headers['Prefer'] = 'return=representation';

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.trim().isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is List && decoded.isNotEmpty) {
            return Map<String, dynamic>.from(decoded.first as Map);
          } else if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        }
        return data;
      }
    } catch (_) {
      // Silently fall back
    }
    return null;
  }

  static Future<Map<String, dynamic>?> update(
    String table,
    Map<String, dynamic> data,
    String matchColumn,
    String matchValue, {
    String schema = 'faculty',
  }) async {
    try {
      final uri = Uri.parse('${FacultySupabaseConfig.supabaseUrl}/rest/v1/$table?$matchColumn=eq.$matchValue');
      final headers = Map<String, String>.from(FacultySupabaseConfig.headers);
      if (schema.isNotEmpty) {
        headers['Accept-Profile'] = schema;
        headers['Content-Profile'] = schema;
      }

      final response = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return Map<String, dynamic>.from(decoded.first as Map);
        }
      }
    } catch (_) {
      // Silently fall back
    }
    return null;
  }

  static Future<bool> delete(
    String table,
    String matchColumn,
    String matchValue, {
    String schema = 'faculty',
  }) async {
    try {
      final uri = Uri.parse('${FacultySupabaseConfig.supabaseUrl}/rest/v1/$table?$matchColumn=eq.$matchValue');
      final headers = Map<String, String>.from(FacultySupabaseConfig.headers);
      if (schema.isNotEmpty) {
        headers['Accept-Profile'] = schema;
        headers['Content-Profile'] = schema;
      }

      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
    } catch (_) {
      // Silently fall back
    }
    return false;
  }

  static Future<bool> upsert(
    String table,
    Map<String, dynamic> data,
    String conflictColumn, {
    String schema = 'faculty',
  }) async {
    try {
      final headers = Map<String, String>.from(FacultySupabaseConfig.headers);
      headers['Prefer'] = 'resolution=merge-duplicates,return=representation';
      if (schema.isNotEmpty) {
        headers['Accept-Profile'] = schema;
        headers['Content-Profile'] = schema;
      }

      var urlStr = '${FacultySupabaseConfig.supabaseUrl}/rest/v1/$table';
      if (conflictColumn.trim().isNotEmpty) {
        urlStr += '?on_conflict=${conflictColumn.trim()}';
      }
      final uri = Uri.parse(urlStr);
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
    } catch (_) {
      // Silently fall back
    }
    return false;
  }

  /// Multi-column filter SELECT — supports multiple eq filters for precise queries
  static Future<List<Map<String, dynamic>>> selectWithFilters(
    String table, {
    String selectQuery = '*',
    Map<String, String> filters = const {},
    String? orderBy,
    bool ascending = true,
    String schema = 'faculty',
  }) async {
    try {
      var urlStr = '${FacultySupabaseConfig.supabaseUrl}/rest/v1/$table?select=$selectQuery';
      for (final entry in filters.entries) {
        urlStr += '&${entry.key}=eq.${Uri.encodeComponent(entry.value)}';
      }
      if (orderBy != null) {
        final order = ascending ? 'asc' : 'desc';
        urlStr += '&order=$orderBy.$order';
      }

      final uri = Uri.parse(urlStr);
      final headers = Map<String, String>.from(FacultySupabaseConfig.headers);
      if (schema.isNotEmpty) {
        headers['Accept-Profile'] = schema;
        headers['Content-Profile'] = schema;
      }

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
    } catch (_) {
      // Silently fall back
    }
    return [];
  }

  static Future<Map<String, dynamic>> testConnection() async {
    if (!FacultySupabaseConfig.isConfigured) {
      return {'success': false, 'message': 'Faculty Supabase Anon Key is missing or default placeholder.'};
    }
    try {
      final headers = Map<String, String>.from(FacultySupabaseConfig.headers);
      headers['Accept-Profile'] = 'public';

      final uri = Uri.parse('${FacultySupabaseConfig.supabaseUrl}/rest/v1/regulations?select=*&limit=1');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': 'Successfully connected to Supabase database!'};
      } else {
        return {'success': false, 'message': 'HTTP ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Maps a file extension to its MIME type so uploaded files are stored with
  /// the correct Content-Type (PDFs render inline, images/open correctly, etc.).
  static String mimeTypeFor(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        : '';
    const map = <String, String>{
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'zip': 'application/zip',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  static Future<String> uploadToStorage(
    String bucket,
    String fileName,
    List<int> bytes, {
    String? mimeType,
  }) async {
    try {
      final uri = Uri.parse('${FacultySupabaseConfig.supabaseUrl}/storage/v1/object/$bucket/$fileName');
      final headers = Map<String, String>.from(FacultySupabaseConfig.headers);
      headers['Content-Type'] = mimeType ?? mimeTypeFor(fileName);
      headers['x-upsert'] = 'true';

      final response = await http.post(uri, headers: headers, body: bytes).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return '${FacultySupabaseConfig.supabaseUrl}/storage/v1/object/public/$bucket/$fileName';
      } else {
        debugPrint('Supabase Storage Upload Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Supabase Storage Upload Exception: $e');
    }
    return fileName;
  }
}

