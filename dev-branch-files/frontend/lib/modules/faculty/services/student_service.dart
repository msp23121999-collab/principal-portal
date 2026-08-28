import 'package:flutter/foundation.dart';
import 'local_storage_base.dart';
import 'supabase_client.dart';

/// STUDENT SERVICE — Supabase Integrated & Robust Filter Logic (No Mock Data)
class StudentService {
  static const String _key = 'students';
  static const String _table = 'students';
  static const String _schema = 'student';

  static void seedIfEmpty() {}

  static void add(Map<String, dynamic> student) {
    final current = LocalStorageBase.readList(_key);
    current.add(student);
    LocalStorageBase.writeList(_key, current);
  }

  static List<Map<String, dynamic>> getAll() {
    return LocalStorageBase.readList(_key);
  }

  static String extractYear(dynamic text) {
    if (text == null) return '';
    final s = text.toString().toUpperCase().trim();
    if (s.contains('IV') || s.contains('4TH') || s.contains('YEAR 4') || s.contains('FOURTH')) return 'IV';
    if (s.contains('III') || s.contains('3RD') || s.contains('YEAR 3') || s.contains('THIRD')) return 'III';
    if (s.contains('II') || s.contains('2ND') || s.contains('YEAR 2') || s.contains('SECOND')) return 'II';
    if (s.contains('I') || s.contains('1ST') || s.contains('YEAR 1') || s.contains('FIRST')) return 'I';
    return '';
  }

  static String calcYearFromSem(dynamic semRaw) {
    final sem = int.tryParse(semRaw?.toString() ?? '') ?? 0;
    if (sem >= 7) return 'IV';
    if (sem >= 5) return 'III';
    if (sem >= 3) return 'II';
    if (sem >= 1) return 'I';
    return '';
  }

  static Future<List<Map<String, dynamic>>> fetchFromSupabase() async {
    try {
      final remote = await SupabaseClientHelper.select(_table, schema: _schema);
      if (remote.isNotEmpty) {
        final converted = remote.map((s) {
          final sem = s['semester']?.toString() ?? '4';
          final yr = (s['year_of_study'] ?? calcYearFromSem(sem)).toString();
          return {
            'studentId': s['student_id'] ?? s['id'] ?? '',
            'roll': s['roll_no'] ?? s['roll_number'] ?? s['register_no'] ?? '',
            'reg': s['register_no'] ?? s['register_number'] ?? s['roll_no'] ?? '',
            'name': s['full_name'] ?? s['name'] ?? '',
            'gender': s['gender'] ?? '',
            'email': s['institute_email'] ?? s['personal_email'] ?? s['email'] ?? '',
            'phone': s['mobile_number'] ?? s['phone'] ?? '',
            'dept': s['department'] ?? 'CSE',
            'sem': sem,
            'sec': s['section'] ?? 'A',
            'year_of_study': yr,
            'year': yr,
            'programme': s['degree'] ?? 'B.E.',
            'status': s['status'] ?? 'Continuing',
            'attendance_percentage': s['attendance_percentage'] ?? s['attendance_pct'],
            'tnea_rank': s['tnea_rank'] ?? '',
            'umis_no': s['umis_no'] ?? '',
            'emis_no': s['emis_no'] ?? '',
            'special_reservation': s['special_reservation'] ?? '',
            'place_of_birth': s['place_of_birth'] ?? '',
            'father_name': s['father_name'] ?? '',
            'father_mobile': s['father_mobile'] ?? '',
            'mother_name': s['mother_name'] ?? '',
            'mother_mobile': s['mother_mobile'] ?? '',
          };
        }).toList();
        LocalStorageBase.writeList(_key, converted);
        return converted;
      }
    } catch (e) {
      debugPrint('Error fetching students from Supabase: $e');
    }
    return getAll();
  }

