// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'supabase_client.dart';

/// CourseAllocationService — Single source of truth for faculty filter cascades.
///
/// Flow:
///   1. `fetchAllocations(facultyId)` loads from `faculty.faculty_course_allocations`
///   2. Joins with `public.regulations` for course_name, semester, course_type
///   3. Provides Year → Class → Subject cascade getters
///   4. `fetchStudentsForClass(classSec)` fetches from `student.students`
///      filtered by department + section + year_of_study + regulation_year
class CourseAllocationService {
  static List<Map<String, dynamic>> _cachedAllocations = [];
  static Map<String, Map<String, dynamic>> _regulationsMap = {}; // course_code → full regulation row
  static List<String> _assignedSubjects = [];
  static String _facultyDept = '';

  /// Fetches faculty course allocations from `faculty.faculty_course_allocations`,
  /// regulations from `public.regulations`, and faculty details from `faculty.faculties`.
  static Future<void> fetchAllocations({String facultyId = 'EMP_CSE_002'}) async {
    try {
      // 1. Fetch allocations from faculty.faculty_course_allocations
      final remoteAllocations = await SupabaseClientHelper.select(
        'faculty_course_allocations',
        schema: 'faculty',
        filterColumn: 'faculty_employee_id',
        filterValue: facultyId,
      );

      _cachedAllocations = remoteAllocations;

      // 2. Fetch regulations mapping (course_code → full row) from public.regulations
      try {
        final regs = await SupabaseClientHelper.select('regulations', schema: 'public');
        final map = <String, Map<String, dynamic>>{};
        for (final r in regs) {
          final code = (r['course_code'] ?? '').toString().trim();
          if (code.isNotEmpty) {
            map[code] = Map<String, dynamic>.from(r);
          }
        }
        _regulationsMap = map;
      } catch (_) {}

      // 3. Fetch faculty info from faculty.faculties (assigned_subjects & department)
      try {
        final facs = await SupabaseClientHelper.select(
          'faculties',
          schema: 'faculty',
          filterColumn: 'employee_id',
          filterValue: facultyId,
        );
        if (facs.isNotEmpty) {
          final f = facs.first;
          _facultyDept = (f['department'] ?? f['dept'] ?? '').toString();
          final rawSubjs = f['assigned_subjects'];
          if (rawSubjs is List) {
            _assignedSubjects = rawSubjs.map((e) => e.toString()).toList();
          }
        }
      } catch (_) {}
    } catch (_) {}
  }

  /// Returns the raw cached allocations list
  static List<Map<String, dynamic>> get allocations => _cachedAllocations;

  // ── Course Name Lookup ──────────────────────────────────────────────────────
  /// Gets course_name for a given course_code from regulations
  static String getCourseName(String courseCode) {
    return _regulationsMap[courseCode]?['course_name']?.toString() ?? '';
  }

  /// Gets the full regulation row for a course_code
  static Map<String, dynamic>? getRegulation(String courseCode) {
    return _regulationsMap[courseCode];
  }

  /// Reverse lookup: course name → course code (first match)
  static String? getCourseCodeForSubject(String subjectName, {String? classSec}) {
    for (final a in _cachedAllocations) {
      final code = (a['course_code'] ?? '').toString().trim();
      final regName = getCourseName(code);
      if (regName.toLowerCase() == subjectName.toLowerCase()) {
        if (classSec != null) {
          final dept = (a['department'] ?? '').toString().trim();
          final sec = (a['section'] ?? '').toString().trim();
          if (classSec.toUpperCase().contains(dept.toUpperCase()) &&
              classSec.toUpperCase().contains(sec.toUpperCase())) {
            return code;
          }
        } else {
          return code;
        }
      }
    }
    return null;
  }

  /// Returns the allocation record for a specific class string like "CSE - A (III Year)"
  static Map<String, dynamic>? getAllocationForClass(String classSec) {
    final parsed = _parseClassSec(classSec);
    if (parsed == null) return null;

    for (final a in _cachedAllocations) {
      final dept = (a['department'] ?? '').toString().trim().toUpperCase();
      final sec = (a['section'] ?? '').toString().trim().toUpperCase();
      final yr = (a['year_of_study'] ?? '').toString().trim().toUpperCase();

      if (dept == parsed['dept'] && sec == parsed['sec'] && yr == parsed['year']) {
        return a;
      }
    }
    return null;
  }

