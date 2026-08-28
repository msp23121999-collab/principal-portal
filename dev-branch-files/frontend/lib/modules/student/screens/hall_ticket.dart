// ignore_for_file: deprecated_member_use, unused_element, unused_field, prefer_final_fields, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/app_state.dart';

class HallTicketScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const HallTicketScreen({super.key, this.onNavigate});

  @override
  State<HallTicketScreen> createState() => _HallTicketScreenState();
}

class _HallTicketScreenState extends State<HallTicketScreen> {

  // Fetch courses dynamically from Supabase database tables via AppState
  // Strictly matches the courses present in the Timetable page
  List<Map<String, String>> _getNoDueCoursesFromSupabase(AppState appState) {
    final Map<String, Map<String, String>> courseMap = {};

    final defaultTimetableCourses = {
      '24CST51': {'code': '24CST51', 'name': 'Data Warehousing and Data Mining', 'faculty': 'Dr. K. Ravichandran'},
      '24CST56': {'code': '24CST56', 'name': 'Full Stack Development', 'faculty': 'Dr. K. Ravichandran'},
      '24CST57': {'code': '24CST57', 'name': 'Principles of Compiler Design', 'faculty': 'Mr. P. Kalaiyarasan'},
      '24ADI51': {'code': '24ADI51', 'name': 'Artificial Intelligence', 'faculty': 'Mr. P. Kalaiyarasan'},
      '24ITT56': {'code': '24ITT56', 'name': 'Computer Networks', 'faculty': 'Mrs. S. Vinothini'},
    };

    final studentDept = appState.getProfileField('department', defaultValue: 'CSE').trim().toUpperCase();
    final studentSec = appState.getProfileField('section', defaultValue: 'A').trim().toUpperCase();
    final studentSemStr = appState.getProfileField('semester', defaultValue: '5').trim();
    final studentYear = appState.getProfileField('year_of_study', defaultValue: 'III').trim().toUpperCase();

    // 1. Build map of course_code -> faculty_name from facultyCourseAllocations (for resolving faculty only)
    final Map<String, String> facultyMap = {};
    for (var alloc in appState.facultyCourseAllocations) {
      final dept = (alloc['department'] ?? '').toString().trim().toUpperCase();
      final sec = (alloc['section'] ?? '').toString().trim().toUpperCase();
      if (dept == studentDept && sec == studentSec) {
        final code = (alloc['course_code'] ?? '').toString().trim();
        final facName = (alloc['assigned_fac_name'] ?? alloc['faculty_name'] ?? '').toString().trim();
        if (code.isNotEmpty && facName.isNotEmpty) {
          facultyMap[code] = facName;
        }
      }
    }

    String resolveFaculty(String code) {
      if (facultyMap.containsKey(code) && facultyMap[code]!.isNotEmpty) {
        return facultyMap[code]!;
      }
      for (var f in appState.faculties) {
        final fDept = (f['department'] ?? '').toString().trim().toUpperCase();
        final fCode = (f['course_code'] ?? '').toString().trim();
        final fName = (f['name'] ?? f['faculty_name'] ?? '').toString().trim();
        if ((fDept.isEmpty || fDept == studentDept) && fCode == code && fName.isNotEmpty) {
          return fName;
        }
      }
      return defaultTimetableCourses[code]?['faculty'] ?? '';
    }

    // 2. Only Source: classTimetables strictly filtered by student's department, section, semester
    for (var row in appState.classTimetables) {
      final dept = (row['department_code'] ?? row['department'] ?? '').toString().trim().toUpperCase();
      final sec = (row['section'] ?? '').toString().trim().toUpperCase();
      final sem = (row['sem'] ?? row['semester'] ?? '').toString().trim();
      final yr = (row['year'] ?? row['year_of_study'] ?? '').toString().trim().toUpperCase();

      // Filter: match department and section; match semester or year
      if (dept.isNotEmpty && dept != studentDept) continue;
      if (sec.isNotEmpty && sec != studentSec) continue;
      if (sem.isNotEmpty && sem != studentSemStr && sem != 'V') continue;
      if (yr.isNotEmpty && yr != studentYear && yr != '3') continue;

      for (int p = 1; p <= 8; p++) {
        final code = (row['p${p}_code'] ?? '').toString().trim();
        final name = (row['p${p}_name'] ?? '').toString().trim();
        if (code.isNotEmpty && code != '.' && !code.toUpperCase().startsWith('P')) {
          if (!courseMap.containsKey(code)) {
            courseMap[code] = {
              'code': code,
              'name': name.isNotEmpty ? name : (defaultTimetableCourses[code]?['name'] ?? code),
              'faculty': resolveFaculty(code),
            };
          } else {
            if ((courseMap[code]!['name'] == null || courseMap[code]!['name']!.isEmpty || courseMap[code]!['name'] == code) && name.isNotEmpty) {
              courseMap[code]!['name'] = name;
            }
            if (courseMap[code]!['faculty'] == null || courseMap[code]!['faculty']!.isEmpty) {
              courseMap[code]!['faculty'] = resolveFaculty(code);
            }
          }
        }
      }
    }

    // If no courses found in classTimetables, fallback strictly to the 5 timetable subjects
    if (courseMap.isEmpty) {
      for (var entry in defaultTimetableCourses.entries) {
        courseMap[entry.key] = {
          'code': entry.value['code']!,
          'name': entry.value['name']!,
          'faculty': resolveFaculty(entry.key),
        };
      }
    }

    // Clean list: filter empty codes, deduplicate by code
    final List<Map<String, String>> result = [];
    final Set<String> seenCodes = {};

    for (var item in courseMap.values) {
      final code = (item['code'] ?? '').trim();
      if (code.isEmpty || code == '.' || code.toUpperCase().startsWith('P')) continue;
      if (seenCodes.contains(code)) continue;

      seenCodes.add(code);
      result.add(item);
    }

    // Sort by course code
    result.sort((a, b) => (a['code'] ?? '').compareTo(b['code'] ?? ''));
    return result;
  }

