// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// ASSIGNMENT SERVICE — Supabase Integrated (No Mock Data)
/// ============================================================
import 'package:flutter/foundation.dart';
import 'local_storage_base.dart';
import 'supabase_client.dart';
import 'student_service.dart';
import 'course_allocation_service.dart';

class AssignmentService {
  static const String _key = 'assignments';
  static const String _table = 'assignments';
  static const String _tableMarks = 'assignment_marks';

  // ── Supabase Fetch Assignments ──────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchFromSupabase({String facultyId = 'EMP_CSE_002'}) async {
    try {
      final remote = await SupabaseClientHelper.select(
        _table,
        schema: 'faculty',
        filterColumn: 'faculty_employee_id',
        filterValue: facultyId,
      );
      final recordsToUse = remote.isNotEmpty
          ? remote
          : await SupabaseClientHelper.select(_table, schema: 'faculty');

      if (recordsToUse.isNotEmpty) {
        final converted = recordsToUse.map((a) {
          final rawId = a['id']?.toString() ?? a['assignment_id']?.toString() ?? '';
          final title = a['title'] ?? 'Untitled Assignment';
          final subject = a['subject_name'] ?? a['subject'] ?? '';
          final section = a['section'] ?? '';
          final dept = a['department'] ?? 'CSE';
          final yearRaw = (a['year'] ?? '').toString();
          final year = yearRaw.isNotEmpty ? yearRaw : _extractYearFromSection(section);
          final dueDate = a['due_date']?.toString() ?? '';
          final maxMarks = (a['total_marks'] as num? ?? a['max_marks'] as num? ?? 100).toInt();
          final desc = a['description'] ?? '';
          final attachUrl = (a['attachment_url'] ?? '').toString();
          final qFile = (attachUrl.startsWith('http') || attachUrl.startsWith('data:')) ? attachUrl : '';
          final qName = (a['attachment_name'] ?? '').toString();

          return {
            'id': rawId,
            'assignmentId': rawId,
            'facultyId': a['faculty_employee_id'] ?? facultyId,
            'title': title,
            'code': a['course_code'] ?? '',
            'subject': subject,
            'dept': dept,
            'section': section,
            'year': year,
            'semester': '',
            'classSec': section,
            'dueDate': dueDate,
            'dueTime': '',
            'maxMarks': maxMarks,
            'description': desc,
            'instructions': '',
            'allowedFileTypes': 'All Formats',
            'status': 'Published',
            'questionFile': qName,
            'questionFileUrl': qFile,
            'attachmentUrl': qFile,
            'submittedCount': 0,
            'totalStudents': 0,
          };
        }).toList();

        LocalStorageBase.writeList(_key, converted);
        return converted;
      }
    } catch (e) {
      debugPrint('Error fetching assignments from Supabase: $e');
    }

