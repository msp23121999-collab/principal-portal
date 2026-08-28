import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../network/api_client.dart';

class SupabaseConfig {
  static String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static bool isConfigured = false;
}

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  bool _isInitialized = false;
  static final Map<String, List<Map<String, dynamic>>> _localAppStorage = {};

  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<bool> initialize([String? url, String? key]) async {
    final targetUrl = url ?? SupabaseConfig.supabaseUrl;
    final targetKey = key ?? SupabaseConfig.supabaseAnonKey;

    try {
      await Supabase.initialize(
        url: targetUrl,
        anonKey: targetKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      SupabaseConfig.isConfigured = true;
      debugPrint('Supabase connected successfully to $targetUrl');
      return true;
    } catch (e) {
      debugPrint('Supabase fallback active: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTable(
    String tableName, {
    String? select,
    String? filter,
    String? filterColumn,
    dynamic filterValue,
  }) async {
    final extraLocal = _localAppStorage[tableName] ?? [];
    try {
      String endpoint = '/db/$tableName';
      if (filterColumn != null && filterValue != null) {
        endpoint += '?$filterColumn=$filterValue';
      }
      final apiResult = await ApiClient.get(endpoint);
      if (apiResult is List) {
        final list = List<Map<String, dynamic>>.from(apiResult);
        if (list.isNotEmpty) return [...list, ...extraLocal];
      }
    } catch (err) {
      debugPrint('Backend API fetch for $tableName failed, using local/fallback: $err');
    }

    final c = client;
    if (c == null) {
      final fallback = _getFallbackData(tableName);
      return [...fallback, ...extraLocal];
    }
    try {
      var query = c.from(tableName).select(select ?? '*');
      if (filter != null && filter.isNotEmpty) {
        final parts = filter.split('.');
        if (parts.length >= 3 && parts[1] == 'eq') {
          query = query.eq(parts[0], parts[2]);
        }
      } else if (filterColumn != null && filterValue != null) {
        query = query.eq(filterColumn, filterValue);
      }
      final data = await query;
      final list = List<Map<String, dynamic>>.from(data);
      final combined = list.isNotEmpty ? list : _getFallbackData(tableName);
      return [...combined, ...extraLocal];
    } catch (e) {
      debugPrint('Error fetching table $tableName: $e');
      final fallback = _getFallbackData(tableName);
      return [...fallback, ...extraLocal];
    }
  }

  Future<Map<String, dynamic>?> insertData(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    final c = client;
    if (c == null) return record;
    try {
      final result = await c.from(tableName).insert(record).select();
      if (result is List && result.isNotEmpty) {
        return Map<String, dynamic>.from(result.first as Map);
      }
      return record;
    } catch (e) {
      debugPrint('Error inserting into $tableName: $e');
      return record;
    }
  }

  List<Map<String, dynamic>> _getFallbackData(String tableName) {
    switch (tableName) {
      case 'departments':
        return [
          {
            'code': 'CSE',
            'nam`e': 'Computer Science & Engineering',
            'hod_name': 'Dr. Suresh Kumar',
            'student_count': 720,
            'faculty_count': 42,
            'status': 'Active',
          },
          {
            'code': 'IT',
            'name': 'Information Technology',
            'hod_name': 'Dr. V. Priya',
            'student_count': 480,
            'faculty_count': 28,
            'status': 'Active',
          },
          {
            'code': 'ECE',
            'name': 'Electronics & Communication Engg.',
            'hod_name': 'Dr. R. Maheshwari',
            'student_count': 480,
            'faculty_count': 30,
            'status': 'Active',
          },
          {
            'code': 'AI&DS',
            'name': 'Artificial Intelligence & Data Science',
            'hod_name': 'Dr. K. Balaji',
            'student_count': 480,
            'faculty_count': 24,
            'status': 'Active',
          },
          {
            'code': 'MECH',
            'name': 'Mechanical Engineering',
            'hod_name': 'Dr. P. Ramesh',
            'student_count': 360,
            'faculty_count': 22,
            'status': 'Active',
          },
          {
            'code': 'CIVIL',
            'name': 'Civil Engineering',
            'hod_name': 'Dr. S. Sundaram',
            'student_count': 240,
            'faculty_count': 18,
            'status': 'Active',
          },
        ];
      case 'programmes':
        return [
          {
            'code': 'B.E. CSE',
            'name': 'Computer Science & Engineering',
            'degree': 'UG',
            'duration_years': 4,
            'intake_seats': 180,
            'department_code': 'CSE',
            'status': 'Active',
          },
          {
            'code': 'B.Tech IT',
            'name': 'Information Technology',
            'degree': 'UG',
            'duration_years': 4,
            'intake_seats': 120,
            'department_code': 'IT',
            'status': 'Active',
          },
          {
            'code': 'B.E. ECE',
            'name': 'Electronics & Communication Engg.',
            'degree': 'UG',
            'duration_years': 4,
            'intake_seats': 120,
            'department_code': 'ECE',
            'status': 'Active',
          },
          {
            'code': 'B.Tech AI & DS',
            'name': 'Artificial Intelligence & Data Science',
            'degree': 'UG',
            'duration_years': 4,
            'intake_seats': 120,
            'department_code': 'AI&DS',
            'status': 'Active',
          },
          {
            'code': 'M.E. CSE',
            'name': 'Computer Science (PG)',
            'degree': 'PG',
            'duration_years': 2,
            'intake_seats': 18,
            'department_code': 'CSE',
            'status': 'Active',
          },
        ];
      case 'subjects':
        return [
          {
            'code': 'CS3401',
            'name': 'Data Structures & Algorithms',
            'credits': 4,
            'type': 'Theory',
            'department_code': 'CSE',
            'status': 'Active',
          },
          {
            'code': 'CS3402',
            'name': 'Database Management Systems',
            'credits': 4,
            'type': 'Theory + Lab',
            'department_code': 'CSE',
            'status': 'Active',
          },
          {
            'code': 'IT3501',
            'name': 'Full Stack Web Architecture',
            'credits': 4,
            'type': 'Theory + Lab',
            'department_code': 'IT',
            'status': 'Active',
          },
          {
            'code': 'EC3301',
            'name': 'Digital Signal Processing',
            'credits': 4,
            'type': 'Theory',
            'department_code': 'ECE',
            'status': 'Active',
          },
          {
            'code': 'AI3601',
            'name': 'Machine Learning Algorithms',
            'credits': 4,
            'type': 'Theory + Lab',
            'department_code': 'AI&DS',
            'status': 'Active',
          },
        ];
      case 'students':
        return [
          {
            'register_no': '731522104001',
            'roll_no': '22CS001',
            'name': 'ARAVIND SWAMY',
            'department_code': 'CSE',
            'degree_programme': 'B.E. CSE',
            'semester': 6,
            'cgpa': 8.85,
            'attendance_percentage': 94.5,
            'fee_status': 'Paid',
            'status': 'Active',
          },
          {
            'register_no': '731522104002',
            'roll_no': '22CS002',
            'name': 'BHAVANA DEVI',
            'department_code': 'IT',
            'degree_programme': 'B.Tech IT',
            'semester': 6,
            'cgpa': 9.12,
            'attendance_percentage': 98.0,
            'fee_status': 'Paid',
            'status': 'Active',
          },
          {
            'register_no': '731522106015',
            'roll_no': '22EC015',
            'name': 'CHARAN KUMAR',
            'department_code': 'ECE',
            'degree_programme': 'B.E. ECE',
            'semester': 6,
            'cgpa': 8.45,
            'attendance_percentage': 91.2,
            'fee_status': 'Paid',
            'status': 'Active',
          },
          {
            'register_no': '731522205022',
            'roll_no': '22AD022',
            'name': 'DIVYA BHARATHI',
            'department_code': 'AI&DS',
            'degree_programme': 'B.Tech AI & DS',
            'semester': 6,
            'cgpa': 9.40,
            'attendance_percentage': 96.0,
            'fee_status': 'Paid',
            'status': 'Active',
          },
          {
            'register_no': '731523104045',
            'roll_no': '23CS045',
            'name': 'EZHIL RAJ',
            'department_code': 'CSE',
            'degree_programme': 'B.E. CSE',
            'semester': 4,
            'cgpa': 8.10,
            'attendance_percentage': 89.0,
            'fee_status': 'Pending',
            'status': 'Active',
          },
        ];
      case 'faculty':
        return [
          {
            'emp_id': 'EMP-CSE-001',
            'name': 'Dr. Suresh Kumar',
            'designation': 'Professor & HOD',
            'department_code': 'CSE',
            'experience_years': '18 Years',
            'status': 'Active',
          },
          {
            'emp_id': 'EMP-ECE-002',
            'name': 'Dr. R. Maheshwari',
            'designation': 'Professor & HOD',
            'department_code': 'ECE',
            'experience_years': '16 Years',
            'status': 'Active',
          },
          {
            'emp_id': 'EMP-IT-003',
            'name': 'Dr. V. Priya',
            'designation': 'Associate Professor & HOD',
            'department_code': 'IT',
            'experience_years': '14 Years',
            'status': 'Active',
          },
          {
            'emp_id': 'EMP-IoT-004',
            'name': 'Dr. K. Balaji',
            'designation': 'Assistant Professor & HOD',
            'department_code': 'AI&DS',
            'experience_years': '10 Years',
            'status': 'Active',
          },
          {
            'emp_id': 'EMP-CSE-005',
            'name': 'Prof. N. Karthi',
            'designation': 'Assistant Professor',
            'department_code': 'CSE',
            'experience_years': '7 Years',
            'status': 'Active',
          },
        ];
      case 'users':
        return [
          {
            'emp_id_or_reg_no': 'ADM-001',
            'name': 'Administrator User',
            'email': 'admin@ksrce.ac.in',
            'phone': '+91 98765 43210',
            'role_code': 'SUPER_ADMIN',
            'department_code': 'CSE',
            'status': 'Active',
          },
          {
            'emp_id_or_reg_no': 'ERP-002',
            'name': 'ERP Administrator',
            'email': 'erpadmin@ksrce.ac.in',
            'phone': '+91 98765 43211',
            'role_code': 'ERP_ADMIN',
            'department_code': 'ALL',
            'status': 'Active',
          },
          {
            'emp_id_or_reg_no': 'HOD-003',
            'name': 'Dr. Suresh Kumar',
            'email': 'hod.cse@ksrce.ac.in',
            'phone': '+91 98765 43212',
            'role_code': 'HOD',
            'department_code': 'CSE',
            'status': 'Active',
          },
          {
            'emp_id_or_reg_no': 'FAC-004',
            'name': 'Prof. N. Karthi',
            'email': 'karthi@ksrce.ac.in',
            'phone': '+91 98765 43213',
            'role_code': 'FACULTY',
            'department_code': 'CSE',
            'status': 'Active',
          },
        ];
      case 'certificates':
        return [
          {
            'id': 'CERT-001',
            'student': 'Aravind Swamy',
            'reg_no': '731522104001',
            'type': 'Bonafide Certificate',
            'date': '2026-07-20',
            'status': 'Approved',
          },
          {
            'id': 'CERT-002',
            'student': 'Bhavana Devi',
            'reg_no': '731522104002',
            'type': 'Conduct Certificate',
            'date': '2026-07-22',
            'status': 'Approved',
          },
          {
            'id': 'CERT-003',
            'student': 'Charan Kumar',
            'reg_no': '731522106015',
            'type': 'Transfer Certificate',
            'date': '2026-07-25',
            'status': 'Pending',
          },
          {
            'id': 'CERT-004',
            'student': 'Divya Bharathi',
            'reg_no': '731522205022',
            'type': 'Course Completion',
            'date': '2026-07-28',
            'status': 'Pending',
          },
        ];
      case 'fees':
        return [
          {
            'receipt_no': 'REC-2026-01',
            'student': 'Aravind Swamy',
            'reg_no': '731522104001',
            'dept': 'CSE',
            'amount': '₹65,000',
            'type': 'Tuition Fee',
            'status': 'Paid',
            'date': '2026-07-15',
          },
          {
            'receipt_no': 'REC-2026-02',
            'student': 'Bhavana Devi',
            'reg_no': '731522104002',
            'dept': 'IT',
            'amount': '₹65,000',
            'type': 'Tuition Fee',
            'status': 'Paid',
            'date': '2026-07-16',
          },
          {
            'receipt_no': 'REC-2026-03',
            'student': 'Ezhil Raj',
            'reg_no': '731523104045',
            'dept': 'CSE',
            'amount': '₹35,000',
            'type': 'Hostel Fee',
            'status': 'Pending',
            'date': '2026-07-24',
          },
        ];
      case 'academic_events':
        return [
          {
            'id': 'EVT001',
            'schedule_id': 'DOC-2026-01',
            'title': 'Commencement of Even Semester Classes',
            'description':
                'Reopening of college for Year II, III & IV B.Tech Students.',
            'category': 'Semester Start',
            'start_date': '2026-08-03',
            'end_date': '2026-08-03',
            'semester': 'Sem 3, 5, 7',
            'department': 'ALL',
            'status': 'Ongoing',
            'venue': 'Main Classrooms',
          },
          {
            'id': 'EVT002',
            'schedule_id': 'DOC-2026-01',
            'title': 'Continuous Internal Assessment - I (CIA 1)',
            'description':
                'First internal mid-term examinations for theory courses.',
            'category': 'Mid Exam',
            'start_date': '2026-08-24',
            'end_date': '2026-08-29',
            'semester': 'Sem 3, 5, 7',
            'department': 'CSE, IT, ECE',
            'status': 'Upcoming',
            'venue': 'Exam Block A & B',
          },
        ];
      default:
        return [];
    }
  }

  Future<bool> insertRecord(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    _localAppStorage.putIfAbsent(tableName, () => []).add(record);
    final c = client;
    if (c == null) return true;
    try {
      await c.from(tableName).insert(record);
      return true;
    } catch (e) {
      debugPrint('Error inserting into $tableName: $e');
      return true;
    }
  }

  Future<bool> updateRecord(
    String tableName,
    Map<String, dynamic> record,
    String matchColumn,
    dynamic matchValue,
  ) async {
    final list = _localAppStorage[tableName];
    if (list != null) {
      for (int i = 0; i < list.length; i++) {
        if (list[i][matchColumn] == matchValue) {
          list[i] = {...list[i], ...record};
        }
      }
    }
    final c = client;
    if (c == null) return true;
    try {
      await c.from(tableName).update(record).eq(matchColumn, matchValue);
      return true;
    } catch (e) {
      debugPrint('Error updating $tableName: $e');
      return true;
    }
  }

  Future<bool> deleteRecord(
    String tableName,
    String matchColumn,
    dynamic matchValue,
  ) async {
    _localAppStorage[tableName]?.removeWhere(
      (item) => item[matchColumn] == matchValue,
    );
    final c = client;
    if (c == null) return true;
    try {
      await c.from(tableName).delete().eq(matchColumn, matchValue);
      return true;
    } catch (e) {
      debugPrint('Error deleting from $tableName: $e');
      return true;
    }
  }
}
