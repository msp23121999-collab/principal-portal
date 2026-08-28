import 'supabase_client.dart';

class ResearchService {
  static const String _table = 'research_publications';
  static const String _schema = 'faculty';

  static Future<List<Map<String, dynamic>>> fetchFromSupabase({String? facultyId}) async {
    try {
      final remote = await SupabaseClientHelper.select(
        _table,
        schema: _schema,
        filterColumn: (facultyId != null && facultyId.isNotEmpty) ? 'faculty_employee_id' : null,
        filterValue: facultyId,
      );

      if (remote.isNotEmpty) {
        return remote.map((r) {
          final pubType = (r['pub_type'] ?? r['category'] ?? 'Journal').toString();
          String category = pubType;
          final ptLower = pubType.toLowerCase();
          if (ptLower == 'journal' || ptLower.contains('journal')) {
            category = 'Journal Publication';
          } else if (ptLower == 'conference' || ptLower.contains('conference')) {
            category = 'Conference Publication';
          } else if (ptLower.contains('book')) {
            category = 'Book / Book Chapter';
          } else if (ptLower.contains('patent')) {
            category = 'Patent';
          } else if (ptLower.contains('project') || ptLower.contains('funded')) {
            category = 'Funded Project';
          } else if (ptLower.contains('consultancy')) {
            category = 'Consultancy';
          } else if (ptLower.contains('achievement') || ptLower.contains('award')) {
            category = 'Research Achievement';
          }

          final venue = (r['journal_or_conf_name'] ?? r['venue'] ?? '').toString();
          final indexing = (r['indexing'] ?? r['extra1'] ?? '').toString();
          final doi = (r['doi'] ?? '').toString();
          final vol = (r['volume_issue'] ?? '').toString();
          final pages = (r['pages'] ?? '').toString();
          final isbn = (r['issn_isbn'] ?? '').toString();
          final pubDate = (r['publication_date'] ?? r['year'] ?? '').toString();
          final docUrl = (r['document_url'] ?? r['file_url'] ?? '').toString();
          final status = (r['verification_status'] ?? r['status'] ?? 'Approved').toString();

          final extra2Parts = <String>[];
          if (doi.isNotEmpty) extra2Parts.add('DOI: $doi');
          if (vol.isNotEmpty) extra2Parts.add(vol);
          if (isbn.isNotEmpty) extra2Parts.add('ISBN/ISSN: $isbn');
          if (pages.isNotEmpty) extra2Parts.add('Pages: $pages');

          return {
            'id': r['id']?.toString() ?? '',
            'facultyId': r['faculty_employee_id'] ?? facultyId ?? 'EMP_CSE_002',
            'title': r['title'] ?? 'Untitled Research',
            'category': category,
            'pub_type': pubType,
            'venue': venue,
            'extra1': indexing.isNotEmpty ? indexing : isbn,
            'extra2': extra2Parts.isNotEmpty ? extra2Parts.join(' | ') : (r['extra2'] ?? ''),
            'year': pubDate.isNotEmpty ? pubDate.split('-').first : '2025',
            'publication_date': pubDate,
            'doi': doi,
            'volume_issue': vol,
            'pages': pages,
            'issn_isbn': isbn,
            'impact_factor': (r['impact_factor'] ?? '0.0').toString(),
            'description': r['description'] ?? (pages.isNotEmpty ? 'Pages: $pages' : ''),
            'fileName': docUrl.isNotEmpty ? docUrl.split('/').last : (r['file_name'] ?? ''),
            'fileUrl': docUrl,
            'status': (status.toLowerCase() == 'verified' || status.toLowerCase() == 'approved') ? 'Approved' : 'Submitted for Verification',
            'verification_status': status,
            'created_at': r['created_at']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> save(Map<String, dynamic> record) async {
    try {
      final dbPayload = <String, dynamic>{
        'faculty_employee_id': record['facultyId'] ?? record['faculty_employee_id'] ?? 'EMP_CSE_002',
        'pub_type': record['pub_type'] ?? (record['category']?.toString().contains('Conference') == true ? 'Conference' : 'Journal'),
        'title': record['title'],
        'journal_or_conf_name': record['venue'] ?? record['journal_or_conf_name'],
        'indexing': record['extra1'] ?? record['indexing'],
        'volume_issue': record['volume_issue'] ?? record['extra2'],
        'pages': record['pages'] ?? '',
        'publication_date': record['publication_date'] ?? '${record['year'] ?? '2025'}-01-01',
        'doi': record['doi'] ?? '',
        'issn_isbn': record['issn_isbn'] ?? '',
        'impact_factor': record['impact_factor'] ?? '0.0',
        'document_url': record['fileUrl'] ?? record['document_url'] ?? '',
        'verification_status': record['status'] == 'Approved' ? 'Verified' : 'Submitted for Verification',
      };
      await SupabaseClientHelper.insert(_table, dbPayload, schema: _schema);
    } catch (_) {}
  }

  static Future<void> delete(String id) async {
    try {
      await SupabaseClientHelper.delete(_table, 'id', id, schema: _schema);
    } catch (_) {}
  }
}
