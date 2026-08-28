import 'package:flutter/foundation.dart';
import 'supabase_client.dart';

/// Grievances Service (Faculty Portal)
/// Interacts with `student.grievances` table in Supabase DB.
/// Only fetches grievances where recipient is chosen as Faculty / Mentor Faculty.
class GrievancesService {
  /// Fetches grievances assigned to Faculty from `student.grievances`
  /// Only fetches if current faculty ID matches recipient_id
  static Future<List<Map<String, dynamic>>> fetchFacultyGrievances({required String facultyId}) async {
    try {
      final response = await SupabaseClientHelper.select(
        'grievances',
        schema: 'student',
      );

      if (response.isNotEmpty) {
        final currentIdClean = facultyId.trim().toLowerCase();

        // Filter strictly where recipient_id matches current logged-in faculty ID
        final filtered = response.where((g) {
          final recipientId = (g['recipient_id'] ?? g['recipientId'] ?? '').toString().trim().toLowerCase();
          return recipientId == currentIdClean;
        }).map((e) {
          final Map<String, dynamic> item = Map<String, dynamic>.from(e);
          final studentId = (item['student_id'] ?? '').toString();
          final rawName = item['student_name']?.toString();
          
          item['studentName'] = (rawName != null && rawName.isNotEmpty) ? rawName : 'Student ($studentId)';
          item['studentRoll'] = item['student_roll'] ?? studentId;
          item['classSec'] = item['class_sec'] ?? 'CSE - A';
          item['priority'] = item['priority'] ?? 'Medium';
          item['status'] = item['status'] ?? 'Pending';
          item['recipientId'] = item['recipient_id'] ?? '';
          item['date'] = item['date'] ?? (item['created_at'] != null ? item['created_at'].toString().substring(0, 10) : '2026-08-10');
          return item;
        }).toList();

        // Sort latest grievances first
        filtered.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
        return filtered;
      }
    } catch (e) {
      debugPrint('Error fetching student grievances from Supabase: $e');
    }
    return [];
  }

  /// Updates status and faculty response/remarks for a grievance in `student.grievances`
  static Future<bool> updateGrievanceStatus({
    required String grievanceId,
    required String status,
    String? response,
    String? remarks,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status,
        'response': response,
        'remarks': remarks,
        'updated_at': DateTime.now().toIso8601String(),
      };
      payload.removeWhere((key, value) => value == null);

      final res = await SupabaseClientHelper.update(
        'grievances',
        payload,
        'id',
        grievanceId,
        schema: 'student',
      );
      return res != null;
    } catch (e) {
      debugPrint('Error updating grievance status in Supabase: $e');
      return false;
    }
  }
}
