import '../shared/services/supabase_service.dart';

class StudentService {
  static Future<List<Map<String, dynamic>>> fetchStudents() async => await SupabaseService.instance.fetchTable('students');
}
