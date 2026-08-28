// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../widgets/academic_year_dropdown.dart';
import '../widgets/student_loading_widget.dart';
import 'dart:html' as html;
import 'dart:convert';

class SubjectMarks {
  final String sNo;
  final String code;
  final String name;
  final double credits;
  final String assessment;
  final String cia1;
  final String cia2;
  final String model;
  final String internal;
  final String semester;
  final double total;
  final double maxMarks;
  final String grade;
  final double gradePoint;
  final String status;
  final String type;
  final String facultyName;
  final String facultyRole;
  final String rating;
  final String remarks;
  final Map<String, dynamic> questionMarks;

  const SubjectMarks({
    required this.sNo,
    required this.code,
    required this.name,
    required this.credits,
    this.assessment = 'CIA - I',
    required this.cia1,
    required this.cia2,
    required this.model,
    required this.internal,
    required this.semester,
    required this.total,
    this.maxMarks = 100.0,
    required this.grade,
    required this.gradePoint,
    required this.status,
    required this.type,
    required this.facultyName,
    this.facultyRole = 'Faculty',
    this.rating = 'Excellent',
    this.remarks = '',
    this.questionMarks = const {},
  });

  double get partATotal {
    double sum = 0;
    questionMarks.forEach((key, val) {
      if (key.toLowerCase().contains('part a')) {
        sum += double.tryParse(val.toString()) ?? 0;
      }
    });
    return sum;
  }

  double get partBTotal {
    double sum = 0;
    questionMarks.forEach((key, val) {
      if (key.toLowerCase().contains('part b')) {
        sum += double.tryParse(val.toString()) ?? 0;
      }
    });
    return sum;
  }
}

class MarksScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const MarksScreen({super.key, this.onNavigate});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  // Filter states
  String _selectedYear = '2025-26';
  String _selectedSemFilter = 'V';
  String _selectedRegFilter = 'R24';
  String _selectedAssessFilter = 'All (CIA + Sem)';
  bool _isLoading = false;

  // Search and Table Filter states
  String _searchQuery = '';
  String _selectedType = 'All Types';
  String _selectedStatus = 'All Status';

  // Table pagination state
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  // ScrollController for subject performance carousel
  final ScrollController _subjectScrollController = ScrollController();

  List<SubjectMarks> _getSubjectsForSemester(String sem) {
    final appState = AppStateProvider.of(context);
    final dbMarks = appState.marksList;

    // Convert Roman numeral to integer
    int semInt = 1;
    switch (sem.toUpperCase()) {
      case 'I': semInt = 1; break;
      case 'II': semInt = 2; break;
      case 'III': semInt = 3; break;
      case 'IV': semInt = 4; break;
      case 'V': semInt = 5; break;
      case 'VI': semInt = 6; break;
      case 'VII': semInt = 7; break;
      case 'VIII': semInt = 8; break;
    }

    final studentDept = appState.getProfileField('department', defaultValue: 'CSE').toString().toUpperCase();

    // Get all matching regulations for this semester & department
    final activeRegs = appState.regulationsList.where((reg) {
      final regSem = int.tryParse(reg['semester']?.toString() ?? '') ?? 0;
      final regDept = reg['department']?.toString().toUpperCase() ?? '';
      return regSem == semInt && regDept == studentDept;
    }).toList();

    // Sort regulations by course code for consistency
    activeRegs.sort((a, b) {
      final codeA = a['course_code']?.toString() ?? '';
      final codeB = b['course_code']?.toString() ?? '';
      return codeA.compareTo(codeB);
    });

    final List<SubjectMarks> list = [];
    int index = 1;

    for (var reg in activeRegs) {
      final code = reg['course_code']?.toString() ?? '';
      final name = reg['course_name']?.toString() ?? '';
      final credits = double.tryParse(reg['credits']?.toString() ?? '3.0') ?? 3.0;
      final type = reg['course_type']?.toString() ?? 'Theory';

      // Find matching row in internal_marks if it exists
      final matchingRow = dbMarks.firstWhere(
        (m) => m['subject_code']?.toString().toUpperCase() == code.toUpperCase(),
        orElse: () => <String, dynamic>{},
      );

      final hasMarks = matchingRow.isNotEmpty;
      final cia1 = hasMarks ? (matchingRow['cia_1']?.toString() ?? '-') : '-';
      final cia2 = hasMarks ? (matchingRow['cia_2']?.toString() ?? '-') : '-';
      final finalMarkStr = hasMarks ? (matchingRow['final_40']?.toString() ?? '-') : '-';
      final double finalMark = hasMarks ? (double.tryParse(finalMarkStr) ?? 0.0) : 0.0;

      String grade = '-';
      double gradePoint = 0.0;
      String status = '-';

      if (hasMarks) {
        status = finalMark >= 20.0 ? 'Passed' : 'Backlog';
        if (finalMark >= 36) { grade = 'O'; gradePoint = 10.0; }
        else if (finalMark >= 32) { grade = 'A+'; gradePoint = 9.0; }
        else if (finalMark >= 28) { grade = 'A'; gradePoint = 8.0; }
        else if (finalMark >= 24) { grade = 'B+'; gradePoint = 7.0; }
        else if (finalMark >= 20) { grade = 'B'; gradePoint = 6.0; }
        else if (finalMark >= 16) { grade = 'C'; gradePoint = 5.0; }
        else { grade = 'RA'; gradePoint = 0.0; }
      }

      // Find allocated faculty from facultyCourseAllocations
      String resolvedFacultyName = 'Mr. P. Kalaiyarasan';
      String resolvedFacultyRole = 'Assistant Professor';

      final empAlloc = appState.facultyCourseAllocations.firstWhere(
        (alloc) => (alloc['course_code'] ?? '').toString().toUpperCase() == code.toUpperCase(),
        orElse: () => <String, dynamic>{},
      );
      if (empAlloc.isNotEmpty) {
        final empId = (empAlloc['faculty_employee_id'] ?? '').toString();
        final faculty = appState.faculties.firstWhere(
          (f) => (f['employee_id'] ?? '').toString() == empId,
          orElse: () => <String, dynamic>{},
        );
        if (faculty.isNotEmpty) {
          resolvedFacultyName = (faculty['full_name'] ?? faculty['name'] ?? empId).toString();
          resolvedFacultyRole = (faculty['designation'] ?? 'Assistant Professor').toString();
        } else {
          resolvedFacultyName = empId;
        }
      } else if (matchingRow['faculty_name'] != null) {
        resolvedFacultyName = matchingRow['faculty_name'].toString();
        resolvedFacultyRole = (matchingRow['faculty_role'] ?? 'Assistant Professor').toString();
      }

      list.add(SubjectMarks(
        sNo: (index++).toString(),
        code: code,
        name: name,
        credits: credits,
        assessment: 'CIA',
        cia1: cia1,
        cia2: cia2,
        model: '-',
        internal: finalMarkStr,
        semester: finalMarkStr,
        total: finalMark,
        maxMarks: 40.0,
        grade: grade,
        gradePoint: gradePoint,
        status: status,
        type: type,
        facultyName: resolvedFacultyName,
        facultyRole: resolvedFacultyRole,
        remarks: hasMarks ? 'Good Performance' : '',
        questionMarks: const {},
      ));
    }

    return list;
  }

  double _calculateSgpa(List<SubjectMarks> subjects) {
    if (subjects.isEmpty) return 0.0;
    double totalPoints = 0;
    double totalCredits = 0;
    for (var sub in subjects) {
      totalPoints += sub.gradePoint * sub.credits;
      totalCredits += sub.credits;
    }
    return totalPoints / totalCredits;
  }

  List<SubjectMarks> get _filteredSubjects {
    final subjects = _getSubjectsForSemester(_selectedSemFilter);
    return subjects.where((subject) {
      final matchesSearch = subject.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          subject.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          subject.facultyName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _selectedType == 'All Types' || subject.type == _selectedType;
      
      final matchesStatus = _selectedStatus == 'All Status' || 
          (_selectedStatus == 'Passed' && subject.status != 'Backlog') ||
          (_selectedStatus == 'Backlog' && subject.status == 'Backlog');
          
      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  // Download PDF Report Sheet
  void _downloadReport() {
    final appState = AppStateProvider.of(context);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSemFilter == 'V';
    final cgpaVal = appState.getProfileField('cgpa');
    final cgpaStr = (!isCurrentActive || cgpaVal.isEmpty) ? '0.00' : cgpaVal;
    
    final currentSubjects = _getSubjectsForSemester(_selectedSemFilter);
    final sgpa = _calculateSgpa(currentSubjects);
    final sgpaStr = sgpa.toStringAsFixed(2);

    final header = '%PDF-1.4\n';
    final body = StringBuffer();
    body.write('BT\n');
    body.write('/F1 18 Tf\n');
    body.write('50 780 Td\n');
    body.write('24 TL\n');
    body.write('(KSRCE ERP - SEMESTER ACADEMIC PERFORMANCE REPORT) Tj T*\n');
    body.write('/F1 12 Tf\n');
    body.write('16 TL\n');
    body.write('0 -10 Td\n');
    body.write('(Academic Year: $_selectedYear | Semester: $_selectedSemFilter) Tj T*\n');
    body.write('() Tj T*\n');
    body.write('(CGPA: $cgpaStr | SGPA: $sgpaStr | Class Rank: 12 / 65) Tj T*\n');
    body.write('() Tj T*\n');
    body.write('(Detailed Subject Grades:) Tj T*\n');
    for (var sub in _filteredSubjects) {
      body.write('(${sub.code} - ${sub.name}: Grade ${sub.grade}, Status: ${sub.status}) Tj T*\n');
    }
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
      ..setAttribute('download', 'academic_performance_${_selectedSemFilter}_semester.pdf')
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Academic report sheet downloaded successfully!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  // Fully functional CSV Export
  void _triggerCsvExport() {
    final filtered = _filteredSubjects;
    String csv = 'S.No,Subject Code,Subject Name,Credits,CIA 1,CIA 2,Model,Internal,Grade,Grade Point,Status\n';
    for (var row in filtered) {
      csv += '${row.sNo},${row.code},${row.name},${row.credits},${row.cia1},${row.cia2},${row.model},${row.internal},${row.grade},${row.gradePoint},${row.status}\n';
    }
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'academic_performance_report_${_selectedSemFilter}_semester.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV Report downloaded successfully!'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  // Fully functional print trigger - prints only the Academic Performance Table
  void _triggerPrint() {
    try {
      final appState = AppStateProvider.of(context);
      final isCurrentActive = appState.isCurrentAcademicYear && _selectedSemFilter == 'V';
      final cgpaVal = appState.getProfileField('cgpa');
      final cgpaStr = (!isCurrentActive || cgpaVal.isEmpty) ? '0.00' : cgpaVal;

      final tables = _getPerformanceTables();
      final StringBuffer htmlContent = StringBuffer();

      htmlContent.write('''<!DOCTYPE html>
<html>
<head>
  <title>Academic Performance Report - Semester $_selectedSemFilter</title>
  <style>
    @page { size: A4 landscape; margin: 10mm; }
    * { box-sizing: border-box; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; padding: 16px; color: #0f172a; }
    h2, h3 { text-align: center; margin: 4px 0; }
    .header { text-align: center; margin-bottom: 20px; border-bottom: 2px solid #2563eb; padding-bottom: 10px; }
    .table-title { background-color: #f1f5f9; border: 1px solid #94a3b8; border-bottom: none; font-size: 11px; font-weight: bold; color: #1e3a8a; padding: 6px 12px; text-align: center; letter-spacing: 0.5px; margin-top: 16px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 16px; font-size: 10px; }
    th { background-color: #eef2f6; border: 1px solid #94a3b8; color: #1e3a8a; padding: 6px; text-align: center; font-weight: bold; }
    td { border: 1px solid #94a3b8; padding: 6px; text-align: center; }
    td.left-align { text-align: left; }
    .footer { margin-top: 28px; font-size: 10px; text-align: center; color: #64748b; }
  </style>
</head>
<body>
  <div class="header">
    <h2 style="color:#1e3a8a;margin:0 0 4px 0;">K.S.R. COLLEGE OF ENGINEERING (AUTONOMOUS)</h2>
    <h3 style="color:#2563eb;margin:0 0 6px 0;">ACADEMIC PERFORMANCE REPORT</h3>
    <p style="font-size:11px;margin:4px 0;color:#475569;">Academic Year: $_selectedYear &nbsp;|&nbsp; Semester: $_selectedSemFilter &nbsp;|&nbsp; CGPA: $cgpaStr &nbsp;|&nbsp; Printed: ${DateTime.now().toString().split(' ')[0]}</p>
  </div>
''');

      for (var table in tables) {
        final filteredRows = table.rows.where((row) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return row.code.toLowerCase().contains(q) || row.title.toLowerCase().contains(q);
        }).toList();

        if (filteredRows.isEmpty && _searchQuery.isNotEmpty) continue;

        htmlContent.write('<div class="table-title">${table.title}</div>');
        htmlContent.write('<table><thead><tr>');
        for (var h in table.headers) {
          htmlContent.write('<th>${h.replaceAll('\n', '<br/>')}</th>');
        }
        htmlContent.write('</tr></thead><tbody>');

        for (var row in filteredRows) {
          htmlContent.write('<tr>');
          htmlContent.write('<td>${row.sNo}</td>');
          htmlContent.write('<td style="font-weight:bold;color:#2563eb;">${row.code}</td>');
          htmlContent.write('<td class="left-align" style="font-weight:500;">${row.title}</td>');
          for (var val in row.values) {
            htmlContent.write('<td>$val</td>');
          }
          htmlContent.write('</tr>');
        }
        htmlContent.write('</tbody></table>');
      }

      htmlContent.write('''
  <div class="footer">KSRCE ERP &mdash; Official Academic Performance Document &mdash; ${DateTime.now().toString().split(' ')[0]}</div>
</body>
</html>''');

      final oldIframe = html.document.getElementById('marks_print_frame');
      if (oldIframe != null) {
        oldIframe.remove();
      }

      final iframe = html.IFrameElement()
        ..id = 'marks_print_frame'
        ..style.position = 'fixed'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.width = '0'
        ..style.height = '0'
        ..style.border = '0'
        ..style.visibility = 'hidden';

      iframe.srcdoc = htmlContent.toString();
      
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

      html.document.body?.append(iframe);
    } catch (_) {
      html.window.print();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 768 && !isDesktop;
    
    final appState = AppStateProvider.of(context);
    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    if (!sems.contains(_selectedSemFilter)) {
      _selectedSemFilter = sems.first;
    }

    if (appState.isLoading || _isLoading) {
      return const SizedBox(
        height: 400,
        child: StudentLoadingWidget(
          size: 60,
          showMessage: false,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 8),

          // 2. Metrics summary cards grid
          _buildMetricsGrid(isDesktop, isTablet),
          const SizedBox(height: 24),

          // 3. Trends & Distributions Charts Row
          _buildChartsRow(isDesktop),
          const SizedBox(height: 24),

          // 4. Subject Performance Overview Horizontal Carousel
          _buildSubjectPerformanceOverview(),
          const SizedBox(height: 28),

          // 5. Actions Bar (Search, filters and actions buttons)
          _buildActionsBar(isDesktop),
          const SizedBox(height: 20),

          // 6. Detailed Performance Table (Hides Semester and Total marks columns)
          _buildDetailedPerformanceTable(),
          const SizedBox(height: 24),

          // 7. Footer sections: Grade Legend & Semester Result Summary
          _buildFooterCards(isDesktop),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final appState = AppStateProvider.of(context);
    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AcademicYearDropdown(),
        const SizedBox(width: 8),
        _buildPillDropdown<String>(
          icon: Icons.school_outlined,
          prefixText: 'Semester',
          value: _selectedSemFilter,
          items: sems,
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedSemFilter = val);
            }
          },
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
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB), size: 16),
          alignment: Alignment.center,
          onChanged: onChanged,
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((T val) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF2563EB), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    '$prefixText ${val.toString().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.3,
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

  // 2. METRICS CARDS GRID (6 stat cards in single row)
  Widget _buildMetricsGrid(bool isDesktop, bool isTablet) {
    int crossAxisCount = 6;
    if (isTablet) {
      crossAxisCount = 3;
    } else if (!isDesktop) {
      crossAxisCount = 2;
    }

    final double cardSpacing = 16.0;
    final currentSubjects = _getSubjectsForSemester(_selectedSemFilter);
    final totalSubjects = currentSubjects.length;
    final totalCredits = currentSubjects.fold<double>(0.0, (prev, element) => prev + element.credits);
    final passedSubjects = currentSubjects.where((s) => s.status != 'Backlog').length;
    final backlogSubjects = currentSubjects.where((s) => s.status == 'Backlog').length;
    
    final sgpa = _calculateSgpa(currentSubjects);
    final sgpaStr = sgpa.toStringAsFixed(2);

    final appState = AppStateProvider.of(context);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSemFilter == 'V';
    final cgpaVal = appState.getProfileField('cgpa');
    final cgpaStr = (!isCurrentActive || cgpaVal.isEmpty) ? '0.00' : cgpaVal;

    final row1Cards = [
      _buildStatCard('CGPA', cgpaStr, 'Till Current Semester', Icons.school, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      _buildStatCard('SGPA ($_selectedSemFilter)', sgpaStr, 'Current Semester', Icons.bar_chart, const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
      _buildStatCard('Subjects', '$totalSubjects', 'Registered', Icons.folder_open, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
    ];

    final row2Cards = [
      _buildStatCard('Credits Earned', '${totalCredits.toInt()}', 'Registered', Icons.layers, const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
      _buildStatCard('Passed', '$passedSubjects', 'All Clear', Icons.check_circle, const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
      _buildStatCard('Backlogs', '$backlogSubjects', 'Outstanding', Icons.cancel, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
    ];

    if (isDesktop) {
      final allCards = [
        _buildStatCard('CGPA', cgpaStr, 'Till Current Semester', Icons.school, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
        _buildStatCard('SGPA ($_selectedSemFilter)', sgpaStr, 'Current Semester', Icons.bar_chart, const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
        _buildStatCard('Subjects', '$totalSubjects', 'Registered', Icons.folder_open, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
        _buildStatCard('Credits Earned', '${totalCredits.toInt()}', 'Registered', Icons.layers, const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
        _buildStatCard('Passed', '$passedSubjects', 'All Clear', Icons.check_circle, const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
        _buildStatCard('Backlogs', '$backlogSubjects', 'Outstanding', Icons.cancel, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
      ];
      return Row(
        children: allCards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
      );
    } else {
      return Column(
        children: [
          Row(
            children: row1Cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: row2Cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // 3. CHARTS ROW (Semester GPA Trend, V Semester Marks Line Chart, Grade Distribution Donut Chart)
  Widget _buildChartsRow(bool isDesktop) {
    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _buildGpaTrendCard()),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: _buildMarksTrendLineCard()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildGradeDistributionCard()),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          _buildGpaTrendCard(),
          const SizedBox(height: 16),
          _buildMarksTrendLineCard(),
          const SizedBox(height: 16),
          _buildGradeDistributionCard(),
        ],
      );
    }
  }

  // GPA Bar Chart Card
  Widget _buildGpaTrendCard() {
    final appState = AppStateProvider.of(context);
    final double maxBarHeight = 120;
    
    final List<String> availableSems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);

    final List<Map<String, dynamic>> barData = [];
    for (var s in availableSems) {
      final subs = _getSubjectsForSemester(s);
      final double val = _calculateSgpa(subs);
      barData.add({'label': 'Sem $s', 'value': val});
    }

    if (barData.isEmpty) {
      final subs = _getSubjectsForSemester(_selectedSemFilter);
      final double val = _calculateSgpa(subs);
      barData.add({'label': 'Sem $_selectedSemFilter', 'value': val});
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Semester GPA Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('GPA', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: barData.map((data) {
              final double val = data['value'] as double;
              final double height = (val / 10.0) * maxBarHeight;
              final isCurrent = data['label'] == 'Sem $_selectedSemFilter';
              return Column(
                children: [
                  Text(
                    val.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 24,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCurrent
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['label'] as String,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Marks Line Chart Card
  Widget _buildMarksTrendLineCard() {
    final currentSubjects = _getSubjectsForSemester(_selectedSemFilter);
    double cia1Sum = 0, cia2Sum = 0, modelSum = 0, internalSum = 0, semSum = 0;
    int cia1Count = 0, cia2Count = 0, modelCount = 0, internalCount = 0, semCount = 0;
    for (var sub in currentSubjects) {
      final c1 = double.tryParse(sub.cia1);
      if (c1 != null) { cia1Sum += c1; cia1Count++; }
      final c2 = double.tryParse(sub.cia2);
      if (c2 != null) { cia2Sum += c2; cia2Count++; }
      final mod = double.tryParse(sub.model);
      if (mod != null) { modelSum += mod; modelCount++; }
      final intern = double.tryParse(sub.internal);
      if (intern != null) { internalSum += intern; internalCount++; }
      final sm = double.tryParse(sub.semester);
      if (sm != null) { semSum += sm; semCount++; }
    }
    
    double val1 = cia1Count > 0 ? (cia1Sum / cia1Count) * (cia1Sum/cia1Count > 50 ? 1.0 : 2.0) : 0;
    double val2 = cia2Count > 0 ? (cia2Sum / cia2Count) * (cia2Sum/cia2Count > 50 ? 1.0 : 2.0) : 0;
    double val3 = modelCount > 0 ? (modelSum / modelCount) * (modelSum/modelCount > 20 ? 1.0 : 5.0) : 0;
    double val4 = internalCount > 0 ? (internalSum / internalCount) * (internalSum/internalCount > 50 ? 1.0 : 2.0) : 0;
    double val5 = semCount > 0 ? (semSum / semCount) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Marks Trend ($_selectedSemFilter Semester)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Percentage (%)', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: LineChartPainter(
                values: [val1, val2, val3, val4, val5],
                labels: const ['CIA 1', 'CIA 2', 'Model', 'Internal', 'Semester'],
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CIA 1 (${val1.toInt()}%)', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Text('CIA 2 (${val2.toInt()}%)', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Text('Model (${val3.toInt()}%)', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Text('Internal (${val4.toInt()}%)', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Text('Semester (${val5.toInt()}%)', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // Grade Distribution Donut Card with updated proportions dynamically
  Widget _buildGradeDistributionCard() {
    final currentSubjects = _getSubjectsForSemester(_selectedSemFilter);
    final total = currentSubjects.length;
    int countO = currentSubjects.where((s) => s.grade == 'O').length;
    int countAp = currentSubjects.where((s) => s.grade == 'A+').length;
    int countA = currentSubjects.where((s) => s.grade == 'A').length;
    int countB = currentSubjects.where((s) => s.grade == 'B').length;
    int countC = currentSubjects.where((s) => s.grade == 'C').length;
    int countRa = currentSubjects.where((s) => s.grade == 'RA').length;

    final List<double> portions = [];
    final List<Color> colors = [];
    if (countO > 0) { portions.add(countO / total); colors.add(const Color(0xFF2563EB)); }
    if (countAp > 0) { portions.add(countAp / total); colors.add(const Color(0xFF16A34A)); }
    if (countA > 0) { portions.add(countA / total); colors.add(const Color(0xFFEA580C)); }
    if (countB > 0) { portions.add(countB / total); colors.add(const Color(0xFF8B5CF6)); }
    if (countC > 0) { portions.add(countC / total); colors.add(const Color(0xFFEC4899)); }
    if (countRa > 0) { portions.add(countRa / total); colors.add(const Color(0xFFDC2626)); }
    if (portions.isEmpty) {
      portions.add(1.0);
      colors.add(const Color(0xFFE2E8F0));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grade Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut Graphic
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: DonutChartPainter(
                        portions: portions,
                        colors: colors,
                      ),
                      child: Container(),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          Text('$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const Text('Subjects', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Legend Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDonutLegendItem(const Color(0xFF2563EB), 'O', '$countO (${(countO / total * 100).toStringAsFixed(1)}%)'),
                    const SizedBox(height: 6),
                    _buildDonutLegendItem(const Color(0xFF16A34A), 'A+', '$countAp (${(countAp / total * 100).toStringAsFixed(1)}%)'),
                    const SizedBox(height: 6),
                    _buildDonutLegendItem(const Color(0xFFEA580C), 'A', '$countA (${(countA / total * 100).toStringAsFixed(1)}%)'),
                    const SizedBox(height: 6),
                    _buildDonutLegendItem(const Color(0xFF8B5CF6), 'B', '$countB (${(countB / total * 100).toStringAsFixed(1)}%)'),
                    const SizedBox(height: 6),
                    _buildDonutLegendItem(const Color(0xFFEC4899), 'C', '$countC (${(countC / total * 100).toStringAsFixed(1)}%)'),
                    const SizedBox(height: 6),
                    _buildDonutLegendItem(const Color(0xFFDC2626), 'RA', '$countRa (${(countRa / total * 100).toStringAsFixed(1)}%)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendItem(Color color, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }

  // 4. SUBJECT PERFORMANCE CAROUSEL ROW
  Widget _buildSubjectPerformanceOverview() {
    final filtered = _filteredSubjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subject Performance Overview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    _subjectScrollController.animateTo(
                      (_subjectScrollController.offset - 270).clamp(0.0, _subjectScrollController.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _subjectScrollController.animateTo(
                      (_subjectScrollController.offset + 270).clamp(0.0, _subjectScrollController.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          controller: _subjectScrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filtered.map((sub) {
              final isPassed = sub.grade != 'RA';
              final color = isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444);

              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            sub.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sub.code,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          sub.grade,
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Academic breakdown metrics
                    _buildCarouselStatRow('Assessment', sub.assessment),
                    _buildCarouselStatRow('Part A Total', '${sub.partATotal.toInt()} / 4'),
                    _buildCarouselStatRow('Part B Total', '${sub.partBTotal.toInt()} / 13'),
                    _buildCarouselStatRow('Overall Total', '${sub.total.toInt()} / ${sub.maxMarks.toInt()}'),
                    const SizedBox(height: 14),

                    // Faculty details
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: Text(
                            sub.facultyName.split(' ').last.substring(0, 1),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.facultyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                sub.facultyRole,
                                style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sub.status == 'Backlog' ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: sub.status == 'Backlog' ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sub.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: sub.status == 'Backlog' ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        ],
      ),
    );
  }

  final GlobalKey _tableSectionKey = GlobalKey();

  void _scrollToSectionTable() {
    final context = _tableSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  // 5. ACTIONS BAR (Search textfield, filter dropdowns, and download buttons)
  Widget _buildActionsBar(bool isDesktop) {
    final searchInput = TextField(
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
          _currentPage = 1;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search subject, code, faculty...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
    );

    final typeDropdown = _buildTableFilterDropdown('All Types', _selectedType, ['All Types', 'Theory', 'Practical'], (val) {
      if (val != null) {
        setState(() {
          _selectedType = val;
          _currentPage = 1;
        });
      }
    });

    final actionButtons = _buildActionButton(Icons.file_upload_outlined, 'Export', _triggerCsvExport);

    if (isDesktop) {
      return Row(
        children: [
          Expanded(flex: 8, child: searchInput),
          const SizedBox(width: 12),
          typeDropdown,
          const Spacer(),
          actionButtons,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchInput,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: typeDropdown),
              const SizedBox(width: 8),
              actionButtons,
            ],
          ),
        ],
      );
    }
  }

  Widget _buildTableFilterDropdown(String hint, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
          style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 12),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
      label: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, String subtitle, {Color? titleColor, double width = 100}) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: titleColor ?? const Color(0xFF2563EB),
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  // 6. ACADEMIC PERFORMANCE TABLE (Subject Code, Name, Credits, Assessment, Status, Remarks)
  List<NCSubTable> _getPerformanceTables() {
    final appState = AppStateProvider.of(context);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSemFilter == 'V';
    if (!isCurrentActive) {
      return [];
    }
    final dbMarks = appState.marksList;
    
    // Group marks by subject code
    final Map<String, List<Map<String, dynamic>>> groupedMarks = {};
    for (var row in dbMarks) {
      final rowAcadYear = row['academic_year']?.toString() ?? '';
      if (rowAcadYear.isNotEmpty && 
          rowAcadYear.replaceAll('–', '-').replaceAll('—', '-').trim() != appState.selectedAcademicYear.replaceAll('–', '-').replaceAll('—', '-').trim()) {
        continue;
      }
      
      final rowSem = row['semester']?.toString() ?? '';
      if (rowSem.isNotEmpty && rowSem.toUpperCase() != _selectedSemFilter.toUpperCase()) {
        continue;
      }
      
      final code = row['subject_code']?.toString() ?? '';
      if (code.isNotEmpty) {
        groupedMarks.putIfAbsent(code, () => []).add(row);
      }
    }
    
    final List<NCTableRow> finalTheory = [];
    final List<NCTableRow> finalSsd = [];
    final List<NCTableRow> finalLab = [];
    final List<NCTableRow> finalTool = [];
    
    // Map selected semester Roman numeral to integer
    int semInt = 1;
    switch (_selectedSemFilter) {
      case 'I': semInt = 1; break;
      case 'II': semInt = 2; break;
      case 'III': semInt = 3; break;
      case 'IV': semInt = 4; break;
      case 'V': semInt = 5; break;
      case 'VI': semInt = 6; break;
      case 'VII': semInt = 7; break;
      case 'VIII': semInt = 8; break;
    }
    
    final studentDept = appState.getProfileField('department', defaultValue: 'CSE').toString().toUpperCase();
    
    // Filter active regulations dynamically
    final activeRegs = appState.regulationsList.where((reg) {
      final regSem = int.tryParse(reg['semester']?.toString() ?? '') ?? 0;
      final regDept = reg['department']?.toString().toUpperCase() ?? '';
      return regSem == semInt && regDept == studentDept;
    }).toList();
    
    // Sort regulations by course code for consistency
    activeRegs.sort((a, b) {
      final codeA = a['course_code']?.toString() ?? '';
      final codeB = b['course_code']?.toString() ?? '';
      return codeA.compareTo(codeB);
    });
    
    int sNoCounter = 1;
    for (var reg in activeRegs) {
      final code = reg['course_code']?.toString() ?? '';
      final name = reg['course_name']?.toString() ?? '';
      final regType = reg['course_type']?.toString().toLowerCase() ?? '';
      
      // Determine course category
      bool isLab = regType.contains('lab') || regType.contains('practical') || name.toLowerCase().contains('laboratory') || code.toLowerCase().contains('lab') || code.toUpperCase().contains('ITP') || code.toUpperCase().contains('CSP');
      bool isSSD = regType.contains('ssd') || name.toLowerCase().contains('soft skills') || code.toUpperCase().contains('SDP');
      bool isTool = regType.contains('tool') || name.toLowerCase().contains('tool course') || code.toUpperCase().contains('CBI') || name.toLowerCase().contains('java programming');
      
      final dbRows = groupedMarks[code] ?? [];
      
      String cia1 = '-';
      String cia2 = '-';
      String a1 = '-';
      String a2 = '-';
      String cie1 = '-';
      String cie2 = '-';
      String cieLab1 = '-';
      String cieLab2 = '-';
      String record = '-';
      String att = '-';
      String finalMark = '-';

      if (dbRows.isNotEmpty) {
        final r = dbRows.first;
        cia1 = r['cia_1']?.toString() ?? '-';
        cia2 = r['cia_2']?.toString() ?? '-';
        a1 = r['a1']?.toString() ?? '-';
        a2 = r['a2']?.toString() ?? '-';
        cie1 = r['cia_1']?.toString() ?? '-';
        cieLab1 = r['cia_1']?.toString() ?? '-';
        cie2 = r['cia_2']?.toString() ?? '-';
        cieLab2 = r['cia_2']?.toString() ?? '-';
        record = r['a1']?.toString() ?? '-';
        att = r['attendance_5']?.toString() ?? '-';
        finalMark = r['final_40']?.toString() ?? '-';

        final avg20Val = r['cia_avg_20']?.toString() ?? '-';
        final avg15Val = r['assignment_avg_15']?.toString() ?? '-';
        final int40Val = r['internal_40_float']?.toString() ?? '-';

        if (isSSD) {
          finalSsd.add(NCTableRow(
            (sNoCounter++).toString(),
            code,
            name,
            [cie1, cie2, avg20Val, int40Val, finalMark],
          ));
        } else if (isLab) {
          finalLab.add(NCTableRow(
            (sNoCounter++).toString(),
            code,
            name,
            [cieLab1, cieLab2, avg20Val, record, att, int40Val, finalMark],
          ));
        } else if (isTool) {
          finalTool.add(NCTableRow(
            (sNoCounter++).toString(),
            code,
            name,
            [cieLab1, cieLab2, avg20Val, att, record, int40Val, finalMark],
          ));
        } else {
          finalTheory.add(NCTableRow(
            (sNoCounter++).toString(),
            code,
            name,
            [cia1, cia2, avg20Val, a1, a2, avg15Val, att, int40Val, finalMark],
          ));
        }
      } else {
        if (isSSD) {
          finalSsd.add(NCTableRow(
            (sNoCounter++).toString(),
            code,
            name,
            [cie1, cie2, '-', '-', finalMark],
          ));
        } else if (isLab) {
          finalLab.add(NCTableRow(
            (sNoCounter++).toString(),
            code,
            name,
            [cieLab1, cieLab2, '-', record, att, '-', finalMark],
          ));
        } else if (isTool) {
          finalTool.add(NCTableRow(
            (sNoCounter++).toString(),
            code,
            name,
            [cieLab1, cieLab2, '-', att, record, '-', finalMark],
          ));
        } else {
          finalTheory.add(NCTableRow(
            (sNoCounter++).toString(),
            code,
            name,
            [cia1, cia2, '-', a1, a2, '-', att, '-', finalMark],
          ));
        }
      }
    }
    
    final String labelYear = appState.selectedAcademicYear;
    final List<NCSubTable> activeTables = [];

    final showTheory = _selectedType == 'All Types' || _selectedType == 'Theory';
    final showPractical = _selectedType == 'All Types' || _selectedType == 'Practical';

    if (showTheory && finalTheory.isNotEmpty) {
      activeTables.add(NCSubTable(
        'Y26 R24-$labelYear EVEN NON INTEGRATED THEORY UG',
        ['S.No', 'Course Code', 'Course Title', 'CIA 1\n(50)', 'CIA 2\n(50)', 'Avg of 2\n(20)', 'A1\n(50)', 'A2\n(50)', 'Avg of 2\n(15)', 'ATTENDANCE\n(5)', 'Internal\n(40)', 'Final\n(40.0)'],
        const {
          0: FlexColumnWidth(1.0),
          1: FlexColumnWidth(2.0),
          2: FlexColumnWidth(5.0),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1.5),
          5: FlexColumnWidth(1.8),
          6: FlexColumnWidth(1.5),
          7: FlexColumnWidth(1.5),
          8: FlexColumnWidth(1.8),
          9: FlexColumnWidth(2.2),
          10: FlexColumnWidth(1.8),
          11: FlexColumnWidth(1.8),
        },
        finalTheory,
      ));
    }
    if (showTheory && finalSsd.isNotEmpty) {
      activeTables.add(NCSubTable(
        'Y26 R24-$labelYear EVEN SSD',
        ['S.No', 'Course Code', 'Course Title', 'CIE 1\n(50)', 'CIE 2\n(50)', 'Avg of 2\n(60)', 'Internal\n(60)', 'Final\n(60.0)'],
        const {
          0: FlexColumnWidth(1.0),
          1: FlexColumnWidth(2.0),
          2: FlexColumnWidth(5.0),
          3: FlexColumnWidth(1.8),
          4: FlexColumnWidth(1.8),
          5: FlexColumnWidth(2.0),
          6: FlexColumnWidth(2.0),
          7: FlexColumnWidth(1.8),
        },
        finalSsd,
      ));
    }
    if (showPractical && finalLab.isNotEmpty) {
      activeTables.add(NCSubTable(
        'Y26 R24-$labelYear EVEN LAB',
        ['S.No', 'Course Code', 'Course Title', 'CIE LAB 1\n(100)', 'CIE LAB 2\n(100)', 'Avg of 2\n(25)', 'RECORD\n(75)', 'ATT\n(5)', 'Internal\n(105)', 'Final\n(60.0)'],
        const {
          0: FlexColumnWidth(1.0),
          1: FlexColumnWidth(2.0),
          2: FlexColumnWidth(5.0),
          3: FlexColumnWidth(2.0),
          4: FlexColumnWidth(2.0),
          5: FlexColumnWidth(1.8),
          6: FlexColumnWidth(1.8),
          7: FlexColumnWidth(1.5),
          8: FlexColumnWidth(2.0),
          9: FlexColumnWidth(1.8),
        },
        finalLab,
      ));
    }
    if (showPractical && finalTool.isNotEmpty) {
      activeTables.add(NCSubTable(
        'Y26 R24-$labelYear EVEN TOOL COURSE',
        ['S.No', 'Course Code', 'Course Title', 'CIE LAB 1\n(50)', 'CIE LAB 2\n(50)', 'Avg of 2\n(25)', 'ATT\n(5)', 'RECORD\n(75)', 'Internal\n(105)', 'Final\n(50.0)'],
        const {
          0: FlexColumnWidth(1.0),
          1: FlexColumnWidth(2.0),
          2: FlexColumnWidth(5.0),
          3: FlexColumnWidth(1.8),
          4: FlexColumnWidth(1.8),
          5: FlexColumnWidth(1.8),
          6: FlexColumnWidth(1.5),
          7: FlexColumnWidth(1.8),
          8: FlexColumnWidth(2.0),
          9: FlexColumnWidth(1.8),
        },
        finalTool,
      ));
    }
    return activeTables;
  }

  Widget _buildDetailedPerformanceTable() {
    final tables = _getPerformanceTables();
    final List<Widget> subTableWidgets = [];

    for (var table in tables) {
      final filteredRows = table.rows.where((row) {
        if (_searchQuery.isEmpty) return true;
        final q = _searchQuery.toLowerCase();
        return row.code.toLowerCase().contains(q) ||
            row.title.toLowerCase().contains(q);
      }).toList();

      if (filteredRows.isEmpty && _searchQuery.isNotEmpty) continue;

      subTableWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(
                  top: BorderSide(color: Color(0xFFCBD5E1)),
                  left: BorderSide(color: Color(0xFFCBD5E1)),
                  right: BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              child: Text(
                table.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Table(
              border: TableBorder.all(color: const Color(0xFF94A3B8), width: 1.0),
              columnWidths: table.columnWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2F6),
                  ),
                  children: table.headers.map((h) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Text(
                        h,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ...filteredRows.map((row) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          row.sNo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          row.code,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          row.title,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      ...row.values.map((val) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            val,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    if (subTableWidgets.isEmpty) {
      subTableWidgets.add(
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No subjects match your filters.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ),
      );
    }

    return Container(
      key: _tableSectionKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Academic Performance Table',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktopWidth = constraints.maxWidth > 1000;
                final tableContent = Column(
                  children: subTableWidgets,
                );

                if (isDesktopWidth) {
                  return SizedBox(
                    width: double.infinity,
                    child: tableContent,
                  );
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1100, // scrollable on mobile/tablet view
                      child: tableContent,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 7. FOOTER CARDS: Grade Legend & Semester Result Summary
  Widget _buildFooterCards(bool isDesktop) {
    return const SizedBox.shrink();
  }

  // Grade Legend Card block with updated grading scale
  Widget _buildGradeLegendCard() {
    final legends = [
      {'grade': 'O', 'range': '90 - 100', 'desc': 'Outstanding'},
      {'grade': 'A', 'range': '80 - 89', 'desc': 'Excellent'},
      {'grade': 'A+', 'range': '70 - 79', 'desc': 'Very Good'},
      {'grade': 'B', 'range': '60 - 69', 'desc': 'Good'},
      {'grade': 'C', 'range': '50 - 59', 'desc': 'Average'},
      {'grade': 'RA', 'range': '< 50', 'desc': 'Re-Appear'},
    ];

    return Container(
      width: 350,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grade Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Column(
            children: legends.map((leg) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        leg['grade']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: leg['grade'] == 'RA' ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(':  ${leg['range']!}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: leg['grade'] == 'RA' ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        leg['desc']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: leg['grade'] == 'RA' ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Result Summary Card block
  Widget _buildResultSummaryCard() {
    final appState = AppStateProvider.of(context);
    final currentSubjects = _getSubjectsForSemester(_selectedSemFilter);
    final int totalSubjects = currentSubjects.length;
    
    double totalCredits = 0;
    int passedCount = 0;
    int backlogCount = 0;
    
    for (var sub in currentSubjects) {
      totalCredits += sub.credits;
      if (sub.status.toLowerCase() == 'backlog' || sub.grade == 'RA' || sub.status.toLowerCase() == 'fail') {
        backlogCount++;
      } else {
        passedCount++;
      }
    }
    
    final sgpa = _calculateSgpa(currentSubjects);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSemFilter == 'V';
    final cgpaStr = (!isCurrentActive || appState.getProfileField('cgpa').isEmpty) ? '0.00' : appState.getProfileField('cgpa');
    
    final bool isPass = backlogCount == 0 && totalSubjects > 0;
    final String resultText = totalSubjects == 0 ? '-' : (isPass ? 'PASS' : 'RA');
    final Color resultBg = isPass ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
    final Color resultTextCol = isPass ? const Color(0xFF065F46) : const Color(0xFF991B1B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Semester Result Summary ($_selectedSemFilter)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResultIndicatorItem('Subjects', totalSubjects.toString(), Icons.menu_book, const Color(0xFF2563EB)),
              _buildResultIndicatorItem('Credits', totalCredits.toStringAsFixed(0), Icons.layers, const Color(0xFF0D9488)),
              _buildResultIndicatorItem('Passed', passedCount.toString(), Icons.check_circle, const Color(0xFF16A34A)),
              _buildResultIndicatorItem('Backlogs', backlogCount.toString(), Icons.cancel, const Color(0xFFDC2626)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('SGPA', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(sgpa.toStringAsFixed(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Column(
                children: [
                  const Text('CGPA', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(cgpaStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Column(
                children: [
                  const Text('Result', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: resultBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      resultText,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: resultTextCol),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultIndicatorItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }
}

// LineChartPainter class (custom draws line and shading)
class LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  LineChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final dotPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final double width = size.width;
    final double height = size.height;

    // Grid lines (y=0, 25, 50, 75, 100%)
    for (int i = 0; i <= 4; i++) {
      final double y = height - (i * height / 4);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    final double xStep = width / (values.length - 1);
    final List<Offset> points = [];

    for (int i = 0; i < values.length; i++) {
      final double val = values[i];
      final double x = i * xStep;
      final double y = height - (val / 100.0 * height);
      points.add(Offset(x, y));
    }

    // Shaded gradient area under line
    final fillPath = Path()..moveTo(points[0].dx, height);
    for (var point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, height);
    fillPath.close();

    final gradient = LinearGradient(
      colors: [
        const Color(0xFF2563EB).withValues(alpha: 0.15),
        const Color(0xFF2563EB).withValues(alpha: 0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    fillPaint.shader = gradient.createShader(Rect.fromLTRB(0, 0, width, height));
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    // Draw point circles
    for (var point in points) {
      canvas.drawCircle(point, 6, dotPaint);
      canvas.drawCircle(point, 6, dotOuterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// DonutChartPainter class (custom draws donut arcs)
class DonutChartPainter extends CustomPainter {
  final List<double> portions;
  final List<Color> colors;

  DonutChartPainter({required this.portions, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double strokeWidth = 18;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -3.14159265 / 2;

    for (int i = 0; i < portions.length; i++) {
      final double sweepAngle = portions[i] * 2 * 3.14159265;
      if (sweepAngle > 0) {
        paint.color = colors[i];
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
          startAngle + 0.05,
          sweepAngle - 0.1,
          false,
          paint,
        );
      }
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NCTableRow {
  final String sNo;
  final String code;
  final String title;
  final List<String> values;
  const NCTableRow(this.sNo, this.code, this.title, this.values);
}

class NCSubTable {
  final String title;
  final List<String> headers;
  final Map<int, TableColumnWidth> columnWidths;
  final List<NCTableRow> rows;
  const NCSubTable(this.title, this.headers, this.columnWidths, this.rows);
}
