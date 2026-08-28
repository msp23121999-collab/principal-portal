import '../shared/services/supabase_service.dart';

class StudentService {
  static Future<List<Map<String, dynamic>>> fetchStudents() async {
    return await SupabaseService.instance.fetchTable('students');
  }
}
