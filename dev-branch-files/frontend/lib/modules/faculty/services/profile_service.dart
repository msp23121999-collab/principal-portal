// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// FACULTY PROFILE SERVICE
/// ============================================================
/// Stores & retrieves faculty profile from Local Storage.
/// Future: replace body with HTTP calls to PostgreSQL REST API.
/// ============================================================
library;

import 'local_storage_base.dart';
import 'postgres_client.dart';

class ProfileService {
  static const String _key = 'profile';
  static const String _table = 'faculties';
  static const String _schema = 'faculty';

  static final Map<String, dynamic> _defaultProfile = {
    'facultyId': 'EMP_CSE_002',
    'employeeId': 'EMP_CSE_002',
    'name': 'Mr. P. Kalaiyarasan',
    'role': 'Faculty',
    'designation': 'Assistant Professor',
    'departmentId': 'DEPT_IT',
    'dept': 'Information Technology',
    'department': 'Information Technology',
    'email': 'kalaiyarasan@ksrce.ac.in',
    'phone': '9876543210',
    'experience': '8+ Years',
    'photoUrl': '',
    'qualification': 'M.E. in Information Technology',
    'subjects': ['Computer Networks', 'Operating Systems', 'Cloud Computing'],
    'research': 'Wireless Networks, Cloud Infrastructure, IoT',
    'address': 'KSR College of Engineering, Tiruchengodu, Tamil Nadu',
    'status': 'Active',
    'hodName': '',
    'hodEmployeeId': 'HOD-CSE-001',
  };

  /// Returns the URL only if it is a safe, directly loadable image URL.
  /// Rejects Google search pages, image result pages, and non-image URLs.
  static String sanitizePhotoUrl(dynamic raw) {
    if (raw == null) return '';
    final url = raw.toString().trim();
    if (url.isEmpty) return '';
    // Allow base64 data URIs (uploaded locally)
    if (url.startsWith('data:image/')) return url;
    // Block Google domains and known non-direct-image URLs
    final blocked = [
      'google.com/imgres',
      'google.com/search',
      'google.co',
      'goo.gl',
      'maps.google',
      'ksrce.ac.in',
      'storage.ksrce',
    ];
    for (final b in blocked) {
      if (url.contains(b)) return '';
    }
    // Must start with https:// and be a plausible image URL
    if (!url.startsWith('https://') && !url.startsWith('http://')) return '';
    return url;
  }

  static void seedIfEmpty() {
    final existing = LocalStorageBase.readMap(_key);
    if (existing.isNotEmpty) return;
    LocalStorageBase.writeMap(_key, _defaultProfile);
  }

  // ── Supabase Integration ────────────────────────────────────
  static Future<String> fetchHodNameFromSupabase({
    String hodEmployeeId = 'HOD-CSE-001',
  }) async {
    try {
      final remote = await SupabaseClientHelper.select(
        _table,
        schema: _schema,
        filterColumn: 'employee_id',
        filterValue: hodEmployeeId,
      );
      if (remote.isNotEmpty) {
        final hod = remote.first;
        final name =
            hod['full_name']?.toString() ?? hod['name']?.toString() ?? '';
        if (name.isNotEmpty) {
          return '$name ($hodEmployeeId)';
        }
      }
    } catch (_) {}
    return '';
  }

