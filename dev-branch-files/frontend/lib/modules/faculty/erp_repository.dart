// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'services/local_storage_base.dart';
import 'services/attendance_service.dart';
import 'services/marks_service.dart';
import 'services/lesson_service.dart';
import 'services/syllabus_service.dart';
import 'services/question_bank_service.dart';
import 'services/assignment_service.dart';
import 'services/leave_service.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';
import 'services/timetable_service.dart';
import 'services/student_service.dart';
import 'services/course_allocation_service.dart';

class ErpRepository extends ChangeNotifier {
  static const String activeFacultyId = 'EMP_CSE_002';
  static final ErpRepository _instance = ErpRepository._internal();
  factory ErpRepository() => _instance;
  ErpRepository._internal() {
    _initData();
    loadData();
  }

  bool isLoadingData = true;

  // Active navigation index
  int _selectedMenuIndex = 0;
  int get selectedMenuIndex => _selectedMenuIndex;
  set selectedMenuIndex(int val) {
    _selectedMenuIndex = val;
    notifyListeners();
  }

  // Academic Year selection
  String selectedAcademicYear = '2025-26';

  void notify() {
    saveAllToLocalStorage();
    notifyListeners();
  }

  // ─── Data Tables ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> attendanceSessions = [];
  List<Map<String, dynamic>> marks = [];
  List<Map<String, dynamic>> leaveApplications = [];
  List<Map<String, dynamic>> lessonPlans = [];
  List<Map<String, dynamic>> syllabusUploads = [];
  List<Map<String, dynamic>> syllabusTopics = [];
  List<Map<String, dynamic>> questionBank = [];
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> timetable = [];
  Map<String, dynamic> profile = {};
  Map<String, String> markSheetStatuses = {};
  Map<String, List<Map<String, dynamic>>> markSheetAuditLogs = {};

  // Leave balances
  Map<String, int> leaveBalances = {
    'Casual Leave': 0,
    'Medical Leave': 0,
    'Earned Leave': 0,
    'On Duty': 0,
    'Compensatory Leave': 0,
  };

  Map<String, Map<String, double>> leaveBalancesMap = {
    'Casual Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
    'Medical Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
    'Sick Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
    'Earned Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
    'On Duty': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
    'Compensatory Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
    'Special Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
  };

  void _initData() {
    students = List<Map<String, dynamic>>.from(StudentService.getAll());
    attendanceSessions = AttendanceService.getAll();
    marks = MarksService.getAll();
    leaveApplications = LeaveService.getAll();
    lessonPlans = LessonService.getAll();
    syllabusUploads = SyllabusService.getAll();
    questionBank = QuestionBankService.getAll();
    assignments = AssignmentService.getAll();
    notifications = NotificationService.getAll();
    timetable = TimetableService.getAll();
    profile = ProfileService.get();
  }

  void saveAllToLocalStorage() {
    // Delegate to each service — keeps LocalStorage writes in one place.
    LocalStorageBase.writeList('students',          students);
    LocalStorageBase.writeMap ('profile',            profile);
    LocalStorageBase.writeList('attendanceSessions', attendanceSessions);
    LocalStorageBase.writeList('marks',              marks);
    LocalStorageBase.writeList('leaveApplications',  leaveApplications);
    LocalStorageBase.writeList('lessonPlans',        lessonPlans);
    LocalStorageBase.writeList('syllabusUploads',    syllabusUploads);
    LocalStorageBase.writeList('syllabusTopics',     syllabusTopics);
    LocalStorageBase.writeList('questionBank',       questionBank);
    LocalStorageBase.writeList('assignments',        assignments);
    LocalStorageBase.writeList('notifications',      notifications);
    LocalStorageBase.writeList('timetable',          timetable);
    LocalStorageBase.writeMap ('markSheetStatuses',  markSheetStatuses);
    LocalStorageBase.writeMap ('markSheetAuditLogs', markSheetAuditLogs);
    LocalStorageBase.writeMap ('questionPaperConfigs', questionPaperConfigs);
  }

