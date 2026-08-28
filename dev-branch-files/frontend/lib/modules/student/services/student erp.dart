import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../faculty/services/supabase_client.dart' as original;
import '../../faculty/services/supabase_config.dart';

class SupabaseService {
  factory SupabaseService() => instance;
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  String selectedAcademicYear = '2025-26';
  bool get isYear2025_26 => selectedAcademicYear.replaceAll('–', '-').replaceAll('—', '-').trim() == '2025-26';

  static String get url => FacultySupabaseConfig.supabaseUrl;
  static String get anonKey => FacultySupabaseConfig.anonKey;

  bool get isConfigured => FacultySupabaseConfig.isConfigured;

  SupabaseClient? get client {
    if (!isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    if (!isConfigured) return;
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      debugPrint('Supabase initialized successfully!');
    } catch (e) {
      debugPrint('Supabase initialize note: $e');
    }
  }

  // --- Student Profile ---
  Future<Map<String, dynamic>?> getStudentProfile(String studentIdCode) async {
    try {
      final data = await SupabaseClientHelper.select('students', filterColumn: 'student_id', filterValue: studentIdCode, schema: 'student');
      if (data.isNotEmpty) {
        return data.first;
      }
    } catch (e) {
      debugPrint('Error fetching student profile: $e');
    }
    return null;
  }

