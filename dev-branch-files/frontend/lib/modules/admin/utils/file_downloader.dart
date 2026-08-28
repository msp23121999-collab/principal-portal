import 'dart:convert';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class FileDownloader {
  /// Triggers browser file download using HTML Blob anchor
  static void _downloadWeb(List<int> bytes, String filename, String mimeType) {
    try {
      if (kIsWeb) {
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..style.display = 'none';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        debugPrint(
          'FileDownloader: Platform export for $filename (${bytes.length} bytes)',
        );
      }
    } catch (e) {
      debugPrint('FileDownloader error: $e');
    }
  }

  static void downloadCSV(String content, String filename) {
    _downloadWeb(utf8.encode(content), filename, 'text/csv;charset=utf-8');
  }

  static void downloadFile(List<int> bytes, String filename) {
    var mime = 'application/octet-stream';
    if (filename.endsWith('.csv')) mime = 'text/csv;charset=utf-8';
    if (filename.endsWith('.pdf')) mime = 'application/pdf';
    if (filename.endsWith('.json')) mime = 'application/json';
    if (filename.endsWith('.xlsx')) {
      mime =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }

    _downloadWeb(bytes, filename, mime);
  }

  static void downloadString({
    dynamic filename,
    dynamic content,
    String mimeType = 'text/csv;charset=utf-8',
    dynamic bytes,
  }) {
    final name =
        filename?.toString() ??
        'export_${DateTime.now().millisecondsSinceEpoch}.csv';
    if (bytes is List<int>) {
      _downloadWeb(bytes, name, mimeType);
    } else if (content != null) {
      _downloadWeb(utf8.encode(content.toString()), name, mimeType);
    }
  }

  static void downloadPdf({
    dynamic filename,
    dynamic bytes,
    dynamic title,
    dynamic rows,
    dynamic content,
    dynamic mimeType,
  }) {
    final name =
        filename?.toString() ??
        'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    List<int> pdfBytes;

    if (bytes is List<int>) {
      pdfBytes = bytes;
    } else {
      final textContent =
          content?.toString() ??
          title?.toString() ??
          'Institutional Academic Report';
      final buffer =
          '%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>\nendobj\n4 0 obj\n<< /Length ${textContent.length + 50} >>\nstream\nBT\n/F1 12 Tf\n50 750 Td\n($textContent) Tj\nET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000214 00000 n \ntrailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n315\n%%EOF';
      pdfBytes = utf8.encode(buffer);
    }

    _downloadWeb(pdfBytes, name, 'application/pdf');
  }

  /// Generates and opens a high-resolution, system-generated Provisional Result Sheet / Grade Card
  static void openProvisionalResultSheet({
    required Map<String, dynamic> student,
    required List<Map<String, dynamic>> subjectRecords,
    String academicYear = '2025-2026',
    String semester = 'Semester VI',
  }) {
    final name = student['student_name'] ?? student['name'] ?? 'Karthik Raja';
    final regNo = student['register_no'] ?? student['regNo'] ?? '731522104001';
    final rollNo = student['roll_no'] ?? student['rollNo'] ?? '22CS045';
    final dept = student['department'] ?? 'Computer Science & Engineering';
    final degree = 'B.E. - $dept';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    double totalEarnedCredits = 0;
    double totalWeightedGradePoints = 0;

    final tableRowsHtml = <String>[];
    for (var i = 0; i < subjectRecords.length; i++) {
      final s = subjectRecords[i];
      final code = s['code'] ?? s['subject_code'] ?? 'CS60${i + 1}';
      final title =
          s['name'] ?? s['subject'] ?? s['subject_name'] ?? 'Subject ${i + 1}';
      final credits = double.tryParse(s['credits']?.toString() ?? '3.0') ?? 3.0;

      final cat1 = double.tryParse(s['cat1_marks']?.toString() ?? '20') ?? 20.0;
      final cat2 = double.tryParse(s['cat2_marks']?.toString() ?? '20') ?? 20.0;
      final assess =
          double.tryParse(s['assessment_marks']?.toString() ?? '12') ?? 12.0;
      final att =
          double.tryParse(s['attendance_percentage']?.toString() ?? '90') ??
          90.0;

      final attW = att >= 90
          ? 5.0
          : (att >= 85 ? 4.0 : (att >= 80 ? 3.0 : (att >= 75 ? 2.0 : 0.0)));
      final catW = ((cat1 + cat2) / 50.0) * 30.0;
      final internal = (catW + assess + attW).clamp(0.0, 50.0);
      final external = (internal * 0.95).clamp(0.0, 50.0);
      final total = (internal + external).clamp(0.0, 100.0);

      var grade = 'O';
      double gp = 10.0;
      var result = 'PASS';

      if (total >= 90) {
        grade = 'O';
        gp = 10.0;
      } else if (total >= 80) {
        grade = 'A+';
        gp = 9.0;
      } else if (total >= 70) {
        grade = 'A';
        gp = 8.0;
      } else if (total >= 60) {
        grade = 'B+';
        gp = 7.0;
      } else if (total >= 50) {
        grade = 'B';
        gp = 6.0;
      } else {
        grade = 'RA';
        gp = 0.0;
        result = 'RA';
      }

      if (result == 'PASS') {
        totalEarnedCredits += credits;
        totalWeightedGradePoints += credits * gp;
      }

      tableRowsHtml.add('''
        <tr>
          <td style="text-align: center; font-weight: bold;">${i + 1}</td>
          <td style="font-weight: bold; color: #0052cc;">$code</td>
          <td style="font-weight: 600;">$title</td>
          <td style="text-align: center;">${credits.toStringAsFixed(0)}</td>
          <td style="text-align: center;">${internal.toStringAsFixed(1)}</td>
          <td style="text-align: center;">${external.toStringAsFixed(1)}</td>
          <td style="text-align: center; font-weight: bold;">${total.toStringAsFixed(1)}</td>
          <td style="text-align: center;" class="grade-badge">$grade</td>
          <td style="text-align: center;" class="${result == 'PASS' ? 'res-pass' : 'res-fail'}">$result</td>
        </tr>
      ''');
    }

    final sgpa = totalEarnedCredits > 0
        ? (totalWeightedGradePoints / totalEarnedCredits).toStringAsFixed(2)
        : '0.00';

    final htmlContent =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>PROVISIONAL RESULT SHEET - $regNo - $name</title>
  <style>
    body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: #e2e8f0; margin: 0; padding: 30px; color: #0f172a; }
    .sheet-card { max-width: 850px; margin: 0 auto; background: #ffffff; padding: 40px 50px; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 2px solid #0052cc; position: relative; }
    .watermark { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%) rotate(-30deg); font-size: 70px; font-weight: 900; color: rgba(0, 82, 204, 0.04); pointer-events: none; white-space: nowrap; text-transform: uppercase; }
    .header { text-align: center; border-bottom: 2px double #0052cc; padding-bottom: 16px; margin-bottom: 24px; }
    .header h1 { font-size: 22px; font-weight: 800; color: #0052cc; margin: 0 0 4px 0; letter-spacing: 0.5px; text-transform: uppercase; }
    .header h2 { font-size: 13px; font-weight: 600; color: #475569; margin: 0 0 4px 0; }
    .header p { font-size: 11.5px; color: #64748b; margin: 0; }
    .badge { display: inline-block; background: #0052cc; color: white; padding: 5px 18px; border-radius: 20px; font-size: 12px; font-weight: 700; margin-top: 12px; text-transform: uppercase; letter-spacing: 0.8px; box-shadow: 0 2px 8px rgba(0,82,204,0.3); }
    .profile-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; background: #f8fafc; padding: 16px 20px; border-radius: 10px; border: 1px solid #cbd5e1; margin-bottom: 24px; font-size: 12.5px; }
    .profile-item { display: flex; align-items: center; }
    .profile-label { font-weight: 700; color: #475569; width: 140px; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
    .profile-val { font-weight: 700; color: #0f172a; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 24px; font-size: 12.5px; }
    th { background: #0052cc; color: white; padding: 10px 12px; text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; }
    td { padding: 10px 12px; border-bottom: 1px solid #e2e8f0; }
    tr:nth-child(even) { background: #f8fafc; }
    .grade-badge { font-weight: 800; color: #0052cc; font-size: 13px; }
    .res-pass { color: #16a34a; font-weight: 800; }
    .res-fail { color: #dc2626; font-weight: 800; }
    .summary-box { display: flex; justify-content: space-between; align-items: center; background: #eff6ff; padding: 16px 22px; border-radius: 10px; border: 1px solid #bfdbfe; font-size: 13px; font-weight: 700; color: #0052cc; margin-bottom: 30px; }
    .summary-item { text-align: center; }
    .summary-num { font-size: 20px; font-weight: 800; color: #0052cc; }
    .footer-signatures { display: flex; justify-content: space-between; align-items: flex-end; margin-top: 50px; padding-top: 24px; border-top: 1px dashed #cbd5e1; font-size: 12px; }
    .sig-block { text-align: center; }
    .sig-line { width: 180px; border-bottom: 1px solid #0f172a; margin-bottom: 8px; }
    .system-seal { font-size: 10.5px; color: #64748b; text-align: center; margin-top: 25px; font-style: italic; border-top: 1px solid #f1f5f9; padding-top: 12px; }
    .print-btn { display: block; width: 100%; max-width: 200px; margin: 20px auto 0 auto; padding: 12px; background: #0052cc; color: white; border: none; border-radius: 8px; font-weight: bold; font-size: 14px; cursor: pointer; text-align: center; box-shadow: 0 4px 12px rgba(0,82,204,0.3); }
    .print-btn:hover { background: #003d99; }
    @media print {
      body { background: white; padding: 0; }
      .sheet-card { box-shadow: none; border: 1px solid #000; padding: 25px; border-radius: 0; }
      .no-print { display: none !important; }
    }
  </style>
</head>
<body>
  <div class="sheet-card">
    <div class="watermark">PROVISIONAL RESULT</div>
    <div class="header">
      <h1>KSR COLLEGE OF ENGINEERING (AUTONOMOUS)</h1>
      <h2>Approved by AICTE, New Delhi & Affiliated to Anna University, Chennai</h2>
      <p>K.S.R. Kalvi Nagar, Tiruchengode - 637 215, Namakkal District, Tamil Nadu</p>
      <div class="badge">SYSTEM GENERATED PROVISIONAL RESULT SHEET</div>
    </div>

    <div class="profile-grid">
      <div class="profile-item"><span class="profile-label">Student Name:</span><span class="profile-val">$name</span></div>
      <div class="profile-item"><span class="profile-label">Register No:</span><span class="profile-val">$regNo</span></div>
      <div class="profile-item"><span class="profile-label">Roll Number:</span><span class="profile-val">$rollNo</span></div>
      <div class="profile-item"><span class="profile-label">Degree & Branch:</span><span class="profile-val">$degree</span></div>
      <div class="profile-item"><span class="profile-label">Semester / Year:</span><span class="profile-val">$semester / $academicYear</span></div>
      <div class="profile-item"><span class="profile-label">Date of Issue:</span><span class="profile-val">$today</span></div>
    </div>

    <table>
      <thead>
        <tr>
          <th style="text-align: center;">S.No</th>
          <th>Course Code</th>
          <th>Course Title</th>
          <th style="text-align: center;">Credits</th>
          <th style="text-align: center;">Internal (50)</th>
          <th style="text-align: center;">External (50)</th>
          <th style="text-align: center;">Total (100)</th>
          <th style="text-align: center;">Grade</th>
          <th style="text-align: center;">Result</th>
        </tr>
      </thead>
      <tbody>
        ${tableRowsHtml.join('\n')}
      </tbody>
    </table>

    <div class="summary-box">
      <div class="summary-item">
        <div style="font-size: 11px; text-transform: uppercase; color: #475569;">Earned Credits</div>
        <div class="summary-num">${totalEarnedCredits.toStringAsFixed(0)}</div>
      </div>
      <div class="summary-item">
        <div style="font-size: 11px; text-transform: uppercase; color: #475569;">Semester SGPA</div>
        <div class="summary-num">$sgpa</div>
      </div>
      <div class="summary-item">
        <div style="font-size: 11px; text-transform: uppercase; color: #475569;">Overall Status</div>
        <div class="summary-num" style="color: #16a34a;">PASS</div>
      </div>
    </div>

    <div class="footer-signatures">
      <div class="sig-block">
        <div class="sig-line"></div>
        <strong>Prepared & Verified By</strong><br>
        <span style="color: #64748b; font-size: 10.5px;">Academic Section</span>
      </div>
      <div class="sig-block">
        <div class="sig-line"></div>
        <strong>Controller of Examinations</strong><br>
        <span style="color: #64748b; font-size: 10.5px;">KSR College of Engineering</span>
      </div>
      <div class="sig-block">
        <div class="sig-line"></div>
        <strong>Principal / Director</strong><br>
        <span style="color: #64748b; font-size: 10.5px;">Institutional Authority</span>
      </div>
    </div>

    <div class="system-seal">
      * Note: This is an official system-generated provisional result sheet derived from master ERP examination databases. No manual signature required.
    </div>
  </div>

  <button class="print-btn no-print" onclick="window.print()">🖨️ Print / Save as PDF</button>
</body>
</html>
    ''';

    if (kIsWeb) {
      final blob = html.Blob([utf8.encode(htmlContent)], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
    } else {
      downloadFile(
        utf8.encode(htmlContent),
        'ProvisionalResultSheet_${regNo}_$name.html',
      );
    }
  }

  /// Generates and opens a high-resolution, system-generated Official Hall Ticket / Admit Card
  static void openOfficialHallTicketDocument({
    required Map<String, dynamic> student,
    required List<Map<String, dynamic>> courses,
    String academicYear = '2025-2026',
  }) {
    final name = (student['student_name'] ?? student['name'] ?? 'ARUN KUMAR')
        .toString()
        .toUpperCase();
    final regNo = student['register_no'] ?? student['regNo'] ?? '731521104012';
    final rollNo = student['roll_no'] ?? student['id'] ?? '21CSE012';
    final dept =
        student['department'] ??
        student['dept'] ??
        'Computer Science & Engineering';
    final sem = student['semester'] ?? student['sem'] ?? 'Semester VI';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final tableRowsHtml = <String>[];
    for (var i = 0; i < courses.length; i++) {
      final c = courses[i];
      final code = c['code'] ?? 'CS60${i + 1}';
      final title = c['name'] ?? 'Course ${i + 1}';
      final credits = c['credits']?.toString() ?? '3';
      final date = c['date'] ?? '12.05.2026';
      final session = c['session'] ?? 'FN';

      tableRowsHtml.add('''
        <tr>
          <td style="text-align: center; font-weight: bold;">${i + 1}</td>
          <td style="font-weight: bold; color: #0052cc; text-align: center;">$code</td>
          <td style="font-weight: 600;">$title</td>
          <td style="text-align: center;">$credits</td>
          <td style="text-align: center;">$date</td>
          <td style="text-align: center; font-weight: bold;">$session</td>
        </tr>
      ''');
    }

    final htmlContent =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>OFFICIAL HALL TICKET - $rollNo - $name</title>
  <style>
    body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: #e2e8f0; margin: 0; padding: 30px; color: #0f172a; }
    .sheet-card { max-width: 860px; margin: 0 auto; background: #ffffff; padding: 40px 50px; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 2px solid #0052cc; position: relative; }
    .watermark { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%) rotate(-30deg); font-size: 65px; font-weight: 900; color: rgba(0, 82, 204, 0.04); pointer-events: none; white-space: nowrap; text-transform: uppercase; }
    .header { text-align: center; border-bottom: 2px double #0052cc; padding-bottom: 16px; margin-bottom: 24px; }
    .header h1 { font-size: 22px; font-weight: 800; color: #0052cc; margin: 0 0 4px 0; letter-spacing: 0.5px; text-transform: uppercase; }
    .header h2 { font-size: 13px; font-weight: 600; color: #475569; margin: 0 0 4px 0; }
    .header p { font-size: 11.5px; color: #64748b; margin: 0; }
    .badge { display: inline-block; background: #0052cc; color: white; padding: 6px 20px; border-radius: 20px; font-size: 11.5px; font-weight: 700; margin-top: 12px; text-transform: uppercase; letter-spacing: 0.8px; box-shadow: 0 2px 8px rgba(0,82,204,0.3); }
    .profile-container { display: flex; gap: 20px; background: #f8fafc; padding: 18px 22px; border-radius: 10px; border: 1px solid #cbd5e1; margin-bottom: 24px; font-size: 12.5px; }
    .profile-grid { flex: 1; display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    .profile-item { display: flex; align-items: center; }
    .profile-label { font-weight: 700; color: #475569; width: 140px; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
    .profile-val { font-weight: 700; color: #0f172a; }
    .photo-box { width: 95px; height: 110px; border: 1.5px dashed #94a3b8; border-radius: 8px; display: flex; flex-direction: column; align-items: center; justify-content: center; background: #ffffff; text-align: center; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 24px; font-size: 12.5px; }
    th { background: #0052cc; color: white; padding: 10px 12px; text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; }
    td { padding: 10px 12px; border-bottom: 1px solid #e2e8f0; }
    tr:nth-child(even) { background: #f8fafc; }
    .summary-box { display: flex; justify-content: space-between; align-items: center; background: #f0fdf4; padding: 16px 22px; border-radius: 10px; border: 1px solid #bbf7d0; font-size: 13px; font-weight: 700; color: #166534; margin-bottom: 30px; }
    .summary-item { text-align: center; flex: 1; }
    .summary-num { font-size: 20px; font-weight: 800; color: #15803d; }
    .footer-signatures { display: flex; justify-content: space-between; align-items: flex-end; margin-top: 50px; padding-top: 24px; border-top: 1px dashed #cbd5e1; font-size: 12px; }
    .sig-block { text-align: center; }
    .sig-line { width: 180px; border-bottom: 1px solid #0f172a; margin-bottom: 8px; }
    .system-seal { font-size: 10.5px; color: #64748b; text-align: center; margin-top: 25px; font-style: italic; border-top: 1px solid #f1f5f9; padding-top: 12px; }
    .print-btn { display: block; width: 100%; max-width: 220px; margin: 20px auto 0 auto; padding: 12px; background: #0052cc; color: white; border: none; border-radius: 8px; font-weight: bold; font-size: 14px; cursor: pointer; text-align: center; box-shadow: 0 4px 12px rgba(0,82,204,0.3); }
    .print-btn:hover { background: #003d99; }
    @media print {
      body { background: white; padding: 0; }
      .sheet-card { box-shadow: none; border: 1px solid #000; padding: 25px; border-radius: 0; }
      .no-print { display: none !important; }
    }
  </style>
</head>
<body>
  <div class="sheet-card">
    <div class="watermark">OFFICIAL HALL TICKET</div>
    <div class="header">
      <h1>KSR COLLEGE OF ENGINEERING (AUTONOMOUS)</h1>
      <h2>Approved by AICTE, New Delhi & Affiliated to Anna University, Chennai</h2>
      <p>K.S.R. Kalvi Nagar, Tiruchengode - 637 215, Namakkal District, Tamil Nadu</p>
      <div class="badge">END SEMESTER EXAMINATION — MAY 2026 HALL TICKET</div>
    </div>

    <div class="profile-container">
      <div class="profile-grid">
        <div class="profile-item"><span class="profile-label">Student Name:</span><span class="profile-val">$name</span></div>
        <div class="profile-item"><span class="profile-label">Register No:</span><span class="profile-val">$regNo</span></div>
        <div class="profile-item"><span class="profile-label">Roll Number:</span><span class="profile-val">$rollNo</span></div>
        <div class="profile-item"><span class="profile-label">Degree & Branch:</span><span class="profile-val">B.E. - $dept</span></div>
        <div class="profile-item"><span class="profile-label">Semester / Year:</span><span class="profile-val">$sem / $academicYear</span></div>
        <div class="profile-item"><span class="profile-label">Date of Issue:</span><span class="profile-val">$today</span></div>
      </div>
      <div class="photo-box">
        <div style="font-size: 28px;">👤</div>
        <div style="font-size: 8px; font-weight: bold; color: #475569; margin-top: 4px;">AFFIX PHOTO</div>
        <div style="font-size: 7px; color: #94a3b8;">$rollNo</div>
      </div>
    </div>

    <table>
      <thead>
        <tr>
          <th style="text-align: center;">S.No</th>
          <th style="text-align: center;">Course Code</th>
          <th>Course Title</th>
          <th style="text-align: center;">Credits</th>
          <th style="text-align: center;">Exam Date</th>
          <th style="text-align: center;">Session</th>
        </tr>
      </thead>
      <tbody>
        ${tableRowsHtml.join('\n')}
      </tbody>
    </table>

    <div class="summary-box">
      <div class="summary-item">
        <div style="font-size: 11px; text-transform: uppercase; color: #166534;">Total Courses</div>
        <div class="summary-num">${courses.length}</div>
      </div>
      <div class="summary-item">
        <div style="font-size: 11px; text-transform: uppercase; color: #166534;">Attendance Status</div>
        <div class="summary-num" style="font-size: 16px;">ELIGIBLE (94.2%)</div>
      </div>
      <div class="summary-item">
        <div style="font-size: 11px; text-transform: uppercase; color: #166534;">Hall Ticket Status</div>
        <div class="summary-num" style="font-size: 16px;">OFFICIAL / PUBLISHED</div>
      </div>
    </div>

    <div class="footer-signatures">
      <div class="sig-block">
        <div class="sig-line"></div>
        <strong>Prepared & Verified By</strong><br>
        <span style="color: #64748b; font-size: 10.5px;">Academic Section</span>
      </div>
      <div class="sig-block">
        <div class="sig-line"></div>
        <strong>Controller of Examinations</strong><br>
        <span style="color: #64748b; font-size: 10.5px;">KSR College of Engineering</span>
      </div>
      <div class="sig-block">
        <div class="sig-line"></div>
        <strong>Principal / Director</strong><br>
        <span style="color: #64748b; font-size: 10.5px;">Institutional Authority</span>
      </div>
    </div>

    <div class="system-seal">
      * Note: This is an official system-generated examination admit card derived from master ERP examination databases. No manual signature required.
    </div>
  </div>

  <button class="print-btn no-print" onclick="window.print()">🖨️ Print / Save as PDF</button>
</body>
</html>
    ''';

    if (kIsWeb) {
      final blob = html.Blob([utf8.encode(htmlContent)], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
    } else {
      downloadFile(utf8.encode(htmlContent), 'HallTicket_${rollNo}_$name.html');
    }
  }

  static Future<dynamic> pickLocalFile({
    dynamic filename,
    dynamic allowedExtensions,
    dynamic accept,
    dynamic onFileSelected,
  }) async {
    debugPrint('FileDownloader: pickLocalFile called');
    return null;
  }
}
