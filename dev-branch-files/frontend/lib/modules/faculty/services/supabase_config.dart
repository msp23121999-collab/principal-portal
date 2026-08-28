import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'local_storage_base.dart';

// ============================================================
// FACULTY MODULE SUPABASE CONFIGURATION
// ============================================================
class FacultySupabaseConfig {
  static String get supabaseUrl {
    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['SUPABASE_URL'] ?? dotenv.env['FACULTY_SUPABASE_URL'];
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    }
    return 'https://jnpvzmbisqzbmhkexhwr.supabase.co';
  }

  static String get anonKey {
    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['SUPABASE_ANON_KEY'] ?? dotenv.env['FACULTY_SUPABASE_ANON_KEY'];
      if (fromEnv != null && fromEnv.isNotEmpty && (fromEnv.startsWith('sb_') || fromEnv.startsWith('ey'))) {
        return fromEnv;
      }
    }
    final stored = LocalStorageBase.readString('faculty_supabase_anon_key');
    if (stored.isNotEmpty && (stored.startsWith('sb_') || stored.startsWith('ey'))) {
      return stored;
    }
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpucHZ6bWJpc3F6Ym1oa2V4aHdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5NzQyODUsImV4cCI6MjEwMDU1MDI4NX0.pvD3I3P_8W_KjCX2BSwTyooRUzN8h6DeOl_LPP5-FDw';
  }

  static String get serviceRoleKey {
    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? dotenv.env['FACULTY_SUPABASE_SERVICE_ROLE_KEY'];
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    }
    return 'sb_secret_Jk1mqYX9Yf8O5UP7Jzen-w_qfN4xMMz';
  }

  static String get connectionString {
    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['SUPABASE_CONNECTION_STRING'] ?? dotenv.env['FACULTY_SUPABASE_CONNECTION_STRING'];
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    }
    return 'postgresql://postgres.jnpvzmbisqzbmhkexhwr:Paaswoord%40123@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres';
  }

  static void setAnonKey(String key) {
    LocalStorageBase.writeString('faculty_supabase_anon_key', key.trim());
  }

  static bool get isConfigured =>
      anonKey.isNotEmpty && anonKey != 'YOUR_SUPABASE_ANON_KEY';

  static String get activeKey {
    final aKey = anonKey;
    if (aKey.isNotEmpty && (aKey.startsWith('sb_') || aKey.startsWith('ey'))) {
      return aKey;
    }
    return serviceRoleKey;
  }

  static Map<String, String> get headers => {
        'apikey': activeKey,
        'Authorization': 'Bearer $activeKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };
}
