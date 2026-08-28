// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// ATTENDANCE SERVICE
/// ============================================================
/// Stores & retrieves attendance sessions from Local Storage.
/// Future: replace body with HTTP calls to PostgreSQL REST API.
/// ============================================================
library;

import 'package:flutter/foundation.dart';
import 'local_storage_base.dart';
import 'supabase_client.dart';
import 'student_service.dart';

class AttendanceService {
  static const String _key = 'attendanceSessions';

  // ── Supabase Integration (No Mock Data) ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchFromSupabase({String facultyId = 'EMP_CSE_002'}) async {
    try {
      final remote = await SupabaseClientHelper.select(
        'attendance_sessions',
        schema: 'faculty',
        filterColumn: 'faculty_employee_id',
        filterValue: facultyId,
      );
      final recordsToUse = remote.isNotEmpty
          ? remote
          : await SupabaseClientHelper.select('attendance_sessions', schema: 'faculty');

      if (recordsToUse.isNotEmpty) {
        final converted = recordsToUse.map((s) => {
          'attendanceId': s['session_code'] ?? s['id']?.toString() ?? '',
          'facultyId': s['faculty_employee_id'] ?? s['faculty_id'] ?? facultyId,
          'date': s['attendance_date'] ?? s['date'] ?? '',
          'day': s['day_of_week'] ?? s['day'] ?? '',
          'period': s['period_code'] ?? s['period'] ?? '',
          'startTime': s['start_time'] ?? '',
          'endTime': s['end_time'] ?? '',
          'subject': s['subject_name'] ?? s['subject'] ?? '',
          'subjectId': s['course_code'] ?? s['subject_id'] ?? '',
          'classSec': s['class_sec'] ?? '${s['department'] ?? ''} - ${s['section'] ?? ''}',
          'sectionId': s['section'] ?? '',
          'departmentId': s['department'] ?? '',
          'semesterId': 'SEM_4',
          'room': s['room_number'] ?? '',
          'present': s['present_count'] ?? s['present'] ?? 0,
          'absent': s['absent_count'] ?? s['absent'] ?? 0,
          'od': s['od_count'] ?? s['od'] ?? 0,
          'ml': s['ml_count'] ?? s['ml'] ?? 0,
          'status': s['is_marked'] == true ? 'Submitted' : 'Pending',
          'records': s['records'] is List ? s['records'] : [],
        }).toList();
        LocalStorageBase.writeList(_key, converted);
        return converted;
      }
    } catch (e) {
      debugPrint('Error fetching attendance from Supabase: $e');
    }
    return getAll();
  }

  // ── CRUD ────────────────────────────────────────────────────
  static List<Map<String, dynamic>> getAll() {
    return LocalStorageBase.readList(_key);
  }

  static List<Map<String, dynamic>> getByClass(String classSec) {
    return getAll().where((s) => s['classSec'] == classSec).toList();
  }

  static List<Map<String, dynamic>> getByFaculty(String facultyId) {
    return getAll().where((s) => s['facultyId'] == facultyId).toList();
  }

  static List<Map<String, dynamic>> getByDate(String date) {
    return getAll().where((s) => s['date'] == date).toList();
  }

  static String _formatIsoDate(dynamic input) {
    if (input == null) return DateTime.now().toIso8601String().split('T')[0];
    final str = input.toString().trim();
    if (str.isEmpty) return DateTime.now().toIso8601String().split('T')[0];
    if (str.contains('/')) {
      final parts = str.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    }
    if (str.contains('-')) {
      final parts = str.split('-');
      if (parts.length == 3 && parts[0].length == 4) {
        final year = parts[0];
        final month = parts[1].padLeft(2, '0');
        final day = parts[2].split('T')[0].split(' ')[0].padLeft(2, '0');
        return '$year-$month-$day';
      }
    }
    return DateTime.now().toIso8601String().split('T')[0];
  }

  static void save(Map<String, dynamic> session) {
    final all = getAll();
    if (session['attendanceId'] == null || session['attendanceId'].toString().isEmpty) {
      session['attendanceId'] = LocalStorageBase.generateId('ATT');
    }
    final idx = all.indexWhere((s) => s['attendanceId'] == session['attendanceId']);
    if (idx >= 0) {
      all[idx] = session;
    } else {
      all.add(session);
    }
    LocalStorageBase.writeList(_key, all);

    // Payload matches faculty.attendance_sessions schema exactly
    final sessionCode = session['attendanceId']?.toString().isNotEmpty == true
        ? session['attendanceId'].toString()
        : 'SES_${session['date']}_${session['period']}_${session['classSec']}'.replaceAll(' ', '_');

    final dept    = (session['departmentId'] ?? session['classSec']?.toString().split('-').first.trim() ?? 'CSE').toString();
    final rawSec  = (session['sectionId'] ?? 'A').toString().replaceAll('SEC_', '').replaceAll('CSE', '').replaceAll('IT', '').trim();
    final section = rawSec.isEmpty ? 'A' : rawSec;

    final payload = <String, dynamic>{
      'session_code':        sessionCode,
      'faculty_employee_id': session['facultyId'] ?? 'EMP_CSE_002',
      'attendance_date':     _formatIsoDate(session['date']),
      'period_code':         session['period'] ?? 'P1',
      'subject_name':        session['subject'] ?? 'Unknown Subject',
      'department':          dept,
      'section':             section,
      'room_number':         session['room'] ?? 'LH-201',
      'present_count':       (session['present'] as num? ?? 0).toInt(),
      'absent_count':        (session['absent'] as num? ?? 0).toInt(),
      'od_count':            (session['od'] as num? ?? 0).toInt(),
      'ml_count':            (session['ml'] as num? ?? 0).toInt(),
      'is_marked':           true,
    };

    SupabaseClientHelper.upsert('attendance_sessions', payload, 'session_code', schema: 'faculty');
  }

  static void delete(String attendanceId) {
    final all = getAll();
    all.removeWhere((s) => s['attendanceId'] == attendanceId);
    LocalStorageBase.writeList(_key, all);
    SupabaseClientHelper.delete('attendance_sessions', 'attendance_id', attendanceId);
  }

  // ── Student Schema Attendance Table Integration ───────────
  static Future<List<Map<String, dynamic>>> fetchStudentAttendanceTable({
    required String date,
    required String classSec,
  }) async {
    String dept = 'CSE';
    String section = 'A';
    String year = 'II Year';

    if (classSec.contains('-')) {
      final parts = classSec.split('-');
      dept = parts[0].trim();
      final secParts = parts[1].trim();
      if (secParts.contains('(')) {
        section = secParts.split('(')[0].trim();
        year = secParts.substring(secParts.indexOf('(') + 1).replaceAll(')', '').trim();
      } else {
        section = secParts;
      }
    }

    final dateStr = _formatIsoDate(date);

    List<Map<String, dynamic>> records = [];
    try {
      final remote = await SupabaseClientHelper.select(
        'attendance_table',
        schema: 'student',
        filterColumn: 'date',
        filterValue: dateStr,
      );

      records = remote.where((r) {
        final rDept = (r['dept'] ?? '').toString().trim().toUpperCase();
        final rSec  = (r['section'] ?? '').toString().trim().toUpperCase();
        return (rDept == dept.toUpperCase()) && (rSec == section.toUpperCase());
      }).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('fetchStudentAttendanceTable error: $e');
    }

    if (records.isEmpty) {
      final allStudents = StudentService.getByClassSec(classSec);
      for (final s in allStudents) {
        final regNo = (s['reg'] ?? s['register_no'] ?? s['roll'] ?? '').toString();
        final name  = (s['name'] ?? s['full_name'] ?? '').toString();
        final sYear = (s['year'] ?? year).toString();

        final newRow = <String, dynamic>{
          'date':    dateStr,
          'reg_no':  regNo,
          'name':    name,
          'dept':    dept,
          'section': section,
          'year':    sYear,
          'p1': null, 'p2': null, 'p3': null, 'p4': null,
          'p5': null, 'p6': null, 'p7': null, 'p8': null,
          'attendance_percentage': null,
        };

        try {
          await SupabaseClientHelper.upsert(
            'attendance_table',
            newRow,
            'reg_no,date',
            schema: 'student',
          );
        } catch (_) {}

        records.add(newRow);
      }
    }

    return records;
  }

  static String? _parseStatusString(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim().toUpperCase();
    if (str.isEmpty) return null;
    if (str == 'TRUE' || str == 'PRESENT') return 'P';
    if (str == 'FALSE' || str == 'ABSENT') return 'A';
    if (str == 'P' || str == 'A' || str == 'OD' || str == 'ML') return str;
    return null;
  }

  static Future<void> updateStudentPeriodAttendance({
    required String date,
    required String classSec,
    required String periodKey,
    required List<Map<String, dynamic>> studentRecords,
  }) async {
    final dateStr = _formatIsoDate(date);
    final periodCol = periodKey.toLowerCase().trim();

    for (final s in studentRecords) {
      final regNo = (s['reg'] ?? s['reg_no'] ?? s['roll'] ?? '').toString();
      if (regNo.isEmpty) continue;

      final currentStatus = (s['status'] ?? 'P').toString().trim().toUpperCase();
      final statusStr = _parseStatusString(currentStatus) ?? 'P';

      final p1v = periodCol == 'p1' ? statusStr : _parseStatusString(s['p1']);
      final p2v = periodCol == 'p2' ? statusStr : _parseStatusString(s['p2']);
      final p3v = periodCol == 'p3' ? statusStr : _parseStatusString(s['p3']);
      final p4v = periodCol == 'p4' ? statusStr : _parseStatusString(s['p4']);
      final p5v = periodCol == 'p5' ? statusStr : _parseStatusString(s['p5']);
      final p6v = periodCol == 'p6' ? statusStr : _parseStatusString(s['p6']);
      final p7v = periodCol == 'p7' ? statusStr : _parseStatusString(s['p7']);
      final p8v = periodCol == 'p8' ? statusStr : _parseStatusString(s['p8']);

      s['p1'] = p1v; s['p2'] = p2v; s['p3'] = p3v; s['p4'] = p4v;
      s['p5'] = p5v; s['p6'] = p6v; s['p7'] = p7v; s['p8'] = p8v;

      String dept = (s['dept'] ?? s['department'] ?? '').toString().trim();
      String sec  = (s['section'] ?? s['sec'] ?? '').toString().trim();
      String year = (s['year'] ?? '').toString().trim();

      if (dept.isEmpty || sec.isEmpty || year.isEmpty) {
        if (classSec.contains('-')) {
          final parts = classSec.split('-');
          if (dept.isEmpty) dept = parts[0].trim();
          final secParts = parts[1].trim();
          if (secParts.contains('(')) {
            if (sec.isEmpty) sec = secParts.split('(')[0].trim();
            if (year.isEmpty) year = secParts.substring(secParts.indexOf('(') + 1).replaceAll(')', '').trim();
          } else {
            if (sec.isEmpty) sec = secParts.trim();
          }
        }
      }
      if (dept.isEmpty) dept = 'CSE';
      if (sec.isEmpty) sec = 'A';
      if (year.isEmpty) year = 'II Year';

      s['dept']    = dept;
      s['section'] = sec;
      s['year']    = year;

      try {
        final payload = <String, dynamic>{
          'date':    dateStr,
          'reg_no':  regNo,
          'name':    (s['name'] ?? '').toString(),
          'dept':    dept,
          'section': sec,
          'year':    year,
          'p1': p1v, 'p2': p2v, 'p3': p3v, 'p4': p4v,
          'p5': p5v, 'p6': p6v, 'p7': p7v, 'p8': p8v,
        };
        final ok = await SupabaseClientHelper.upsert(
          'attendance_table',
          payload,
          'reg_no,date',
          schema: 'student',
        );
        debugPrint('Updated attendance for $regNo ($periodCol = $statusStr): ok=$ok');
      } catch (e) {
        debugPrint('Error updating attendance for reg_no=$regNo: $e');
      }
    }

    await calculateAndStoreTotalAttendancePercentage(force: true);
  }

  /// Calculates total attendance percentage across ALL dates for each student
  /// from 'attendance_table' in 'student' schema and stores it in the
  /// 'attendance_percentage' column in 'student.students'.
  static Future<void> calculateAndStoreTotalAttendancePercentage({bool force = false}) async {
    try {
      final attendanceRows = await SupabaseClientHelper.select(
        'attendance_table',
        schema: 'student',
      );

      if (attendanceRows.isEmpty) return;

      final Map<String, List<Map<String, dynamic>>> studentMap = {};
      for (final row in attendanceRows) {
        final regNo = (row['reg_no'] ?? '').toString().trim();
        if (regNo.isNotEmpty) {
          studentMap.putIfAbsent(regNo, () => []).add(row);
        }
      }

      for (final entry in studentMap.entries) {
        final regNo = entry.key;
        final rows  = entry.value;

        int totalMarked  = 0;
        int totalPresent = 0;

        for (final r in rows) {
          for (final pCol in ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8']) {
            final val = r[pCol];
            if (val != null && val.toString().trim().isNotEmpty) {
              totalMarked++;
              final st = val.toString().trim().toUpperCase();
              if (st == 'P' || st == 'OD') {
                totalPresent++;
              }
            }
          }
        }

        final totalPct = totalMarked > 0
            ? double.parse((totalPresent / totalMarked * 100).toStringAsFixed(2))
            : 100.0;

        try {
          await SupabaseClientHelper.update(
            'students',
            {'attendance_percentage': totalPct},
            'register_no',
            regNo,
            schema: 'student',
          );
        } catch (e) {
          debugPrint('Error updating attendance_percentage for $regNo: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in calculateAndStoreTotalAttendancePercentage: $e');
    }
  }

  /// Submits an attendance correction request to the `hod` schema table `hod.attendance_correction_requests`
  static Future<bool> submitHodCorrectionRequest({
    required String facultyEmployeeId,
    required String facultyName,
    required String department,
    required String yearOfStudy,
    required String section,
    required String subjectCode,
    required String subjectName,
    required String periodCode,
    required String attendanceDate,
    required String reasonCategory,
    required String facultyRemarks,
    required List<Map<String, dynamic>> requestedRecords,
    String? attendanceSessionId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'attendance_session_id': attendanceSessionId,
        'faculty_employee_id': facultyEmployeeId,
        'faculty_name': facultyName,
        'department': department,
        'year_of_study': yearOfStudy,
        'section': section,
        'subject_code': subjectCode,
        'subject_name': subjectName,
        'period_code': periodCode,
        'attendance_date': attendanceDate,
        'reason_category': reasonCategory,
        'faculty_remarks': facultyRemarks,
        'status': 'Pending HOD Approval',
        'requested_records_json': requestedRecords,
      };

      final result = await SupabaseClientHelper.insert(
        'attendance_correction_requests',
        payload,
        schema: 'hod',
      );
      return result != null;
    } catch (e) {
      debugPrint('Error submitting HOD attendance correction request: $e');
      return false;
    }
  }
}

