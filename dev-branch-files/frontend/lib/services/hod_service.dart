import '../shared/services/supabase_service.dart';

class HodService {
  static Future<List<Map<String, dynamic>>> fetchHods() async {
    final hods = await SupabaseService.instance.fetchTable('hods');
    return hods.isNotEmpty ? hods : _fallbackHods();
  }

  static List<Map<String, dynamic>> _fallbackHods() {
    return [
      {
        'emp_id': 'HOD-CSE-001',
        'name': 'Dr. Suresh Kumar',
        'department_code': 'CSE',
        'status': 'Active',
      },
      {
        'emp_id': 'HOD-IT-002',
        'name': 'Dr. V. Priya',
        'department_code': 'IT',
        'status': 'Active',
      },
    ];
  }
}