  Map<String, dynamic> questionPaperConfigs = {};

  void saveQuestionPaperConfig(String key, Map<String, dynamic> config) {
    questionPaperConfigs[key] = config;
    LocalStorageBase.writeMap('questionPaperConfigs', questionPaperConfigs);
    notifyListeners();
  }

  Map<String, dynamic>? getQuestionPaperConfig(String key) {
    if (questionPaperConfigs.containsKey(key)) {
      final val = questionPaperConfigs[key];
      if (val is Map) return Map<String, dynamic>.from(val);
    }
    final read = LocalStorageBase.readMap('questionPaperConfigs');
    if (read.containsKey(key)) {
      final val = read[key];
      if (val is Map) {
        questionPaperConfigs[key] = val;
        return Map<String, dynamic>.from(val);
      }
    }
    return null;
  }

  int get totalUploadsCount => syllabusUploads.length + assignments.length;

  static const String _fallbackPdfBase64 =
      'JVBERi0xLjQKMSAwIG9iago8PAovVHlwZSAvQ2F0YWxvZwovUGFnZXMgMiAwIFIKPj4KZW5kb2JqCjIgMCBvYmoKPDAKL1R5cGUgL1BhZ2VzCi9LaWRzIFszIDAgUl0KL0NvdW50IDEKPj4KZW5kb2JqCjMgMCBvYmoKPDAKL1R5cGUgL1BhZ2UKL1BhcmVudCAyIDAgUgovTWVkaWFCb3hbMCAwIDYxMiA3OTJdCi9SZXNvdXJjZXMgPDw+PgovQ29udGVudHMgNCAwIFIKPj4KZW5kb2JqCjQgMCBvYmoKPDAKL0xlbmd0aCA0NQo+PgpzdHJlYW0KQlQKL0YxIDEyIFRmCjEwMCA3MDAgVGRDCihDRU5UUkFMSVpFRCBDQU1TIEFDQURFTUlDIFBERiBET0NVTUVOVCkgVGoKRU5ECmVuZHN0cmVhbQplbmRvYmoKeHJlZgowIDUKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDE1IDAwMDAwIG4gCjAwMDAwMDAwNjggMDAwMDAgbiAKMDAwMDAwMDEyOSAwMDAwMCBuIAowMDAwMDAwMjMwIDAwMDAwIG4gCnRyYWlsZXIKPDAKL1NpemUgNQovUm9vdCAxIDAgUgo+PgpzdGFydHhyZWYKMzI1CiUlRU9G';

  void triggerFileDownload(String filename, String content, String mimeType) {
    try {
      if (content.startsWith('http://') || content.startsWith('https://')) {
        html.AnchorElement(href: content)
          ..setAttribute('download', filename)
          ..target = '_blank'
          ..click();
        return;
      }
      if (content.startsWith('data:')) {
        final parts = content.split(',');
        final base64Data = parts.length > 1 ? parts[1] : parts[0];
        final bytes = base64.decode(base64Data);
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
        return;
      }

      List<int> bytes;
      if (mimeType.contains('pdf') && !content.startsWith('%PDF')) {
        bytes = base64.decode(_fallbackPdfBase64);
      } else {
        bytes = utf8.encode(content);
      }

      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint("Download failed: $e");
    }
  }