  /// Fetches students with precise multi-column filters from `student.students`.
  /// Used by attendance, marks entry, and assignment pages for accurate student lists.
  static Future<List<Map<String, dynamic>>> fetchStudentsByFilter({
    required String department,
    required String section,
    String? yearOfStudy,
    String? regulationYear,
  }) async {
    try {
      final filters = <String, String>{
        'department': department,
        'section': section,
      };
      if (yearOfStudy != null && yearOfStudy.isNotEmpty) {
        filters['year_of_study'] = yearOfStudy;
      }
      if (regulationYear != null && regulationYear.isNotEmpty) {
        filters['regulation_year'] = regulationYear;
      }

      debugPrint('StudentService.fetchStudentsByFilter: filters=$filters');

      final remote = await SupabaseClientHelper.selectWithFilters(
        _table,
        schema: _schema,
        filters: filters,
        orderBy: 'roll_no',
      );

      if (remote.isNotEmpty) {
        return remote.map((s) {
          final sem = s['semester']?.toString() ?? '';
          final yr = (s['year_of_study'] ?? calcYearFromSem(sem)).toString();
          return {
            'studentId': s['student_id'] ?? s['id'] ?? '',
            'roll': s['roll_no'] ?? s['roll_number'] ?? s['register_no'] ?? '',
            'reg': s['register_no'] ?? s['register_number'] ?? s['roll_no'] ?? '',
            'name': s['full_name'] ?? s['name'] ?? '',
            'gender': s['gender'] ?? '',
            'email': s['institute_email'] ?? s['personal_email'] ?? s['email'] ?? '',
            'phone': s['mobile_number'] ?? s['phone'] ?? '',
            'dept': s['department'] ?? '',
            'sem': sem,
            'sec': s['section'] ?? '',
            'year_of_study': yr,
            'year': yr,
            'programme': s['degree'] ?? 'B.E.',
            'status': s['status'] ?? 'Continuing',
            'regulation_year': s['regulation_year'] ?? '',
            'attendance_percentage': s['attendance_percentage'],
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching students with filters: $e');
    }
    return [];
  }

  static List<Map<String, dynamic>> getByClassSec(String classSec) {
    final all = getAll();
    if (classSec.trim().isEmpty) return all;

    final parts = classSec.split('-');
    final dept = parts[0].trim().toUpperCase();
    String sec = 'A';
    String reqYear = extractYear(classSec);

    if (parts.length >= 2) {
      final rest = parts[1].trim();
      sec = rest.split(' ')[0].split('(')[0].trim().toUpperCase();
    }

    final filtered = all.where((s) {
      final sDept = (s['dept'] ?? s['department'] ?? '').toString().trim().toUpperCase();
      final sSec = (s['sec'] ?? s['section'] ?? '').toString().trim().toUpperCase();
      
      final rawYear = (s['year_of_study'] ?? s['year'] ?? '').toString().trim();
      final sYear = extractYear(rawYear.isNotEmpty ? rawYear : calcYearFromSem(s['sem'] ?? s['semester']));

      final matchDept = sDept == dept ||
          (dept == 'CSE' && sDept.contains('COMPUTER')) ||
          (dept == 'IT' && sDept.contains('INFORMATION'));
      final matchSec = sSec == sec;
      final matchYear = reqYear.isEmpty || sYear.isEmpty || sYear == reqYear;

      return matchDept && matchSec && matchYear;
    }).toList();

    return filtered;
  }

  static Future<List<Map<String, dynamic>>> fetchCounsellingLogs(String facultyId) async {
    try {
      final response = await SupabaseClientHelper.select(
        'mentor_counselling_logs',
        filterColumn: 'faculty_employee_id',
        filterValue: facultyId,
        schema: 'faculty',
      );
      return response;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> createCounsellingLog(Map<String, dynamic> logData) async {
    final result = await SupabaseClientHelper.insert(
      'mentor_counselling_logs',
      logData,
      schema: 'faculty',
    );
    return result != null;
  }
}