  Future<void> updateStudentProfile(String id, String email, String phone, String address) async {
    try {
      await SupabaseClientHelper.update('students', {
        'personal_email': email,
        'mobile_number': phone,
        'address': address,
      }, 'id', id, schema: 'student');
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  // --- Notifications ---
  Future<List<Map<String, dynamic>>> getNotifications(String studentId) async {
    try {
      return await SupabaseClientHelper.select('student_notifications', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await SupabaseClientHelper.update('student_notifications', {'is_read': true}, 'id', id, schema: 'student');
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead(String studentId) async {
    try {
      await SupabaseClientHelper.update('student_notifications', {'is_read': true}, 'student_id', studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }

  // --- Fees ---
  Future<List<Map<String, dynamic>>> getFees(String studentId) async {
    try {
      return await SupabaseClientHelper.select('fees', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching fees: $e');
      return [];
    }
  }

  Future<void> payFee(String id, String receiptNo, String paymentDate) async {
    try {
      await SupabaseClientHelper.update('fees', {
        'is_paid': true,
        'receipt_no': receiptNo,
        'payment_date': paymentDate,
      }, 'id', id, schema: 'student');
    } catch (e) {
      debugPrint('Error paying fee: $e');
    }
  }

  // --- Library ---
  Future<List<Map<String, dynamic>>> getLibraryBooks() async {
    try {
      return await SupabaseClientHelper.select('library_books', schema: 'student');
    } catch (e) {
      debugPrint('Error fetching library books: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLibraryTransactions(String studentId) async {
    try {
      return await SupabaseClientHelper.select('library_transactions', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching library transactions: $e');
      return [];
    }
  }

  Future<void> addLibraryTransaction(String studentId, String bookId, String type, String? dueDate) async {
    try {
      await SupabaseClientHelper.insert('library_transactions', {
        'student_id': studentId,
        'book_id': bookId,
        'type': type,
        'due_date': dueDate,
        'is_active': true,
      }, schema: 'student');
    } catch (e) {
      debugPrint('Error adding library transaction: $e');
    }
  }

  Future<void> renewLibraryBook(String transactionId, String newDueDate) async {
    try {
      await SupabaseClientHelper.update('library_transactions', {
        'due_date': newDueDate,
      }, 'id', transactionId, schema: 'student');
    } catch (e) {
      debugPrint('Error renewing library book: $e');
    }
  }

  // --- Hostel Outings ---
  Future<List<Map<String, dynamic>>> getOutings(String studentId) async {
    try {
      return await SupabaseClientHelper.select('hostel_outing_requests', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching outings: $e');
      return [];
    }
  }

  Future<void> addOutingRequest(String studentId, String purpose, String destination, String outTime, String inTime, String date) async {
    try {
      await SupabaseClientHelper.insert('hostel_outing_requests', {
        'student_id': studentId,
        'purpose': purpose,
        'destination': destination,
        'out_time': '${date}T$outTime',
        'in_time': '${date}T$inTime',
        'out_date': date,
        'status': 'Pending',
      }, schema: 'student');
    } catch (e) {
      debugPrint('Error adding outing request: $e');
    }
  }

  // --- Grievance ---
  Future<List<Map<String, dynamic>>> getGrievances(String studentId) async {
    try {
      return await SupabaseClientHelper.select('grievances', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching grievances: $e');
      return [];
    }
  }

  Future<void> addGrievance({
    required String studentId,
    String? studentName,
    String? studentRoll,
    String? classSec,
    required String category,
    required String subject,
    required String description,
    String? recipient,
    String? priority,
    String? date,
  }) async {
    try {
      final payload = <String, dynamic>{
        'student_id': studentId,
        'category': category,
        'subject': subject,
        'description': description,
        'recipient': recipient ?? 'HOD',
        'priority': priority ?? 'Medium',
        'status': 'Pending',
        'date': date ?? DateTime.now().toString().split(' ')[0],
      };
      if (studentName != null && studentName.isNotEmpty) {
        payload['student_name'] = studentName;
      }
      if (studentRoll != null && studentRoll.isNotEmpty) {
        payload['student_roll'] = studentRoll;
      }
      if (classSec != null && classSec.isNotEmpty) {
        payload['class_sec'] = classSec;
      }
      await SupabaseClientHelper.insert('grievances', payload, schema: 'student');
    } catch (e) {
      debugPrint('Error adding grievance: $e');
    }
  }

  Future<void> replyToGrievance(String grievanceId, String updatedDescription) async {
    try {
      await SupabaseClientHelper.update(
        'grievances',
        {
          'description': updatedDescription,
          'status': 'In Review',
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id',
        grievanceId,
        schema: 'student',
      );
    } catch (e) {
      debugPrint('Error replying to grievance: $e');
    }
  }

  // --- Certificate ---
  Future<List<Map<String, dynamic>>> getCertificates(String studentId) async {
    try {
      return await SupabaseClientHelper.select('certificate_requests', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching certificates: $e');
      return [];
    }
  }

  Future<void> addCertificateRequest(String studentId, String type, String reason, String date) async {
    try {
      await SupabaseClientHelper.insert('certificate_requests', {
        'student_id': studentId,
        'certificate_type': type,
        'reason': reason,
        'request_date': date,
        'status': 'Pending',
      }, schema: 'student');
    } catch (e) {
      debugPrint('Error adding certificate request: $e');
    }
  }

  // --- Achievements ---
  Future<List<Map<String, dynamic>>> getAchievements(String studentId) async {
    try {
      return await SupabaseClientHelper.select('achievements', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching achievements: $e');
      return [];
    }
  }

  Future<void> addAchievement(String studentId, String title, String category, String organizedBy, String date, String description) async {
    try {
      await SupabaseClientHelper.insert('achievements', {
        'student_id': studentId,
        'title': title,
        'category': category,
        'organized_by': organizedBy,
        'date': date,
        'description': description,
        'status': 'Pending',
      }, schema: 'student');
    } catch (e) {
      debugPrint('Error adding achievement: $e');
    }
  }

  // --- Extra Courses ---
  Future<List<Map<String, dynamic>>> getExtraCourses() async {
    try {
      return await SupabaseClientHelper.select('extra_courses', schema: 'student');
    } catch (e) {
      debugPrint('Error fetching extra courses: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExtraCourseEnrollments(String studentId) async {
    try {
      return await SupabaseClientHelper.select('extra_course_enrollments', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching enrollments: $e');
      return [];
    }
  }

  Future<void> enrollExtraCourse(String studentId, String courseId) async {
    try {
      await SupabaseClientHelper.insert('extra_course_enrollments', {
        'student_id': studentId,
        'course_id': courseId,
        'status': 'Enrolled',
      }, schema: 'student');
    } catch (e) {
      debugPrint('Error enrolling in course: $e');
    }
  }

  // --- Placements ---
  Future<List<Map<String, dynamic>>> getPlacements() async {
    try {
      return await SupabaseClientHelper.select('placements', schema: 'student');
    } catch (e) {
      debugPrint('Error fetching placements: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPlacementApplications(String studentId) async {
    try {
      return await SupabaseClientHelper.select('placement_applications', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching applications: $e');
      return [];
    }
  }

  Future<void> applyPlacement(String studentId, String placementId) async {
    try {
      await SupabaseClientHelper.insert('placement_applications', {
        'student_id': studentId,
        'placement_id': placementId,
      }, schema: 'student');
    } catch (e) {
      debugPrint('Error applying to placement: $e');
    }
  }

  // --- Notice Board ---
  Future<List<Map<String, dynamic>>> getNotices() async {
    try {
      return await SupabaseClientHelper.select('notice_board_posts', schema: 'student');
    } catch (e) {
      debugPrint('Error fetching notices: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNoticeBookmarks(String studentId) async {
    try {
      return await SupabaseClientHelper.select('notice_bookmarks', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching notice bookmarks: $e');
      return [];
    }
  }

  Future<void> addNoticeBookmark(String studentId, String noticeId) async {
    try {
      await SupabaseClientHelper.insert('notice_bookmarks', {
        'student_id': studentId,
        'notice_id': noticeId,
      }, schema: 'student');
    } catch (e) {
      debugPrint('Error adding notice bookmark: $e');
    }
  }

  Future<void> removeNoticeBookmark(String studentId, String noticeId) async {
    try {
      await SupabaseClientHelper.delete('notice_bookmarks', 'notice_id', noticeId, schema: 'student');
    } catch (e) {
      debugPrint('Error removing notice bookmark: $e');
    }
  }

  // --- Marks ---
  Future<List<Map<String, dynamic>>> getStudentMarks(String studentIdCode, [String? rollNo, String? registerNo]) async {
    try {
      final targetId = studentIdCode.trim();
      final targetReg = registerNo?.trim() ?? '';

      var urlStr = '${FacultySupabaseConfig.supabaseUrl}/rest/v1/internal_marks?select=*';
      if (targetReg.isNotEmpty) {
        urlStr += '&or=(student_id.eq.$targetId,register_no.eq.$targetReg)';
      } else {
        urlStr += '&student_id=eq.$targetId';
      }

      final headers = Map<String, String>.from(FacultySupabaseConfig.headers);
      headers['Accept-Profile'] = 'student';
      headers['Content-Profile'] = 'student';

      final response = await http.get(Uri.parse(urlStr), headers: headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final resList = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();

          try {
            final faculties = await SupabaseClientHelper.select('faculties', schema: 'faculty');
            final Map<String, Map<String, String>> facultyInfoMap = {};
            for (var f in faculties) {
              final empId = f['employee_id']?.toString() ?? '';
              if (empId.isNotEmpty) {
                facultyInfoMap[empId] = {
                  'name': f['full_name']?.toString() ?? 'Mr. P. Kalaiyarasan',
                  'role': f['designation']?.toString() ?? f['role']?.toString() ?? 'Assistant Professor',
                };
              }
            }

            final enriched = resList.map((row) {
              final mutableRow = Map<String, dynamic>.from(row);
              final empId = mutableRow['faculty_employee_id']?.toString() ?? mutableRow['faculty_id']?.toString() ?? '';
              final fInfo = facultyInfoMap[empId];
              mutableRow['faculty_name'] = fInfo?['name'] ?? 'Mr. P. Kalaiyarasan';
              mutableRow['faculty_role'] = fInfo?['role'] ?? 'Assistant Professor';
              return mutableRow;
            }).toList();

            return enriched;
          } catch (_) {
            return resList.map((row) {
              final mutableRow = Map<String, dynamic>.from(row);
              mutableRow['faculty_name'] = 'Mr. P. Kalaiyarasan';
              mutableRow['faculty_role'] = 'Assistant Professor';
              return mutableRow;
            }).toList();
          }
        }
      } else {
        debugPrint('Error fetching internal_marks (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching student internal marks: $e');
    }
    return [];
  }

  // --- Attendance ---
  Future<List<Map<String, dynamic>>> getStudentAttendance(String regNo) async {
    try {
      return await SupabaseClientHelper.select('attendance_table', filterColumn: 'reg_no', filterValue: regNo, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching student attendance: $e');
      return [];
    }
  }

  // --- Timetable ---
  Future<List<Map<String, dynamic>>> getTimetables(String classSec) async {
    try {
      return await SupabaseClientHelper.select('timetables', filterColumn: 'section', filterValue: classSec, schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching timetables: $e');
      return [];
    }
  }

  // --- Syllabus ---
  Future<List<Map<String, dynamic>>> getSyllabus() async {
    try {
      return await SupabaseClientHelper.select('syllabus_uploads', schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching syllabus: $e');
      return [];
    }
  }

  // --- Assignments ---
  Future<List<Map<String, dynamic>>> getAssignments() async {
    try {
      return await SupabaseClientHelper.select('assignments', schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAssignmentMarks(String studentId) async {
    try {
      return await SupabaseClientHelper.select('assignment_marks', filterColumn: 'reg_no', filterValue: studentId, schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching assignment marks: $e');
      return [];
    }
  }

  // --- Academic Calendar ---
  Future<List<Map<String, dynamic>>> getAcademicCalendarEvents(String academicYear) async {
    try {
      var list = await SupabaseClientHelper.select('academic_calendar_events', filterColumn: 'academic_year', filterValue: academicYear, schema: 'public');
      if (list.isEmpty) {
        list = await SupabaseClientHelper.select('academic_calendar_events', schema: 'public');
      }
      if (list.isEmpty) {
        list = await SupabaseClientHelper.select('academic_calendar', schema: 'public');
      }
      return list.map((e) {
        final map = Map<String, dynamic>.from(e);
        if (map['event_date'] == null && map['date'] != null) {
          map['event_date'] = map['date'];
        }
        if (map['venue'] == null && map['place'] != null) {
          map['venue'] = map['place'];
        }
        if (map['event_type'] == null && map['type'] != null) {
          map['event_type'] = map['type'];
        }
        return map;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching academic calendar: $e');
      return [];
    }
  }

  // --- Student Documents ---
  Future<List<Map<String, dynamic>>> getStudentDocuments(String studentIdCode) async {
    try {
      final list1 = await SupabaseClientHelper.select('student_documents', filterColumn: 'student_id', filterValue: studentIdCode, schema: 'student');
      if (list1.isNotEmpty) return list1;
      final list2 = await SupabaseClientHelper.select('student_documents', filterColumn: 'student_id', filterValue: studentIdCode, schema: 'public');
      if (list2.isNotEmpty) return list2;
      return await SupabaseClientHelper.select('student_documents', filterColumn: 'student_id', filterValue: studentIdCode, schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching student documents: $e');
      return [];
    }
  }

  Future<bool> uploadStudentDocument({
    required String studentId,
    required String documentName,
    required String fileName,
    String? fileUrl,
    String status = 'Verified',
    String? verificationStatus,
  }) async {
    try {
      final finalStatus = verificationStatus ?? status;
      final payload = {
        'student_id': studentId,
        'document_name': documentName,
        'file_name': fileName,
        'file_url': fileUrl ?? 'https://storage.ksrce.ac.in/docs/${studentId}_$fileName',
        'verification_status': finalStatus,
        'uploaded_at': DateTime.now().toIso8601String(),
      };
      await SupabaseClientHelper.insert('student_documents', payload, schema: 'student');
      await SupabaseClientHelper.insert('student_documents', payload, schema: 'public');
      return true;
    } catch (e) {
      debugPrint('Error uploading student document: $e');
      return false;
    }
  }

  // --- Lesson Plans (for Reports/Surveys outcome items) ---
  Future<List<Map<String, dynamic>>> getLessonPlans() async {
    try {
      return await SupabaseClientHelper.select('lesson_plans', schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching lesson plans: $e');
      return [];
    }
  }

  // --- Submissions logs ---
  Future<void> submitExitSurveyLog(String studentUuid, String jsonPayload) async {
    try {
      await SupabaseClientHelper.insert('grievances', {
        'student_id': studentUuid,
        'category': 'Exit Survey',
        'subject': 'Survey Submission',
        'description': jsonPayload,
      }, schema: 'student');
    } catch (e) {
      debugPrint('Error submitting survey: $e');
    }
  }

  Future<void> submitCourseFeedbackLog(String studentUuid, String jsonPayload) async {
    try {
      await SupabaseClientHelper.insert('grievances', {
        'student_id': studentUuid,
        'category': 'Course Feedback',
        'subject': 'Feedback Submission',
        'description': jsonPayload,
      }, schema: 'student');
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
    }
  }
}

// Shadow class to intercept Supabase queries in student module
class SupabaseClientHelper {
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String selectQuery = '*',
    String? filterColumn,
    String? filterValue,
    String? orderBy,
    bool ascending = true,
    String schema = 'faculty',
  }) async {
    if (table != 'academic_years' && !SupabaseService.instance.isYear2025_26) {
      return [];
    }
    return original.SupabaseClientHelper.select(
      table,
      selectQuery: selectQuery,
      filterColumn: filterColumn,
      filterValue: filterValue,
      orderBy: orderBy,
      ascending: ascending,
      schema: schema,
    );
  }

  static Future<Map<String, dynamic>?> insert(
    String table,
    Map<String, dynamic> data, {
    String schema = 'faculty',
  }) async {
    if (!SupabaseService.instance.isYear2025_26) {
      return null;
    }
    return original.SupabaseClientHelper.insert(table, data, schema: schema);
  }

  static Future<Map<String, dynamic>?> update(
    String table,
    Map<String, dynamic> data,
    String matchColumn,
    String matchValue, {
    String schema = 'faculty',
  }) async {
    if (!SupabaseService.instance.isYear2025_26) {
      return null;
    }
    return original.SupabaseClientHelper.update(table, data, matchColumn, matchValue, schema: schema);
  }

  static Future<bool> delete(
    String table,
    String matchColumn,
    String matchValue, {
    String schema = 'faculty',
  }) async {
    if (!SupabaseService.instance.isYear2025_26) {
      return false;
    }
    return original.SupabaseClientHelper.delete(table, matchColumn, matchValue, schema: schema);
  }

  static Future<bool> upsert(
    String table,
    Map<String, dynamic> data,
    String conflictColumn, {
    String schema = 'faculty',
  }) async {
    if (!SupabaseService.instance.isYear2025_26) {
      return false;
    }
    return original.SupabaseClientHelper.upsert(table, data, conflictColumn, schema: schema);
  }

  static Future<Map<String, dynamic>> testConnection() async {
    return original.SupabaseClientHelper.testConnection();
  }
}
