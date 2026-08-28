// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// MARKS SERVICE
/// ============================================================
/// Stores & retrieves marks from Local Storage.
/// Future: replace body with HTTP calls to PostgreSQL REST API.
/// ============================================================
library;

import 'local_storage_base.dart';
import 'supabase_client.dart';

class MarksService {
  static const String _keyMarks    = 'marks';
  static const String _keyStatuses = 'markSheetStatuses';
  static const String _keyAudit    = 'markSheetAuditLogs';

  // ── Seed defaults ────────────────────────────────────────────
  static void seedIfEmpty() {
    // No mock seeding — real data comes directly from Supabase DB.
  }

  // ── Supabase Integration ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchFromSupabase({String facultyId = 'EMP_CSE_002'}) async {
    // 1. Fetch marks records directly from Supabase faculty.marks table
    try {
      final remoteMarks = await SupabaseClientHelper.select('marks', schema: 'faculty');
      if (remoteMarks.isNotEmpty) {
        final formattedMarks = remoteMarks.map((m) => {
          'marksId': m['id']?.toString() ?? '',
          'studentRoll': m['student_roll']?.toString() ?? m['student_id']?.toString() ?? '',
          'register_no': m['register_no']?.toString() ?? m['student_roll']?.toString() ?? '',
          'studentName': m['student_name']?.toString() ?? '',
          'subject': m['subject']?.toString() ?? '',
          'subjectCode': m['subject_code']?.toString() ?? '',
          'assessment': m['assessment']?.toString() ?? '',
          'classSec': m['class_sec']?.toString() ?? '',
          'part_a': m['part_a'] ?? 0,
          'part_b': m['part_b'] ?? 0,
          'total': m['total'] ?? 0,
          'max_marks': m['max_marks'] ?? 50,
          'percentage': m['percentage'] ?? 0,
          'grade': m['grade']?.toString() ?? 'F',
          'facultyEmployeeId': m['faculty_employee_id']?.toString() ?? facultyId,
        }).toList();
        LocalStorageBase.writeList(_keyMarks, formattedMarks);
      }
    } catch (e) {
      // Keep existing local cache if offline
    }

    // 2. Fetch mark sheet statuses from Supabase
    final remote = await SupabaseClientHelper.select(
      'mark_sheet_statuses',
      schema: 'faculty',
      filterColumn: 'faculty_employee_id',
      filterValue: facultyId,
    );
    final recordsToUse = remote.isNotEmpty
        ? remote
        : await SupabaseClientHelper.select('mark_sheet_statuses', schema: 'faculty');

