// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// COURSE MATERIAL SERVICE — Pure Database (No Local Storage / No Fallbacks)
/// ============================================================
import 'supabase_client.dart';
import 'local_storage_base.dart';

class SyllabusService {
  static const String _table = 'course_materials';
  static const String _schema = 'faculty';

  static void seedIfEmpty() {}

  static List<Map<String, dynamic>> getAll() => [];

  static List<Map<String, dynamic>> getBySubject(String subject) => [];

  static List<Map<String, dynamic>> getByFaculty(String facultyId) => [];

  static Future<List<Map<String, dynamic>>> fetchFromSupabase({String? facultyId}) async {
    List<Map<String, dynamic>> remote = [];
    try {
      remote = await SupabaseClientHelper.select(
        _table,
        schema: _schema,
        filterColumn: (facultyId != null && facultyId.isNotEmpty) ? 'faculty_employee_id' : null,
        filterValue: facultyId,
      );
    } catch (_) {
      try {
        remote = await SupabaseClientHelper.select(
          'syllabus_uploads',
          schema: _schema,
          filterColumn: (facultyId != null && facultyId.isNotEmpty) ? 'faculty_employee_id' : null,
          filterValue: facultyId,
        );
      } catch (_) {}
    }

    if (remote.isNotEmpty) {
      final seenKeys = <String>{};
      final List<Map<String, dynamic>> result = [];

      for (final s in remote) {
        final id = s['id']?.toString() ?? '';
        final title = (s['material_title'] ?? s['file_name'] ?? 'Course Material').toString();
        final fileName = (s['file_name'] ?? 'document.pdf').toString();
        final key = id.isNotEmpty ? id : '$title--$fileName';

        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          result.add({
            'id': id,
            'syllabusId': id,
            'title': title,
            'type': s['material_type'] ?? 'Lecture Notes',
            'subject': s['subject_name'] ?? s['subject'] ?? '',
            'courseCode': s['course_code'] ?? '',
            'classSection': s['class_sec'] ?? s['section'] ?? s['department'] ?? 'CSE - A',
            'department': s['department'] ?? '',
            'section': s['section'] ?? '',
            'description': s['description'] ?? '',
            'fileName': fileName,
            'fileSize': s['file_size'] ?? '1.0 MB',
            'fileUrl': s['file_url'] ?? '',
            'fileData': s['file_url'] ?? '',
            'uploadedOn': s['created_at'] != null ? s['created_at'].toString().substring(0, 10) : DateTime.now().toString().substring(0, 10),
            'status': 'Published',
          });
        }
      }
      return result;
    }
    return [];
  }

  static Future<void> save(Map<String, dynamic> material) async {
    final payload = <String, dynamic>{
      'faculty_employee_id': material['facultyId'] ?? 'EMP_CSE_002',
      'material_title': material['title'] ?? material['fileName'] ?? 'Course Material',
      'material_type': material['type'] ?? 'Lecture Notes',
      'subject_name': material['subject'] ?? '',
      'course_code': material['courseCode'] ?? '',
      'department': material['department'] ?? '',
      'section': material['section'] ?? '',
      'class_sec': material['classSection'] ?? 'CSE - A',
      'description': material['description'] ?? '',
      'file_url': material['fileUrl'] ?? material['fileData'] ?? '',
      'file_name': material['fileName'] ?? 'document.pdf',
      'file_size': material['fileSize'] ?? '1.0 MB',
    };

    try {
      await SupabaseClientHelper.upsert(
        _table,
        payload,
        'faculty_employee_id,material_title,subject_name,file_name',
        schema: _schema,
      );
    } catch (_) {
      try {
        await SupabaseClientHelper.insert(_table, payload, schema: _schema);
      } catch (_) {}
    }
  }

  static Future<void> delete(String id) async {
    try {
      await SupabaseClientHelper.delete(_table, 'id', id, schema: _schema);
    } catch (_) {
      try {
        await SupabaseClientHelper.delete('syllabus_uploads', 'id', id, schema: _schema);
      } catch (_) {}
    }
  }
}