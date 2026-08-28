import '../shared/services/supabase_service.dart';

class ProgrammeSubjectService {
  static Future<List<Map<String, dynamic>>> fetchProgrammes() async {
    try {
      return await SupabaseService.instance.fetchTable('programmes');
    } catch (e) {
      print('Error fetching programmes: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSubjects() async {
    try {
      return await SupabaseService.instance.fetchTable('subjects');
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchProgrammeSubjectMappings({
    String? subjectCode,
  }) async {
    try {
      return await SupabaseService.instance.fetchTable(
        'programme_subject_mappings',
        filter: subjectCode != null ? 'subject_code.eq.$subjectCode' : null,
      );
    } catch (e) {
      print('Error fetching programme subject mappings: $e');
      return [];
    }
  }

  static Future<bool> createProgramme(Map<String, dynamic> data) async {
    try {
      final result = await SupabaseService.instance.insertData('programmes', data);
      return result != null;
    } catch (e) {
      print('Error creating programme: $e');
      return false;
    }
  }

  static Future<bool> updateProgramme(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.updateData('programmes', data, id);
    } catch (e) {
      print('Error updating programme: $e');
      return false;
    }
  }

  static Future<bool> deleteProgramme(String id) async {
    try {
      return await SupabaseService.instance.deleteData('programmes', id);
    } catch (e) {
      print('Error deleting programme: $e');
      return false;
    }
  }

  static Future<bool> createSubject(Map<String, dynamic> data) async {
    try {
      final result = await SupabaseService.instance.insertData('subjects', data);
      return result != null;
    } catch (e) {
      print('Error creating subject: $e');
      return false;
    }
  }

  static Future<bool> updateSubject(
    String id,
    Map<String, dynamic> data, {
    Map<String, dynamic>? previous,
  }) async {
    try {
      return await SupabaseService.instance.updateData('subjects', data, id);
    } catch (e) {
      print('Error updating subject: $e');
      return false;
    }
  }

  static Future<bool> mapSubjectToProgramme(Map<String, dynamic> data) async {
    try {
      final result = await SupabaseService.instance.insertData(
        'programme_subject_mappings',
        data,
      );
      return result != null;
    } catch (e) {
      print('Error mapping subject to programme: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCourseOutcomes(
    String subjectCode,
  ) async {
    try {
      return await SupabaseService.instance.fetchTable(
        'course_outcomes',
        filter: 'subject_code.eq.$subjectCode',
      );
    } catch (e) {
      print('Error fetching course outcomes: $e');
      return [];
    }
  }

  static Future<bool> addCourseOutcome(Map<String, dynamic> data) async {
    try {
      final result = await SupabaseService.instance.insertData(
        'course_outcomes',
        data,
      );
      return result != null;
    } catch (e) {
      print('Error adding course outcome: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSubjectUnits(
    String subjectCode,
  ) async {
    try {
      return await SupabaseService.instance.fetchTable(
        'subject_units',
        filter: 'subject_code.eq.$subjectCode',
      );
    } catch (e) {
      print('Error fetching subject units: $e');
      return [];
    }
  }

  static Future<bool> addSubjectUnit(Map<String, dynamic> data) async {
    try {
      final result = await SupabaseService.instance.insertData(
        'subject_units',
        data,
      );
      return result != null;
    } catch (e) {
      print('Error adding subject unit: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAuditHistory(String id) async {
    try {
      return await SupabaseService.instance.fetchTable(
        'subject_audit_logs',
        filter: 'subject_id.eq.$id',
      );
    } catch (e) {
      print('Error fetching audit history: $e');
      return [];
    }
  }

  static Future<bool> isSubjectReferenced(String subjectCode) async {
    try {
      final mappings = await SupabaseService.instance.fetchTable(
        'programme_subject_mappings',
        filter: 'subject_code.eq.$subjectCode',
      );
      return mappings.isNotEmpty;
    } catch (e) {
      print('Error checking subject references: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSubjectsByProgramme(
    String programmeId,
  ) async {
    try {
      final subjects = await SupabaseService.instance.fetchTable(
        'subjects',
        filter: 'programme_id.eq.$programmeId',
      );
      return subjects;
    } catch (e) {
      print('Error fetching subjects for programme: $e');
      return [];
    }
  }

  static Future<bool> addSubjectToProgramme(
    Map<String, dynamic> subjectData,
  ) async {
    try {
      final result = await SupabaseService.instance.insertData(
        'subjects',
        subjectData,
      );
      return result != null;
    } catch (e) {
      print('Error adding subject: $e');
      return false;
    }
  }

  static Future<bool> deleteSubject(String subjectId) async {
    try {
      return await SupabaseService.instance.deleteData('subjects', subjectId);
    } catch (e) {
      print('Error deleting subject: $e');
      return false;
    }
  }
}
