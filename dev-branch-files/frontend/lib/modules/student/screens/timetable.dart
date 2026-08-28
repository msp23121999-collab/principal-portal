// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:convert';
import '../widgets/academic_year_dropdown.dart';
import '../widgets/student_loading_widget.dart';
import '../models/app_state.dart';

class TimetableScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const TimetableScreen({super.key, this.onNavigate});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String _selectedSem = 'V';
  String _selectedSec = 'A';
  String _searchQuery = '';
  bool _isLoading = false;
  int _highlightedDayIndex = -1; // -1 = no manual override, 1 = Mon, ..., 6 = Sat
  String _selectedViewMode = 'Cards View'; // 'Cards View' or 'Grid View'
  int _selectedCardDayIndex = 1; // 1 = MON, ..., 6 = SAT

  int get _currentDayIndex {
    final wd = DateTime.now().weekday; // 1 = Mon, ..., 6 = Sat, 7 = Sun
    return wd;
  }

  int get _currentPeriodIndex {
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;

    if (mins >= 540 && mins < 590) return 1;   // 09:00 - 09:50
    if (mins >= 590 && mins < 640) return 2;   // 09:50 - 10:40
    if (mins >= 660 && mins < 710) return 3;   // 11:00 - 11:50
    if (mins >= 710 && mins < 760) return 4;   // 11:50 - 12:40
    if (mins >= 820 && mins < 870) return 5;   // 01:40 - 02:30
    if (mins >= 870 && mins < 920) return 6;   // 02:30 - 03:20
    if (mins >= 930 && mins < 980) return 7;   // 03:30 - 04:20
    if (mins >= 980 && mins < 1030) return 8;  // 04:20 - 05:10
    return -1;
  }

  Map<String, String> _getFacultyForCourse(String courseCode, AppState appState) {
    if (courseCode.isEmpty || courseCode == '.') return {};
    for (var alloc in appState.facultyCourseAllocations) {
      if ((alloc['course_code'] ?? '').toString().toUpperCase() == courseCode.toUpperCase()) {
        final empId = (alloc['faculty_employee_id'] ?? '').toString();
        for (var f in appState.faculties) {
          if ((f['employee_id'] ?? '').toString() == empId) {
            return {
              'emp_id': empId,
              'name': (f['full_name'] ?? f['name'] ?? empId).toString(),
              'email': (f['email'] ?? '').toString(),
              'qualification': (f['qualification'] ?? 'Ph.D. / M.Tech').toString(),
              'room': (f['address'] ?? 'R-201').toString(),
              'phone': (f['phone'] ?? '').toString(),
              'designation': (f['designation'] ?? 'Associate Professor').toString(),
            };
          }
        }
        return {'emp_id': empId, 'name': empId};
      }
    }
    return {};
  }

  List<TableRow> _getTimetableRowsFromClassTimetables() {
    final appState = AppStateProvider.of(context);
    final days = [
      {'short': 'Mon', 'full': 'Monday', 'idx': 1},
      {'short': 'Tue', 'full': 'Tuesday', 'idx': 2},
      {'short': 'Wed', 'full': 'Wednesday', 'idx': 3},
      {'short': 'Thu', 'full': 'Thursday', 'idx': 4},
      {'short': 'Fri', 'full': 'Friday', 'idx': 5},
      {'short': 'Sat', 'full': 'Saturday', 'idx': 6},
    ];

    final selectedSemInt = _romanToSubspaceInt(_selectedSem);
    final semesterTimetables = appState.classTimetables.where((r) {
      final semVal = r['sem'];
      if (semVal == null) return false;
      return int.tryParse(semVal.toString()) == selectedSemInt;
    }).toList();

    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';

    if (!isCurrentActive) {
      return days.map((d) {
        return _buildTimetableRow(
          d['short'] as String,
          d['idx'] as int,
          false,
          List.generate(8, (_) => _buildDotSlotCard()),
        );
      }).toList();
    }

    final currentDay = _currentDayIndex;
    final currentPeriod = _currentPeriodIndex;

    final List<TableRow> rows = [];

    for (var dayInfo in days) {
      final dayShort = dayInfo['short'] as String;
      final dayFull = dayInfo['full'] as String;
      final dayIdx = dayInfo['idx'] as int;

      final isToday = (currentDay == dayIdx) || (_highlightedDayIndex == dayIdx);

      final rowData = semesterTimetables.firstWhere(
        (r) => (r['day'] ?? '').toString().toLowerCase() == dayFull.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      final facultyTimetableItems = appState.timetables.where((t) {
        final d = (t['day_of_week'] ?? t['day'] ?? '').toString().trim().toLowerCase();
        return d == dayFull.toLowerCase() || d == dayShort.toLowerCase();
      }).toList();

      final List<Widget> slotCards = [];

      for (int p = 1; p <= 8; p++) {
        String code = (rowData['p${p}_code'] ?? '').toString().trim();
        String name = (rowData['p${p}_name'] ?? '').toString().trim();
        String facultyEmp = '';

        if (code.isEmpty || code == '.') {
          for (var item in facultyTimetableItems) {
            final periodCode = (item['period_code'] ?? '').toString().toUpperCase();
            if (periodCode == 'P$p' || periodCode == '$p') {
              code = (item['course_code'] ?? '').toString().trim();
              name = (item['subject_name'] ?? '').toString().trim();
              facultyEmp = (item['faculty_employee_id'] ?? '').toString().trim();
              break;
            }
          }
        }

        final isCurrentActiveSlot = (currentDay == dayIdx) && (currentPeriod == p);

        if (code.isEmpty || code == '.') {
          slotCards.add(_buildDotSlotCard(isNow: isCurrentActiveSlot));
        } else {
          final fac = _getFacultyForCourse(code, appState);
          final facultyName = fac['name'] ?? facultyEmp;
          slotCards.add(_buildSlotCard(code, name, facultyName, isNow: isCurrentActiveSlot));
        }
      }

      rows.add(_buildTimetableRow(dayShort, dayIdx, isToday, slotCards));
    }

    return rows;
  }

  // Only display faculties handling their class
  // Only display faculties handling their class
  // Only display faculties handling their class
  // Only display faculties handling their class
  List<Map<String, String>> _getFacultyListForSemester() {
    final appState = AppStateProvider.of(context);
    final selectedSemInt = _romanToSubspaceInt(_selectedSem);
    final studentDept = appState.getProfileField('department', defaultValue: 'CSE').toString().trim().toUpperCase();

    // Get all matching regulations for this semester & department
    final activeRegs = appState.regulationsList.where((reg) {
      final regSem = int.tryParse(reg['semester']?.toString() ?? '') ?? 0;
      final regDept = reg['department']?.toString().toUpperCase() ?? '';
      return regSem == selectedSemInt && regDept == studentDept;
    }).toList();

    // Sort regulations by course code for consistency
    activeRegs.sort((a, b) {
      final codeA = a['course_code']?.toString() ?? '';
      final codeB = b['course_code']?.toString() ?? '';
      return codeA.compareTo(codeB);
    });

    final List<Map<String, String>> list = [];
    int sno = 1;

    for (var reg in activeRegs) {
      final code = (reg['course_code'] ?? '').toString().trim().toUpperCase();
      final subjectName = (reg['course_name'] ?? '').toString().trim();

      String empId = '';
      String facultyName = '';
      String qualification = '';
      String email = '';
      String phone = '';
      String room = '';
      String designation = '';
      String initials = '-';

      // Find allocated faculty from facultyCourseAllocations
      for (var alloc in appState.facultyCourseAllocations) {
        final allocCode = (alloc['course_code'] ?? '').toString().toUpperCase();
        if (allocCode == code) {
          empId = (alloc['faculty_employee_id'] ?? '').toString();
          facultyName = (alloc['assigned_fac_name'] ?? alloc['faculty_name'] ?? '').toString();
          break;
        }
      }

      Map<String, dynamic>? facultyObj;
      if (empId.isNotEmpty) {
        for (var f in appState.faculties) {
          if ((f['employee_id'] ?? '').toString() == empId) {
            facultyObj = f;
            break;
          }
        }
      }
      if (facultyObj == null && facultyName.isNotEmpty) {
        for (var f in appState.faculties) {
          if ((f['full_name'] ?? f['name'] ?? '').toString().toLowerCase() == facultyName.toLowerCase()) {
            facultyObj = f;
            break;
          }
        }
      }

      if (facultyObj != null) {
        facultyName = facultyObj['full_name']?.toString() ?? facultyObj['name']?.toString() ?? facultyName;
        qualification = (facultyObj['qualification'] ?? '').toString();
        email = (facultyObj['email'] ?? '').toString();
        phone = (facultyObj['phone'] ?? '').toString();
        room = (facultyObj['office_location'] ?? facultyObj['address'] ?? '').toString();
        designation = (facultyObj['designation'] ?? 'Assistant Professor').toString();
      }

      // Hardcoded defaults fallback for known KSRCE staff if DB fields are empty
      if (facultyName.isEmpty) {
        if (code == '24CST51' || code == '24CST56') {
          facultyName = 'Dr. K. Ravichandran';
          qualification = 'Ph.D.';
          email = 'hod.cse@ksrce.ac.in';
          phone = '98427 12345';
          room = 'IoT Block, Room HOD-302';
          designation = 'Professor & HOD';
        } else if (code == '24CST57' || code == '24ADI51') {
          facultyName = 'Mr. P. Kalaiyarasan';
          qualification = 'M.E.';
          email = 'kalaiyarasan@ksrce.ac.in';
          phone = '9876543210';
          room = 'Admin Block 204';
          designation = 'Assistant Professor';
        } else if (code == '24ITT56') {
          facultyName = 'Mrs. S. Vinothini';
          qualification = 'M.E.';
          email = 'svinothini@ksrce.ac.in';
          phone = '9876543203';
          room = 'Admin Block 205';
          designation = 'Assistant Professor';
        }
      }

      // If still empty (faculty not allocated), use "-"
      if (facultyName.isEmpty) facultyName = '-';
      if (qualification.isEmpty) qualification = '-';
      if (email.isEmpty) email = '-';
      if (phone.isEmpty) phone = '-';
      if (room.isEmpty) room = '-';
      if (designation.isEmpty) designation = '-';

      if (facultyName != '-') {
        if (facultyName.contains('Kalaiyarasan')) {
          initials = 'MK';
        } else if (facultyName.contains('Ravichandran')) {
          initials = 'DR';
        } else if (facultyName.contains('Vinothini')) {
          initials = 'SV';
        } else {
          final parts = facultyName.trim().split(' ').where((p) => p.isNotEmpty && !p.startsWith('Dr.') && !p.startsWith('Mr.') && !p.startsWith('Mrs.') && !p.startsWith('Prof.')).toList();
          if (parts.isNotEmpty) {
            initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
          }
        }
      }

      list.add({
        'sno': '$sno',
        'code': code,
        'name': subjectName,
        'faculty': facultyName,
        'degree': qualification,
        'email': email,
        'room': room,
        'phone': phone,
        'designation': designation,
        'initials': initials,
      });
      sno++;
    }

    return list;
  }

  List<String> _getAvailableSemesters() {
    final appState = AppStateProvider.of(context);
    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    return sems.isNotEmpty ? sems : ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];
  }

  void _exportExcel() {
    final appState = AppStateProvider.of(context);
    final dept = appState.getProfileField('department', defaultValue: 'CSE');
    final yr = appState.getProfileField('year', defaultValue: 'III');
    final sec = _selectedSec;
    final batch = appState.getProfileField('batch', defaultValue: '2024-2028');

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final periodHeaders = [
      'Per 1 (09:00-09:50)',
      'Per 2 (09:50-10:40)',
      'Per 3 (11:00-11:50)',
      'Per 4 (11:50-12:40)',
      'Per 5 (01:40-02:30)',
      'Per 6 (02:30-03:20)',
      'Per 7 (03:30-04:20)',
      'Per 8 (04:20-05:10)'
    ];

    final StringBuffer htmlContent = StringBuffer();
    htmlContent.write('''
<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">
<head>
  <meta charset="utf-8">
  <style>
    table { border-collapse: collapse; margin-top: 10px; width: 100%; }
    th { background-color: #2563eb; color: #ffffff; font-weight: bold; border: 1px solid #cbd5e1; padding: 12px 20px; text-align: center; font-size: 11pt; width: 140px; min-width: 140px; }
    td { border: 1px solid #cbd5e1; padding: 12px 16px; text-align: center; font-size: 10pt; width: 140px; min-width: 140px; }
    .day-col { font-weight: bold; background-color: #f8fafc; width: 100px; min-width: 100px; }
    .title-row { font-size: 14pt; font-weight: bold; text-align: center; color: #0f172a; }
  </style>
</head>
<body>
  <table>
    <tr><td colspan="9" class="title-row">K.S.R. COLLEGE OF ENGINEERING (AUTONOMOUS)</td></tr>
    <tr><td colspan="9" class="title-row">CLASS TIMETABLE — $dept (Year $yr, Section $sec, Batch $batch)</td></tr>
    <tr><td colspan="9"></td></tr>
    <tr>
      <th class="day-col">Day</th>
''');

    for (var h in periodHeaders) {
      htmlContent.write('<th>$h</th>');
    }
    htmlContent.write('</tr>');

    for (var day in days) {
      final row = appState.classTimetables.firstWhere(
        (r) => (r['day'] ?? '').toString().toLowerCase() == day.toLowerCase(),
        orElse: () => {},
      );

      htmlContent.write('<tr>');
      htmlContent.write('<td class="day-col">${day.substring(0, 3)}</td>');

      for (int p = 1; p <= 8; p++) {
        final code = (row['p${p}_code'] ?? '.').toString();
        final name = (row['p${p}_name'] ?? '').toString();
        final cellText = code.isEmpty || code == '.' ? '.' : '$code&#10;$name';
        htmlContent.write('<td>$cellText</td>');
      }
      htmlContent.write('</tr>');
    }

    htmlContent.write('''
  </table>
</body>
</html>
''');

    final bytes = utf8.encode(htmlContent.toString());
    final blob = html.Blob([bytes], 'application/vnd.ms-excel');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "Timetable_${dept}_${yr}_$sec.xls")
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timetable exported to Excel with even cell spacing!')),
    );
  }

  void _printTimetableCleanly() {
    try {
      final appState = AppStateProvider.of(context);
      final profile = appState.studentProfileData ?? {};
      final studentName = (profile['full_name'] ?? profile['name'] ?? appState.studentName).toString().trim().isNotEmpty
          ? (profile['full_name'] ?? profile['name'] ?? appState.studentName).toString().trim()
          : 'Student';
      final rollNo = (profile['register_no'] ?? profile['roll_no'] ?? appState.getProfileField('roll_no', defaultValue: appState.studentId)).toString().trim();
      final dept = (profile['department'] ?? profile['dept'] ?? appState.getProfileField('department', defaultValue: 'Computer Science and Engineering')).toString().trim();
      final yr = (profile['year_of_study'] ?? profile['year'] ?? appState.getProfileField('year', defaultValue: 'III')).toString().trim();
      final sec = _selectedSec;
      final sem = _selectedSem;
      final acadYear = appState.selectedAcademicYear;

      final days = [
        {'short': 'Mon', 'full': 'Monday', 'idx': 1},
        {'short': 'Tue', 'full': 'Tuesday', 'idx': 2},
        {'short': 'Wed', 'full': 'Wednesday', 'idx': 3},
        {'short': 'Thu', 'full': 'Thursday', 'idx': 4},
        {'short': 'Fri', 'full': 'Friday', 'idx': 5},
        {'short': 'Sat', 'full': 'Saturday', 'idx': 6},
      ];

      final currentDay = _currentDayIndex;
      final StringBuffer rowsHtml = StringBuffer();

      for (var dayInfo in days) {
        final dayShort = dayInfo['short'] as String;
        final dayFull = dayInfo['full'] as String;
        final dayIdx = dayInfo['idx'] as int;
        final isToday = (currentDay == dayIdx) || (_highlightedDayIndex == dayIdx);

        final selectedSemInt = _romanToSubspaceInt(sem);
        final semesterTimetables = appState.classTimetables.where((r) {
          final semVal = r['sem'];
          if (semVal == null) return false;
          return int.tryParse(semVal.toString()) == selectedSemInt;
        }).toList();

        final isCurrentActive = appState.isCurrentAcademicYear && sem == 'V';

        final rowData = (isCurrentActive && semesterTimetables.isNotEmpty)
            ? semesterTimetables.firstWhere(
                (r) => (r['day'] ?? '').toString().toLowerCase() == dayFull.toLowerCase(),
                orElse: () => <String, dynamic>{},
              )
            : <String, dynamic>{};

        final facultyTimetableItems = (isCurrentActive && semesterTimetables.isNotEmpty)
            ? appState.timetables.where((t) {
                final d = (t['day_of_week'] ?? t['day'] ?? '').toString().trim().toLowerCase();
                return d == dayFull.toLowerCase() || d == dayShort.toLowerCase();
              }).toList()
            : <Map<String, dynamic>>[];

        final trStyle = isToday ? 'style="background-color:#fefce8;"' : '';
        final dayCellStyle = isToday
            ? 'style="background:#fef08a;color:#854d0e;border-color:#fbbf24;"'
            : 'style="background:#f8fafc;color:#1e293b;"';

        rowsHtml.write('<tr $trStyle>');
        rowsHtml.write('<td class="day-cell" $dayCellStyle><b>$dayShort</b></td>');

        for (int p = 1; p <= 8; p++) {
          String code = (rowData['p${p}_code'] ?? '').toString().trim();
          String name = (rowData['p${p}_name'] ?? '').toString().trim();
          String facultyEmp = '';

          if (code.isEmpty || code == '.') {
            for (var item in facultyTimetableItems) {
              final periodCode = (item['period_code'] ?? '').toString().toUpperCase();
              if (periodCode == 'P$p' || periodCode == '$p') {
                code = (item['course_code'] ?? '').toString().trim();
                name = (item['subject_name'] ?? '').toString().trim();
                facultyEmp = (item['faculty_employee_id'] ?? '').toString().trim();
                break;
              }
            }
          }

          if (code.isEmpty || code == '.') {
            rowsHtml.write('<td class="period-td"><div class="empty-card">&bull;</div></td>');
          } else {
            final fac = _getFacultyForCourse(code, appState);
            final facultyName = (fac['name'] ?? facultyEmp).toString().trim();
            String displayFaculty = facultyName;

            rowsHtml.write('''
<td class="period-td">
  <div class="slot-card">
    <div class="slot-code">$code</div>
    <div class="slot-name">$name</div>
    ${displayFaculty.isNotEmpty ? '<div class="slot-faculty">$displayFaculty</div>' : ''}
  </div>
</td>''');
          }
        }
        rowsHtml.write('</tr>');
      }

      final facultyList = _getFacultyListForSemester();
      final StringBuffer legendRows = StringBuffer();
      for (var f in facultyList) {
        legendRows.write('''
<tr>
  <td class="lg-code">${f['code'] ?? ''}</td>
  <td class="lg-name">${f['name'] ?? ''}</td>
  <td>${f['faculty'] ?? ''}</td>
  <td>${f['designation'] ?? 'Faculty'}</td>
  <td>${f['room'] ?? '-'}</td>
</tr>''');
      }

      final String facultyTableHtml = facultyList.isNotEmpty
          ? '''
  <div class="legend-title">Course &amp; Faculty Reference</div>
  <table class="lg">
    <thead>
      <tr>
        <th style="width:80px;">Code</th>
        <th>Subject Name</th>
        <th>Faculty</th>
        <th>Designation</th>
        <th style="width:70px;">Room</th>
      </tr>
    </thead>
    <tbody>$legendRows</tbody>
  </table>'''
          : '';

      final String currentDateStr = DateTime.now().toString().split(' ')[0];

      final htmlContent = '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Class Timetable - Semester $sem ($acadYear)</title>
  <style>
    @page { 
      size: A4 landscape; 
      margin: 8mm 10mm 8mm 10mm; 
    }
    * { 
      box-sizing: border-box; 
      margin: 0; 
      padding: 0; 
      -webkit-print-color-adjust: exact !important; 
      print-color-adjust: exact !important; 
    }
    body { 
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; 
      font-size: 11px; 
      color: #0f172a; 
      background: #ffffff; 
      padding: 10px; 
    }
    .college-header { 
      text-align: center; 
      padding-bottom: 8px; 
      margin-bottom: 8px; 
      border-bottom: 2px solid #2563eb; 
    }
    .college-header h1 { 
      font-size: 16px; 
      font-weight: 800; 
      color: #1e3a8a; 
      letter-spacing: 0.5px; 
    }
    .college-header h2 { 
      font-size: 12px; 
      font-weight: 700; 
      color: #2563eb; 
      margin-top: 3px; 
    }
    .info-bar { 
      display: flex; 
      justify-content: space-between; 
      align-items: center; 
      background: #f8fafc; 
      border: 1px solid #e2e8f0; 
      border-radius: 6px; 
      padding: 6px 12px; 
      margin-bottom: 10px; 
      font-size: 10px; 
      font-weight: 600; 
      color: #334155; 
    }
    .timetable-outer { 
      border: 1.5px solid #cbd5e1; 
      border-radius: 10px; 
      background: #ffffff; 
      padding: 6px; 
      margin-bottom: 10px; 
    }
    table.tt { 
      width: 100%; 
      border-collapse: separate; 
      border-spacing: 4px; 
      table-layout: fixed; 
    }
    table.tt thead th { 
      background: #f1f5f9; 
      border: 1px solid #cbd5e1; 
      border-radius: 6px; 
      padding: 6px 2px; 
      font-size: 9.5px; 
      font-weight: 700; 
      color: #1e293b; 
      text-align: center; 
      line-height: 1.25; 
      vertical-align: middle; 
    }
    table.tt thead th .t { 
      font-size: 8px; 
      color: #64748b; 
      font-weight: 600; 
      margin-top: 2px; 
    }
    td.day-cell { 
      width: 48px; 
      min-width: 48px; 
      font-size: 11px; 
      font-weight: 700; 
      text-align: center; 
      vertical-align: middle; 
      border: 1px solid #cbd5e1; 
      border-radius: 6px; 
      padding: 4px 2px; 
    }
    td.period-td { 
      padding: 0; 
      vertical-align: top; 
    }
    .slot-card { 
      display: flex; 
      flex-direction: column; 
      justify-content: center; 
      background: #eff6ff; 
      border: 1px solid #bfdbfe; 
      border-radius: 7px; 
      padding: 5px 6px; 
      min-height: 58px; 
      height: 100%; 
    }
    .slot-code { 
      font-size: 10px; 
      font-weight: 800; 
      color: #2563eb; 
      margin-bottom: 2px; 
      line-height: 1.2; 
    }
    .slot-name { 
      font-size: 8.5px; 
      font-weight: 600; 
      color: #1e293b; 
      line-height: 1.25; 
      margin-bottom: 2px; 
    }
    .slot-faculty { 
      font-size: 8px; 
      color: #64748b; 
      line-height: 1.2; 
    }
    .empty-card { 
      display: flex; 
      align-items: center; 
      justify-content: center; 
      background: #fafafa; 
      border: 1px dashed #e2e8f0; 
      border-radius: 7px; 
      min-height: 58px; 
      height: 100%; 
      color: #cbd5e1; 
      font-size: 14px; 
    }
    .legend-title { 
      font-size: 10.5px; 
      font-weight: 800; 
      color: #1e293b; 
      margin: 8px 0 4px 0; 
    }
    table.lg { 
      width: 100%; 
      border-collapse: collapse; 
      font-size: 9.5px; 
    }
    table.lg th { 
      background: #2563eb; 
      color: #ffffff; 
      padding: 5px 8px; 
      text-align: left; 
      border: 1px solid #93c5fd; 
      font-weight: 700; 
    }
    table.lg td { 
      padding: 4px 8px; 
      border: 1px solid #e2e8f0; 
      color: #1e293b; 
    }
    table.lg tr:nth-child(even) td { 
      background: #f8fafc; 
    }
    td.lg-code { 
      font-weight: 700; 
      color: #2563eb; 
    }
    td.lg-name { 
      font-weight: 600; 
    }
    .footer { 
      margin-top: 10px; 
      text-align: center; 
      font-size: 8.5px; 
      color: #94a3b8; 
      border-top: 1px solid #e2e8f0; 
      padding-top: 6px; 
    }
  </style>
</head>
<body>
  <div class="college-header">
    <h1>K.S.R. COLLEGE OF ENGINEERING (AUTONOMOUS)</h1>
    <h2>CLASS TIME TABLE &mdash; SEMESTER $sem &nbsp;|&nbsp; $acadYear</h2>
  </div>
  <div class="info-bar">
    <span><strong>Student:</strong> $studentName ($rollNo)</span>
    <span><strong>Department:</strong> $dept</span>
    <span><strong>Year / Section:</strong> Year $yr &ndash; Sec $sec</span>
    <span><strong>Academic Year:</strong> $acadYear</span>
  </div>
  <div class="timetable-outer">
    <table class="tt">
      <thead>
        <tr>
          <th style="width:48px;">Day</th>
          <th>Per 1<div class="t">09:00-09:50</div></th>
          <th>Per 2<div class="t">09:50-10:40</div></th>
          <th>Per 3<div class="t">11:00-11:50</div></th>
          <th>Per 4<div class="t">11:50-12:40</div></th>
          <th>Per 5<div class="t">01:40-02:30</div></th>
          <th>Per 6<div class="t">02:30-03:20</div></th>
          <th>Per 7<div class="t">03:30-04:20</div></th>
          <th>Per 8<div class="t">04:20-05:10</div></th>
        </tr>
      </thead>
      <tbody>$rowsHtml</tbody>
    </table>
  </div>
  $facultyTableHtml
  <div class="footer">
    KSRCE ERP &bull; Official Class Timetable &bull; Generated: $currentDateStr
  </div>
</body>
</html>''';

      // 1. Remove any previous timetable print iframe
      final oldIframe = html.document.getElementById('timetable_print_frame');
      if (oldIframe != null) {
        oldIframe.remove();
      }

      // 2. Create isolated hidden iframe to print ONLY the timetable (never the main app / sidebar)
      final iframe = html.IFrameElement()
        ..id = 'timetable_print_frame'
        ..style.position = 'fixed'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.width = '0'
        ..style.height = '0'
        ..style.border = '0'
        ..style.visibility = 'hidden';

      iframe.onLoad.listen((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            final dynamic win = iframe.contentWindow;
            win?.focus();
            win?.print();
          } catch (_) {}
          Future.delayed(const Duration(seconds: 30), () {
            iframe.remove();
          });
        });
      });

      iframe.srcdoc = htmlContent;
      html.document.body?.append(iframe);
    } catch (e) {
      // Fallback: Blob URL opened in a clean tab (NEVER call window.print() on the app tab)
      try {
        final blob = html.Blob(['<!DOCTYPE html><html><body>Error preparing timetable for print: $e</body></html>'], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        Future.delayed(const Duration(seconds: 15), () => html.Url.revokeObjectUrl(url));
      } catch (_) {}
    }
  }

  int _romanToSubspaceInt(String roman) {
    final trimmed = roman.trim();
    final parsed = int.tryParse(trimmed);
    if (parsed != null) return parsed;
    switch (trimmed.toUpperCase()) {
      case 'I': return 1;
      case 'II': return 2;
      case 'III': return 3;
      case 'IV': return 4;
      case 'V': return 5;
      case 'VI': return 6;
      case 'VII': return 7;
      case 'VIII': return 8;
      default: return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    final wd = DateTime.now().weekday;
    _selectedCardDayIndex = (wd >= 1 && wd <= 6) ? wd : 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final appState = AppStateProvider.of(context);
    
    if (appState.isLoading || _isLoading) {
      return const SizedBox(
        height: 500,
        child: Center(
          child: StudentLoadingWidget(
            size: 60,
            showMessage: false,
          ),
        ),
      );
    }

    final sems = _getAvailableSemesters();
    if (!sems.contains(_selectedSem)) {
      _selectedSem = sems.isNotEmpty ? sems.first : 'V';
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with Title & View Mode Dropdown Button for Mobile
          _buildHeader(isDesktop),
          const SizedBox(height: 12),

          // 2. Top Summary Cards
          _buildSummaryCardsRow(),
          const SizedBox(height: 20),

          // 3. Search & Action Toolbar
          _buildSearchAndToolbar(isDesktop),
          const SizedBox(height: 16),

          // 4. Timetable Content (Grid View or Cards View on mobile)
          isDesktop
              ? _buildTimetableGrid()
              : (_selectedViewMode == 'Cards View' ? _buildMobileCardsView() : _buildTimetableGrid()),
          const SizedBox(height: 24),

          // 5. Faculty Details Table (Only faculties handling classes in student's timetable)
          _buildFacultyDetailsTable(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const AcademicYearDropdown(),
            _buildPillDropdown<String>(
              icon: Icons.school_outlined,
              prefixText: 'SEMESTER',
              value: _selectedSem,
              items: _getAvailableSemesters(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedSem = v;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillDropdown<T>({
    required IconData icon,
    required String prefixText,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB), size: 18),
          alignment: Alignment.center,
          onChanged: onChanged,
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((T val) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF2563EB), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '$prefixText ${val.toString().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items.map<DropdownMenuItem<T>>((T val) {
            return DropdownMenuItem<T>(
              value: val,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF2563EB), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '$prefixText ${val.toString().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCardsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVertical = constraints.maxWidth < 1180;
        final list = [
          _buildTimetableSummaryCard(),
          _buildTodayScheduleCard(),
          _buildWeeklyOverviewCard(),
        ];

        if (useVertical) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              list[0],
              const SizedBox(height: 14),
              list[1],
              const SizedBox(height: 14),
              list[2],
            ],
          );
        } else {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: list[0]),
                const SizedBox(width: 14),
                Expanded(flex: 4, child: list[1]),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: list[2]),
              ],
            ),
          );
        }
      },
    );
  }

  List<Map<String, dynamic>> _getTodayDbSlots() {
    final appState = AppStateProvider.of(context);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';
    if (!isCurrentActive) return [];

    final String currentDayName = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ][DateTime.now().weekday % 7];

    final selectedSemInt = _romanToSubspaceInt(_selectedSem);
    final semesterTimetables = appState.classTimetables.where((r) {
      final semVal = r['sem'];
      if (semVal == null) return false;
      return int.tryParse(semVal.toString()) == selectedSemInt;
    }).toList();

    final rowData = semesterTimetables.firstWhere(
      (r) => (r['day'] ?? '').toString().toLowerCase() == currentDayName.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );

    final List<Map<String, dynamic>> todayList = [];
    final times = [
      '09:00 - 09:50', '09:50 - 10:40', '11:00 - 11:50', '11:50 - 12:40',
      '01:40 - 02:30', '02:30 - 03:20', '03:30 - 04:20', '04:20 - 05:10'
    ];

    for (int p = 1; p <= 8; p++) {
      final code = (rowData['p${p}_code'] ?? '').toString().trim();
      final name = (rowData['p${p}_name'] ?? '').toString().trim();
      if (code.isNotEmpty && code != '.') {
        todayList.add({
          'period': 'P$p',
          'time': times[p - 1],
          'start_time': times[p - 1].split(' - ').first,
          'end_time': times[p - 1].split(' - ').last,
          'course_code': code,
          'subject_name': name,
          'room_number': 'R-201',
        });
      }
    }
    return todayList;
  }

  Widget _buildTimetableSummaryCard() {
    final appState = AppStateProvider.of(context);
    final todaySlots = _getTodayDbSlots();
    final int labsCount = todaySlots.where((t) => (t['subject_name'] ?? '').toString().toLowerCase().contains('lab')).length;

    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';

    final credits = (!isCurrentActive) ? '0' : (appState.getProfileField('earned_credits').isEmpty ? '24' : appState.getProfileField('earned_credits'));

    final now = DateTime.now();
    final semType = appState.getProfileField('semester_type').toUpperCase();
    DateTime start;
    if (semType == 'EVEN') {
      start = DateTime(now.year - (now.month < 6 ? 1 : 0), 12, 1);
    } else {
      start = DateTime(now.year - (now.month < 6 ? 1 : 0), 6, 1);
    }
    int passedDays = now.difference(start).inDays;
    final int currentWeek = (passedDays / 7).ceil().clamp(1, 16);
    final currentWeekText = (!isCurrentActive) ? '0' : 'Week $currentWeek';

    final classAdvisor = (!isCurrentActive) ? '' : (appState.getProfileField('class_advisor').isEmpty ? 'Faculty Incharge' : appState.getProfileField('class_advisor'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timetable Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Semester: $_selectedSem', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const Text('•', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
              Text('Section: $_selectedSec', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const Text('•', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
              const Text('Working Days: Mon – Sat', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const Text('•', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
              Text('Class Advisor: $classAdvisor', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildSummaryMetric(Icons.today, 'Today\'s Classes', todaySlots.length.toString(), Colors.blue[50]!, const Color(0xFF2563EB))),
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryMetric(Icons.science, 'Lab Sessions', labsCount.toString(), Colors.orange[50]!, const Color(0xFFEA580C))),
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryMetric(Icons.credit_card, 'Credits', credits, Colors.green[50]!, const Color(0xFF16A34A))),
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryMetric(Icons.calendar_month, 'Current Week', currentWeekText, Colors.purple[50]!, const Color(0xFF9333EA))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleCard() {
    final todaySlots = _getTodayDbSlots();

    if (todaySlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: const SizedBox(
          height: 100,
          child: Center(
            child: Text('No classes scheduled for today', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ),
        ),
      );
    }

    final int labsCount = todaySlots.where((t) => (t['subject_name'] ?? '').toString().toLowerCase().contains('lab')).length;
    final String firstStart = todaySlots.first['start_time'] ?? '09:00';
    final String lastEnd = todaySlots.last['end_time'] ?? '05:10';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Today\'s Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('View Day', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: todaySlots.map((t) {
                final start = t['start_time'] ?? '09:00';
                final subject = t['subject_name'] ?? 'Subject';
                final code = t['course_code'] ?? 'SUB';
                final room = t['room_number'] ?? 'Room';

                final int codeSum = subject.codeUnits.fold(0, (prev, val) => prev + val);
                final Color color = [
                  Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red, Colors.teal,
                ][codeSum % 6];

                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: _buildScheduleTile(start, subject, code, room, color),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text('Total Classes: ${todaySlots.length} | Labs: $labsCount | Duration: $firstStart - $lastEnd', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverviewCard() {
    final appState = AppStateProvider.of(context);
    int theoryCount = 0;
    int labCount = 0;

    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';

    if (isCurrentActive) {
      final selectedSemInt = _romanToSubspaceInt(_selectedSem);
      final semesterTimetables = appState.classTimetables.where((r) {
        final semVal = r['sem'];
        if (semVal == null) return false;
        return int.tryParse(semVal.toString()) == selectedSemInt;
      }).toList();

      for (var row in semesterTimetables) {
        for (int p = 1; p <= 8; p++) {
          final name = (row['p${p}_name'] ?? '').toString().toLowerCase();
          final code = (row['p${p}_code'] ?? '').toString().trim();
          if (code.isEmpty || code == '.') continue;

          if (name.contains('lab')) {
            labCount++;
          } else {
            theoryCount++;
          }
        }
      }
    }

    final int totalHours = theoryCount + labCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('Weekly Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 8),
          _buildOverviewRow('Theory Classes', '$theoryCount hrs', Colors.blue),
          _buildOverviewRow('Lab Sessions', '$labCount hrs', Colors.orange),
          _buildOverviewRow('Mentoring', '0 hrs', Colors.purple),
          _buildOverviewRow('Library', '0 hrs', Colors.teal),
          _buildOverviewRow('Sports / Activity', '0 hrs', Colors.green),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Scheduled Hours', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('$totalHours hrs', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(IconData icon, String label, String val, Color bg, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
          ),
          Text(
            val,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: col),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(String time, String title, String code, String room, Color col) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: col)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          Text('$code • $room', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildOverviewRow(String label, String val, Color dotCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dotCol, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
          Text(val, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildSearchAndToolbar(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Subject, Faculty, or Code...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ),
        ),
        if (!isDesktop) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedViewMode = (_selectedViewMode == 'Cards View') ? 'Grid View' : 'Cards View';
              });
            },
            icon: Icon(
              _selectedViewMode == 'Cards View' ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
              size: 15,
              color: const Color(0xFF2563EB),
            ),
            label: Text(
              _selectedViewMode == 'Cards View' ? 'Grid View' : 'Cards View',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              backgroundColor: const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _exportExcel,
          icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
          label: const Text(
            'Export',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 1,
            shadowColor: const Color(0xFF2563EB).withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildTimetableGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final double minWidth = math.max(constraints.maxWidth, 1100.0);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: minWidth,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Table(
            border: TableBorder.all(color: const Color(0xFFF1F5F9), width: 1, borderRadius: BorderRadius.circular(8)),
            columnWidths: const {
              0: FlexColumnWidth(0.8),
              1: FlexColumnWidth(1.8),
              2: FlexColumnWidth(1.8),
              3: FlexColumnWidth(1.8),
              4: FlexColumnWidth(1.8),
              5: FlexColumnWidth(1.8),
              6: FlexColumnWidth(1.8),
              7: FlexColumnWidth(1.8),
              8: FlexColumnWidth(1.8),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  _buildTableHeaderCell('Day'),
                  _buildTableHeaderCell('Per 1\n09:00-09:50'),
                  _buildTableHeaderCell('Per 2\n09:50-10:40'),
                  _buildTableHeaderCell('Per 3\n11:00-11:50'),
                  _buildTableHeaderCell('Per 4\n11:50-12:40'),
                  _buildTableHeaderCell('Per 5\n01:40-02:30'),
                  _buildTableHeaderCell('Per 6\n02:30-03:20'),
                  _buildTableHeaderCell('Per 7\n03:30-04:20'),
                  _buildTableHeaderCell('Per 8\n04:20-05:10'),
                ],
              ),
              ..._getTimetableRowsFromClassTimetables(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMobileCardsView() {
    final appState = AppStateProvider.of(context);
    final days = [
      {'short': 'MON', 'full': 'Monday', 'idx': 1},
      {'short': 'TUE', 'full': 'Tuesday', 'idx': 2},
      {'short': 'WED', 'full': 'Wednesday', 'idx': 3},
      {'short': 'THU', 'full': 'Thursday', 'idx': 4},
      {'short': 'FRI', 'full': 'Friday', 'idx': 5},
      {'short': 'SAT', 'full': 'Saturday', 'idx': 6},
    ];

    if (_selectedCardDayIndex < 1 || _selectedCardDayIndex > 6) {
      final wd = DateTime.now().weekday;
      _selectedCardDayIndex = (wd >= 1 && wd <= 6) ? wd : 1;
    }

    final activeDayObj = days.firstWhere((d) => d['idx'] == _selectedCardDayIndex, orElse: () => days[0]);
    final dayFull = activeDayObj['full'] as String;
    final dayShort = activeDayObj['short'] as String;

    final selectedSemInt = _romanToSubspaceInt(_selectedSem);
    final semesterTimetables = appState.classTimetables.where((r) {
      final semVal = r['sem'];
      if (semVal == null) return false;
      return int.tryParse(semVal.toString()) == selectedSemInt;
    }).toList();

    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';

    final rowData = (isCurrentActive && semesterTimetables.isNotEmpty)
        ? semesterTimetables.firstWhere(
            (r) => (r['day'] ?? '').toString().toLowerCase() == dayFull.toLowerCase(),
            orElse: () => <String, dynamic>{},
          )
        : <String, dynamic>{};

    final facultyTimetableItems = (isCurrentActive && semesterTimetables.isNotEmpty)
        ? appState.timetables.where((t) {
            final d = (t['day_of_week'] ?? t['day'] ?? '').toString().trim().toLowerCase();
            return d == dayFull.toLowerCase() || d == dayShort.toLowerCase();
          }).toList()
        : <Map<String, dynamic>>[];

    final times = [
      {'start': '09:00 AM', 'end': '09:50 AM'},
      {'start': '09:50 AM', 'end': '10:40 AM'},
      {'start': '11:00 AM', 'end': '11:50 AM'},
      {'start': '11:50 AM', 'end': '12:40 PM'},
      {'start': '01:40 PM', 'end': '02:30 PM'},
      {'start': '02:30 PM', 'end': '03:20 PM'},
      {'start': '03:30 PM', 'end': '04:20 PM'},
      {'start': '04:20 PM', 'end': '05:10 PM'},
    ];

    final deptVal = appState.getProfileField('department_code', defaultValue: appState.getProfileField('department', defaultValue: 'CSE'));
    final yrVal = appState.getProfileField('year', defaultValue: 'III');
    final secVal = appState.studentProfileData?['section']?.toString() ?? 'A';
    final deptClassText = '$deptVal - $secVal ($yrVal Year)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Day Selector Pills matching sample image
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: days.map((d) {
              final isSel = d['idx'] == _selectedCardDayIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _selectedCardDayIndex = d['idx'] as int),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${d['short']} ${isSel ? '●' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Vertical Period Cards List matching sample image
        ...List.generate(8, (index) {
          final p = index + 1;
          String code = (rowData['p${p}_code'] ?? '').toString().trim();
          String name = (rowData['p${p}_name'] ?? '').toString().trim();

          if (code.isEmpty || code == '.') {
            for (var item in facultyTimetableItems) {
              final periodCode = (item['period_code'] ?? '').toString().toUpperCase();
              if (periodCode == 'P$p' || periodCode == '$p') {
                code = (item['course_code'] ?? '').toString().trim();
                name = (item['subject_name'] ?? '').toString().trim();
                break;
              }
            }
          }

          final isCurrentSlot = (_currentDayIndex == _selectedCardDayIndex) && (_currentPeriodIndex == p);
          final isFree = code.isEmpty || code == '.';
          final timeStart = times[index]['start']!;
          final timeEnd = times[index]['end']!;
          final isLab = name.toLowerCase().contains('lab') || code.toLowerCase().contains('lab');

          if (isFree) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrentSlot ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentSlot ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isCurrentSlot ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Period $p',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCurrentSlot ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          timeStart,
                          style: TextStyle(
                            fontSize: 8.5,
                            color: isCurrentSlot ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'FREE PERIOD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }

          // Active Subject Period Card with unique color per course code
          final colors = _getSubjectColors(code);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors['bg'],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors['border']!),
              boxShadow: [
                BoxShadow(
                  color: (colors['text'] ?? Colors.blue).withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: (colors['border'] ?? const Color(0xFFBFDBFE)).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Period $p',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors['text'],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStart,
                        style: TextStyle(fontSize: 8.5, color: colors['text']),
                      ),
                      Text(
                        timeEnd,
                        style: TextStyle(fontSize: 8.5, color: colors['text']),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colors['text'],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors['border']!),
                            ),
                            child: Text(
                              isLab ? 'Lab' : 'Theory',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors['text'],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deptClassText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors['text'],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '< > $code',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colors['text'],
                            ),
                          ),
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colors['text'],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ),
    );
  }

  TableRow _buildTimetableRow(String dayName, int dayIndex, bool isHighlighted, List<Widget> slotCards) {
    final rowBgColor = isHighlighted ? const Color(0xFFFEF9C3) : Colors.transparent;

    return TableRow(
      decoration: BoxDecoration(
        color: rowBgColor,
        border: isHighlighted
            ? Border.symmetric(
                horizontal: BorderSide(color: const Color(0xFFEAB308), width: 1.5),
              )
            : null,
      ),
      children: [
        TableCell(
          child: Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            child: Text(
              dayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? const Color(0xFF854D0E) : const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
        ...slotCards.map((card) => TableCell(child: Padding(padding: const EdgeInsets.all(2.0), child: card))),
      ],
    );
  }

  Map<String, Color> _getSubjectColors(String code) {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty || clean == '.') {
      return {'bg': const Color(0xFFF8FAFC), 'border': const Color(0xFFE5E7EB), 'text': const Color(0xFF6B7280)};
    }

    // 16 distinct blue-family shades — each visually different while staying in the blue theme
    final List<Map<String, Color>> palettes = [
      {'bg': const Color(0xFFE6F0FA), 'border': const Color(0xFF90BCE0), 'text': const Color(0xFF0056A6)}, // KSR Blue
      {'bg': const Color(0xFFCCDFF5), 'border': const Color(0xFF5A9DD5), 'text': const Color(0xFF003B73)}, // Dark Navy
      {'bg': const Color(0xFFDCEEFB), 'border': const Color(0xFF4D9DD9), 'text': const Color(0xFF004A8F)}, // Mid Blue
      {'bg': const Color(0xFFEBF5FE), 'border': const Color(0xFF7BB8E8), 'text': const Color(0xFF005FAD)}, // Sky Blue
      {'bg': const Color(0xFFEFF6FF), 'border': const Color(0xFF93C5FD), 'text': const Color(0xFF1D4ED8)}, // Bright Blue
      {'bg': const Color(0xFFDBEAFE), 'border': const Color(0xFF60A5FA), 'text': const Color(0xFF1E40AF)}, // Vivid Blue
      {'bg': const Color(0xFFEEF2FF), 'border': const Color(0xFFA5B4FC), 'text': const Color(0xFF3730A3)}, // Indigo
      {'bg': const Color(0xFFE0E7FF), 'border': const Color(0xFF818CF8), 'text': const Color(0xFF3730A3)}, // Deep Indigo
      {'bg': const Color(0xFFE0F2FE), 'border': const Color(0xFF7DD3FC), 'text': const Color(0xFF0369A1)}, // Light Sky
      {'bg': const Color(0xFFBAE6FD), 'border': const Color(0xFF38BDF8), 'text': const Color(0xFF075985)}, // Cyan Blue
      {'bg': const Color(0xFFCFE2FF), 'border': const Color(0xFF6EA8FE), 'text': const Color(0xFF084298)}, // Bootstrap Blue
      {'bg': const Color(0xFFD9E8FF), 'border': const Color(0xFF6BAED6), 'text': const Color(0xFF08306B)}, // Steel Blue
      {'bg': const Color(0xFFBFD7ED), 'border': const Color(0xFF4292C6), 'text': const Color(0xFF08519C)}, // Medium Blue
      {'bg': const Color(0xFFE3EEF9), 'border': const Color(0xFF9ECAE1), 'text': const Color(0xFF2171B5)}, // Powder Blue
      {'bg': const Color(0xFFD0E4F7), 'border': const Color(0xFF539CC4), 'text': const Color(0xFF0D4F8B)}, // Cornflower
      {'bg': const Color(0xFFC8DFED), 'border': const Color(0xFF3182BD), 'text': const Color(0xFF023858)}, // Ocean Blue
    ];

    // FNV-1a hash: excellent distribution for similar prefixes (e.g. CS3301 vs CS3401)
    int hash = 2166136261;
    for (int i = 0; i < clean.length; i++) {
      hash ^= clean.codeUnitAt(i);
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    final index = hash.abs() % palettes.length;
    return palettes[index];
  }

  Widget _buildSlotCard(String code, String name, String faculty, {bool isNow = false}) {
    final matchesQuery = _searchQuery.isEmpty ||
        code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        faculty.toLowerCase().contains(_searchQuery.toLowerCase());

    final double opacity = matchesQuery ? 1.0 : 0.25;
    final colors = _getSubjectColors(code);

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        constraints: const BoxConstraints(minHeight: 100),
        decoration: BoxDecoration(
          color: isNow ? const Color(0xFFEFF6FF) : colors['bg'],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isNow ? const Color(0xFF2563EB) : colors['border']!,
            width: isNow ? 2.0 : 1.0,
          ),
          boxShadow: isNow
              ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4)),
                child: const Text('NOW', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            Text(
              code,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: colors['text']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              name,
              style: const TextStyle(fontSize: 10, color: Color(0xFF334155), fontWeight: FontWeight.w600, height: 1.15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (faculty.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                faculty,
                style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDotSlotCard({bool isNow = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      height: 100,
      decoration: BoxDecoration(
        color: isNow ? const Color(0xFFEFF6FF) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNow ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          width: isNow ? 2.0 : 1.0,
        ),
      ),
      child: Center(
        child: Text(
          '.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isNow ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  Widget _buildFacultyDetailsTable() {
    final filteredFaculty = _getFacultyListForSemester().where((fac) {
      final name = fac['faculty']!.toLowerCase();
      final code = fac['code']!.toLowerCase();
      final subject = fac['name']!.toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || code.contains(q) || subject.contains(q);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt, size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Text(
                'Faculty Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (filteredFaculty.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No handling faculty found for current timetable.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 44,
                dataRowHeight: 64,
                dividerThickness: 1,
                horizontalMargin: 16,
                columnSpacing: 36,
                headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('S.No', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  DataColumn(label: Text('Subject Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  DataColumn(label: Text('Subject Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  DataColumn(label: Text('Faculty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  DataColumn(label: Text('Qualification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  DataColumn(label: Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
                  DataColumn(label: Text('Office Room', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  DataColumn(label: Text('Phone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                ],
                rows: filteredFaculty.map((fac) {
                  return DataRow(cells: [
                    DataCell(Text(fac['sno']!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                    DataCell(Text(fac['code']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
                    DataCell(Text(fac['name']!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: fac['faculty'] == '-' ? const Color(0xFFE2E8F0) : const Color(0xFF1D4ED8),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              fac['initials'] ?? 'DR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: fac['faculty'] == '-' ? const Color(0xFF64748B) : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(fac['faculty']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text(fac['designation'] ?? 'Assistant Professor', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(fac['degree']!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                    DataCell(Text(fac['email']!, style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB)))),
                    DataCell(Text(fac['room']!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                    DataCell(Text(fac['phone']!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
