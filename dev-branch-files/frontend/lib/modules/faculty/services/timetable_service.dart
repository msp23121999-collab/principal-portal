// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// TIMETABLE SERVICE — Connected to timetable.class_timetables
/// Faculty periods resolved via faculty.faculty_course_allocations
/// ============================================================
library;

import 'package:flutter/foundation.dart';
import 'local_storage_base.dart';
import 'supabase_client.dart';

class TimetableService {
  static const String _key = 'timetable';

  static void seedIfEmpty() {}

  static String normalizeClassSec(String classSec) {
    return classSec.trim();
  }

  /// Fetches the faculty's timetable by:
  /// 1. Getting their course allocations from faculty.faculty_course_allocations
  /// 2. Fetching all class timetable rows from timetable.class_timetables
  /// 3. Client-side JOIN: matching each period's course_code against allocations
  static Future<List<Map<String, dynamic>>> fetchFromSupabase({
    String facultyId = 'EMP_CSE_002',
  }) async {
    try {
      // 1. Get this faculty's course allocations
      final allocations = await SupabaseClientHelper.select(
        'faculty_course_allocations',
        schema: 'faculty',
        filterColumn: 'faculty_employee_id',
        filterValue: facultyId,
      );

      if (allocations.isEmpty) {
        final empty = _emptyWeek();
        LocalStorageBase.writeList(_key, empty);
        return empty;
      }

      // 2. Build lookup: {course_code → [{dept, section, year}]} for this faculty
      final allocMap = <String, List<Map<String, String>>>{};
      for (final a in allocations) {
        final code = a['course_code']?.toString() ?? '';
        if (code.isEmpty) continue;
        allocMap.putIfAbsent(code, () => []).add({
          'department': a['department']?.toString() ?? '',
          'section': a['section']?.toString() ?? '',
          'year': a['year_of_study']?.toString() ?? '',
          'academic_year': a['academic_year']?.toString() ?? '',
        });
      }

      // 3. Fetch all class timetable rows from exposed schema: 'timetable'
      var allRows = await SupabaseClientHelper.select(
        'class_timetables',
        schema: 'timetable',
      );
      if (allRows.isEmpty) {
        allRows = await SupabaseClientHelper.select(
          'class_timetables',
          schema: 'faculty',
        );
      }

      if (allRows.isEmpty) {
        final empty = _emptyWeek();
        LocalStorageBase.writeList(_key, empty);
        return empty;
      }

      // 4. Client-side JOIN — for each row, scan P1–P8 and check if the period's
      //    course_code matches any of this faculty's allocations (same dept+section+year)
      final daysMap = <String, List<Map<String, dynamic>>>{};

      for (final row in allRows) {
        final day = row['day']?.toString() ?? 'Monday';
        final dept = row['department_code']?.toString() ?? '';
        final sec = row['section']?.toString() ?? '';
        final yr = row['year']?.toString() ?? '';

        for (int p = 1; p <= 8; p++) {
          final code = (row['p${p}_code'] ?? '').toString().trim();
          final name = (row['p${p}_name'] ?? '').toString().trim();
          if (code.isEmpty) continue;

          // Check if this faculty is allocated this course for this exact section
          final courseAllocs = allocMap[code];
          if (courseAllocs == null) continue;

          final matches = courseAllocs.where((a) =>
            a['department'] == dept &&
            a['section'] == sec &&
            a['year'] == yr
          );
          if (matches.isEmpty) continue;

          // This period belongs to this faculty
          daysMap.putIfAbsent(day, () => []).add({
            'period': 'P$p',
            'subject': name,
            'code': code,
            'classSec': '$dept - $sec ($yr Year)',
            'room': '',
            'type': 'Theory',
            'facultyId': facultyId,
          });
        }
      }

      // 5. Convert to standard day-schedule output format
      final result = <Map<String, dynamic>>[];
      for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']) {
        result.add({
          'day': day,
          'schedule': daysMap[day] ?? [],
        });
      }

      LocalStorageBase.writeList(_key, result);
      return result;
    } catch (e) {
      // Fallback cleanly
    }
    return getAll();
  }

  /// Returns an empty week structure
  static List<Map<String, dynamic>> _emptyWeek() {
    return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        .map((d) => <String, dynamic>{'day': d, 'schedule': <Map<String, dynamic>>[]})
        .toList();
  }

  static List<Map<String, dynamic>> getAll() {
    return LocalStorageBase.readList(_key);
  }

  static List<Map<String, dynamic>> getByFaculty(String facultyId) {
    final all = getAll();
    final result = <Map<String, dynamic>>[];
    for (final day in all) {
      final schedule = (day['schedule'] as List? ?? [])
          .map((p) => Map<String, dynamic>.from(p as Map))
          .where((p) => p['facultyId'] == facultyId || facultyId.isEmpty)
          .toList();
      if (schedule.isNotEmpty) {
        result.add({...day, 'schedule': schedule});
      }
    }
    return result.isEmpty ? all : result;
  }

  static List<String> getClassesForFaculty(String facultyId) {
    final classes = <String>{};
    for (final day in getByFaculty(facultyId)) {
      final schedule = day['schedule'] as List? ?? [];
      for (final p in schedule) {
        if (p['classSec'] != null && (p['classSec'] as String).isNotEmpty) {
          classes.add(p['classSec'] as String);
        }
      }
    }
    return classes.toList();
  }

  static List<String> getSubjectsForClass(String facultyId, String classSec) {
    final subjects = <String>{};
    for (final day in getByFaculty(facultyId)) {
      final schedule = day['schedule'] as List? ?? [];
      for (final p in schedule) {
        if (p['classSec'] == classSec && p['subject'] != null) {
          subjects.add(p['subject'] as String);
        }
      }
    }
    return subjects.toList();
  }

  static List<String> getSubjectsForFaculty(String facultyId) {
    final subjects = <String>{};
    for (final day in getByFaculty(facultyId)) {
      final schedule = day['schedule'] as List? ?? [];
      for (final p in schedule) {
        if (p['subject'] != null && (p['subject'] as String).isNotEmpty) {
          subjects.add(p['subject'] as String);
        }
      }
    }
    return subjects.toList();
  }
}