  static Future<Map<String, dynamic>> fetchFromSupabase({
    String employeeId = 'EMP_CSE_002',
  }) async {
    final remote = await SupabaseClientHelper.select(
      _table,
      schema: _schema,
      filterColumn: 'employee_id',
      filterValue: employeeId,
    );

    final hodNameFromDb = await fetchHodNameFromSupabase(
      hodEmployeeId: 'HOD-CSE-001',
    );

    if (remote.isNotEmpty) {
      final p = remote.first;
      final converted = {
        'facultyId': p['employee_id'] ?? employeeId,
        'employeeId': p['employee_id'] ?? employeeId,
        'name': p['full_name'] ?? p['name'] ?? '',
        'role': p['role'] ?? '',
        'designation': p['designation'] ?? '',
        'departmentId': p['department_id'] ?? '',
        'dept': p['department'] ?? '',
        'department': p['department'] ?? '',
        'email': p['email'] ?? '',
        'officialEmail': p['official_email'] ?? p['email'] ?? '',
        'personalEmail': p['personal_email'] ?? '',
        'phone': p['phone'] ?? '',
        'experience': p['experience'] != null ? '${p['experience']} Years' : '',
        'qualification': p['qualification'] ?? '',
        'photoUrl': sanitizePhotoUrl(p['photo_url']),
        'research': p['research_interests'] ?? '',
        'address': p['address'] ?? '',
        'dob': p['dob']?.toString() ?? '',
        'gender': p['gender']?.toString() ?? '',
        'bloodGroup': p['blood_group']?.toString() ?? '',
        'emergencyContact': p['emergency_contact']?.toString() ?? '',
        'specialization': p['specialization']?.toString() ?? '',
        'dateOfJoining': p['date_of_joining']?.toString() ?? '',
        'employmentType': p['employment_type']?.toString() ?? '',
        'staffType': p['staff_type']?.toString() ?? '',
        'nationality': p['nationality']?.toString() ?? '',
        'maritalStatus': p['marital_status']?.toString() ?? '',
        'officeLocation': p['office_location']?.toString() ?? '',
        'teachingExperienceYears':
            p['teaching_experience_years']?.toString() ?? '',
        'ugDegree': p['ug_degree']?.toString() ?? '',
        'pgDegree': p['pg_degree']?.toString() ?? '',
        'phdDegree': p['phd_degree']?.toString() ?? '',
        'university': p['university']?.toString() ?? '',
        'orcid': p['orcid']?.toString() ?? '',
        'scopusId': p['scopus_id']?.toString() ?? '',
        'googleScholar': p['google_scholar']?.toString() ?? '',
        'researchGate': p['research_gate']?.toString() ?? '',
        'publicationCount': p['publication_count']?.toString() ?? '',
        'weeklyWorkloadHours': p['weekly_workload_hours']?.toString() ?? '',
        'subjects': p['assigned_subjects'] is List
            ? List<String>.from(p['assigned_subjects'])
            : [],
        'status': p['status'] ?? 'Active',
        'hodName': hodNameFromDb,
        'hodEmployeeId': 'HOD-CSE-001',
      };
      LocalStorageBase.writeMap(_key, converted);
      return converted;
    }
    return get();
  }

  static Map<String, dynamic> get() {
    final stored = LocalStorageBase.readMap(_key);
    if (stored.isNotEmpty) {
      // Sanitize cached photoUrl on every read to fix any previously stored bad URLs
      final cleaned = Map<String, dynamic>.from(stored);
      cleaned['photoUrl'] = sanitizePhotoUrl(stored['photoUrl']);
      return cleaned;
    }
    return Map<String, dynamic>.from(_defaultProfile);
  }

  static void save(Map<String, dynamic> profile) {
    LocalStorageBase.writeMap(_key, profile);
    SupabaseClientHelper.upsert(
      _table,
      {
        'employee_id':
            profile['employeeId'] ?? profile['facultyId'] ?? 'FAC73124',
        'code': _departmentCode(
          profile['departmentId'] ?? profile['department'] ?? profile['dept'],
        ),
        'full_name': profile['name'] ?? '',
        'role': profile['role'] ?? '',
        'designation': profile['designation'] ?? '',
        'department': profile['department'] ?? profile['dept'] ?? '',
        'email': profile['email'] ?? '',
        'phone': profile['phone'] ?? '',
        'experience': profile['experience'] ?? '',
        'qualification': profile['qualification'] ?? '',
        'photo_url': profile['photoUrl'] ?? '',
        'research_interests': profile['research'] ?? '',
        'address': profile['address'] ?? '',
        'assigned_subjects': profile['subjects'] ?? [],
        'status': profile['status'] ?? 'Active',
      },
      'employee_id',
      schema: _schema,
    );
  }

  static String _departmentCode(dynamic value) {
    final raw = value?.toString().trim().toUpperCase() ?? '';
    final match = RegExp(r'\(([A-Z]+)\)').firstMatch(raw);
    if (match != null) return match.group(1)!;
    final cleaned = raw
        .replaceAll('DEPT_', '')
        .replaceAll('DEP-', '')
        .split('-')
        .first
        .split('_')
        .first;
    return cleaned.isEmpty ? 'CSE' : cleaned;
  }

  static void update(Map<String, dynamic> updates) {
    final current = get();
    current.addAll(updates);
    save(current);
  }

  static String get facultyId => get()['facultyId']?.toString() ?? 'FAC73124';
  static String get name => get()['name']?.toString() ?? 'Faculty';
}
