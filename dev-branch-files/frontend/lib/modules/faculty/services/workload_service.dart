import 'supabase_client.dart';
import 'timetable_service.dart';

/// Workload Service — Single source of truth via TimetableService
///   • Timetable data from `timetable.class_timetables` (via TimetableService)
///   • Course allocations from `faculty.faculty_course_allocations`
///   • Faculty profile from `faculty.faculties`
class WorkloadService {
  /// Fetches timetable slots for a faculty member — delegates to TimetableService
  /// which queries timetable.class_timetables + faculty.faculty_course_allocations
  static Future<List<Map<String, dynamic>>> fetchFacultyTimetable(String facultyId) async {
    return TimetableService.fetchFromSupabase(facultyId: facultyId);
  }

  /// Fetches official course allocations from Supabase `faculty.faculty_course_allocations`
  static Future<List<Map<String, dynamic>>> fetchCourseAllocations(String facultyId) async {
    try {
      final response = await SupabaseClientHelper.select(
        'faculty_course_allocations',
        filterColumn: 'faculty_employee_id',
        filterValue: facultyId,
        schema: 'faculty',
      );
      if (response.isNotEmpty) {
        return response;
      }
    } catch (_) {}
    return [];
  }

  /// Fetches faculty profile workload hours & designation norms from Supabase
  static Future<Map<String, dynamic>> fetchWorkloadProfile(String facultyId) async {
    try {
      final response = await SupabaseClientHelper.select(
        'faculties',
        filterColumn: 'employee_id',
        filterValue: facultyId,
        schema: 'faculty',
      );

      if (response.isNotEmpty) {
        return response.first;
      }
    } catch (_) {}

    return {};
  }
}
