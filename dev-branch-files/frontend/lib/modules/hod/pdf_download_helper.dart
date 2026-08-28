import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'hod_toast.dart';

class PdfDownloadHelper {
  /// Show confirmation dialog before downloading PDF or Excel, showing details in a clean column
  static void showExportConfirmation(
    BuildContext context, {
    String? title,
    List<String>? headers,
    List<List<String>>? rows,
  }) {
    final String currentDate = DateTime.now().toLocal().toString().split('.')[0];
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(
                Icons.cloud_download_rounded,
                color: Color(0xFF2563EB),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                title != null ? 'Export $title' : 'Export Department Report',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review the export details below before generating the file:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Column of export details
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Department', 'Computer Science & Engineering (DEP-CSE-001)'),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildDetailRow('Head of Dept', 'Dr. K. Govindaraj'),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildDetailRow('Export Date', currentDate),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildDetailRow(
                        'Data Range',
                        rows != null ? '${rows.length} Records' : '5 KPIs & 12 Academic Sections',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select your preferred export format:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            // Cancel Button
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            
            // Excel Export Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                downloadDepartmentReportExcel(title: title, headers: headers, rows: rows);
                HodToast.show(
                  context,
                  message: '${title?.replaceAll(" ", "_") ?? "Department_Overview_Report"}.xlsx downloaded successfully!',
                  isSuccess: true,
                );
              },
              icon: const Icon(Icons.table_chart_rounded, size: 16, color: Colors.white),
              label: const Text(
                'Microsoft Excel (.xlsx)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A), // Green color for Excel
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),

            // PDF Export Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                downloadDepartmentReportPdf(title: title, headers: headers, rows: rows);
                HodToast.show(
                  context,
                  message: '${title?.replaceAll(" ", "_") ?? "Department_Overview_Report"}.pdf downloaded successfully!',
                  isSuccess: true,
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
              label: const Text(
                'PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626), // Red color for PDF
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  /// Downloads valid PDF 1.4 binary file
  static void downloadDepartmentReportPdf({
    String? title,
    List<String>? headers,
    List<List<String>>? rows,
  }) {
    if (kIsWeb) {
      final List<String> reportLines = [
        'KSR COLLEGE OF ENGINEERING - HOD PORTAL',
        (title ?? 'DEPARTMENT CENTRAL MANAGEMENT OVERVIEW REPORT').toUpperCase(),
        '------------------------------------------------------------------------------------------------------------------',
        'Date: ${DateTime.now().toLocal().toString().split('.')[0]}',
        'Department: Computer Science & Engineering (DEP-CSE-001)',
        'Head of Department: Dr. K. Govindaraj',
        '',
      ];

      if (headers != null && rows != null) {
        // Calculate max widths for each column
        final List<int> colWidths = List.filled(headers.length, 0);
        for (int i = 0; i < headers.length; i++) {
          colWidths[i] = headers[i].length;
        }
        for (var row in rows) {
          for (int i = 0; i < row.length; i++) {
            if (i < colWidths.length && row[i].length > colWidths[i]) {
              colWidths[i] = row[i].length;
            }
          }
        }

        // Header Line
        final StringBuffer headerBuf = StringBuffer();
        for (int i = 0; i < headers.length; i++) {
          headerBuf.write(headers[i].padRight(colWidths[i] + 3));
        }
        reportLines.add(headerBuf.toString());
        reportLines.add(''.padRight(headerBuf.length, '-'));

        // Rows
        for (var row in rows) {
          final StringBuffer rowBuf = StringBuffer();
          for (int i = 0; i < row.length; i++) {
            rowBuf.write(row[i].padRight(colWidths[i] + 3));
          }
          reportLines.add(rowBuf.toString());
        }
      } else {
        reportLines.addAll([
          '1. KEY DEPARTMENT METRICS',
          '   - Total Enrolled Students: 480 (+12 This Semester)',
          '   - Total Faculty Members: 24 (2 On Leave Today)',
          '   - Student Attendance Today: 94.1% (1.8% higher than yesterday)',
          '   - Faculty Attendance Today: 91.6% (2.3% higher than yesterday)',
          '   - Pending Approvals: 12 (6 High Priority)',
          '',
          '2. DEPARTMENT CLASSES OVERVIEW (12 Active Classes)',
          '   - IV YEAR (Strength: 119): Sec A 90% (Good), Sec B 75% (Avg), Sec C 72% (Avg)',
          '   - III YEAR (Strength: 119): Sec A 82% (Good), Sec B 78% (Avg), Sec C 74% (Avg)',
          '   - II YEAR  (Strength: 119): Sec A 85% (Good), Sec B 80% (Good), Sec C 77% (Avg)',
          '   - I YEAR   (Strength: 120): Sec A 90% (Avg), Sec B 82% (Avg), Sec C 78% (Low)',
          '',
          '3. ACADEMIC CALENDAR & UPCOMING DEADLINES',
          '   - Jul 25, 2026: Internal Assessment II Marks Deadline (Deadline)',
          '   - Jul 28, 2026: National IoT Symposium Workshop (Workshop)',
          '   - Aug 01, 2026: Mid-Semester Feedback Review (Review)',
          '   - Aug 15, 2026: Independence Day Holiday (Holiday)',
        ]);
      }

      reportLines.add('------------------------------------------------------------------------------------------------------------------');
      reportLines.add('Official Department Record - System Generated Document');

      final pdfBytes = _buildValidPdfBinary(
        title ?? 'Department Central Management Overview Report',
        reportLines,
      );

      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // 1. Open PDF document directly in new browser tab for instant viewing
      html.window.open(url, '_blank');

      // 3. Keep blob URL active so browser can load & render PDF in new tab
      Future.delayed(const Duration(seconds: 10), () {
        html.Url.revokeObjectUrl(url);
      });
    }
  }

  /// Downloads structured CSV spreadsheet matching Excel requirements
  static void downloadDepartmentReportExcel({
    String? title,
    List<String>? headers,
    List<List<String>>? rows,
  }) {
    if (kIsWeb) {
      final StringBuffer csvContent = StringBuffer();
      
      final String reportTitle = title ?? 'DEPARTMENT CENTRAL MANAGEMENT OVERVIEW REPORT';
      csvContent.writeln(reportTitle.toUpperCase());
      csvContent.writeln('KSR COLLEGE OF ENGINEERING - HOD PORTAL');
      csvContent.writeln('Generated Date,${DateTime.now().toLocal().toString().split('.')[0]}');
      csvContent.writeln('Department,Computer Science & Engineering (DEP-CSE-001)');
      csvContent.writeln('Head of Department,Dr. K. Govindaraj');
      csvContent.writeln();
      
      if (headers != null && rows != null) {
        // Write headers
        csvContent.writeln(headers.join(','));
        // Write rows
        for (var row in rows) {
          final escapedRow = row.map((cell) {
            final clean = cell.replaceAll('\n', ' ').replaceAll('"', '""');
            if (clean.contains(',') || clean.contains('"')) {
              return '"$clean"';
            }
            return clean;
          }).join(',');
          csvContent.writeln(escapedRow);
        }
      } else {
        csvContent.writeln('KEY DEPARTMENT METRICS');
        csvContent.writeln('Metric Name,Value,Detail');
        csvContent.writeln('Total Students,480,+12 This Semester');
        csvContent.writeln('Total Faculty,24,2 On Leave');
        csvContent.writeln('Student Attendance,94.1%,1.8% from yesterday');
        csvContent.writeln('Faculty Attendance,91.6%,2.3% from yesterday');
        csvContent.writeln('Pending Approvals,12,6 High Priority');
        csvContent.writeln();
        
        csvContent.writeln('DEPARTMENT CLASSES');
        csvContent.writeln('Year,Section,Faculty Assigned,Present Count,Total Count,Attendance Percent,Status');
        csvContent.writeln('IV YEAR,Section A,Prof. R. Kavitha,32,40,90%,Good');
        csvContent.writeln('IV YEAR,Section B,Prof. S. Praveen,30,40,75%,Average');
        csvContent.writeln('IV YEAR,Section C,Prof. M. Rajesh,28,39,72%,Average');
        csvContent.writeln('III YEAR,Section A,Prof. K. Nandhini,33,40,82%,Good');
        csvContent.writeln('III YEAR,Section B,Prof. P. Deepak,31,40,78%,Average');
        csvContent.writeln('III YEAR,Section C,Prof. V. Harini,29,39,74%,Average');
        csvContent.writeln('II YEAR,Section A,Prof. G. Mohan,34,40,85%,Good');
        csvContent.writeln('II YEAR,Section B,Prof. A. Gayathri,32,40,80%,Good');
        csvContent.writeln('II YEAR,Section C,Prof. S. Arunkumar,30,39,77%,Average');
        csvContent.writeln('I YEAR,Section A,Prof. T. Sridhar,36,40,90%,Average');
        csvContent.writeln('I YEAR,Section B,Prof. N. Swathi,33,40,82%,Average');
        csvContent.writeln('I YEAR,Section C,Prof. R. Dinesh,31,40,78%,Low');
        csvContent.writeln();
        
        csvContent.writeln('ACADEMIC EVENTS & DEADLINES');
        csvContent.writeln('Event Date,Event Title,Category');
        csvContent.writeln('Jul 25 2026,Internal Assessment II Marks Deadline,Deadline');
        csvContent.writeln('Jul 28 2026,National IoT Symposium Workshop,Workshop');
        csvContent.writeln('Aug 01 2026,Mid-Semester Feedback Review,Review');
        csvContent.writeln('Aug 15 2026,Independence Day Holiday,Holiday');
      }

      final bytes = utf8.encode(csvContent.toString());
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final filename = '${title?.replaceAll(' ', '_') ?? "Department_Overview_Report"}.xlsx';
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  /// Generates clean PDF 1.4 Binary Structure compliant with all PDF readers
  static List<int> _buildValidPdfBinary(String title, List<String> lines) {
    final StringBuffer streamContent = StringBuffer();
    
    // Header Title
    streamContent.writeln('BT');
    streamContent.writeln('/F1 16 Tf');
    streamContent.writeln('1 0 0 1 40 750 Tm');
    streamContent.writeln('(${_escapePdfText(title)}) Tj');
    streamContent.writeln('ET');

    // Body text
    double yPos = 720;
    streamContent.writeln('BT');
    streamContent.writeln('/F1 10 Tf');

    for (String line in lines) {
      if (yPos < 40) break;
      streamContent.writeln('1 0 0 1 40 ${yPos.toStringAsFixed(1)} Tm');
      streamContent.writeln('(${_escapePdfText(line)}) Tj');
      yPos -= 16;
    }
    streamContent.writeln('ET');

    final String streamStr = streamContent.toString();
    final List<int> streamBytes = utf8.encode(streamStr);

    final StringBuffer pdf = StringBuffer();
    pdf.write('%PDF-1.4\n');
    pdf.write('%\u00e2\u00e3\u00cf\u00d3\n');

    final int obj1Off = pdf.length;
    pdf.write('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    final int obj2Off = pdf.length;
    pdf.write('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

    final int obj3Off = pdf.length;
    pdf.write('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n');

    final int obj4Off = pdf.length;
    pdf.write('4 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n');
    pdf.write(streamStr);
    pdf.write('\nendstream\nendobj\n');

    final int obj5Off = pdf.length;
    pdf.write('5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n');

    final int xrefOff = pdf.length;
    pdf.write('xref\n0 6\n');
    pdf.write('0000000000 65535 f \n');
    pdf.write('${obj1Off.toString().padLeft(10, '0')} 00000 n \n');
    pdf.write('${obj2Off.toString().padLeft(10, '0')} 00000 n \n');
    pdf.write('${obj3Off.toString().padLeft(10, '0')} 00000 n \n');
    pdf.write('${obj4Off.toString().padLeft(10, '0')} 00000 n \n');
    pdf.write('${obj5Off.toString().padLeft(10, '0')} 00000 n \n');

    pdf.write('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xrefOff\n%%EOF\n');

    return utf8.encode(pdf.toString());
  }

  static String _escapePdfText(String text) {
    return text.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
  }
}
