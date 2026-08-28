import 'package:flutter/foundation.dart';
import 'supabase_client.dart';

/// Marks Entry Service — Interacts with Supabase tables:
///   • `faculty.assessment_question_sets`
///   • `faculty.marks`
///   • `faculty.mark_sheet_statuses`
class MarksEntryService {
  /// Fetches question set configuration (Parts & Max Marks) for an assessment
  static Future<Map<String, dynamic>?> fetchQuestionSet({
    required String assessmentName,
    required String courseCode,
    required String section,
  }) async {
    try {
      var response = await SupabaseClientHelper.select(
        'assessment_question_sets',
        schema: 'faculty',
        filterColumn: 'course_code',
        filterValue: courseCode,
      );

      if (response.isEmpty) {
        response = await SupabaseClientHelper.select(
          'assessment_question_sets',
          schema: 'public',
          filterColumn: 'course_code',
          filterValue: courseCode,
        );
      }

      if (response.isNotEmpty) {
        final normExam = assessmentName.replaceAll(' - ', ' ').replaceAll('-', ' ').trim().toUpperCase();
        final normSec  = section.trim().toUpperCase();

        final match = response.where((r) {
          final dbExam = (r['assessment_name'] ?? '').toString().replaceAll(' - ', ' ').replaceAll('-', ' ').trim().toUpperCase();
          final dbSec  = (r['section'] ?? '').toString().trim().toUpperCase();
          final matchesExam = dbExam == normExam || dbExam.contains(normExam) || normExam.contains(dbExam);
          final matchesSec  = dbSec.isEmpty || normSec.isEmpty || dbSec == normSec || dbSec.contains(normSec);
          return matchesExam && matchesSec;
        }).firstOrNull;

        if (match != null) {
          final partsConfig = match['parts_config_json'];
          if (partsConfig is List) {
            return {
              'parts': partsConfig.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
              'overallMax': match['total_max_marks'] ?? 100.0,
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching question set from Supabase: $e');
    }
    return null;
  }

  /// Saves or updates question set configuration in `faculty.assessment_question_sets`
  static Future<bool> saveQuestionSet({
    required String assessmentName,
    required String courseCode,
    required String department,
    required String section,
    required String academicYear,
    required List<Map<String, dynamic>> partsConfig,
    required double totalMaxMarks,
  }) async {
    try {
      final payload = <String, dynamic>{
        'assessment_name': assessmentName,
        'course_code': courseCode,
        'department': department,
        'section': section,
        'academic_year': academicYear,
        'parts_config_json': partsConfig,
        'total_max_marks': totalMaxMarks,
      };

      final result = await SupabaseClientHelper.upsert(
        'assessment_question_sets',
        payload,
        'course_code,assessment_name,section',
        schema: 'faculty',
      );
      return result;
    } catch (e) {
      debugPrint('Error saving question set: $e');
      return false;
    }
  }

  /// Fetches student marks from `faculty.marks`
  static Future<List<Map<String, dynamic>>> fetchStudentMarks({
    required String facultyId,
    required String courseCode,
    required String assessment,
  }) async {
    try {
      List<Map<String, dynamic>> response = [];
      if (facultyId.isNotEmpty) {
        response = await SupabaseClientHelper.select(
          'marks',
          schema: 'faculty',
          filterColumn: 'faculty_employee_id',
          filterValue: facultyId,
        );
      }

      if (response.isEmpty) {
        response = await SupabaseClientHelper.select(
          'marks',
          schema: 'faculty',
        );
      }

      if (response.isNotEmpty) {
        final normExam = assessment.replaceAll(' - ', ' ').replaceAll('-', ' ').trim().toUpperCase();
        return response.where((m) {
          final dbExam = (m['assessment'] ?? '').toString().replaceAll(' - ', ' ').replaceAll('-', ' ').trim().toUpperCase();
          final matchesExam = dbExam == normExam || dbExam.contains(normExam) || normExam.contains(dbExam);
          final matchesSubject = courseCode.isEmpty ||
              (m['subject_code'] ?? '').toString().toLowerCase().contains(courseCode.toLowerCase()) ||
              (m['subject'] ?? '').toString().toLowerCase().contains(courseCode.toLowerCase());
          return matchesExam && matchesSubject;
        }).map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching student marks: $e');
    }
    return [];
  }

  /// Saves a student mark record to `faculty.marks`
  static Future<bool> saveStudentMark({
    required String facultyEmployeeId,
    required String studentId,
    required String registerNo,
    required String studentRoll,
    required String studentName,
    required String subjectCode,
    required String subjectName,
    required String assessment,
    required String academicYear,
    required double totalMarks,
    required double maxMarks,
    double partA = 0.0,
    double partB = 0.0,
    double partC = 0.0,
    String? classSec,
    String? year,
    String? department,
    String? section,
    double? percentage,
    String? grade,
    String? remarks,
    Map<String, dynamic>? questionMarks,
    Map<String, dynamic>? marksJson,
    double? passingMarks,
    bool isAbsent = false,
    String status = 'Draft',
  }) async {
    try {
      String resolvedStudentId = studentId.trim();
      if (resolvedStudentId.isEmpty || resolvedStudentId == registerNo || resolvedStudentId == studentRoll) {
        try {
          final stus = await SupabaseClientHelper.select(
            'students',
            schema: 'student',
            filterColumn: 'register_no',
            filterValue: registerNo,
          );
          if (stus.isNotEmpty && stus.first['student_id'] != null) {
            resolvedStudentId = stus.first['student_id'].toString();
          }
        } catch (_) {}
      }
      if (resolvedStudentId.isEmpty) {
        resolvedStudentId = registerNo.isNotEmpty ? registerNo : studentRoll;
      }

      final payload = <String, dynamic>{
        'faculty_employee_id': facultyEmployeeId,
        'student_id': resolvedStudentId,
        'register_no': registerNo,
        'student_roll': studentRoll,
        'student_name': studentName,
        'subject_code': subjectCode,
        'subject': subjectName,
        'assessment': assessment,
        'academic_year': academicYear,
        'part_a': partA,
        'part_b': partB,
        'part_c': partC,
        'total': totalMarks,
        'max_marks': maxMarks,
        'is_absent': isAbsent,
        'status': status,
        'class_sec': classSec,
        'year': year,
        'department': department,
        'section': section,
        'percentage': percentage,
        'grade': grade,
        'remarks': remarks,
        'question_marks': questionMarks,
        'passing_marks': passingMarks,
      };
      payload.removeWhere((key, value) => value == null);

      final result = await SupabaseClientHelper.upsert(
        'marks',
        payload,
        'register_no,subject,assessment',
        schema: 'faculty',
      );
      return result;
    } catch (e) {
      debugPrint('Error saving student mark: $e');
      return false;
    }
  }

  /// Deletes a student mark record from `faculty.marks`
  static Future<bool> deleteStudentMark({
    required String registerNo,
    required String subject,
    required String assessment,
  }) async {
    try {
      final filters = <String, String>{
        'register_no': registerNo,
        'subject': subject,
        'assessment': assessment,
      };
      final matches = await SupabaseClientHelper.selectWithFilters(
        'marks',
        schema: 'faculty',
        filters: filters,
      );
      if (matches.isNotEmpty) {
        final id = matches.first['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          return await SupabaseClientHelper.delete('marks', 'id', id, schema: 'faculty');
        }
      }
    } catch (e) {
      debugPrint('Error deleting student mark: $e');
    }
    return false;
  }
}