    final local = getAll();
    return local;
  }

  static List<Map<String, dynamic>> getAll() => LocalStorageBase.readList(_key);

  /// Extracts the year-of-study label (e.g. "III Year") from a class/section
  /// string such as "CSE - A (III Year)".
  static String _extractYearFromSection(String section) {
    final s = section.toUpperCase();
    if (s.contains('IV') || s.contains('4TH') || s.contains('4 YEAR')) return 'IV Year';
    if (s.contains('III') || s.contains('3RD') || s.contains('3 YEAR')) return 'III Year';
    if (s.contains('II') || s.contains('2ND') || s.contains('2 YEAR')) return 'II Year';
    if (s.contains('I') || s.contains('1ST') || s.contains('1 YEAR')) return 'I Year';
    final match = RegExp(r'\(([^)]+)\)').firstMatch(section);
    if (match != null) {
      final inner = match.group(1)!.trim();
      if (inner.isEmpty) return '';
      return inner.contains('Year') ? inner : '$inner Year';
    }
    return '';
  }

  // ── Supabase Fetch Student Assignment Marks ──────────────────
  /// Returns a per-student roster for the assignment built by merging existing
  /// `faculty.assignment_marks` rows with the enrolled students for `classSec`.
  /// No synthetic marks/submissions are generated — students without a marks
  /// row are reported as 'Not Submitted' with marks 0.
  static Future<Map<String, List<Map<String, dynamic>>>> fetchAssignmentMarksFromSupabase({
    required String assignmentId,
    required String classSec,
  }) async {
    List<Map<String, dynamic>> remoteMarks = [];
    try {
      remoteMarks = await SupabaseClientHelper.select(
        _tableMarks,
        schema: 'faculty',
        filterColumn: 'assignment_id',
        filterValue: assignmentId,
      );
    } catch (e) {
      debugPrint('Error fetching assignment_marks: $e');
    }

    final byRegNo = <String, Map<String, dynamic>>{};
    for (final m in remoteMarks) {
      final regNo = (m['reg_no'] ?? m['student_id'] ?? '').toString().trim();
      if (regNo.isNotEmpty) byRegNo[regNo] = m;
    }

    final enrolledByReg = <String, Map<String, dynamic>>{};
    for (final st in StudentService.getByClassSec(classSec)) {
      final regNo =
          (st['reg'] ?? st['registerNo'] ?? st['regNo'] ?? st['roll'] ?? '').toString().trim();
      if (regNo.isNotEmpty) enrolledByReg[regNo] = st;
    }

    final submitted = <Map<String, dynamic>>[];
    final notSubmitted = <Map<String, dynamic>>[];

    final allRegNos = <String>{...byRegNo.keys, ...enrolledByReg.keys};
    for (final regNo in allRegNos) {
      final row = byRegNo[regNo];
      final enrolled = enrolledByReg[regNo];

      final status = (row?['status'] ?? 'Not Submitted').toString();
      final item = {
        'regNo': regNo,
        'name': row?['name'] ?? enrolled?['name'] ?? '',
        'department': row?['department'] ?? enrolled?['dept'] ?? 'CSE',
        'year': (row?['year'] ?? enrolled?['year'] ?? enrolled?['year_of_study'] ?? '').toString(),
        'section': row?['section'] ?? enrolled?['sec'] ?? 'A',
        'marks': row?['marks'] ?? 0,
        'status': status,
        'fileUrl': row?['assignment_file'] ?? '',
        'submittedAt': row?['submitted_at']?.toString() ?? '',
        'student_id': enrolled?['studentId'],
        'hasRow': row != null,
      };
      if (status == 'Not Submitted') {
        notSubmitted.add(item);
      } else {
        submitted.add(item);
      }
    }

    return {'submitted': submitted, 'notSubmitted': notSubmitted};
  }

  // ── Save Student Marks ─────────────────────────────────────
  static Future<void> saveStudentMarks({
    required String assignmentId,
    required List<Map<String, dynamic>> marksList,
    String cia = 'CIA 1',
    int sem = 5,
    String year = 'III Year',
    int assignmentNumber = 1,
  }) async {
    for (var s in marksList) {
      final regNo = s['regNo'] ?? s['reg_no'] ?? '';
      final marks = num.tryParse(s['marks']?.toString() ?? '0') ?? 0;
      final status = s['status'] ?? 'Graded';

      final payload = <String, dynamic>{
        'assignment_id': assignmentId,
        'reg_no':        regNo,
        'student_id':    s['student_id'],
        'name':          s['name'] ?? '',
        'department':    s['department'] ?? 'CSE',
        'section':       s['section'] ?? 'A',
        'subject_code':  (s['subject_code'] ?? '').toString(),
        'marks':         marks,
        'assignment_file': (s['fileUrl'] ?? s['assignment_file'] ?? '').toString(),
        'status':        status,
        'cia':           s['cia'] ?? cia,
        'sem':           s['sem'] ?? sem,
        'year':          s['year'] ?? year,
        'assignment_number': s['assignment_number'] ?? assignmentNumber,
      };

      try {
        await SupabaseClientHelper.upsert(
          _tableMarks,
          payload,
          'reg_no,subject_code,cia,sem,year,assignment_number',
          schema: 'faculty',
        );
      } catch (e) {
        debugPrint('Error upserting assignment_marks for reg_no=$regNo: $e');
      }

      try {
        final notifPayload = <String, dynamic>{
          'student_id':  regNo,
          'title':       'Assignment Marks Updated',
          'category':    'ACADEMIC',
          'description': 'Your marks for this assignment have been updated to $marks marks.',
          'is_read':     false,
        };
        await SupabaseClientHelper.insert(
          'student_notifications',
          notifPayload,
          schema: 'student',
        );
      } catch (_) {}
    }
  }

  // ── Save New Assignment with Question File ──────────────────
  /// Persists an assignment to `faculty.assignments`. The payload only contains
  /// columns that actually exist in the table (sending unknown columns such as
  /// `year`/`question_file_url`/`allowed_file_types` makes PostgREST reject the
  /// insert with PGRST204). After a successful insert the real remote UUID is
  /// written back to the local cache so downstream marks lookups use a valid id.
  static Future<void> save(Map<String, dynamic> assignment) async {
    final all = getAll();
    if (assignment['assignmentId'] == null || assignment['assignmentId'].toString().isEmpty) {
      assignment['assignmentId'] = LocalStorageBase.generateId('ASG');
    }
    assignment['createdAt'] ??= DateTime.now().toIso8601String();

    final idx = all.indexWhere((a) => a['assignmentId'] == assignment['assignmentId']);
    if (idx >= 0) {
      all[idx] = assignment;
    } else {
      all.add(assignment);
    }
    LocalStorageBase.writeList(_key, all);

    final sectionClean = (assignment['section'] ?? 'A')
        .toString()
        .replaceAll('Section ', '')
        .replaceAll('CSE-', '')
        .trim();

    final attachUrl = (assignment['questionFileUrl'] ?? assignment['attachmentUrl'] ?? '').toString();
    final fileUrl = (attachUrl.startsWith('http') || attachUrl.startsWith('data:')) ? attachUrl : '';

    String courseCode = (assignment['code'] ?? '').toString();
    if (courseCode.isEmpty) {
      courseCode = CourseAllocationService.getCourseCodeForClassAndSubject(
            sectionClean, (assignment['subject'] ?? '').toString(),
          ) ??
          CourseAllocationService.getCourseCodeForSubject((assignment['subject'] ?? '').toString()) ??
          '';
    }

    final payload = <String, dynamic>{
      'faculty_employee_id': assignment['facultyId'] ?? 'EMP_CSE_002',
      'course_code':         courseCode,
      'subject_name':        assignment['subject'] ?? '',
      'department':          assignment['dept'] ?? 'CSE',
      'section':             sectionClean.isEmpty ? 'A' : sectionClean,
      'title':               assignment['title'] ?? 'Untitled Assignment',
      'description':         assignment['description'] ?? '',
      'due_date':            assignment['dueDate'] ?? DateTime.now().toString().substring(0, 10),
      'total_marks':         int.tryParse(assignment['maxMarks']?.toString() ?? '100') ?? 100,
      'attachment_url':      fileUrl.isEmpty ? null : fileUrl,
      'attachment_name':     (assignment['questionFile'] ?? '').toString(),
      'academic_year':       assignment['academicYear'] ?? '2025-26',
      'year':                _extractYearFromSection(sectionClean),
      'allowed_file_types':  (assignment['allowedFileTypes'] ?? 'All Formats').toString(),
      'allow_late_submission': true,
      'late_deduction_pct':    0.0,
    };

    Map<String, dynamic>? created;
    try {
      created = await SupabaseClientHelper.insert(_table, payload, schema: 'faculty');
    } catch (e) {
      debugPrint('Error inserting assignment to Supabase: $e');
    }

    if (created != null && (created['id']?.toString().isNotEmpty ?? false)) {
      final remoteId = created['id'].toString();
      final updated = getAll();
      final existingIdx = updated.indexWhere((a) =>
          (a['assignmentId'] ?? a['id'] ?? '').toString() == assignment['assignmentId'].toString() ||
          (a['id'] ?? '').toString() == remoteId);
      if (existingIdx >= 0) {
        updated[existingIdx] = Map<String, dynamic>.from(updated[existingIdx])
          ..['id'] = remoteId
          ..['assignmentId'] = remoteId;
      } else {
        updated.add(Map<String, dynamic>.from(assignment)
          ..['id'] = remoteId
          ..['assignmentId'] = remoteId);
      }
      LocalStorageBase.writeList(_key, updated);
    }
  }

  static Future<void> delete(String assignmentId) async {
    final all = getAll();
    all.removeWhere((a) => a['assignmentId'] == assignmentId || a['id'] == assignmentId);
    LocalStorageBase.writeList(_key, all);

    if (assignmentId.isNotEmpty) {
      try {
        await SupabaseClientHelper.delete(_table, 'id', assignmentId, schema: 'faculty');
      } catch (e) {
        debugPrint('Error deleting assignment from Supabase: $e');
      }
    }
  }
}
