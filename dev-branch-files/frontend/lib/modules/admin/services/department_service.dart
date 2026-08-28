import '../shared/services/supabase_service.dart';

class DepartmentService {
  static Future<List<Map<String, dynamic>>> fetchDepartments() async {
    try {
      final departments = await SupabaseService.instance.fetchTable('departments');
      return departments;
    } catch (e) {
      print('Error fetching departments: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createDepartment(Map<String, dynamic> data) async {
    try {
      return await SupabaseService.instance.insertData('departments', data);
    } catch (e) {
      print('Error creating department: $e');
      return null;
    }
  }

  static Future<bool> updateDepartment(String id, Map<String, dynamic> data) async {
    try {
      return await SupabaseService.instance.updateData('departments', data, id);
    } catch (e) {
      print('Error updating department: $e');
      return false;
    }
  }

  static Future<bool> deleteDepartment(String id) async {
    try {
      return await SupabaseService.instance.deleteData('departments', id);
    } catch (e) {
      print('Error deleting department: $e');
      return false;
    }
  }
}
