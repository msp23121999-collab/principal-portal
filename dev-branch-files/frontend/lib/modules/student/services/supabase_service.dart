import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<List<Map<String, dynamic>>> getStudentFamily(String studentIdCode) async {
    try {
      return await SupabaseClientHelper.select('student_family', filterColumn: 'student_id', filterValue: studentIdCode, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching student family: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentEducation(String studentIdCode) async {
    try {
      return await SupabaseClientHelper.select('student_education', filterColumn: 'student_id', filterValue: studentIdCode, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching student education: $e');
      return [];
    }
  }

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

  Future<List<Map<String, dynamic>>> getStudentFinancials(String studentIdCode) async {
    try {
      return await SupabaseClientHelper.select('student_financials', filterColumn: 'student_id', filterValue: studentIdCode, schema: 'student');
    } catch (e) {
      debugPrint('Error fetching student financials: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFeesFiltered({
    required String studentIdCode,
    required String academicYear,
    required String semester,
  }) async {
    try {
      final clientRef = client;
      if (clientRef == null) return [];
      
      final normAy = academicYear.replaceAll('–', '-').replaceAll('—', '-').trim();
      final normSem = semester.trim().toUpperCase();

      final results = await Future.wait([
        clientRef
            .schema('student')
            .from('fees')
            .select('*')
            .eq('student_id', studentIdCode)
            .eq('academic_year', normAy)
            .eq('semester', normSem),
        clientRef
            .schema('student')
            .from('student_financials')
            .select('*')
            .eq('student_id', studentIdCode)
            .eq('academic_year', normAy)
            .eq('semester', normSem)
      ]);

      final List<dynamic> list1 = results[0];
      final List<dynamic> list2 = results[1];

      final List<Map<String, dynamic>> combined = [];
      for (var f in list1) {
        combined.add({
          'id': f['id']?.toString() ?? '',
          'title': f['title'] ?? 'Fee',
          'category': f['category'] ?? 'General',
          'amount': double.tryParse(f['amount']?.toString() ?? '0.0') ?? 0.0,
          'due_date': f['due_date']?.toString() ?? '2026-08-25',
          'is_paid': f['is_paid'] == true,
          'payment_date': f['payment_date']?.toString(),
          'receipt_no': f['receipt_no']?.toString(),
          'academic_year': f['academic_year'] ?? normAy,
          'semester': f['semester'] ?? normSem,
        });
      }

      for (var f in list2) {
        final title = (f['fee_head'] ?? 'Fee Head').toString();
        final exists = combined.any((item) =>
            (item['title'] ?? '').toString().toLowerCase() == title.toLowerCase());
        if (!exists) {
          final totalAmt = double.tryParse(f['total_amount']?.toString() ?? '0') ?? 0.0;
          final paidAmt = double.tryParse(f['paid_amount']?.toString() ?? '0') ?? 0.0;
          final isPaid = f['payment_status'] == 'Paid' || (totalAmt > 0 && paidAmt >= totalAmt);

          String cat = 'Academic';
          if (title.toLowerCase().contains('tuition')) {
            cat = 'Tuition';
          } else if (title.toLowerCase().contains('transport') || title.toLowerCase().contains('bus')) {
            cat = 'Transport';
          } else if (title.toLowerCase().contains('exam')) {
            cat = 'Examination';
          } else if (title.toLowerCase().contains('hostel')) {
            cat = 'Hostel';
          }

          combined.add({
            'id': f['id']?.toString() ?? '',
            'title': title,
            'category': cat,
            'amount': totalAmt,
            'due_date': '2026-08-25',
            'is_paid': isPaid,
            'payment_date': null,
            'receipt_no': f['receipt_no']?.toString(),
            'academic_year': f['academic_year'] ?? normAy,
            'semester': f['semester'] ?? normSem,
          });
        }
      }

      return combined;
    } catch (e) {
      debugPrint("Error fetching filtered fees: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFees(String studentIdCode) async {
    try {
      final list1 = await SupabaseClientHelper.select('fees', filterColumn: 'student_id', filterValue: studentIdCode, schema: 'student');
      final list2 = await SupabaseClientHelper.select('student_financials', filterColumn: 'student_id', filterValue: studentIdCode, schema: 'student');

      final List<Map<String, dynamic>> combined = [];
      for (var f in list1) {
        combined.add({
          'id': f['id'],
          'title': f['title'] ?? 'Fee',
          'category': f['category'] ?? 'General',
          'amount': f['amount'] ?? 0,
          'due_date': f['due_date']?.toString() ?? '2026-08-25',
          'is_paid': f['is_paid'] == true,
          'payment_date': f['payment_date']?.toString(),
          'receipt_no': f['receipt_no'],
          'academic_year': f['academic_year'] ?? '2025-26',
          'semester': f['semester'] ?? 'V',
        });
      }

      for (var f in list2) {
        final title = (f['fee_head'] ?? 'Fee Head').toString();
        final ay = (f['academic_year'] ?? '2025-26').toString();
        final sem = (f['semester'] ?? 'V').toString();
        final exists = combined.any((item) =>
            (item['title'] ?? '').toString().toLowerCase() == title.toLowerCase() &&
            (item['academic_year'] ?? '').toString() == ay &&
            (item['semester'] ?? '').toString() == sem);
        if (!exists) {
          final totalAmt = double.tryParse(f['total_amount']?.toString() ?? '0') ?? 0.0;
          final paidAmt = double.tryParse(f['paid_amount']?.toString() ?? '0') ?? 0.0;
          final isPaid = f['payment_status'] == 'Paid' || (totalAmt > 0 && paidAmt >= totalAmt);

          String cat = 'Academic';
          if (title.toLowerCase().contains('tuition')) {
            cat = 'Tuition';
          } else if (title.toLowerCase().contains('transport') || title.toLowerCase().contains('bus')) {
            cat = 'Transport';
          } else if (title.toLowerCase().contains('exam')) {
            cat = 'Examination';
          } else if (title.toLowerCase().contains('hostel')) {
            cat = 'Hostel';
          }

          combined.add({
            'id': f['id'],
            'title': title,
            'category': cat,
            'amount': totalAmt,
            'due_date': f['created_at']?.toString().substring(0, 10) ?? '2026-08-25',
            'is_paid': isPaid,
            'payment_date': isPaid ? f['created_at']?.toString().substring(0, 10) : null,
            'receipt_no': f['receipt_no'],
            'academic_year': ay,
            'semester': sem,
          });
        }
      }

      return combined;
    } catch (e) {
      debugPrint('Error fetching fees: $e');
      return [];
    }
  }

  Future<void> updateStudentProfile(String id, String name, String email, String phone, String address) async {
    try {
      await SupabaseClientHelper.update('students', {
        'full_name': name,
        'personal_email': email,
        'mobile_number': phone,
        'address': address,
      }, 'id', id, schema: 'student');
      debugPrint('Successfully synced student profile update to DB!');
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  // --- Notifications ---
  Future<List<Map<String, dynamic>>> getNotifications(String studentId) async {
    try {
      final specific = await SupabaseClientHelper.select('student_notifications', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
      final broadcast = await SupabaseClientHelper.select('student_notifications', filterColumn: 'student_id', filterValue: 'ALL', schema: 'student');

      final Map<String, Map<String, dynamic>> combinedMap = {};
      for (var n in specific) {
        combinedMap[n['id'].toString()] = n;
      }
      for (var n in broadcast) {
        combinedMap[n['id'].toString()] = n;
      }

      if (combinedMap.isEmpty) {
        final allNotifs = await SupabaseClientHelper.select('student_notifications', schema: 'student');
        for (var n in allNotifs) {
          combinedMap[n['id'].toString()] = n;
        }
      }

      final list = combinedMap.values.toList();
      list.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      return list;
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
      final res = await SupabaseClientHelper.select('grievances', filterColumn: 'student_id', filterValue: studentId, schema: 'student');
      if (res.isNotEmpty) return res;
      final rollRes = await SupabaseClientHelper.select('grievances', filterColumn: 'student_roll', filterValue: studentId, schema: 'student');
      if (rollRes.isNotEmpty) return rollRes;
      return await SupabaseClientHelper.select('grievances', schema: 'student');
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

  // --- Timetable ---
  Future<List<Map<String, dynamic>>> getClassTimetables({
    String? department,
    String? year,
    String? section,
    String? academicYear,
  }) async {
    if (!isYear2025_26) return [];
    try {
      // Build URL with multiple filters against the 'timetable' schema
      final baseUrl = '${FacultySupabaseConfig.supabaseUrl}/rest/v1/class_timetables?select=*';
      final params = <String>[];
      if (department != null && department.isNotEmpty) params.add('department_code=eq.$department');
      if (section != null && section.isNotEmpty) params.add('section=eq.$section');
      if (academicYear != null && academicYear.isNotEmpty) {
        // The timetable schema stores academic_year as "2025-2026" (4-digit), normalize
        final expandedYear = _expandAcademicYear(academicYear);
        params.add('academic_year=eq.$expandedYear');
      }
      final url = params.isEmpty ? baseUrl : '$baseUrl&${params.join('&')}';

      final headers = Map<String, String>.from(FacultySupabaseConfig.headers);
      headers['Accept-Profile'] = 'timetable';
      headers['Content-Profile'] = 'timetable';

      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      } else {
        debugPrint('Error fetching class_timetables: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching class_timetables: $e');
    }
    return [];
  }

  // Converts "2025-26" → "2025-2026" for timetable schema queries
  static String _expandAcademicYear(String shortYear) {
    final re = RegExp(r'^(\d{4})-(\d{2})$');
    final m = re.firstMatch(shortYear);
    if (m != null) {
      return '${m.group(1)}-${m.group(1)!.substring(0, 2)}${m.group(2)}';
    }
    return shortYear; // already expanded or unknown format
  }

  // Normalizes "2025–2026" (en-dash) or "2025-2026" → "2025-26" (short)
  static String normalizeAcademicYearLabel(String label) {
    var s = label.replaceAll('\u2013', '-').replaceAll('\u2014', '-');
    final re = RegExp(r'^(\d{4})-(\d{4})$');
    final m = re.firstMatch(s);
    if (m != null) s = '${m.group(1)}-${m.group(2)!.substring(2)}';
    return s;
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
      return await SupabaseClientHelper.select(
        'placements',
        schema: 'student',
      );
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
  Future<List<Map<String, dynamic>>> getStudentAttendance(String regNo, {String? studentId, String? rollNo}) async {
    try {
      if (regNo.isNotEmpty) {
        final res = await SupabaseClientHelper.select('attendance_table', filterColumn: 'reg_no', filterValue: regNo, schema: 'student');
        if (res.isNotEmpty) return res;
      }
      if (studentId != null && studentId.isNotEmpty) {
        final res = await SupabaseClientHelper.select('attendance_table', filterColumn: 'reg_no', filterValue: studentId, schema: 'student');
        if (res.isNotEmpty) return res;
      }
      if (rollNo != null && rollNo.isNotEmpty) {
        final res = await SupabaseClientHelper.select('attendance_table', filterColumn: 'reg_no', filterValue: rollNo, schema: 'student');
        if (res.isNotEmpty) return res;
      }
      return await SupabaseClientHelper.select('attendance_table', schema: 'student');
    } catch (e) {
      debugPrint('Error fetching student attendance: $e');
      return [];
    }
  }

  // --- Timetable ---
  Future<List<Map<String, dynamic>>> getTimetables(String classSec) async {
    try {
      final res = await SupabaseClientHelper.select('timetables', filterColumn: 'section', filterValue: classSec, schema: 'faculty');
      if (res.isNotEmpty) return res;
      return await SupabaseClientHelper.select('timetables', schema: 'faculty');
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

  // --- Exam Schedules ---
  Future<List<Map<String, dynamic>>> getExamSchedules([String? department]) async {
    try {
      final res = await SupabaseClientHelper.select(
        'exam_time_table',
        selectQuery: '*, departments:department_id(name, code)',
        schema: 'public',
      );
      return res;
    } catch (e) {
      try {
        return await SupabaseClientHelper.select('exam_time_table', schema: 'public');
      } catch (err) {
        debugPrint('Error fetching exam schedules: $err');
        return [];
      }
    }
  }

  // --- Course Materials ---
  Future<List<Map<String, dynamic>>> getCourseMaterials() async {
    try {
      return await SupabaseClientHelper.select('course_materials', schema: 'faculty').timeout(
        const Duration(seconds: 4),
        onTimeout: () => [],
      );
    } catch (_) {
      return [];
    }
  }

  // --- Assignments ---
  Future<List<Map<String, dynamic>>> getAssignments() async {
    try {
      return await SupabaseClientHelper.select('assignments', schema: 'faculty').timeout(
        const Duration(seconds: 4),
        onTimeout: () => [],
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAssignmentMarks(String regNo, {String? studentId}) async {
    try {
      if (regNo.isNotEmpty) {
        final res = await SupabaseClientHelper.select('assignment_marks', filterColumn: 'reg_no', filterValue: regNo, schema: 'faculty');
        if (res.isNotEmpty) return res;
      }
      if (studentId != null && studentId.isNotEmpty) {
        final res = await SupabaseClientHelper.select('assignment_marks', filterColumn: 'student_id', filterValue: studentId, schema: 'faculty');
        if (res.isNotEmpty) return res;
      }
      return await SupabaseClientHelper.select('assignment_marks', schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching assignment marks: $e');
      return [];
    }
  }

  Future<String?> uploadAssignmentFile(String studentId, String fileName, List<int> bytes) async {
    if (!isYear2025_26) return null;
    try {
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = '$studentId/$sanitizedFileName';
      
      final uri = Uri.parse('${FacultySupabaseConfig.supabaseUrl}/storage/v1/object/assignments/$path');
      final headers = <String, String>{
        'apikey': FacultySupabaseConfig.anonKey,
        'Authorization': 'Bearer ${FacultySupabaseConfig.anonKey}',
        'Content-Type': 'application/octet-stream',
        'x-upsert': 'true',
      };

      final response = await http.post(uri, headers: headers, body: bytes).timeout(const Duration(seconds: 20));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final publicUrl = '${FacultySupabaseConfig.supabaseUrl}/storage/v1/object/public/assignments/$path';
        debugPrint('Successfully uploaded assignment file to storage: $publicUrl');
        return publicUrl;
      } else {
        debugPrint('Error uploading assignment file (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception uploading assignment file: $e');
    }
    return null;
  }

  Future<bool> submitAssignment({
    required String assignmentId,
    required String regNo,
    required String studentId,
    required String studentName,
    required String department,
    required String section,
    required String subjectCode,
    required String fileUrl,
    required bool isLate,
  }) async {
    try {
      String? validStudentId;
      if (studentId.isNotEmpty) {
        final existing = await SupabaseClientHelper.select(
          'students',
          selectQuery: 'student_id',
          filterColumn: 'student_id',
          filterValue: studentId,
          schema: 'student',
        );
        if (existing.isNotEmpty) {
          validStudentId = studentId;
        } else if (regNo.isNotEmpty) {
          final byRegNo = await SupabaseClientHelper.select(
            'students',
            selectQuery: 'student_id',
            filterColumn: 'register_no',
            filterValue: regNo,
            schema: 'student',
          );
          if (byRegNo.isNotEmpty) {
            validStudentId = byRegNo.first['student_id']?.toString();
          }
        }
      }

      final payload = <String, dynamic>{
        'assignment_id': assignmentId,
        'reg_no': regNo,
        'student_id': validStudentId,
        'name': studentName,
        'department': department,
        'section': section,
        'subject_code': subjectCode,
        'assignment_file': fileUrl,
        'status': 'Submitted',
        'submitted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_late': isLate,
      };

      final success = await SupabaseClientHelper.upsert(
        'assignment_marks',
        payload,
        'assignment_id,reg_no',
        schema: 'faculty',
      );
      return success;
    } catch (e) {
      debugPrint('Error submitting assignment: $e');
      return false;
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
      // Normalize field names
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

  // --- Lesson Plans (for Reports/Surveys outcome items) ---
  Future<List<Map<String, dynamic>>> getLessonPlans() async {
    try {
      return await SupabaseClientHelper.select('lesson_plans', schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching lesson plans: $e');
      return [];
    }
  }

  // --- Faculties ---
  Future<List<Map<String, dynamic>>> getFaculties() async {
    try {
      return await SupabaseClientHelper.select('faculties', schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching faculties: $e');
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
      debugPrint('Error submitting feedback log: $e');
    }
  }

  Future<bool> submitStudentFeedbackResult({
    required String facultyEmployeeId,
    required String courseCode,
    required String subject,
    required String department,
    required String section,
    required String classSec,
    required String academicYear,
    required int semester,
    required String period,
    required int rating,
    required int knowledge,
    required int methodology,
    required int punctuality,
    required int availability,
    required String comment,
    String? studentAlias,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final feedbackId = 'FB_$timestamp';
      final alias = studentAlias ?? 'Anonymous Student #${(timestamp % 30) + 1}';
      final dateStr = DateTime.now().toString().substring(0, 10);

      final payload = {
        'feedback_id': feedbackId,
        'faculty_employee_id': facultyEmployeeId,
        'course_code': courseCode,
        'subject': subject,
        'department': department,
        'section': section,
        'class_sec': classSec,
        'academic_year': academicYear,
        'semester': semester,
        'period': period,
        'rating': rating,
        'knowledge': knowledge,
        'methodology': methodology,
        'punctuality': punctuality,
        'availability': availability,
        'comment': comment,
        'student_alias': alias,
        'date': dateStr,
      };

      await SupabaseClientHelper.insert('student_feedback_results', payload, schema: 'faculty');
      debugPrint('Successfully inserted feedback to faculty.student_feedback_results');
      return true;
    } catch (e) {
      debugPrint('Error inserting to faculty.student_feedback_results: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCourseAllocations() async {
    try {
      return await SupabaseClientHelper.select('faculty_course_allocations', schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching course allocations: $e');
      return [];
    }
  }

  // --- Transport ---
  Future<List<Map<String, dynamic>>> getTransportBuses() async {
    try {
      return await SupabaseClientHelper.select('transport_buses', schema: 'student');
    } catch (e) {
      debugPrint('Error fetching transport buses: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getStudentTransportPass(String studentIdCode) async {
    try {
      final passes = await SupabaseClientHelper.select('transport_passes', filterColumn: 'student_id', filterValue: studentIdCode, schema: 'student');
      if (passes.isNotEmpty) {
        return passes.first;
      }
    } catch (e) {
      debugPrint('Error fetching student transport pass: $e');
    }
    return null;
  }

  // --- Course Allocations & Regulations ---
  Future<List<Map<String, dynamic>>> getFacultyCourseAllocations() async {
    try {
      return await SupabaseClientHelper.select('faculty_course_allocations', schema: 'faculty');
    } catch (e) {
      debugPrint('Error fetching faculty course allocations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRegulations() async {
    try {
      return await SupabaseClientHelper.select('regulations', schema: 'public');
    } catch (e) {
      debugPrint('Error fetching regulations: $e');
      return [];
    }
  }

  // --- Academic Years (from public.academic_years) ---
  Future<List<Map<String, dynamic>>> getAcademicYears() async {
    try {
      final data = await SupabaseClientHelper.select(
        'academic_years',
        orderBy: 'start_date',
        ascending: true,
        schema: 'public',
      );
      return data.map((row) {
        final raw = row;
        final normalized = normalizeAcademicYearLabel(row['label']?.toString() ?? '');
        return <String, dynamic>{
          ...raw,
          'label_short': normalized,
          'is_current': row['is_current'] == true,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching academic years: $e');
      return [];
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
