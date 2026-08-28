import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DeanSupabaseConfig {
  static String get supabaseUrl {
    try {
      if (dotenv.isInitialized) {
        final envUrl = dotenv.env['SUPABASE_URL'];
        if (envUrl != null && envUrl.isNotEmpty) {
          final trimmed = envUrl.trim();
          return trimmed.replaceFirst(RegExp(r'/rest/v1/?$'), '').replaceFirst(RegExp(r'/+$'), '');
        }
      }
    } catch (_) {}
    return 'https://jnpvzmbisqzbmhkexhwr.supabase.co';
  }

  static String get publishableKey {
    try {
      if (dotenv.isInitialized) {
        final envKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'];
        if (envKey != null && envKey.isNotEmpty) return envKey;
      }
    } catch (_) {}
    return '';
  }

  static Map<String, String> getHeaders(String schema) {
    final keyToUse = publishableKey;
    if (keyToUse.isEmpty) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY is not configured. Do not use a service-role secret in Flutter.');
    }
    return {
      'apikey': keyToUse,
      'Authorization': 'Bearer $keyToUse',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
      if (schema.isNotEmpty) 'Accept-Profile': schema,
      if (schema.isNotEmpty) 'Content-Profile': schema,
    };
  }
}

class DeanSupabaseService {
  DeanSupabaseService._privateConstructor();
  static final DeanSupabaseService instance = DeanSupabaseService._privateConstructor();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    print('[DEAN TRACE] Supabase initialize START');
    try {
      if (!dotenv.isInitialized) {
        try {
          await dotenv.load(fileName: '.env');
          print('[DEAN TRACE] dotenv load success');
        } catch (e, stackTrace) {
          print('[DEAN TRACE] dotenv load failure: $e');
          debugPrintStack(stackTrace: stackTrace);
          return;
        }
      } else {
        print('[DEAN TRACE] dotenv load success');
      }

      final urlLoaded = dotenv.env['SUPABASE_URL'] != null && dotenv.env['SUPABASE_URL']!.isNotEmpty;
      final keyLoaded = (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY']) != null &&
          ((dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'])!.isNotEmpty);

      print('[DEAN TRACE] SUPABASE_URL loaded: ${urlLoaded ? 'true' : 'false'}');
      print('[DEAN TRACE] SUPABASE_PUBLISHABLE_KEY loaded: ${keyLoaded ? 'true' : 'false'}');
    } catch (e, stackTrace) {
      print('[DEAN TRACE] Supabase initialize EXCEPTION: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
    print('[DEAN TRACE] Supabase initialize COMPLETE');
  }

  // --- Helper REST SELECT Function ---
  Future<List<Map<String, dynamic>>> _select(
    String table, {
    String selectQuery = '*',
    String? filterColumn,
    String? filterValue,
    String? orderBy,
    bool ascending = true,
    required String schema,
  }) async {
    try {
      var urlStr = '${DeanSupabaseConfig.supabaseUrl}/rest/v1/$table?select=$selectQuery';
      if (filterColumn != null && filterValue != null) {
        urlStr += '&$filterColumn=eq.$filterValue';
      }
      if (orderBy != null) {
        final order = ascending ? 'asc' : 'desc';
        urlStr += '&order=$orderBy.$order';
      }

      final uri = Uri.parse(urlStr);
      final headers = DeanSupabaseConfig.getHeaders(schema);
      print('[DEAN TRACE] HTTP request $schema.$table URL: ${uri.toString()}');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));

      print('[DEAN TRACE] HTTP status $schema.$table: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final result = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          print('[DEAN TRACE] rows returned $schema.$table: ${result.length}');
          return result;
        }
      } else if (response.statusCode == 401) {
        print('[DEAN TRACE] authentication issue $schema.$table: true');
      } else if (response.statusCode == 403) {
        print('[DEAN TRACE] authentication issue $schema.$table: false');
      } else {
        print('[DEAN TRACE] HTTP status $schema.$table: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('[DEAN TRACE] HTTP request exception $table: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
    print('[DEAN TRACE] rows returned $schema.$table: 0');
    return [];
  }

  // --- 1. Fetch Students List (Schema: public, Table: students) ---
  Future<List<Map<String, dynamic>>> getStudentsList() async {
    return await _select('students', schema: 'public');
  }

  // --- 2. Fetch Faculties List (Schema: public, Table: faculties) ---
  Future<List<Map<String, dynamic>>> getFacultiesList() async {
    return await _select('faculties', schema: 'public');
  }

  // --- 3. Fetch Departments List (Schema: public, Table: departments) ---
  Future<List<Map<String, dynamic>>> getDepartmentsList() async {
    return await _select('departments', schema: 'public');
  }

  // --- 4. Fetch Curriculum Regulations (Dean-specific governance table preferred) ---
  Future<List<Map<String, dynamic>>> getRegulationsList() async {
    final deanList = await _select('dean_regulations', orderBy: 'created_at', ascending: false, schema: 'dean');
    if (deanList.isNotEmpty) return deanList;
    final list = await _select('regulations', schema: 'public');
    if (list.isNotEmpty) return list;
    return [];
  }

  // --- 5. Fetch Academic Calendar Events (Dean-owned calendar preferred) ---
  Future<List<Map<String, dynamic>>> getCalendarEvents() async {
    final deanList = await _select('dean_calendar_events', orderBy: 'event_date', ascending: true, schema: 'dean');
    if (deanList.isNotEmpty) return deanList;
    final list = await _select('academic_calendar_events', orderBy: 'event_date', ascending: true, schema: 'public');
    if (list.isNotEmpty) return list;
    return [];
  }

  // --- 6. Fetch Research Projects (Schema: public, Table: hod_research_contributions) ---
  Future<List<Map<String, dynamic>>> getResearchProjects() async {
    return await _select('hod_research_contributions', schema: 'public');
  }

  // --- 7. Fetch Faculty Approvals (Dean approval queue) ---
  Future<List<Map<String, dynamic>>> getFacultyApprovals() async {
    print('[DEAN TRACE] GET dean.dean_academic_approvals START');
    final deanList = await _select('dean_academic_approvals', orderBy: 'created_at', ascending: false, schema: 'dean');
    print('[DEAN TRACE] rows returned dean.dean_academic_approvals: ${deanList.length}');
    return deanList;
  }

  // --- 8. Fetch Examination Marks & Mark Sheets (Schema: public, Table: student_marks) ---
  Future<List<Map<String, dynamic>>> getExaminationMarks() async {
    return await _select('student_marks', schema: 'public');
  }

  // --- 9. Fetch Mark Sheet Statuses - NOT AVAILABLE ---
  /// Note: mark_sheet_statuses table does not exist in the database.
  /// Marks status can be found in student_marks.status column (DRAFT, SUBMITTED, APPROVED).
  Future<List<Map<String, dynamic>>> getMarkSheetStatuses() async {
    debugPrint('getMarkSheetStatuses() called - no table exists. Use getExaminationMarks() instead.');
    return [];
  }

  // --- 10. Fetch Placements List - NOT AVAILABLE ---
  /// Note: placements table does not exist in the database.
  /// Placement data tracking would need to be added to the schema.
  Future<List<Map<String, dynamic>>> getPlacementsList() async {
    debugPrint('getPlacementsList() called - no placements table exists in database.');
    return [];
  }

  // --- 11. Fetch Placement Applications - NOT AVAILABLE ---
  /// Note: placement_applications table does not exist in the database.
  Future<List<Map<String, dynamic>>> getPlacementApplications() async {
    debugPrint('getPlacementApplications() called - no placement_applications table exists in database.');
    return [];
  }

  // --- 12. Dean-specific entity accessors ---
  Future<List<Map<String, dynamic>>> getDeanAcademicApprovals() async {
    return await _select('dean_academic_approvals', orderBy: 'created_at', ascending: false, schema: 'dean');
  }

  Future<List<Map<String, dynamic>>> getDeanCalendarEvents() async {
    return await _select('dean_calendar_events', orderBy: 'event_date', ascending: true, schema: 'dean');
  }

  Future<List<Map<String, dynamic>>> getDeanNotifications() async {
    return await _select('dean_notifications', orderBy: 'created_at', ascending: false, schema: 'dean');
  }

  Future<List<Map<String, dynamic>>> getDeanRegulations() async {
    return await _select('dean_regulations', orderBy: 'created_at', ascending: false, schema: 'dean');
  }

  Future<List<Map<String, dynamic>>> getDeanMeetings() async {
    print('[DEAN TRACE] getDeanMeetings START');
    print('[DEAN TRACE] GET dean.dean_meetings');
    final result = await _select('dean_meetings', orderBy: 'scheduled_at', ascending: true, schema: 'dean');
    print('[DEAN TRACE] rows returned dean.dean_meetings: ${result.length}');
    return result;
  }

  Future<List<Map<String, dynamic>>> getDeanExaminationSignoffs() async {
    return await _select('dean_examination_signoffs', schema: 'dean');
  }

  Future<Map<String, dynamic>?> updateExaminationSignoff(String id, Map<String, dynamic> payload) async {
    return await _update('dean_examination_signoffs', 'id', id, payload, schema: 'dean');
  }

  Future<List<Map<String, dynamic>>> getDeanRepositoryDocuments() async {
    return await _select('dean_repository_documents', orderBy: 'created_at', ascending: false, schema: 'dean');
  }

  // --- 13. Dean CRUD operations ---
  Future<Map<String, dynamic>?> createAcademicApproval(Map<String, dynamic> payload) async {
    return await _insert('dean_academic_approvals', payload, schema: 'dean');
  }

  Future<Map<String, dynamic>?> updateAcademicApproval(String requestId, Map<String, dynamic> payload) async {
    return await _update('dean_academic_approvals', 'request_id', requestId, payload, schema: 'dean');
  }

  Future<Map<String, dynamic>?> createCalendarEvent(Map<String, dynamic> payload) async {
    return await _insert('dean_calendar_events', payload, schema: 'dean');
  }

  Future<Map<String, dynamic>?> updateCalendarEvent(String eventId, Map<String, dynamic> payload) async {
    return await _update('dean_calendar_events', 'id', eventId, payload, schema: 'dean');
  }

  Future<Map<String, dynamic>?> createDeanNotification(Map<String, dynamic> payload) async {
    return await _insert('dean_notifications', payload, schema: 'dean');
  }

  Future<Map<String, dynamic>?> createMeeting(Map<String, dynamic> payload) async {
    return await _insert('dean_meetings', payload, schema: 'dean');
  }

  Future<Map<String, dynamic>?> addRepositoryMetadata(Map<String, dynamic> payload) async {
    return await _insert('dean_repository_documents', payload, schema: 'dean');
  }

  Future<bool> deleteRepositoryDocument(String documentId) async {
    return await _delete('dean_repository_documents', 'id', documentId, schema: 'dean');
  }

  Future<List<Map<String, dynamic>>> listRepositoryStorageFiles({String bucket = 'dean-repository'}) async {
    try {
      final uri = Uri.parse('${DeanSupabaseConfig.supabaseUrl}/storage/v1/object/list/$bucket');
      final headers = DeanSupabaseConfig.getHeaders('public');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'prefix': ''}),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Supabase storage list exception: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> uploadRepositoryFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    String contentType = 'application/octet-stream',
  }) async {
    try {
      final uri = Uri.parse('${DeanSupabaseConfig.supabaseUrl}/storage/v1/object/$bucket/$path');
      final headers = DeanSupabaseConfig.getHeaders('public');
      headers['Content-Type'] = contentType;
      final response = await http.post(uri, headers: headers, body: bytes).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('Supabase storage upload exception: $e');
    }
    return null;
  }

  Future<bool> deleteRepositoryFile({required String bucket, required String path}) async {
    try {
      final uri = Uri.parse('${DeanSupabaseConfig.supabaseUrl}/storage/v1/object/$bucket/$path');
      final headers = DeanSupabaseConfig.getHeaders('public');
      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Supabase storage delete exception: $e');
    }
    return false;
  }

  Future<String?> getRepositorySignedUrl({required String bucket, required String path, int expiresInSeconds = 3600}) async {
    try {
      final uri = Uri.parse('${DeanSupabaseConfig.supabaseUrl}/storage/v1/object/sign/$bucket/$path?expiresIn=$expiresInSeconds');
      final headers = DeanSupabaseConfig.getHeaders('public');
      final response = await http.post(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return decoded['signedURL']?.toString() ?? decoded['signedUrl']?.toString();
        }
      }
    } catch (e) {
      debugPrint('Supabase storage signed URL exception: $e');
    }
    return null;
  }

  // --- 14. Insert Notification into dean_notifications with role ---
  Future<Map<String, dynamic>?> insertNotification({
    required String title,
    required String description,
    required String role,
    String category = 'GENERAL',
    String priority = 'MEDIUM',
    String source = 'Dean Office',
    String type = 'ANNOUNCEMENT',
    String? facultyEmployeeId,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'content': description,
      'message': description,
      'role': role,
      'category': category,
      'priority': priority,
      'source': source,
      'type': type,
      'status': 'PUBLISHED',
      'is_read': false,
      'read_count': 0,
      'total_count': 1,
      if (facultyEmployeeId != null && facultyEmployeeId.isNotEmpty)
        'faculty_employee_id': facultyEmployeeId,
    };
    return await createDeanNotification(payload);
  }

  // --- Helper REST INSERT Function ---
  Future<Map<String, dynamic>?> _insert(String table, Map<String, dynamic> data, {required String schema}) async {
    try {
      final uri = Uri.parse('${DeanSupabaseConfig.supabaseUrl}/rest/v1/$table');
      final headers = DeanSupabaseConfig.getHeaders(schema);
      final response = await http.post(uri, headers: headers, body: jsonEncode(data)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return Map<String, dynamic>.from(decoded.first as Map);
        } else if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('Supabase INSERT $table [$schema] Exception: $e');
    }
    return null;
  }

  // --- Helper REST UPDATE Function ---
  Future<Map<String, dynamic>?> _update(String table, String filterColumn, String filterValue, Map<String, dynamic> data, {required String schema}) async {
    try {
      final uri = Uri.parse('${DeanSupabaseConfig.supabaseUrl}/rest/v1/$table?$filterColumn=eq.${Uri.encodeComponent(filterValue)}');
      final headers = DeanSupabaseConfig.getHeaders(schema);
      final response = await http.patch(uri, headers: headers, body: jsonEncode(data)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return Map<String, dynamic>.from(decoded.first as Map);
        } else if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('Supabase UPDATE $table [$schema] Exception: $e');
    }
    return null;
  }

  // --- Helper REST DELETE Function ---
  Future<bool> _delete(String table, String filterColumn, String filterValue, {required String schema}) async {
    try {
      final uri = Uri.parse('${DeanSupabaseConfig.supabaseUrl}/rest/v1/$table?$filterColumn=eq.$filterValue');
      final headers = DeanSupabaseConfig.getHeaders(schema);
      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 4));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Supabase DELETE $table [$schema] Exception: $e');
      return false;
    }
  }

  // --- Add & Delete Academic Calendar Event ---
  Future<Map<String, dynamic>?> addCalendarEvent(Map<String, dynamic> payload) async {
    return await _insert('dean_calendar_events', payload, schema: 'dean');
  }

  Future<bool> deleteCalendarEvent(String eventId) async {
    return await _delete('dean_calendar_events', 'id', eventId, schema: 'dean');
  }

  // ============================================================================
  // COMPREHENSIVE DATA RETRIEVAL FOR DEAN ANALYTICS
  // ============================================================================

  // --- ATTENDANCE DATA ---
  /// Fetch all student attendance records for analytics
  Future<List<Map<String, dynamic>>> getStudentAttendanceRecords() async {
    return await _select('attendance_table', orderBy: 'date', ascending: false, schema: 'student');
  }

  /// Fetch attendance records for a specific student
  Future<List<Map<String, dynamic>>> getStudentAttendanceByReg(String regNo) async {
    return await _select('attendance_table', filterColumn: 'reg_no', filterValue: regNo, schema: 'student');
  }

  /// Fetch class-wise attendance summary
  Future<List<Map<String, dynamic>>> getClassAttendanceSummary() async {
    return await _select('attendance_table', schema: 'student');
  }

  /// Fetch faculty session attendance records (Schema: public, Table: attendance_sessions)
  Future<List<Map<String, dynamic>>> getFacultyAttendanceSessions() async {
    return await _select('attendance_sessions', orderBy: 'session_date', ascending: false, schema: 'public');
  }

  // --- FACULTY DATA & PERFORMANCE ---
  /// Fetch faculty course allocations - NOT AVAILABLE
  /// Note: faculty_course_allocations table does not exist in the database.
  Future<List<Map<String, dynamic>>> getFacultyCourseAllocations() async {
    debugPrint('getFacultyCourseAllocations() called - no table exists in database.');
    return [];
  }

  /// Fetch all faculty timetables (Schema: public, Table: timetables)
  Future<List<Map<String, dynamic>>> getFacultyTimetables() async {
    return await _select('timetables', schema: 'public');
  }

  /// Fetch lesson plans for progress tracking - NOT AVAILABLE
  /// Note: lesson_plans table does not exist in the database.
  /// Alternative: Use hod_course_diaries which tracks syllabus completion.
  Future<List<Map<String, dynamic>>> getLessonPlans() async {
    debugPrint('getLessonPlans() called - no lesson_plans table. Use getCourseDiary() instead.');
    return [];
  }

  /// Fetch lesson plans by faculty - NOT AVAILABLE
  /// Note: lesson_plans table does not exist in the database.
  Future<List<Map<String, dynamic>>> getLessonPlansByFaculty(String employeeId) async {
    debugPrint('getLessonPlansByFaculty() called - no lesson_plans table exists.');
    return [];
  }

  /// Fetch syllabus uploads for compliance checking - NOT AVAILABLE
  /// Note: syllabus_uploads table does not exist in the database.
  /// Alternative: Use hod_department_files with category='Syllabus & Curriculum'
  Future<List<Map<String, dynamic>>> getSyllabusUploads() async {
    debugPrint('getSyllabusUploads() called - no syllabus_uploads table. Use getDepartmentFiles() instead.');
    return [];
  }

  /// Fetch leave applications (Schema: public, Table: hod_leave_requests)
  Future<List<Map<String, dynamic>>> getFacultyLeaveApplications() async {
    return await _select('hod_leave_requests', schema: 'public');
  }

  /// Fetch assignments - NOT AVAILABLE
  /// Note: assignments table does not exist in the database.
  /// Alternative: Use assignment_marks which contains assignment submission records.
  Future<List<Map<String, dynamic>>> getFacultyAssignments() async {
    debugPrint('getFacultyAssignments() called - no assignments table. Use getAssignmentMarks() instead.');
    return [];
  }

  /// Fetch assignment marks
  Future<List<Map<String, dynamic>>> getAssignmentMarks() async {
    return await _select('assignment_marks', schema: 'faculty');
  }

  // --- EXAMINATION & MARKS DATA ---
  /// Fetch all marks records (Schema: public, Table: student_marks)
  Future<List<Map<String, dynamic>>> getAllMarksRecords() async {
    return await _select('student_marks', orderBy: 'created_at', ascending: false, schema: 'public');
  }

  /// Fetch marks by student (Schema: public, Table: student_marks)
  Future<List<Map<String, dynamic>>> getMarksByStudent(String studentId) async {
    return await _select('student_marks', filterColumn: 'student_id', filterValue: studentId, schema: 'public');
  }

  /// Fetch marks by faculty (Schema: public, Table: student_marks)
  Future<List<Map<String, dynamic>>> getMarksByFaculty(String employeeId) async {
    return await _select('student_marks', filterColumn: 'faculty_id', filterValue: employeeId, schema: 'public');
  }

  // --- DEPARTMENT & ADMINISTRATIVE DATA ---
  /// Fetch class advisers (Schema: public, Table: hod_class_advisers)
  Future<List<Map<String, dynamic>>> getClassAdvisers() async {
    return await _select('hod_class_advisers', schema: 'public');
  }

  /// Fetch mentor assignments (Schema: public, Table: hod_mentors)
  Future<List<Map<String, dynamic>>> getMentorAssignments() async {
    return await _select('hod_mentors', schema: 'public');
  }

  /// Fetch department events (Schema: public, Table: hod_events)
  Future<List<Map<String, dynamic>>> getDepartmentEvents() async {
    return await _select('hod_events', orderBy: 'start_date', ascending: false, schema: 'public');
  }

  /// Fetch department notices (Schema: public, Table: hod_notifications)
  Future<List<Map<String, dynamic>>> getDepartmentNotices() async {
    return await _select('hod_notifications', orderBy: 'created_at', ascending: false, schema: 'public');
  }

  /// Fetch course diary records (Schema: public, Table: hod_course_diaries)
  Future<List<Map<String, dynamic>>> getCourseDiary() async {
    return await _select('hod_course_diaries', schema: 'public');
  }

  /// Fetch department files (Schema: public, Table: hod_department_files)
  Future<List<Map<String, dynamic>>> getDepartmentFiles() async {
    return await _select('hod_department_files', schema: 'public');
  }

  /// Fetch audit logs - NOT AVAILABLE
  /// Note: audit_logs table does not exist in the database.
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    debugPrint('getAuditLogs() called - no audit_logs table exists in database.');
    return [];
  }

  // --- ACADEMIC STRUCTURE DATA ---
  /// Fetch all subjects
  Future<List<Map<String, dynamic>>> getSubjects() async {
    return await _select('subjects', schema: 'public');
  }

  /// Fetch class sections
  Future<List<Map<String, dynamic>>> getClassSections() async {
    return await _select('class_sections', schema: 'public');
  }

  /// Fetch academic years
  Future<List<Map<String, dynamic>>> getAcademicYears() async {
    return await _select('academic_years', schema: 'public');
  }

  /// Fetch all users (for role/permission checking)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await _select('users', schema: 'public');
  }

  // --- CALCULATED/AGGREGATED DATA HELPERS ---
  /// Calculate average CGPA across all students
  Future<double> calculateAverageCGPA() async {
    final students = await getStudentsList();
    if (students.isEmpty) return 0.0;
    
    double totalCGPA = 0;
    int count = 0;
    for (final student in students) {
      final cgpa = double.tryParse((student['cgpa'] ?? 0).toString()) ?? 0.0;
      if (cgpa > 0) {
        totalCGPA += cgpa;
        count++;
      }
    }
    return count > 0 ? totalCGPA / count : 0.0;
  }

  /// Calculate overall pass percentage from marks data
  Future<double> calculateOverallPassPercentage() async {
    final marks = await getAllMarksRecords();
    if (marks.isEmpty) return 0.0;
    
    int passCount = 0;
    for (final mark in marks) {
      final grade = mark['grade']?.toString().toUpperCase() ?? '';
      if (grade.isNotEmpty && grade != 'F' && grade != 'RA') {
        passCount++;
      }
    }
    return marks.isNotEmpty ? (passCount / marks.length) * 100 : 0.0;
  }

  /// Calculate attendance percentage for a student
  Future<double> calculateStudentAttendancePercentage(String regNo) async {
    final records = await getStudentAttendanceByReg(regNo);
    if (records.isEmpty) return 0.0;
    
    int presentDays = 0;
    int totalDays = records.length;
    
    for (final record in records) {
      final p1 = record['p1'] as bool? ?? false;
      final p2 = record['p2'] as bool? ?? false;
      final p3 = record['p3'] as bool? ?? false;
      final p4 = record['p4'] as bool? ?? false;
      final p5 = record['p5'] as bool? ?? false;
      final p6 = record['p6'] as bool? ?? false;
      final p7 = record['p7'] as bool? ?? false;
      
      // Count days with at least one present period
      if (p1 || p2 || p3 || p4 || p5 || p6 || p7) {
        presentDays++;
      }
    }
    
    return totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;
  }

  /// Calculate backlog percentage (students with failing grades)
  Future<double> calculateBacklogPercentage() async {
    final students = await getStudentsList();
    final marks = await getAllMarksRecords();
    
    if (students.isEmpty) return 0.0;
    
    Set<String> backlogStudents = {};
    for (final mark in marks) {
      final grade = mark['grade']?.toString().toUpperCase() ?? '';
      if (grade == 'F' || grade == 'RA') {
        final studentId = mark['student_id']?.toString() ?? '';
        if (studentId.isNotEmpty) {
          backlogStudents.add(studentId);
        }
      }
    }
    
    return students.isNotEmpty ? (backlogStudents.length / students.length) * 100 : 0.0;
  }

  /// Get department-wise student distribution
  Future<Map<String, int>> getDepartmentWiseStudentCount() async {
    final students = await getStudentsList();
    final deptCounts = <String, int>{};
    
    for (final student in students) {
      final dept = student['department']?.toString() ?? 'Unknown';
      deptCounts[dept] = (deptCounts[dept] ?? 0) + 1;
    }
    
    return deptCounts;
  }

  /// Get department-wise faculty distribution
  Future<Map<String, int>> getDepartmentWiseFacultyCount() async {
    final faculties = await getFacultiesList();
    final deptCounts = <String, int>{};
    
    for (final faculty in faculties) {
      final dept = faculty['department']?.toString() ?? 'Unknown';
      deptCounts[dept] = (deptCounts[dept] ?? 0) + 1;
    }
    
    return deptCounts;
  }
}