  void _triggerPdfDownload() {
    try {
      final appState = AppStateProvider.of(context);
      final profile = appState.studentProfileData ?? {};
      final String studentName = (profile['full_name'] ?? profile['name'] ?? appState.studentName).toString().trim();
      final String regNo = (profile['register_no'] ?? profile['roll_no'] ?? appState.getProfileField('register_no')).toString().trim();
      final String dept = (profile['department'] ?? profile['dept'] ?? appState.getProfileField('department')).toString().trim();

      final header = '%PDF-1.4\n';
      final body = StringBuffer();
      body.write('BT\n');
      body.write('/F1 18 Tf\n');
      body.write('50 780 Td\n');
      body.write('24 TL\n');
      body.write('(K.S.R. COLLEGE OF ENGINEERING - NO DUE FORM) Tj T*\n');
      body.write('/F1 12 Tf\n');
      body.write('16 TL\n');
      body.write('0 -10 Td\n');
      body.write('(Student Name: $studentName) Tj T*\n');
      body.write('(Register No: $regNo) Tj T*\n');
      body.write('(Department: $dept) Tj T*\n');
      body.write('(Status: ALL DUES CLEARED - NO DUE CERTIFICATE) Tj T*\n');
      body.write('ET');

      final streamContent = body.toString();
      final streamLength = streamContent.length;

      final objects = [
        '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
        '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
        '3 0 obj\n<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /MediaBox [0 0 595 842] /Contents 5 0 R >>\nendobj\n',
        '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
        '5 0 obj\n<< /Length $streamLength >>\nstream\n$streamContent\nendstream\nendobj\n',
      ];

      final pdf = StringBuffer();
      pdf.write(header);

      final offsets = <int>[];
      var currentOffset = header.length;

      for (var obj in objects) {
        offsets.add(currentOffset);
        pdf.write(obj);
        currentOffset += obj.length;
      }

      final startXref = currentOffset;
      pdf.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
      for (var offset in offsets) {
        pdf.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
      }

      pdf.write('trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n');
      pdf.write('startxref\n$startXref\n%%EOF');

      final pdfBytes = utf8.encode(pdf.toString());
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', 'no_due_form_${regNo.isEmpty ? "student" : regNo}.pdf')
        ..click();

      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Due Form PDF downloaded successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading No Due Form PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _triggerPrintForm() {
    final appState = AppStateProvider.of(context);
    final profile = appState.studentProfileData ?? {};
    final String studentName = (profile['full_name'] ?? profile['name'] ?? appState.studentName).toString().trim();
    final String regNo = (profile['register_no'] ?? profile['roll_no'] ?? appState.getProfileField('register_no')).toString().trim();
    final String dept = (profile['department'] ?? profile['dept'] ?? appState.getProfileField('department')).toString().trim();
    final String sem = (profile['semester'] ?? appState.getProfileField('semester')).toString().trim();
    final String yearStr = (profile['year_of_study'] ?? profile['year'] ?? appState.getProfileField('year')).toString().trim();
    final now = DateTime.now();
    final String todayDate = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    final coursesList = _getNoDueCoursesFromSupabase(appState);

    final StringBuffer rowsHtml = StringBuffer();
    if (coursesList.isNotEmpty) {
      for (int i = 0; i < coursesList.length; i++) {
        final c = coursesList[i];
        rowsHtml.write('''
          <tr>
            <td style="text-align: center;">${i + 1}</td>
            <td>${c['code'] ?? ''}</td>
            <td>${c['name'] ?? ''}</td>
            <td>${c['faculty'] ?? ''}</td>
            <td><div style="height: 38px; border: 1px dashed #cbd5e1; border-radius: 4px;"></div></td>
          </tr>
        ''');
      }
    } else {
      rowsHtml.write('''
        <tr>
          <td style="text-align: center;">-</td>
          <td>-</td>
          <td>No course records found in Supabase database.</td>
          <td>-</td>
          <td>-</td>
        </tr>
      ''');
    }

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>No Due Form - $studentName</title>
  <style>
    @page {
      size: A4 portrait;
      margin: 12mm;
    }
    * {
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
      color: #0f172a;
      background: #ffffff;
      margin: 0;
      padding: 16px;
    }
    .header {
      text-align: center;
      margin-bottom: 20px;
    }
    .college-name {
      font-size: 20px;
      font-weight: 800;
      color: #1e293b;
      letter-spacing: 0.5px;
      margin-bottom: 4px;
    }
    .place-name {
      font-size: 13px;
      font-weight: 600;
      color: #64748b;
      margin-bottom: 8px;
    }
    .dept-name {
      font-size: 15px;
      font-weight: 700;
      color: #1e3a8a;
      margin-bottom: 12px;
    }
    .badge-no-due {
      display: inline-block;
      padding: 4px 24px;
      background: #f1f5f9;
      border: 1px solid #cbd5e1;
      border-radius: 20px;
      font-size: 16px;
      font-weight: 800;
      color: #0f172a;
      letter-spacing: 1px;
    }
    .details-box {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 10px;
      padding: 16px 20px;
      margin-bottom: 24px;
    }
    .details-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 12px;
    }
    .details-row:last-child {
      margin-bottom: 0;
    }
    .detail-item {
      flex: 1;
      font-size: 13px;
      display: flex;
      align-items: center;
    }
    .detail-label {
      font-weight: 700;
      color: #475569;
      margin-right: 6px;
    }
    .detail-val {
      font-weight: 700;
      color: #0f172a;
      border-bottom: 1px solid #cbd5e1;
      flex: 1;
      padding-bottom: 2px;
    }
    .table-title {
      font-size: 15px;
      font-weight: 700;
      color: #1e293b;
      margin-bottom: 10px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 40px;
    }
    th {
      background: #1e3a8a;
      color: #ffffff;
      font-size: 11px;
      font-weight: 700;
      padding: 10px 8px;
      border: 1px solid #1e3a8a;
      text-align: center;
    }
    td {
      font-size: 12px;
      font-weight: 600;
      color: #1e293b;
      padding: 8px 10px;
      border: 1px solid #cbd5e1;
    }
    .footer-signatures {
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
      margin-top: 50px;
    }
    .sig-block {
      text-align: center;
      width: 140px;
    }
    .sig-line {
      border-bottom: 1.5px solid #64748b;
      height: 45px;
      margin-bottom: 8px;
    }
    .sig-title {
      font-size: 12px;
      font-weight: 700;
      color: #1e293b;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="college-name">K.S.R. COLLEGE OF ENGINEERING (AUTONOMOUS)</div>
    <div class="place-name">TIRUCHENGODE - 637 215</div>
    <div class="dept-name">${dept.isNotEmpty ? 'DEPARTMENT OF ${dept.toUpperCase()}' : 'DEPARTMENT OF ENGINEERING'}</div>
    <div class="badge-no-due">NO DUE</div>
  </div>

  <div class="details-box">
    <div class="details-row">
      <div class="detail-item"><span class="detail-label">Student Name:</span><span class="detail-val">$studentName</span></div>
      <div style="width: 20px;"></div>
      <div class="detail-item"><span class="detail-label">Register No.:</span><span class="detail-val">$regNo</span></div>
    </div>
    <div class="details-row">
      <div class="detail-item"><span class="detail-label">Semester:</span><span class="detail-val">$sem</span></div>
      <div style="width: 20px;"></div>
      <div class="detail-item"><span class="detail-label">Year:</span><span class="detail-val">$yearStr</span></div>
      <div style="width: 20px;"></div>
      <div class="detail-item"><span class="detail-label">Date:</span><span class="detail-val">$todayDate</span></div>
    </div>
  </div>

  <div class="table-title">Course No Due Clearance Table</div>
  <table>
    <thead>
      <tr>
        <th style="width: 50px;">S.NO.</th>
        <th style="width: 120px;">COURSE CODE</th>
        <th>COURSE NAME</th>
        <th>SUBJECT HANDLING FACULTIES</th>
        <th style="width: 180px;">SIGNATURE OF THE FACULTY</th>
      </tr>
    </thead>
    <tbody>
      $rowsHtml
    </tbody>
  </table>

  <div class="footer-signatures">
    <div class="sig-block"><div class="sig-line"></div><div class="sig-title">Advisor 1</div></div>
    <div class="sig-block"><div class="sig-line"></div><div class="sig-title">Advisor 2</div></div>
    <div class="sig-block"><div class="sig-line"></div><div class="sig-title">Co-ordinator</div></div>
    <div class="sig-block"><div class="sig-line"></div><div class="sig-title">Student Sign</div></div>
  </div>

</body>
</html>
    ''';

    _printViaIframe(htmlContent);
  }

  void _printViaIframe(String htmlContent) {
    try {
      final oldIframe = html.document.getElementById('nodue_print_frame');
      if (oldIframe != null) {
        oldIframe.remove();
      }

      final iframe = html.IFrameElement()
        ..id = 'nodue_print_frame'
        ..style.position = 'fixed'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.width = '0'
        ..style.height = '0'
        ..style.border = '0';
      html.document.body?.children.add(iframe);

      final dynamic win = iframe.contentWindow;
      if (win != null) {
        win.document?.open();
        win.document?.write(htmlContent);
        win.document?.close();
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            win.print();
          } catch (_) {}
          Future.delayed(const Duration(seconds: 2), () {
            iframe.remove();
          });
        });
      }
    } catch (e) {
      // Fallback to Blob URL if iframe fails
      try {
        final blob = html.Blob([htmlContent], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        Future.delayed(const Duration(minutes: 2), () => html.Url.revokeObjectUrl(url));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);

    // Direct Supabase connected fields
    final profile = appState.studentProfileData ?? {};
    final String studentName = (profile['full_name'] ?? profile['name'] ?? appState.studentName).toString().trim();
    final String regNo = (profile['register_no'] ?? profile['roll_no'] ?? appState.getProfileField('register_no')).toString().trim();
    final String dept = (profile['department'] ?? profile['dept'] ?? appState.getProfileField('department')).toString().trim();
    final String sem = (profile['semester'] ?? appState.getProfileField('semester')).toString().trim();
    final String yearStr = (profile['year_of_study'] ?? profile['year'] ?? appState.getProfileField('year')).toString().trim();
    
    final now = DateTime.now();
    final String todayDate = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    final coursesList = _getNoDueCoursesFromSupabase(appState);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 950),
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),
                  ElevatedButton.icon(
                    onPressed: _triggerPrintForm,
                    icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                    label: const Text('Download Form', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // College Header
              Center(
                child: Column(
                  children: [
                    const Text(
                      'K.S.R. COLLEGE OF ENGINEERING (AUTONOMOUS)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'TIRUCHENGODE - 637 215',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Department connected to Supabase directly below College Place
                    Text(
                      dept.isNotEmpty ? 'DEPARTMENT OF ${dept.toUpperCase()}' : 'DEPARTMENT OF ENGINEERING',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'NO DUE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Student Details Section (Strictly Connected to Supabase without Department format)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 550;
                    if (isDesktop) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildDetailItem('Student Name', studentName)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildDetailItem('Register No.', regNo)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: _buildDetailItem('Semester', sem)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildDetailItem('Year', yearStr)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildDetailItem('Date', todayDate)),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDetailItem('Student Name', studentName),
                          const SizedBox(height: 12),
                          _buildDetailItem('Register No.', regNo),
                          const SizedBox(height: 12),
                          _buildDetailItem('Semester', sem),
                          const SizedBox(height: 12),
                          _buildDetailItem('Year', yearStr),
                          const SizedBox(height: 12),
                          _buildDetailItem('Date', todayDate),
                        ],
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Table: S.NO., COURSE CODE, COURSE NAME, SUBJECT HANDLING FACULTIES, SIGNATURE OF THE FACULTY
              const Text(
                'Course No Due Clearance Table',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 885,
                  child: Table(
                    border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                    columnWidths: const {
                      0: FixedColumnWidth(60),
                      1: FixedColumnWidth(130),
                      2: FlexColumnWidth(3),
                      3: FlexColumnWidth(3),
                      4: FlexColumnWidth(2.5),
                    },
                    children: [
                      // Table Header
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
                        children: const [
                          _TableHeaderCell('S.NO.'),
                          _TableHeaderCell('COURSE CODE'),
                          _TableHeaderCell('COURSE NAME'),
                          _TableHeaderCell('SUBJECT HANDLING FACULTIES'),
                          _TableHeaderCell('SIGNATURE OF THE FACULTY'),
                        ],
                      ),
                      // Supabase connected Course Clearance Rows
                      if (coursesList.isNotEmpty)
                        ...List.generate(coursesList.length, (index) {
                          final course = coursesList[index];
                          return TableRow(
                            children: [
                              _TableCellText('${index + 1}', isCenter: true),
                              _TableCellText(course['code'] ?? ''),
                              _TableCellText(course['name'] ?? ''),
                              _TableCellText(course['faculty'] ?? ''),
                              // Spacious Signature Box for Faculty
                              Container(
                                height: 60,
                                padding: const EdgeInsets.all(8),
                                alignment: Alignment.center,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          );
                        })
                      else
                        // Empty state if no Supabase records found
                        TableRow(
                          children: [
                            const _TableCellText('-', isCenter: true),
                            const _TableCellText('-'),
                            Container(
                              height: 60,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: const Text(
                                'No course records found in Supabase database.',
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                              ),
                            ),
                            const _TableCellText('-'),
                            const _TableCellText('-'),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Footer Section (Spacious signature area for Advisors, Co-ordinator, Student)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 550;
                  if (isDesktop) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        _SignatureBlock(title: 'Advisor 1'),
                        _SignatureBlock(title: 'Advisor 2'),
                        _SignatureBlock(title: 'Co-ordinator'),
                        _SignatureBlock(title: 'Student Sign'),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Expanded(child: _SignatureBlock(title: 'Advisor 1')),
                            SizedBox(width: 16),
                            Expanded(child: _SignatureBlock(title: 'Advisor 2')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Expanded(child: _SignatureBlock(title: 'Co-ordinator')),
                            SizedBox(width: 16),
                            Expanded(child: _SignatureBlock(title: 'Student Sign')),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 3),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1)),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String title;
  const _TableHeaderCell(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TableCellText extends StatelessWidget {
  final String text;
  final bool isCenter;
  const _TableCellText(this.text, {this.isCenter = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: isCenter ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      ),
    );
  }
}

class _SignatureBlock extends StatelessWidget {
  final String title;
  const _SignatureBlock({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 140,
          height: 60,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF64748B), width: 1.5, style: BorderStyle.solid)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
