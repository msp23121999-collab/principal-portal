import 'package:flutter/foundation.dart';
import 'supabase_client.dart';

/// Feedback Service — Interacts strictly with Supabase table: `faculty.student_feedback_results`
class FeedbackService {
  static const String _table = 'student_feedback_results';
  static const String _schema = 'faculty';

  /// Helper to sanitize student alias so NO real names in parentheses are shown
  static String _cleanStudentAlias(dynamic rawAlias, int index) {
    if (rawAlias == null) return 'Anonymous Student #$index';
    final str = rawAlias.toString().trim();
    if (str.contains('(')) {
      final clean = str.split('(').first.trim();
      if (clean.isNotEmpty) return clean;
    }
    if (str.isEmpty) return 'Anonymous Student #$index';
    return str;
  }

  /// Fetches anonymized individual student feedback records for logged-in faculty directly from Supabase DB
  static Future<List<Map<String, dynamic>>> fetchFacultyFeedback(String facultyId) async {
    try {
      final response = await SupabaseClientHelper.select(
        _table,
        schema: _schema,
        filterColumn: 'faculty_employee_id',
        filterValue: facultyId,
      );

      if (response.isNotEmpty) {
        final allFeedbacks = <Map<String, dynamic>>[];
        int counter = 1;

        for (final row in response) {
          final rowId = row['feedback_id']?.toString() ?? row['id']?.toString() ?? 'FB10$counter';
          final courseCode = (row['course_code'] ?? '').toString();
          final dept = (row['department'] ?? 'CSE').toString();
          final sec = (row['section'] ?? 'A').toString();
          final academicYear = (row['academic_year'] ?? '2025-26').toString();
          final sem = (row['semester'] ?? 5).toString();
          final year = _calcYearFromSem(sem);
          final defaultClassSec = dept.isNotEmpty && sec.isNotEmpty 
              ? '$dept - Section $sec ($year Year)' 
              : 'Class $year Year';

          final String subject = row['subject']?.toString() ?? courseCode;
          final String classSec = row['class_sec']?.toString() ?? defaultClassSec;
          final String period = row['period']?.toString() ?? 'Odd Semester 2025-26';
          final String comment = row['comment']?.toString() ?? '';
          final String rawAlias = row['student_alias']?.toString() ?? 'Anonymous Student #$counter';
          final String studentAlias = _cleanStudentAlias(rawAlias, counter);
          final String date = (row['date']?.toString() ?? row['created_at']?.toString().split('T').first ?? '').toString();

          final rating = (row['rating'] as num? ?? 5).toInt().clamp(1, 5);
          final knowledge = (row['knowledge'] as num? ?? rating).toInt().clamp(1, 5);
          final methodology = (row['methodology'] as num? ?? rating).toInt().clamp(1, 5);
          final punctuality = (row['punctuality'] as num? ?? rating).toInt().clamp(1, 5);
          final availability = (row['availability'] as num? ?? rating).toInt().clamp(1, 5);

          allFeedbacks.add({
            'id': rowId,
            'feedbackId': rowId,
            'courseCode': courseCode,
            'subject': subject,
            'dept': dept,
            'sec': sec,
            'classSec': classSec,
            'period': period,
            'academicYear': academicYear,
            'year': year,
            'studentAlias': studentAlias,
            'rating': rating,
            'knowledge': knowledge,
            'methodology': methodology,
            'punctuality': punctuality,
            'availability': availability,
            'feedbackPercentage': rating * 20.0,
            'comment': comment,
            'date': date,
          });
          counter++;
        }
        return allFeedbacks;
      }
    } catch (e) {
      debugPrint('Error fetching feedback from Supabase: $e');
    }

    return [];
  }

  /// Submits an individual student feedback record to Supabase DB
  static Future<bool> insertFeedback(Map<String, dynamic> feedback) async {
    try {
      final payload = {
        'feedback_id': feedback['id'] ?? feedback['feedbackId'] ?? 'FB_${DateTime.now().millisecondsSinceEpoch}',
        'faculty_employee_id': feedback['facultyId'] ?? feedback['faculty_employee_id'] ?? 'EMP_CSE_002',
        'course_code': feedback['courseCode'] ?? feedback['subject_code'] ?? '',
        'subject': feedback['subject'] ?? '',
        'department': feedback['dept'] ?? 'CSE',
        'section': feedback['sec'] ?? 'A',
        'class_sec': feedback['classSec'] ?? 'CSE - A (III Year)',
        'academic_year': feedback['academicYear'] ?? '2025-26',
        'period': feedback['period'] ?? 'Odd Semester 2025-26',
        'rating': feedback['rating'] ?? 5,
        'knowledge': feedback['knowledge'] ?? 5,
        'methodology': feedback['methodology'] ?? 5,
        'punctuality': feedback['punctuality'] ?? 5,
        'availability': feedback['availability'] ?? 4,
        'comment': feedback['comment'] ?? '',
        'student_alias': _cleanStudentAlias(feedback['studentAlias'], 1),
        'date': feedback['date'] ?? DateTime.now().toIso8601String().split('T').first,
      };

      await SupabaseClientHelper.insert(_table, payload, schema: _schema);
      return true;
    } catch (e) {
      debugPrint('Error inserting feedback into Supabase: $e');
      return false;
    }
  }

  static String _calcYearFromSem(dynamic semRaw) {
    final sem = int.tryParse(semRaw?.toString() ?? '') ?? 0;
    if (sem >= 7) return 'IV';
    if (sem >= 5) return 'III';
    if (sem >= 3) return 'II';
    if (sem >= 1) return 'I';
    return 'III';
  }
}