  void triggerNativeUpload(Function(String name, int size, String dataUrl) callback) {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.click();
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.onLoadEnd.listen((e) {
            callback(file.name, file.size, reader.result as String);
          });
          reader.readAsDataUrl(file);
        }
      });
    } catch (e) {
      debugPrint("Upload failed: $e");
    }
  }

  void setGlobalPrintContent(String htmlContent) {
    // Kept for backward compatibility
  }

  void triggerPrintHtmlDocument(String htmlContent) {
    try {
      // Create a Blob from the standalone HTML document
      final blob = html.Blob([htmlContent], 'text/html;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Open a clean standalone window containing ONLY the HTML document
      final dynamic printWin = html.window.open(url, '_blank');
      
      if (printWin != null) {
        Future.delayed(const Duration(milliseconds: 600), () {
          try {
            printWin.focus();
            printWin.print();
          } catch (e) {
            debugPrint("Print window error: $e");
          }
          Future.delayed(const Duration(seconds: 5), () {
            html.Url.revokeObjectUrl(url);
          });
        });
      } else {
        _printViaIframe(htmlContent);
      }
    } catch (e) {
      debugPrint("Print window failed: $e");
      _printViaIframe(htmlContent);
    }
  }

  Future<void> exportHtmlToPdf(String filename, String htmlContent) async {
    try {
      if (html.document.getElementById('html2pdf-script') == null) {
        final script = html.ScriptElement()
          ..id = 'html2pdf-script'
          ..src = 'https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js';
        html.document.head?.children.add(script);

        for (int i = 0; i < 30; i++) {
          if (js.context.hasProperty('html2pdf')) break;
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      final div = html.DivElement()
        ..style.position = 'fixed'
        ..style.left = '-9999px'
        ..style.top = '0'
        ..style.width = '1000px'
        ..innerHtml = htmlContent;

      html.document.body?.children.add(div);

      final opts = js.JsObject.jsify({
        'margin': [8, 8, 8, 8],
        'filename': filename,
        'image': {'type': 'jpeg', 'quality': 0.98},
        'html2canvas': {'scale': 2},
        'jsPDF': {'unit': 'mm', 'format': 'a4', 'orientation': 'landscape'}
      });

      if (js.context.hasProperty('html2pdf')) {
        final dynamic html2pdfFn = js.context['html2pdf'];
        final dynamic worker = html2pdfFn(div, opts);
        worker.callMethod('save', []);
      } else {
        triggerPrintHtmlDocument(htmlContent);
      }

      Future.delayed(const Duration(seconds: 4), () {
        try {
          div.remove();
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('exportHtmlToPdf error: $e');
      triggerPrintHtmlDocument(htmlContent);
    }
  }

  void _printViaIframe(String htmlContent) {
    try {
      final iframe = html.IFrameElement()
        ..style.position = 'fixed'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.width = '0'
        ..style.height = '0'
        ..style.border = '0';
      html.document.body?.children.add(iframe);

      final dynamic win = iframe.contentWindow;
      if (win != null) {
        win.document?.open();
        win.document?.write(htmlContent);
        win.document?.close();
        Future.delayed(const Duration(milliseconds: 400), () {
          try {
            win.print();
          } catch (_) {}
          Future.delayed(const Duration(seconds: 2), () {
            iframe.remove();
          });
        });
      }
    } catch (e) {
      debugPrint("Iframe print error: $e");
    }
  }

  Future<void> loadData() async {
    isLoadingData = true;
    notifyListeners();

    try {
      // 1. Profile — via ProfileService for active logged-in faculty FAC002
      try {
        profile = await ProfileService.fetchFromSupabase(employeeId: activeFacultyId);
        if (profile.isEmpty || profile['employeeId'] == null || profile['employeeId'].toString().isEmpty) {
          final newProfile = Map<String, dynamic>.from(profile);
          newProfile['employeeId'] = activeFacultyId;
          newProfile['facultyId'] = activeFacultyId;
          ProfileService.save(newProfile);
          profile = newProfile;
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
        profile = ProfileService.get();
      }

      // 2. Students — via StudentService
      try {
        students = await StudentService.fetchFromSupabase();
      } catch (e) {
        debugPrint('Error loading students: $e');
        students = StudentService.getAll();
      }

      // 3. Attendance — via AttendanceService (for FAC002)
      try {
        attendanceSessions = await AttendanceService.fetchFromSupabase(facultyId: activeFacultyId);
      } catch (e) {
        debugPrint('Error loading attendance: $e');
        attendanceSessions = AttendanceService.getAll();
      }

      // 4. Marks — via MarksService (for FAC002)
      try {
        await MarksService.fetchFromSupabase(facultyId: activeFacultyId);
        markSheetStatuses = MarksService.getAllStatuses();
        markSheetAuditLogs = MarksService.getAllAuditLogs();
      } catch (e) {
        debugPrint('Error loading marks: $e');
      }

      // 5. Leave — via LeaveService (for FAC002)
      try {
        leaveApplications = await LeaveService.fetchFromSupabase();
        _recalculateLeaveBalances(activeFacultyId);
      } catch (e) {
        debugPrint('Error loading leave: $e');
        leaveApplications = LeaveService.getAll();
      }

      // 6. Lesson Plans — via LessonService (for FAC002)
      try {
        lessonPlans = await LessonService.fetchFromSupabase(facultyId: activeFacultyId);
      } catch (e) {
        debugPrint('Error loading lesson plans: $e');
        lessonPlans = LessonService.getAll();
      }

      // 7. Syllabus — via SyllabusService
      try {
        syllabusUploads = await SyllabusService.fetchFromSupabase();
        final loadedTopics = LocalStorageBase.readList('syllabusTopics');
        if (loadedTopics.isNotEmpty) {
          syllabusTopics = loadedTopics;
        }
      } catch (e) {
        debugPrint('Error loading syllabus: $e');
        syllabusUploads = SyllabusService.getAll();
      }

      // 8. Question Bank — via QuestionBankService
      try {
        questionBank = await QuestionBankService.fetchFromSupabase();
      } catch (e) {
        debugPrint('Error loading question bank: $e');
        questionBank = QuestionBankService.getAll();
      }

      // 9. Assignments — via AssignmentService (for FAC002)
      try {
        assignments = await AssignmentService.fetchFromSupabase(facultyId: activeFacultyId);
      } catch (e) {
        debugPrint('Error loading assignments: $e');
        assignments = AssignmentService.getAll();
      }

      // 10. Notifications — via NotificationService (for FAC002)
      try {
        notifications = await NotificationService.fetchFromSupabase(facultyId: activeFacultyId);
      } catch (e) {
        debugPrint('Error loading notifications: $e');
        notifications = NotificationService.getAll();
      }

      // 11. Timetable — via TimetableService (for EMP_CSE_002)
      try {
        timetable = await TimetableService.fetchFromSupabase(facultyId: activeFacultyId);
      } catch (e) {
        debugPrint('Error loading timetable: $e');
        timetable = TimetableService.getAll();
      }

      // 12. Course Allocations — via CourseAllocationService (for EMP_CSE_002)
      try {
        await CourseAllocationService.fetchAllocations(facultyId: activeFacultyId);
      } catch (e) {
        debugPrint('Error loading course allocations: $e');
      }
    } finally {
      isLoadingData = false;
      notifyListeners();
    }
  }

  void _recalculateLeaveBalances(String facultyId) {
    leaveBalances = LeaveService.getBalances(facultyId);
  }

  Future<void> applyLeave(Map<String, dynamic> leave) async {
    LeaveService.apply(leave);
    final facultyId = profile['facultyId']?.toString() ?? 'FAC73124';
    leaveApplications = LeaveService.getByFaculty(facultyId);

    NotificationService.push({
      'facultyId': profile['facultyId'] ?? 'FAC73124',
      'title': 'New Leave Applied',
      'body': 'Leave application for ${leave['days']} days submitted successfully.',
      'time': 'Just now',
      'read': false,
      'tag': 'Approval',
      'priority': 'MEDIUM',
      'type': 'leave'
    });
    notifications = NotificationService.getAll();

    _recalculateLeaveBalances(facultyId);
    notifyListeners();
  }

  Future<void> withdrawLeave(String id) async {
    await LeaveService.withdraw(id);
    leaveApplications.removeWhere((app) => (app['id']?.toString() ?? app['leaveId']?.toString()) == id);
    _recalculateLeaveBalances(profile['employeeId'] ?? 'EMP_CSE_002');
    notifyListeners();
  }

  // ─── Student Logics ────────────────────────────────────────────────────────
  Future<bool> addStudent(Map<String, dynamic> student) async {
    StudentService.add(student);
    students = StudentService.getAll();
    notifyListeners();
    return true;
  }

  // ─── Assignment Logics ─────────────────────────────────────────────────────
  Future<void> addAssignment(Map<String, dynamic> assignment) async {
    await AssignmentService.save(assignment);
    try {
      assignments = await AssignmentService.fetchFromSupabase();
    } catch (e) {
      assignments = AssignmentService.getAll();
    }
    notifyListeners();
  }

  Future<void> deleteAssignment(String assignmentId) async {
    AssignmentService.delete(assignmentId);
    assignments = AssignmentService.getAll();
    notifyListeners();
  }

  // ─── Attendance Logics ─────────────────────────────────────────────────────
  Future<void> saveAttendanceSession(Map<String, dynamic> session) async {
    AttendanceService.save(session);
    attendanceSessions = AttendanceService.getAll();

    NotificationService.push({
      'facultyId': profile['facultyId'] ?? 'FAC73124',
      'title': 'Attendance Saved',
      'body': 'Attendance for ${session['classSec']} saved successfully.',
      'time': 'Just now',
      'read': false,
      'tag': 'System Alert',
      'priority': 'HIGH',
      'type': 'attendance'
    });
    notifications = NotificationService.getAll();

    notifyListeners();
  }

  // ─── Marks Logics ──────────────────────────────────────────────────────────
  Future<void> saveMarks(List<Map<String, dynamic>> newMarks) async {
    MarksService.saveMany(newMarks);
    marks = MarksService.getAll();
    notifyListeners();
  }

  Future<void> saveMarkSheetDraft(String exam, String classSec, String subject, List<Map<String, dynamic>> newMarks) async {
    MarksService.saveDraft(exam, classSec, subject, newMarks);
    marks             = MarksService.getAll();
    markSheetStatuses = MarksService.getAllStatuses();
    notifyListeners();
  }

  Future<void> submitMarkSheet(String exam, String classSec, String subject, List<Map<String, dynamic>> newMarks) async {
    MarksService.submitSheet(exam, classSec, subject, newMarks);
    marks             = MarksService.getAll();
    markSheetStatuses = MarksService.getAllStatuses();
    notifyListeners();
  }

  Future<void> auditMarkSheetChange(String exam, String classSec, String subject, String facultyName, String prevMarks, String updatedMarks, String? reason) async {
    MarksService.addAuditEntry(exam, classSec, subject, facultyName, prevMarks, updatedMarks, reason);
    markSheetAuditLogs = MarksService.getAllAuditLogs();
    notifyListeners();
  }

  // ─── Notifications Logics ──────────────────────────────────────────────────
  int get unreadNotificationsCount => notifications.where((n) => n['read'] != true).length;

  Future<void> reloadNotifications() async {
    try {
      notifications = await NotificationService.fetchFromSupabase(facultyId: activeFacultyId);
    } catch (_) {
      notifications = NotificationService.getAll();
    }
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String id, {bool read = true}) async {
    NotificationService.markRead(id, read: read);
    notifications = NotificationService.getAll();
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    NotificationService.markAllRead(profile['facultyId']?.toString() ?? 'FAC73124');
    notifications = NotificationService.getAll();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    NotificationService.delete(id);
    notifications = NotificationService.getAll();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final list = <Map<String, dynamic>>[];

    // 1. Search Students
    for (var s in students) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final reg  = (s['reg']  ?? '').toString().toLowerCase();
      final roll = (s['roll'] ?? '').toString().toLowerCase();
      final dept = (s['dept'] ?? '').toString().toLowerCase();
      final sec  = (s['sec']  ?? '').toString().toLowerCase();

      if (name.contains(q) || reg.contains(q) || roll.contains(q) || dept.contains(q) || sec.contains(q)) {
        list.add({
          'type': 'student',
          'title': s['name'] ?? '',
          'subtitle': 'Roll No: ${s['roll']} | Reg: ${s['reg']} | Dept: ${s['dept']} | Sec: ${s['sec']}',
          'details': s,
        });
      }
    }

    // 2. Search Subjects & Timetable slots
    final seenSubjects = <String>{};
    for (var day in timetable) {
      for (var s in (day['schedule'] as List? ?? [])) {
        final subject = (s['subject'] ?? '').toString();
        final code    = (s['code']    ?? '').toString();
        final classSec = (s['classSec'] ?? '').toString();
        
        final subjectL = subject.toLowerCase();
        final codeL    = code.toLowerCase();
        final classSecL = classSec.toLowerCase();

        final matchesQuery = subjectL.contains(q) || codeL.contains(q) || classSecL.contains(q);
        if (matchesQuery) {
          final key = '$subject|$code';
          if (!seenSubjects.contains(key) && subject.isNotEmpty) {
            seenSubjects.add(key);
            list.add({
              'type': 'subject',
              'title': subject,
              'subtitle': 'Subject Code: $code | Class: $classSec',
              'details': s,
            });
          }
        }
      }
    }

    // 3. Search Classes
    final seenClasses = <String>{};
    for (var day in timetable) {
      for (var s in (day['schedule'] as List? ?? [])) {
        final classSec = (s['classSec'] ?? '').toString();
        if (classSec.toLowerCase().contains(q) && classSec.isNotEmpty) {
          if (!seenClasses.contains(classSec)) {
            seenClasses.add(classSec);
            list.add({
              'type': 'subject',
              'title': classSec,
              'subtitle': 'Engineering Class & Section | Department: CSE/IT',
              'details': s,
            });
          }
        }
      }
    }

    // 4. Search Lesson Progress Topics
    for (var lp in lessonPlans) {
      final topic = (lp['topic'] ?? '').toString();
      final subj = (lp['subject'] ?? '').toString();
      final unit = (lp['unit'] ?? '').toString();
      final cls = (lp['classSec'] ?? '').toString();
      if (topic.toLowerCase().contains(q) || subj.toLowerCase().contains(q) || unit.toLowerCase().contains(q) || cls.toLowerCase().contains(q)) {
        list.add({
          'type': 'subject',
          'title': topic,
          'subtitle': 'Lesson Progress Topic | $subj | $unit ($cls)',
          'details': lp,
        });
      }
    }

    return list;
  }

  Future<Map<String, dynamic>> checkMedicalLeave(String roll, {String? date}) async {
    final target = leaveApplications.where(
      (l) => l['status'] == 'Approved' && l['type'] == 'Medical Leave',
    ).firstOrNull ?? <String, dynamic>{};
    if (target.isNotEmpty) {
      return {'hasMl': true, 'leave': target};
    }
    return {'hasMl': false};
  }

  // ── Question Bank Status Summary (Dashboard Integration) ─────────────────────
  int get qbTotalCount => questionBank.length;
  int get qbDraftCount => questionBank.where((q) => (q['status'] ?? q['submissionStatus']) == 'Draft').length;
  int get qbPendingHodCount => questionBank.where((q) {
    final s = (q['status'] ?? q['submissionStatus'] ?? '').toString();
    return s == 'Submitted' || s == 'Pending Review' || s == 'Pending HOD Review';
  }).length;
  int get qbApprovedCount => questionBank.where((q) {
    final s = (q['status'] ?? q['submissionStatus'] ?? '').toString();
    return s == 'Approved' || s == 'Approved by HOD';
  }).length;
  int get qbRejectedCount => questionBank.where((q) {
    final s = (q['status'] ?? q['submissionStatus'] ?? '').toString();
    return s == 'Rejected' || s == 'Rejected by HOD';
  }).length;
}
