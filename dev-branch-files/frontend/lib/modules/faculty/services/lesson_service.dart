// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// LESSON PROGRESS SERVICE — Supabase Integrated (No Mock Data)
/// ============================================================
library;

import 'package:flutter/foundation.dart';
import 'local_storage_base.dart';
import 'supabase_client.dart';

class LessonService {
  static const String _key = 'lessonPlans';
  static const String _table = 'lesson_plans';
  static const String _schema = 'faculty';

  static void seedIfEmpty() {}

  static List<Map<String, dynamic>> getAll() {
    return LocalStorageBase.readList(_key);
  }

  static Future<List<Map<String, dynamic>>> fetchFromSupabase({required String facultyId}) async {
    try {
      final remote = await SupabaseClientHelper.select(
        _table,
        schema: _schema,
        filterColumn: 'faculty_employee_id',
        filterValue: facultyId,
      );

      final recordsToUse = remote.isNotEmpty
          ? remote
          : await SupabaseClientHelper.select(_table, schema: _schema);

      if (recordsToUse.isNotEmpty) {
        final converted = recordsToUse.map((lp) {
          final unitNum = lp['unit_number'] ?? lp['unit'] ?? 1;
          final unitInt = unitNum is int ? unitNum : (int.tryParse(unitNum.toString()) ?? 1);
          final statusStr = (lp['status'] ?? 'Pending').toString();
          return {
            'id': lp['id']?.toString() ?? '',
            'lessonPlanId': lp['id']?.toString() ?? '',
            'facultyId': lp['faculty_employee_id']?.toString() ?? facultyId,
            'code': lp['course_code'] ?? '',
            'subject': lp['subject_name'] ?? lp['subject'] ?? '',
            'unit': 'Unit $unitInt',
            'unitNumber': unitInt,
            'unitTitle': lp['unit_title'] ?? 'Unit $unitInt',
            'topic': lp['topic_name'] ?? lp['topic_title'] ?? lp['topic'] ?? '',
            'plannedDate': lp['planned_date'] ?? '',
            'completionDate': lp['actual_date'] ?? lp['completed_date'] ?? '',
            'status': statusStr,
            'teachingAid': lp['teaching_aid'] ?? 'Blackboard',
            'targetHours': lp['target_hours'] ?? 1,
            'department': lp['department'] ?? '',
            'section': lp['section'] ?? '',
            'academicYear': lp['academic_year'] ?? '2025-26',
            'delayReason': lp['delay_reason'] ?? '',
            'remarks': lp['remarks'] ?? '',
            'progress': (statusStr == 'Completed') ? 1.0 : (statusStr == 'In Progress' ? 0.5 : 0.0),
          };
        }).toList();

        LocalStorageBase.writeList(_key, converted);
        return converted;
      }
    } catch (e) {
      debugPrint('Error fetching lesson plans from Supabase: $e');
    }

    return getAll();
  }

  static Future<void> save(Map<String, dynamic> item) async {
    final all = getAll();
    final String id = item['id']?.toString() ?? item['lessonPlanId']?.toString() ?? LocalStorageBase.generateId('LP');
    item['id'] = id;
    item['lessonPlanId'] = id;

    final unitNumStr = (item['unit'] ?? '1').toString().replaceAll(RegExp(r'[^\d]'), '');
    final int unitInt = int.tryParse(unitNumStr) ?? 1;

    item['unitNumber'] = unitInt;
    item['status'] ??= 'Pending';

    final idx = all.indexWhere((lp) => lp['id'] == id || lp['lessonPlanId'] == id);
    if (idx >= 0) {
      all[idx] = item;
    } else {
      all.add(item);
    }
    LocalStorageBase.writeList(_key, all);

    final payload = {
      'faculty_employee_id': item['facultyId'] ?? 'FAC002',
      'course_code': item['code'] ?? '',
      'subject_name': item['subject'] ?? '',
      'unit_number': unitInt,
      'unit_title': item['unitTitle'] ?? 'Unit $unitInt',
      'topic_name': item['topic'] ?? '',
      'planned_date': (item['plannedDate']?.toString().isNotEmpty == true) ? item['plannedDate'] : null,
      'actual_date': (item['completionDate']?.toString().isNotEmpty == true) ? item['completionDate'] : null,
      'status': item['status'] ?? 'Pending',
      'teaching_aid': item['teachingAid'] ?? 'Blackboard',
      'department': item['department'] ?? '',
      'section': item['section'] ?? '',
      'academic_year': item['academicYear'] ?? '2025-26',
      'delay_reason': item['delayReason'] ?? '',
      'target_hours': item['targetHours'] ?? 1,
      'remarks': item['remarks'] ?? '',
    };

    try {
      await SupabaseClientHelper.insert(_table, payload, schema: _schema);
    } catch (e) {
      debugPrint('Supabase lesson plan insert warning: $e');
    }
  }

  static Future<void> delete(String lessonPlanId) async {
    final all = getAll();
    all.removeWhere((lp) => lp['lessonPlanId'] == lessonPlanId || lp['id'] == lessonPlanId);
    LocalStorageBase.writeList(_key, all);

    try {
      await SupabaseClientHelper.delete(_table, 'id', lessonPlanId, schema: _schema);
    } catch (e) {
      debugPrint('Supabase lesson plan delete warning: $e');
    }
  }

  static double get overallProgress {
    final list = getAll();
    if (list.isEmpty) return 0.0;
    final total = list.fold<double>(0.0, (sum, lp) => sum + ((lp['progress'] as num? ?? 0.0).toDouble()));
    return total / list.length;
  }

  static Future<void> submitMonthlyProgressToHod({
    required String facultyId,
    required String department,
    required String section,
    required String subject,
    required String courseCode,
    required String month,
    required String academicYear,
    required int totalTopics,
    required int completedTopics,
    required double completionPct,
  }) async {
    final all = getAll();
    for (final lp in all) {
      if ((subject.isEmpty || lp['subject'] == subject) && (courseCode.isEmpty || lp['code'] == courseCode)) {
        lp['monthlyStatus'] = 'Submitted to HOD';
      }
    }
    LocalStorageBase.writeList(_key, all);

    final hodPayload = {
      'faculty_employee_id': facultyId,
      'department': department,
      'section': section,
      'subject_name': subject,
      'course_code': courseCode,
      'month': month,
      'academic_year': academicYear,
      'total_topics': totalTopics,
      'completed_topics': completedTopics,
      'overall_completion_pct': completionPct,
      'submission_status': 'Submitted',
      'submitted_at': DateTime.now().toIso8601String(),
    };

    try {
      await SupabaseClientHelper.insert('lesson_plan_progress', hodPayload, schema: 'hod');
    } catch (e) {
      debugPrint('Warning submitting lesson plan progress to HOD schema: $e');
    }
  }
}