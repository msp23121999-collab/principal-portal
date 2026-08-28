// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// LEAVE SERVICE — Pure Database Integrated
/// ============================================================
import 'supabase_client.dart';

class LeaveService {
  static const String _table = 'leave_applications';
  static const String _schema = 'faculty';
  static const String defaultHodId = 'HOD-CSE-001';

  static final List<Map<String, dynamic>> _inMemoryLeaves = [];

  static const Map<String, int> _defaultBalances = {
    'Casual Leave': 8,
    'Medical Leave': 15,
    'Earned Leave': 10,
    'On Duty': 5,
    'Special Leave': 4,
    'Compensatory Leave': 3,
  };

  static void seedIfEmpty() {}

  static List<Map<String, dynamic>> getAll() => [];

  static Future<List<Map<String, String>>> fetchDepartmentFaculties({String currentEmpId = 'FAC002'}) async {
    try {
      final remote = await SupabaseClientHelper.select('faculties', schema: _schema);
      if (remote.isNotEmpty) {
        final list = <Map<String, String>>[];
        for (final f in remote) {
          final empId = f['employee_id']?.toString() ?? '';
          final role = f['role']?.toString() ?? '';
          final name = f['full_name']?.toString() ?? f['name']?.toString() ?? '';
          final desig = f['designation']?.toString() ?? '';
          final dept = (f['department'] ?? f['dept'] ?? 'CSE').toString().trim();

          if (empId.isNotEmpty && empId != currentEmpId && empId != defaultHodId && !role.toUpperCase().contains('HOD')) {
            list.add({
              'id': empId,
              'name': name,
              'designation': desig,
              'department': dept.isNotEmpty ? dept : 'CSE',
              'label': name.isNotEmpty ? (desig.isNotEmpty ? '$name ($desig)' : name) : empId,
            });
          }
        }
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    final defaults = [
      {'id': 'FAC001', 'name': 'Dr. S. Pradeep', 'designation': 'Professor', 'department': 'CSE', 'label': 'Dr. S. Pradeep (Professor)'},
      {'id': 'FAC003', 'name': 'Ms. P. Kavitha', 'designation': 'Assistant Professor', 'department': 'CSE', 'label': 'Ms. P. Kavitha (Assistant Professor)'},
      {'id': 'FAC004', 'name': 'Dr. K. Ramesh', 'designation': 'Associate Professor', 'department': 'CSE', 'label': 'Dr. K. Ramesh (Associate Professor)'},
      {'id': 'FAC005', 'name': 'Mr. R. Anand', 'designation': 'Assistant Professor', 'department': 'IT', 'label': 'Mr. R. Anand (Assistant Professor)'},
      {'id': 'FAC006', 'name': 'Ms. M. Deepa', 'designation': 'Assistant Professor', 'department': 'IT', 'label': 'Ms. M. Deepa (Assistant Professor)'},
      {'id': 'FAC007', 'name': 'Dr. V. Suresh', 'designation': 'Professor', 'department': 'ECE', 'label': 'Dr. V. Suresh (Professor)'},
      {'id': 'FAC008', 'name': 'Ms. N. Divya', 'designation': 'Assistant Professor', 'department': 'EEE', 'label': 'Ms. N. Divya (Assistant Professor)'},
    ];

    return defaults.where((f) => f['id'] != currentEmpId).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchFromSupabase() async {
    List<Map<String, dynamic>> results = [];
    try {
      final remote = await SupabaseClientHelper.select(_table, schema: _schema);
      if (remote.isNotEmpty) {
        results = remote.map((l) {
          final id = l['id']?.toString() ?? '';
          final startDate = l['start_date']?.toString() ?? l['from_date']?.toString() ?? '';
          final endDate = l['end_date']?.toString() ?? l['to_date']?.toString() ?? '';
          final facultyEmpId = l['faculty_employee_id']?.toString() ?? l['faculty_id']?.toString() ?? 'FAC002';

          return {
            'id': id,
            'leaveId': id,
            'facultyId': facultyEmpId,
            'hodEmployeeId': l['hod_employee_id']?.toString() ?? defaultHodId,
            'type': l['leave_type'] ?? 'Casual Leave',
            'priority': l['priority'] ?? 'Normal',
            'session': l['session_type'] ?? 'Full Day',
            'isHalfDay': l['is_half_day'] ?? false,
            'fromDate': startDate,
            'toDate': endDate,
            'totalCalendarDays': (l['total_calendar_days'] as num? ?? 1).toInt(),
            'weekendDaysExcluded': (l['weekends_excluded'] as num? ?? 0).toInt(),
            'holidaysExcluded': (l['holidays_excluded'] as num? ?? 0).toInt(),
            'days': (l['total_days'] as num? ?? 1.0).toDouble(),
            'reason': l['reason'] ?? '',
            'remarks': l['remarks'] ?? l['hod_remarks'] ?? '',
            'substituteFacultyId': l['substitute_faculty_id'] ?? l['alternate_faculty_id'] ?? '',
            'attachmentName': l['attachment_name'] ?? '',
            'attachmentUrl': l['attachment_url'] ?? l['document_url'] ?? '',
            'status': l['status'] ?? 'Pending',
            'academicYear': l['academic_year'] ?? '2025-26',
            'appliedOn': l['applied_date'] ?? l['created_at'] ?? startDate,
            'createdAt': l['created_at'] ?? l['applied_date'] ?? startDate,
            'substitutions_json': l['substitutions_json'],
          };
        }).toList();
      }
    } catch (_) {
      try {
        final remoteDefault = await SupabaseClientHelper.select(_table);
        if (remoteDefault.isNotEmpty) {
          results = remoteDefault.map((l) {
            final id = l['id']?.toString() ?? '';
            final startDate = l['start_date']?.toString() ?? l['from_date']?.toString() ?? '';
            final endDate = l['end_date']?.toString() ?? l['to_date']?.toString() ?? '';
            final facultyEmpId = l['faculty_employee_id']?.toString() ?? l['faculty_id']?.toString() ?? 'FAC002';

            return {
              'id': id,
              'leaveId': id,
              'facultyId': facultyEmpId,
              'hodEmployeeId': l['hod_employee_id']?.toString() ?? defaultHodId,
              'type': l['leave_type'] ?? 'Casual Leave',
              'priority': l['priority'] ?? 'Normal',
              'session': l['session_type'] ?? 'Full Day',
              'isHalfDay': l['is_half_day'] ?? false,
              'fromDate': startDate,
              'toDate': endDate,
              'totalCalendarDays': (l['total_calendar_days'] as num? ?? 1).toInt(),
              'weekendDaysExcluded': (l['weekends_excluded'] as num? ?? 0).toInt(),
              'holidaysExcluded': (l['holidays_excluded'] as num? ?? 0).toInt(),
              'days': (l['total_days'] as num? ?? 1.0).toDouble(),
              'reason': l['reason'] ?? '',
              'remarks': l['remarks'] ?? l['hod_remarks'] ?? '',
              'substituteFacultyId': l['substitute_faculty_id'] ?? l['alternate_faculty_id'] ?? '',
              'attachmentName': l['attachment_name'] ?? '',
              'attachmentUrl': l['attachment_url'] ?? l['document_url'] ?? '',
              'status': l['status'] ?? 'Pending',
              'academicYear': l['academic_year'] ?? '2025-26',
              'appliedOn': l['applied_date'] ?? l['created_at'] ?? startDate,
              'createdAt': l['created_at'] ?? l['applied_date'] ?? startDate,
              'substitutions_json': l['substitutions_json'],
            };
          }).toList();
        }
      } catch (_) {}
    }

    final combined = <Map<String, dynamic>>[..._inMemoryLeaves];
    final existingIds = combined.map((i) => i['id']?.toString()).toSet();

    for (final r in results) {
      final rId = r['id']?.toString();
      if (rId != null && !existingIds.contains(rId)) {
        combined.add(r);
        existingIds.add(rId);
      }
    }

    return combined;
  }

  /// Withdraws and permanently deletes a leave application and its substitutions from Supabase DB
  static Future<bool> withdraw(String id) async {
    if (id.isEmpty) return false;
    _inMemoryLeaves.removeWhere((item) => item['id']?.toString() == id || item['leaveId']?.toString() == id);
    try {
      // 1. Delete associated substitutions first
      await SupabaseClientHelper.delete('leave_substitutions', 'leave_application_id', id, schema: _schema);
      
      // 2. Delete the leave application row from faculty.leave_applications
      final success = await SupabaseClientHelper.delete(_table, 'id', id, schema: _schema);
      if (!success) {
        await SupabaseClientHelper.delete(_table, 'display_id', id, schema: _schema);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<Map<String, dynamic>> getByFaculty(String facultyId) => [];

  static Map<String, int> getBalances(String facultyId) {
    return Map<String, int>.from(_defaultBalances);
  }

  static Future<Map<String, Map<String, double>>> fetchLeaveBalances({
    String facultyEmpId = 'EMP_CSE_002',
    String academicYear = '2025-26',
  }) async {
    try {
      final response = await SupabaseClientHelper.select(
        'leave_balances',
        schema: _schema,
        filterColumn: 'faculty_employee_id',
        filterValue: facultyEmpId,
      );

      if (response.isNotEmpty) {
        final row = response.firstWhere(
          (r) => (r['academic_year'] ?? '').toString() == academicYear,
          orElse: () => response.first,
        );

        double parseNum(dynamic val, double fallback) {
          if (val == null) return fallback;
          return (double.tryParse(val.toString()) ?? fallback);
        }

        final clTotal = parseNum(row['casual_leave_total'], 0.0);
        final clUsed = parseNum(row['casual_leave_used'], 0.0);

        final mlTotal = parseNum(row['medical_leave_total'], 0.0);
        final mlUsed = parseNum(row['medical_leave_used'], 0.0);

        final elTotal = parseNum(row['earned_leave_total'], 0.0);
        final elUsed = parseNum(row['earned_leave_used'], 0.0);

        final odTotal = parseNum(row['on_duty_total'], 0.0);
        final odUsed = parseNum(row['on_duty_used'], 0.0);

        final compTotal = parseNum(row['compensatory_leave_total'], 0.0);
        final compUsed = parseNum(row['compensatory_leave_used'], 0.0);

        final spTotal = parseNum(row['special_leave_total'], 0.0);
        final spUsed = parseNum(row['special_leave_used'], 0.0);

        return {
          'Casual Leave': {'total': clTotal, 'used': clUsed, 'remaining': (clTotal - clUsed).clamp(0.0, clTotal)},
          'Sick Leave': {'total': mlTotal, 'used': mlUsed, 'remaining': (mlTotal - mlUsed).clamp(0.0, mlTotal)},
          'Medical Leave': {'total': mlTotal, 'used': mlUsed, 'remaining': (mlTotal - mlUsed).clamp(0.0, mlTotal)},
          'Earned Leave': {'total': elTotal, 'used': elUsed, 'remaining': (elTotal - elUsed).clamp(0.0, elTotal)},
          'On Duty': {'total': odTotal, 'used': odUsed, 'remaining': (odTotal - odUsed).clamp(0.0, odTotal)},
          'Compensatory Leave': {'total': compTotal, 'used': compUsed, 'remaining': (compTotal - compUsed).clamp(0.0, compTotal)},
          'Special Leave': {'total': spTotal, 'used': spUsed, 'remaining': (spTotal - spUsed).clamp(0.0, spTotal)},
        };
      }
    } catch (_) {}

    return {
      'Casual Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
      'Sick Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
      'Medical Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
      'Earned Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
      'On Duty': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
      'Compensatory Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
      'Special Leave': {'total': 0.0, 'used': 0.0, 'remaining': 0.0},
    };
  }

  static String _formatIsoDate(dynamic input) {
    if (input == null) return DateTime.now().toIso8601String().split('T')[0];
    final str = input.toString().trim();
    if (str.isEmpty) return DateTime.now().toIso8601String().split('T')[0];

    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(str)) {
      return str;
    }

    try {
      final months = {'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12};
      final parts = str.split(RegExp(r'[\s\/\-\.]'));
      if (parts.length == 3) {
        int? day = int.tryParse(parts[0]);
        int? month;
        int? year = int.tryParse(parts[2]);

        if (day == null && parts[0].length == 4) {
          year = int.tryParse(parts[0]);
          month = int.tryParse(parts[1]);
          day = int.tryParse(parts[2]);
        } else {
          month = int.tryParse(parts[1]) ?? months[parts[1].toLowerCase()];
        }

        if (day != null && month != null && year != null) {
          return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        }
      }
    } catch (_) {}

    return DateTime.now().toIso8601String().split('T')[0];
  }

  static Future<Map<String, dynamic>> apply(Map<String, dynamic> leave) async {
    final rawSub = (leave['substituteFacultyId'] ?? leave['alternateFaculty'] ?? '').toString().trim();
    final subFaculty = (rawSub.isEmpty || rawSub.toLowerCase() == 'none' || rawSub.toLowerCase().startsWith('none ('))
        ? 'None'
        : rawSub;

    final facultyEmpId = leave['facultyId'] ?? leave['facultyEmployeeId'] ?? 'FAC002';
    final startDateStr = _formatIsoDate(leave['fromDate'] ?? leave['startDate']);
    final endDateStr = _formatIsoDate(leave['toDate'] ?? leave['endDate']);
    final substitutions = leave['substitutions'] ?? leave['substitutions_json'];

    final payload = <String, dynamic>{
      'faculty_employee_id': facultyEmpId,
      'leave_type': leave['type'] ?? 'Casual Leave',
      'start_date': startDateStr,
      'end_date': endDateStr,
      'status': leave['status'] ?? 'Pending',
      'total_days': (leave['days'] as num? ?? 1.0).toDouble(),
      'reason': (leave['reason'] != null && leave['reason'].toString().trim().isNotEmpty)
          ? leave['reason'].toString().trim()
          : 'Personal Leave',
      'priority': leave['priority'] ?? 'Normal',
      'session_type': leave['session'] ?? 'Full Day',
      'is_half_day': leave['isHalfDay'] ?? false,
      'total_calendar_days': (leave['totalCalendarDays'] as num? ?? 1).toInt(),
      'weekends_excluded': (leave['weekendDaysExcluded'] as num? ?? 0).toInt(),
      'holidays_excluded': (leave['holidaysExcluded'] as num? ?? 0).toInt(),
      'substitute_faculty_id': subFaculty,
      'academic_year': leave['academicYear'] ?? '2025-26',
      'hod_employee_id': leave['hodEmployeeId'] ?? defaultHodId,
      if (substitutions != null) 'substitutions_json': substitutions,
    };

    if (subFaculty != 'None') {
      payload['alternate_faculty_id'] = subFaculty;
    }

    if (leave['attachmentName'] != null && leave['attachmentName'].toString().isNotEmpty) {
      payload['attachment_name'] = leave['attachmentName'];
    }
    final docUrl = leave['attachmentUrl'] ?? leave['document_url'] ?? leave['documentUrl'];
    if (docUrl != null && docUrl.toString().isNotEmpty) {
      payload['attachment_url'] = docUrl;
      payload['document_url'] = docUrl;
    }

    final givenId = leave['id']?.toString() ?? leave['leaveId']?.toString() ?? '';
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (uuidRegex.hasMatch(givenId)) {
      payload['id'] = givenId;
    }

    Map<String, dynamic>? inserted;
    try {
      inserted = await SupabaseClientHelper.insert(_table, payload, schema: _schema);
    } catch (_) {}

    if (inserted == null) {
      final corePayload = <String, dynamic>{
        'faculty_employee_id': facultyEmpId,
        'leave_type': payload['leave_type'],
        'start_date': startDateStr,
        'end_date': endDateStr,
        'total_days': payload['total_days'],
        'reason': payload['reason'],
        'status': payload['status'],
        'academic_year': payload['academic_year'],
        'hod_employee_id': payload['hod_employee_id'],
        if (substitutions != null) 'substitutions_json': substitutions,
      };
      try {
        inserted = await SupabaseClientHelper.insert(_table, corePayload, schema: _schema);
      } catch (_) {}
    }

    if (inserted != null && inserted['id'] != null) {
      final leaveAppId = inserted['id'].toString();
      leave['id'] = leaveAppId;
      leave['leaveId'] = leaveAppId;

      // Insert individual substitution rows into faculty.leave_substitutions
      if (substitutions is List && substitutions.isNotEmpty) {
        for (final sub in substitutions) {
          try {
            final subMap = Map<String, dynamic>.from(sub as Map);
            final subPayload = <String, dynamic>{
              'leave_application_id': leaveAppId,
              'leave_date': _formatIsoDate(subMap['date'] ?? subMap['leaveDate']),
              'period_code': (subMap['period'] ?? subMap['periodCode'] ?? 'P1').toString(),
              'class_sec': (subMap['classSec'] ?? '').toString(),
              'subject_code': (subMap['subjectCode'] ?? subMap['code'] ?? '').toString(),
              'subject_name': (subMap['subject'] ?? subMap['subjectName'] ?? '').toString(),
              'substitute_faculty_id': (subMap['substituteFacultyId'] ?? '').toString(),
              'substitute_faculty_name': (subMap['substituteFaculty'] ?? subMap['substituteFacultyName'] ?? '').toString(),
              'original_faculty_id': facultyEmpId,
              'time_slot': (subMap['time'] ?? subMap['timeSlot'] ?? '').toString(),
              'room': (subMap['room'] ?? '').toString(),
              'status': 'Pending Acceptance',
            };
            await SupabaseClientHelper.insert('leave_substitutions', subPayload, schema: _schema);
          } catch (e) {
            // Silently continue if substitution insert catches error
          }
        }
      }
    } else {
      final fallbackId = 'LV_${DateTime.now().millisecondsSinceEpoch}';
      leave['id'] = fallbackId;
      leave['leaveId'] = fallbackId;
    }

    _inMemoryLeaves.insert(0, Map<String, dynamic>.from(leave));
    return leave;
  }
}