  // ── Handling Years ──────────────────────────────────────────────────────────
  static List<String> getAllocatedYears() {
    final years = <String>{};
    for (final a in _cachedAllocations) {
      final y = (a['year_of_study'] ?? a['year'] ?? '').toString().trim();
      if (y.isNotEmpty) {
        final formatted = y.contains('Year') ? y : '$y Year';
        years.add(formatted);
      }
    }
    final list = years.toList()..sort();
    return list;
  }

  // ── Handling Departments ────────────────────────────────────────────────────
  static List<String> getAllocatedDepartments() {
    final depts = <String>{};
    for (final a in _cachedAllocations) {
      final d = (a['department'] ?? a['dept'] ?? '').toString().trim();
      if (d.isNotEmpty) depts.add(d);
    }
    if (depts.isEmpty && _facultyDept.isNotEmpty) {
      depts.add(_facultyDept);
    }
    return depts.toList()..sort();
  }

  // ── Handling Classes & Sections ─────────────────────────────────────────────
  static List<String> getAllocatedClasses({String selectedYear = 'All Years', String selectedDept = 'All Departments'}) {
    final classes = <String>{};

    for (final a in _cachedAllocations) {
      final dept = (a['department'] ?? a['dept'] ?? '').toString().trim();
      final sec = (a['section'] ?? '').toString().trim();
      final rawYear = (a['year_of_study'] ?? a['year'] ?? '').toString().trim();
      final yearLabel = rawYear.isNotEmpty ? (rawYear.contains('Year') ? rawYear : '$rawYear Year') : '';

      final matchesYear = selectedYear == 'All Years' || yearLabel.isEmpty || yearLabel.contains(selectedYear) || selectedYear.contains(yearLabel);
      final matchesDept = selectedDept == 'All Departments' || dept.toLowerCase() == selectedDept.toLowerCase();

      if (matchesYear && matchesDept) {
        if (yearLabel.isNotEmpty) {
          classes.add('$dept - $sec ($yearLabel)');
        } else {
          classes.add('$dept - $sec');
        }
      }
    }

    return classes.toList()..sort();
  }

  // ── Handling Subjects ───────────────────────────────────────────────────────
  static List<String> getAllocatedSubjects({String selectedClass = 'All Classes', String selectedDept = 'All Departments'}) {
    final subjects = <String>{};

    for (final a in _cachedAllocations) {
      final dept = (a['department'] ?? a['dept'] ?? '').toString().trim();
      final sec = (a['section'] ?? '').toString().trim();
      final rawYear = (a['year_of_study'] ?? a['year'] ?? '').toString().trim();
      final yearLabel = rawYear.isNotEmpty ? (rawYear.contains('Year') ? rawYear : '$rawYear Year') : '';
      final classStr = yearLabel.isNotEmpty ? '$dept - $sec ($yearLabel)' : '$dept - $sec';

      final code = (a['course_code'] ?? '').toString().trim();
      final nameFromReg = getCourseName(code);
      final subjName = nameFromReg.isNotEmpty ? nameFromReg : code;

      final matchesClass = selectedClass == 'All Classes' || classStr.contains(selectedClass) || selectedClass.contains(sec);
      final matchesDept = selectedDept == 'All Departments' || dept.toLowerCase() == selectedDept.toLowerCase();

      if (matchesClass && matchesDept && subjName.isNotEmpty) {
        subjects.add(subjName);
      }
    }

    if (subjects.isEmpty && _assignedSubjects.isNotEmpty) {
      subjects.addAll(_assignedSubjects);
    }
    return subjects.toList()..sort();
  }

  /// Returns the course_code for a subject within a specific class
  static String? getCourseCodeForClassAndSubject(String classSec, String subjectName) {
    final parsed = _parseClassSec(classSec);
    if (parsed == null) return null;

    for (final a in _cachedAllocations) {
      final dept = (a['department'] ?? '').toString().trim().toUpperCase();
      final sec = (a['section'] ?? '').toString().trim().toUpperCase();
      final yr = (a['year_of_study'] ?? '').toString().trim().toUpperCase();
      final code = (a['course_code'] ?? '').toString().trim();
      final regName = getCourseName(code);

      final matchesDept = dept == parsed['dept'];
      final matchesSec = sec == parsed['sec'];
      final matchesYear = parsed['year']!.isEmpty || yr == parsed['year'] || yr.contains(parsed['year']!);
      final matchesSubject = regName.toLowerCase() == subjectName.toLowerCase() || code.toLowerCase() == subjectName.toLowerCase();

      if (matchesDept && matchesSec && matchesYear && matchesSubject) {
        return code;
      }
    }
    return null;
  }

