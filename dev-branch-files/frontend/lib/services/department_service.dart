import '../shared/services/supabase_service.dart';

class DepartmentService {
  static Future<List<Map<String, dynamic>>> fetchDepartments() async {
    final departments = await SupabaseService.instance.fetchTable(
      'departments',
    );
    return departments.isNotEmpty ? departments : _fallbackDepartments();
  }

  static List<Map<String, dynamic>> _fallbackDepartments() {
    return [
      {
        'code': 'CSE',
        'name': 'Computer Science & Engineering',
        'hod_name': 'Dr. Suresh Kumar',
        'student_count': 720,
        'faculty_count': 42,
        'status': 'Active',
      },
      {
        'code': 'IT',
        'name': 'Information Technology',
        'hod_name': 'Dr. V. Priya',
        'student_count': 480,
        'faculty_count': 28,
        'status': 'Active',
      },
    ];
  }
}
