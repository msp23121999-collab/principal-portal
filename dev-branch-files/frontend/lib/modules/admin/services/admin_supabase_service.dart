import 'dart:typed_data';

import '../shared/services/supabase_service.dart';

class AdminSupabaseService {
  factory AdminSupabaseService() {
    return _instance;
  }

  AdminSupabaseService._internal();
  static final AdminSupabaseService _instance =
      AdminSupabaseService._internal();

  static AdminSupabaseService get instance => _instance;

  /// Initialize admin-specific Supabase configuration
  Future<void> initialize() async {
    try {
      await SupabaseService.instance.initialize();
    } catch (e) {
      print('Error initializing admin Supabase service: $e');
      rethrow;
    }
  }

  /// Fetch admin-specific data from Supabase
  Future<List<Map<String, dynamic>>> fetchAdminData(
    String tableName, {
    String? filter,
  }) async {
    try {
      return await SupabaseService.instance.fetchTable(
        tableName,
        select: '*',
        filter: filter,
      );
    } catch (e) {
      print('Error fetching admin data from $tableName: $e');
      return [];
    }
  }

  /// Insert admin data
  Future<Map<String, dynamic>?> insertAdminData(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData(tableName, data);
    } catch (e) {
      print('Error inserting admin data into $tableName: $e');
      return null;
    }
  }

  /// Update admin data
  Future<bool> updateAdminData(
    String tableName,
    Map<String, dynamic> data,
    String filterId,
  ) async {
    try {
      return await SupabaseService.instance.updateData(
        tableName,
        data,
        filterId,
      );
    } catch (e) {
      print('Error updating admin data in $tableName: $e');
      return false;
    }
  }

  /// Delete admin data
  Future<bool> deleteAdminData(String tableName, String filterId) async {
    try {
      return await SupabaseService.instance.deleteData(tableName, filterId);
    } catch (e) {
      print('Error deleting admin data from $tableName: $e');
      return false;
    }
  }

  /// Fetch circulars from the principal schema.
  static Future<List<Map<String, dynamic>>> fetchCirculars() async {
    try {
      return await SupabaseService.instance.fetchTable('circulars');
    } catch (e) {
      print('Error fetching circulars: $e');
      return [];
    }
  }

  /// Fetch meetings from the principal schema.
  static Future<List<Map<String, dynamic>>> fetchMeetings() async {
    try {
      return await SupabaseService.instance.fetchTable('meetings');
    } catch (e) {
      print('Error fetching meetings: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> addMeeting(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData('meetings', data);
    } catch (e) {
      print('Error adding meeting: $e');
      return null;
    }
  }

  /// Fetch audit log entries.
  static Future<List<Map<String, dynamic>>> fetchAuditEntries() async {
    try {
      return await SupabaseService.instance.fetchTable('audit_logs');
    } catch (e) {
      print('Error fetching audit entries: $e');
      return [];
    }
  }

  /// Add a new audit log entry.
  static Future<Map<String, dynamic>?> addAuditEntry(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData('audit_logs', data);
    } catch (e) {
      print('Error adding audit entry: $e');
      return null;
    }
  }

  /// Delete an audit log entry by id.
  static Future<bool> deleteAuditEntry(String id) async {
    try {
      return await SupabaseService.instance.deleteData('audit_logs', id);
    } catch (e) {
      print('Error deleting audit entry: $e');
      return false;
    }
  }

  /// Fetch approval requests.
  static Future<List<Map<String, dynamic>>> fetchApprovalRequests() async {
    try {
      return await SupabaseService.instance.fetchTable('approval_requests');
    } catch (e) {
      print('Error fetching approval requests: $e');
      return [];
    }
  }

  /// Add a new approval request.
  static Future<Map<String, dynamic>?> addApprovalRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData(
        'approval_requests',
        data,
      );
    } catch (e) {
      print('Error adding approval request: $e');
      return null;
    }
  }

  /// Update an approval request by id.
  static Future<bool> updateApprovalRequest(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.updateData(
        'approval_requests',
        data,
        id,
      );
    } catch (e) {
      print('Error updating approval request: $e');
      return false;
    }
  }

  /// Delete an approval request by id.
  static Future<bool> deleteApprovalRequest(String id) async {
    try {
      return await SupabaseService.instance.deleteData('approval_requests', id);
    } catch (e) {
      print('Error deleting approval request: $e');
      return false;
    }
  }

  /// Fetch student attendance marks.
  static Future<List<Map<String, dynamic>>>
  fetchStudentAttendanceMarks() async {
    try {
      return await SupabaseService.instance.fetchTable(
        'student_attendance_marks',
      );
    } catch (e) {
      print('Error fetching student attendance marks: $e');
      return [];
    }
  }

  /// Add a student attendance mark record.
  static Future<Map<String, dynamic>?> addStudentAttendanceMark(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData(
        'student_attendance_marks',
        data,
      );
    } catch (e) {
      print('Error adding student attendance mark: $e');
      return null;
    }
  }

  /// Update a student attendance mark record.
  static Future<bool> updateStudentAttendanceMark(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.updateData(
        'student_attendance_marks',
        data,
        id,
      );
    } catch (e) {
      print('Error updating student attendance mark: $e');
      return false;
    }
  }

  /// Delete a student attendance mark record.
  static Future<bool> deleteStudentAttendanceMark(String id) async {
    try {
      return await SupabaseService.instance.deleteData(
        'student_attendance_marks',
        id,
      );
    } catch (e) {
      print('Error deleting student attendance mark: $e');
      return false;
    }
  }

  /// Fetch faculty attendance records.
  static Future<List<Map<String, dynamic>>> fetchFacultyAttendance() async {
    try {
      return await SupabaseService.instance.fetchTable('faculty_attendance');
    } catch (e) {
      print('Error fetching faculty attendance: $e');
      return [];
    }
  }

  /// Add a faculty attendance record.
  static Future<Map<String, dynamic>?> addFacultyAttendance(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData(
        'faculty_attendance',
        data,
      );
    } catch (e) {
      print('Error adding faculty attendance: $e');
      return null;
    }
  }

  /// Update a faculty attendance record.
  static Future<bool> updateFacultyAttendance(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.updateData(
        'faculty_attendance',
        data,
        id,
      );
    } catch (e) {
      print('Error updating faculty attendance: $e');
      return false;
    }
  }

  /// Delete a faculty attendance record.
  static Future<bool> deleteFacultyAttendance(String id) async {
    try {
      return await SupabaseService.instance.deleteData(
        'faculty_attendance',
        id,
      );
    } catch (e) {
      print('Error deleting faculty attendance: $e');
      return false;
    }
  }

  /// Fetch repository folders.
  static Future<List<Map<String, dynamic>>> fetchRepositoryFolders() async {
    try {
      return await SupabaseService.instance.fetchTable('repository_folders');
    } catch (e) {
      print('Error fetching repository folders: $e');
      return [];
    }
  }

  /// Fetch repository documents, optionally filtered by folder.
  static Future<List<Map<String, dynamic>>> fetchRepositoryDocuments({
    String? folderId,
  }) async {
    try {
      return await SupabaseService.instance.fetchTable(
        'repository_documents',
        filter: folderId != null ? 'folder_id.eq.$folderId' : null,
      );
    } catch (e) {
      print('Error fetching repository documents: $e');
      return [];
    }
  }

  /// Upload a repository file to Supabase storage.
  static Future<String?> uploadRepositoryFile(
    String fileName,
    Uint8List bytes, {
    String? mimeType,
  }) async {
    try {
      final path =
          'repository/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await SupabaseService.instance.client.storage
          .from('documents')
          .uploadBinary(path, bytes);
      return path;
    } catch (e) {
      print('Error uploading repository file: $e');
      return null;
    }
  }

  /// Add a repository document record.
  static Future<Map<String, dynamic>?> addRepositoryDocument(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData(
        'repository_documents',
        data,
      );
    } catch (e) {
      print('Error adding repository document: $e');
      return null;
    }
  }

  /// Add a repository folder.
  static Future<Map<String, dynamic>?> addRepositoryFolder(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData(
        'repository_folders',
        data,
      );
    } catch (e) {
      print('Error adding repository folder: $e');
      return null;
    }
  }

  /// Delete a repository document by id.
  static Future<bool> deleteRepositoryDocument(String id) async {
    try {
      return await SupabaseService.instance.deleteData(
        'repository_documents',
        id,
      );
    } catch (e) {
      print('Error deleting repository document: $e');
      return false;
    }
  }

  /// Fetch exam schedules.
  static Future<List<Map<String, dynamic>>> fetchExamSchedules() async {
    try {
      return await SupabaseService.instance.fetchTable('exam_schedules');
    } catch (e) {
      print('Error fetching exam schedules: $e');
      return [];
    }
  }

  /// Add an exam schedule.
  static Future<Map<String, dynamic>?> addExamSchedule(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData('exam_schedules', data);
    } catch (e) {
      print('Error adding exam schedule: $e');
      return null;
    }
  }

  /// Update an exam schedule by id.
  static Future<bool> updateExamSchedule(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.updateData(
        'exam_schedules',
        data,
        id,
      );
    } catch (e) {
      print('Error updating exam schedule: $e');
      return false;
    }
  }

  /// Delete an exam schedule by id.
  static Future<bool> deleteExamSchedule(String id) async {
    try {
      return await SupabaseService.instance.deleteData('exam_schedules', id);
    } catch (e) {
      print('Error deleting exam schedule: $e');
      return false;
    }
  }

  /// Fetch monthly finance records.
  static Future<List<Map<String, dynamic>>> fetchMonthlyFinance() async {
    try {
      return await SupabaseService.instance.fetchTable('monthly_finance');
    } catch (e) {
      print('Error fetching monthly finance: $e');
      return [];
    }
  }

  /// Fetch department fee status.
  static Future<List<Map<String, dynamic>>> fetchDepartmentFeeStatus() async {
    try {
      return await SupabaseService.instance.fetchTable('department_fee_status');
    } catch (e) {
      print('Error fetching department fee status: $e');
      return [];
    }
  }

  /// Add a monthly finance record.
  static Future<Map<String, dynamic>?> addMonthlyFinance(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData('monthly_finance', data);
    } catch (e) {
      print('Error adding monthly finance: $e');
      return null;
    }
  }

  /// Delete a monthly finance record by id.
  static Future<bool> deleteMonthlyFinance(String id) async {
    try {
      return await SupabaseService.instance.deleteData('monthly_finance', id);
    } catch (e) {
      print('Error deleting monthly finance: $e');
      return false;
    }
  }

  /// Fetch hall ticket status records.
  static Future<List<Map<String, dynamic>>> fetchHallTicketStatus() async {
    try {
      return await SupabaseService.instance.fetchTable('hall_tickets');
    } catch (e) {
      print('Error fetching hall ticket status: $e');
      return [];
    }
  }

  /// Fetch admin users.
  static Future<List<Map<String, dynamic>>> fetchAdminUsers() async {
    try {
      return await SupabaseService.instance.fetchTable('admin_users');
    } catch (e) {
      print('Error fetching admin users: $e');
      return [];
    }
  }

  /// Add a hall ticket record.
  static Future<Map<String, dynamic>?> addHallTicket(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData('hall_tickets', data);
    } catch (e) {
      print('Error adding hall ticket: $e');
      return null;
    }
  }

  /// Add multiple hall ticket records in a batch.
  static Future<void> addHallTicketsInBatch(
    List<Map<String, dynamic>> data,
  ) async {
    if (data.isEmpty) return;
    try {
      await SupabaseService.instance.client.from('hall_tickets').insert(data);
    } catch (e) {
      print('Error adding hall tickets in batch: $e');
      // Optionally rethrow or handle error
    }
  }

  /// Fetch departments.
  static Future<List<Map<String, dynamic>>> fetchDepartments() async {
    try {
      return await SupabaseService.instance.fetchTable('departments');
    } catch (e) {
      print('Error fetching departments: $e');
      return [];
    }
  }

  /// Fetch academic years.
  static Future<List<Map<String, dynamic>>> fetchAcademicYears() async {
    try {
      return await SupabaseService.instance.fetchTable('academic_years');
    } catch (e) {
      print('Error fetching academic years: $e');
      return [];
    }
  }

  /// Fetch notification triggers.
  static Future<List<Map<String, dynamic>>> fetchNotificationTriggers() async {
    try {
      return await SupabaseService.instance.fetchTable('notification_triggers');
    } catch (e) {
      print('Error fetching notification triggers: $e');
      return [];
    }
  }

  /// Fetch notification logs.
  static Future<List<Map<String, dynamic>>> fetchNotificationLogs() async {
    try {
      return await SupabaseService.instance.fetchTable('notification_logs');
    } catch (e) {
      print('Error fetching notification logs: $e');
      return [];
    }
  }

  /// Add a notification log entry.
  static Future<Map<String, dynamic>?> addNotificationLog(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData(
        'notification_logs',
        data,
      );
    } catch (e) {
      print('Error adding notification log: $e');
      return null;
    }
  }

  /// Add a notification trigger.
  static Future<Map<String, dynamic>?> addNotificationTrigger(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData(
        'notification_triggers',
        data,
      );
    } catch (e) {
      print('Error adding notification trigger: $e');
      return null;
    }
  }

  /// Update a notification trigger by id.
  static Future<bool> updateNotificationTrigger(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.updateData(
        'notification_triggers',
        data,
        id,
      );
    } catch (e) {
      print('Error updating notification trigger: $e');
      return false;
    }
  }

  /// Fetch scholarship schemes.
  static Future<List<Map<String, dynamic>>> fetchScholarshipSchemes() async {
    try {
      return await SupabaseService.instance.fetchTable('scholarship_schemes');
    } catch (e) {
      print('Error fetching scholarship schemes: $e');
      return [];
    }
  }

  /// Add a scholarship scheme.
  static Future<Map<String, dynamic>?> addScholarshipScheme(
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.insertData(
        'scholarship_schemes',
        data,
      );
    } catch (e) {
      print('Error adding scholarship scheme: $e');
      return null;
    }
  }

  /// Update a scholarship scheme by id.
  static Future<bool> updateScholarshipScheme(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.updateData(
        'scholarship_schemes',
        data,
        id,
      );
    } catch (e) {
      print('Error updating scholarship scheme: $e');
      return false;
    }
  }

  /// Delete a scholarship scheme by id.
  static Future<bool> deleteScholarshipScheme(String id) async {
    try {
      return await SupabaseService.instance.deleteData(
        'scholarship_schemes',
        id,
      );
    } catch (e) {
      print('Error deleting scholarship scheme: $e');
      return false;
    }
  }

  /// Fetch enrollment batches.
  static Future<List<Map<String, dynamic>>> fetchEnrollmentBatches() async {
    try {
      return await SupabaseService.instance.fetchTable('enrollment_batches');
    } catch (e) {
      print('Error fetching enrollment batches: $e');
      return [];
    }
  }
}
