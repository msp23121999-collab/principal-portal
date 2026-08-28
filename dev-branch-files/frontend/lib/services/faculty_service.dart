import '../shared/services/supabase_service.dart';

class FacultyService {
  static Future<List<Map<String, dynamic>>> fetchFaculty() async {
    final faculty = await SupabaseService.instance.fetchTable('faculty');
    return faculty.isNotEmpty ? faculty : _fallbackFaculty();
  }

  static List<Map<String, dynamic>> _fallbackFaculty() {
    return [
      {
        'emp_id': 'EMP-CSE-001',
        'name': 'Dr. Suresh Kumar',
        'designation': 'Professor & HOD',
        'department_code': 'CSE',
        'experience_years': '18 Years',
        'status': 'Active',
      },
      {
        'emp_id': 'EMP-IT-002',
        'name': 'Dr. V. Priya',
        'designation': 'Associate Professor',
        'department_code': 'IT',
        'experience_years': '14 Years',
        'status': 'Active',
      },
    ];
  }
}
