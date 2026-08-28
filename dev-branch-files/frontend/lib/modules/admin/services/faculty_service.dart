import '../shared/services/supabase_service.dart';

class FacultyService {
  static Future<List<Map<String, dynamic>>> fetchFaculty() async {
    try {
      return await SupabaseService.instance.fetchTable('faculty');
    } catch (e) {
      print('Error fetching faculty: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> addFaculty(Map<String, dynamic> data) async {
    try {
      return await SupabaseService.instance.insertData('faculty', data);
    } catch (e) {
      print('Error adding faculty: $e');
      return null;
    }
  }

  static Future<bool> updateFaculty(String id, Map<String, dynamic> data) async {
    try {
      return await SupabaseService.instance.updateData('faculty', data, id);
    } catch (e) {
      print('Error updating faculty: $e');
      return false;
    }
  }

  static Future<bool> deleteFaculty(String id) async {
    try {
      return await SupabaseService.instance.deleteData('faculty', id);
    } catch (e) {
      print('Error deleting faculty: $e');
      return false;
    }
  }
}