  /// Returns the regulation_year for a given class section from allocations
  static String? getRegulationYearForClass(String classSec) {
    final alloc = getAllocationForClass(classSec);
    return alloc?['regulation_year']?.toString();
  }

  // ── Student Fetching ────────────────────────────────────────────────────────
  /// Fetches students from `student.students` filtered by the allocation's
  /// department, section, year_of_study, and regulation_year.
  /// Returns formatted student maps ready for attendance/marks/assignment UIs.
  static Future<List<Map<String, dynamic>>> fetchStudentsForClass(String classSec) async {
    final parsed = _parseClassSec(classSec);
    if (parsed == null) return [];

    // Find matching allocation to get regulation_year
    String regYear = '';
    for (final a in _cachedAllocations) {
      final dept = (a['department'] ?? '').toString().trim().toUpperCase();
      final sec = (a['section'] ?? '').toString().trim().toUpperCase();
      final yr = (a['year_of_study'] ?? '').toString().trim().toUpperCase();

      if (dept == parsed['dept'] && sec == parsed['sec'] &&
          (parsed['year']!.isEmpty || yr == parsed['year'] || yr.contains(parsed['year']!))) {
        regYear = (a['regulation_year'] ?? '').toString().trim();
        break;
      }
    }

    // Build precise multi-column filter
    final filters = <String, String>{
      'department': parsed['dept']!,
      'section': parsed['sec']!,
    };

    // Map Roman numeral year to year_of_study value in students table
    if (parsed['year']!.isNotEmpty) {
      filters['year_of_study'] = parsed['year']!;
    }

    // Filter by regulation_year for strict matching
    if (regYear.isNotEmpty) {
      filters['regulation_year'] = regYear;
    }

    debugPrint('CourseAllocationService.fetchStudentsForClass: classSec=$classSec, filters=$filters');

    try {
      final students = await SupabaseClientHelper.selectWithFilters(
        'students',
        schema: 'student',
        filters: filters,
        orderBy: 'roll_no',
      );

      return students.map((s) {
        final sem = s['semester']?.toString() ?? '';
        final yr = (s['year_of_study'] ?? _calcYearFromSem(sem)).toString();
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
    } catch (e) {
      debugPrint('Error fetching students for class $classSec: $e');
      return [];
    }
  }

  // ── Parse Helper ────────────────────────────────────────────────────────────
  /// Parses "CSE - A (III Year)" → {dept: CSE, sec: A, year: III}
  static Map<String, String>? _parseClassSec(String classSec) {
    if (classSec.trim().isEmpty) return null;

    String dept = '';
    String sec = '';
    String year = '';

    final parts = classSec.split('-');
    dept = parts[0].trim().toUpperCase();

    if (parts.length >= 2) {
      final rest = parts[1].trim();
      // Extract section (before parenthesis)
      sec = rest.split('(')[0].split(' ')[0].trim().toUpperCase();
      // Extract year from parenthesis
      final yearMatch = RegExp(r'\(([^)]+)\)').firstMatch(rest);
      if (yearMatch != null) {
        final inner = yearMatch.group(1)!.trim();
        // Extract Roman numeral: "III Year" → "III"
        year = inner.replaceAll(RegExp(r'\s*Year\s*', caseSensitive: false), '').trim().toUpperCase();
      }
    }

    if (dept.isEmpty) return null;
    if (sec.isEmpty) sec = 'A';

    return {'dept': dept, 'sec': sec, 'year': year};
  }

  static String _calcYearFromSem(dynamic semRaw) {
    final sem = int.tryParse(semRaw?.toString() ?? '') ?? 0;
    if (sem >= 7) return 'IV';
    if (sem >= 5) return 'III';
    if (sem >= 3) return 'II';
    if (sem >= 1) return 'I';
    return '';
  }
}