    if (recordsToUse.isNotEmpty) {
      final statuses = <String, String>{};
      for (final s in recordsToUse) {
        final key = '${s['assessment_type']}_${s['department']} - ${s['section']}_${s['subject_name']}';
        statuses[key] = s['status'] ?? 'Draft';
      }
      LocalStorageBase.writeMap(_keyStatuses, statuses);
    }
    return getAll();
  }

  // ── Marks CRUD ──────────────────────────────────────────────
  static List<Map<String, dynamic>> getAll() => LocalStorageBase.readList(_keyMarks);

  static List<Map<String, dynamic>> getBySubjectAndClass(String subject, String classSec) {
    return getAll().where((m) => m['subject'] == subject && m['classSec'] == classSec).toList();
  }

  static List<Map<String, dynamic>> getByExam(String exam, String classSec, String subject) {
    return getAll().where((m) =>
      m['assessment'] == exam &&
      m['classSec'] == classSec &&
      m['subject'] == subject
    ).toList();
  }

  /// Upserts a batch of marks records
  static void saveMany(List<Map<String, dynamic>> newMarks) {
    final all = getAll();
    for (final m in newMarks) {
      if (m['marksId'] == null || m['marksId'].toString().isEmpty) {
        m['marksId'] = LocalStorageBase.generateId('MRK');
      }
      final idx = all.indexWhere((x) =>
        x['studentRoll'] == m['studentRoll'] &&
        x['subject']     == m['subject'] &&
        x['assessment']  == m['assessment']);
      if (idx >= 0) {
        all[idx] = m;
      } else {
        all.add(m);
      }

      final regNo = (m['studentReg'] ?? m['register_no'] ?? m['studentRoll'] ?? '').toString();
      final rollNo = (m['studentRoll'] ?? '').toString();
      final subj = (m['subject'] ?? '').toString();
      final assess = (m['assessment'] ?? '').toString();
      final facId = (m['facultyId'] ?? m['facultyEmployeeId'] ?? 'EMP_CSE_002').toString();

      // Sync to Supabase asynchronously using composite unique constraint
      SupabaseClientHelper.upsert('marks', {
        'student_id': m['studentId'] ?? rollNo,
        'student_roll': rollNo,
        'register_no': regNo.isNotEmpty ? regNo : rollNo,
        'student_name': m['studentName'] ?? '',
        'faculty_employee_id': facId,
        'subject': subj,
        'subject_code': m['subjectCode'] ?? '24CST57',
        'assessment': assess,
        'class_sec': m['classSec'] ?? '',
        'part_a': m['partA'] ?? m['part_a'] ?? 0,
        'part_b': m['partB'] ?? m['part_b'] ?? 0,
        'total': m['total'] ?? 0,
        'max_marks': m['max_marks'] ?? 50,
        'percentage': m['percentage'] ?? 0,
        'grade': m['grade'] ?? 'F',
        'status': m['status'] ?? 'Draft',
        'remarks': m['remarks'] ?? '',
      }, 'register_no,subject,assessment', schema: 'faculty');
    }
    LocalStorageBase.writeList(_keyMarks, all);
  }

  // ── Marksheet workflow ──────────────────────────────────────
  static Map<String, String> getAllStatuses() {
    final raw = LocalStorageBase.readMap(_keyStatuses);
    return raw.map((k, v) => MapEntry(k, v.toString()));
  }

  static String getStatus(String exam, String classSec, String subject) {
    final statuses = getAllStatuses();
    return statuses['${exam}_${classSec}_$subject'] ?? '';
  }

  static void setStatus(String exam, String classSec, String subject, String status) {
    final statuses = getAllStatuses();
    statuses['${exam}_${classSec}_$subject'] = status;
    LocalStorageBase.writeMap(_keyStatuses, statuses);
  }

  static void saveDraft(String exam, String classSec, String subject, List<Map<String, dynamic>> newMarks) {
    setStatus(exam, classSec, subject, 'Draft');
    saveMany(newMarks);
  }

  static void submitSheet(String exam, String classSec, String subject, List<Map<String, dynamic>> newMarks) {
    setStatus(exam, classSec, subject, 'Submitted for Verification');
    saveMany(newMarks);
    
    final subDates = LocalStorageBase.readMap('markSheetSubmissionDates');
    subDates['${exam}_${classSec}_$subject'] = DateTime.now().toString().substring(0, 10);
    LocalStorageBase.writeMap('markSheetSubmissionDates', subDates);
  }

  // ── Audit log ───────────────────────────────────────────────
  static Map<String, List<Map<String, dynamic>>> getAllAuditLogs() {
    final raw = LocalStorageBase.readMap(_keyAudit);
    return raw.map((k, v) {
      if (v is List) {
        final list = v.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        return MapEntry(k, list);
      }
      return MapEntry(k, <Map<String, dynamic>>[]);
    });
  }

  static List<Map<String, dynamic>> getAuditLog(String exam, String classSec, String subject) {
    final logs = getAllAuditLogs();
    return logs['${exam}_${classSec}_$subject'] ?? [];
  }

  static void addAuditEntry(String exam, String classSec, String subject,
      String faculty, String prev, String next, String? reason) {
    final key = '${exam}_${classSec}_$subject';
    final logs = getAllAuditLogs();
    logs.putIfAbsent(key, () => []);
    logs[key]!.add({
      'by': faculty,
      'time': DateTime.now().toString().substring(0, 19),
      'prev': prev,
      'next': next,
      'reason': reason ?? 'No reason provided',
    });
    LocalStorageBase.writeMap(_keyAudit, logs);
  }
}

