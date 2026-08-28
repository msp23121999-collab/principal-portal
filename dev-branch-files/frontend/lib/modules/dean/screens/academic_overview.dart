// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/bento_card.dart';

class AcademicOverviewScreen extends StatefulWidget {
  const AcademicOverviewScreen({super.key});

  @override
  State<AcademicOverviewScreen> createState() => _AcademicOverviewScreenState();
}

class _AcademicOverviewScreenState extends State<AcademicOverviewScreen> {
  String selectedDept = 'All Departments';
  String selectedProgramme = 'All Programmes';
  String selectedSemester = 'All Semesters';

  void _exportReport(BuildContext context, DeanAppState appState) {
    final String csvContent = _generateCsvReport(appState);
    try {
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'academic_overview_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      anchor.click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Export error: $e');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Academic Overview Report exported successfully!'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _generateCsvReport(DeanAppState appState) {
    final sb = StringBuffer();
    sb.writeln('CAMS Engineering - Academic Overview Report');
    sb.writeln('Export Date,${DateTime.now().toIso8601String()}');
    sb.writeln('Department Filter,$selectedDept');
    sb.writeln('Programme Filter,$selectedProgramme');
    sb.writeln('Semester Filter,$selectedSemester');
    sb.writeln();
    sb.writeln('Key Metrics');
    sb.writeln('Total Students,${appState.studentsData.length}');
    sb.writeln('Total Faculty,${appState.facultiesData.length}');
    sb.writeln('Total Programmes,${appState.regulationsData.length}');
    sb.writeln('Total Courses Offered,${appState.markSheetsData.length}');
    sb.writeln('Overall Pass Percentage,${appState.calculatedOverallPassPercentage.toStringAsFixed(2)}%');
    sb.writeln('Average SGPA,${appState.calculatedAverageSGPA.toStringAsFixed(2)}');
    sb.writeln();
    sb.writeln('Department Wise Academic Summary');
    sb.writeln('S.No,Department,Students,Faculty,Courses,Avg SGPA,Pass %,Backlog %,Placement %');
    sb.writeln('1,Computer Science & Engineering,1256,72,48,8.78,92.35%,12.45%,91.20%');
    sb.writeln('2,Information Technology,1102,65,42,8.65,93.41%,11.02%,93.41%');
    sb.writeln('3,Electronics & Communication,1045,68,46,8.32,90.12%,14.12%,88.33%');
    sb.writeln('4,Mechanical Engineering,987,63,44,7.95,87.68%,16.35%,82.10%');
    sb.writeln('5,Civil Engineering,658,40,28,7.72,85.23%,18.75%,78.60%');
    sb.writeln('6,Artificial Intelligence & DS,876,50,32,8.62,91.28%,10.28%,90.12%');
    sb.writeln('7,MBA,512,28,18,8.41,91.85%,8.65%,88.67%');
    sb.writeln('8,MCA,420,26,16,8.33,89.74%,11.23%,87.50%');
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    final students = appState.studentsData;
    final faculties = appState.facultiesData;
    final markSheets = appState.markSheetsData;

    final deptOptions = ['All Departments', 'CSE', 'IT', 'IoT', 'ECE', 'EEE', 'MECH', 'CIVIL', 'AI & DS', 'MBA', 'MCA'];
    final progOptions = ['All Programmes', 'B.E.', 'B.Tech', 'M.E.', 'M.Tech', 'MBA', 'MCA', 'Ph.D.'];

    final selectedDeptStudents = (selectedDept == 'All Departments')
      ? students
      : students
          .where((s) {
            final d = (s['department'] ?? s['dept'] ?? '').toString();
            return _isDeptMatch(d, selectedDept);
          })
          .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Filter Row & Export Report Button
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildFilterDropdown(selectedDept, deptOptions, (val) => setState(() => selectedDept = val!)),
                    _buildFilterDropdown(selectedProgramme, progOptions, (val) => setState(() => selectedProgramme = val!)),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DeanTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedDept = 'All Departments';
                          selectedProgramme = 'All Programmes';
                        });
                      },
                      child: const Text('Reset', style: TextStyle(color: DeanTheme.textMuted, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _exportReport(context, appState),
                icon: const Icon(Icons.download, size: 16, color: DeanTheme.textDark),
                label: const Text('Export Report', style: TextStyle(fontSize: 12, color: DeanTheme.textDark, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: const BorderSide(color: DeanTheme.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. At a Glance 8 Metric Badges (Replaces Old Top Metric Cards)
          _buildAtAGlanceGrid(context, appState),
          const SizedBox(height: 24),

          // 3. Row 1: Individual Department View Section
          Row(
            children: [
              const Icon(Icons.apartment, size: 18, color: DeanTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                selectedDept == 'All Departments'
                    ? 'Individual Department View (Select a Department to Filter)'
                    : 'Individual Department View — $selectedDept',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
              ),
              if (selectedDept != 'All Departments') ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: selectedDeptStudents.isNotEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedDeptStudents.isNotEmpty ? '${selectedDeptStudents.length} Active Students' : '0 Students',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selectedDeptStudents.isNotEmpty ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          if (isDesktop)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _buildStudentsTrendCard(appState, selectedDept)),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildPassBySemesterCard(appState, selectedDept)),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildAcademicHighlightsCard(appState, selectedDept)),
                ],
              ),
            )
          else
            Column(
              children: [
                _buildStudentsTrendCard(appState, selectedDept),
                const SizedBox(height: 16),
                _buildPassBySemesterCard(appState, selectedDept),
                const SizedBox(height: 16),
                _buildAcademicHighlightsCard(appState, selectedDept),
              ],
            ),
          const SizedBox(height: 24),

          // 4. Row 2: Overall Department View Section
          Row(
            children: [
              const Icon(Icons.analytics, size: 18, color: DeanTheme.primaryBlue),
              const SizedBox(width: 8),
              const Text(
                'Overall Department View (Institutional Summary)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Extended Department Wise Academic Summary Table (No horizontal scrolling)
                Expanded(
                  flex: 7,
                  child: _buildDepartmentSummaryTableCard(appState),
                ),
                const SizedBox(width: 16),
                // 2. Average SGPA by Dept + Backlog Analysis stacked vertically as 2 cards
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildSgpaByDeptCard(appState),
                      const SizedBox(height: 16),
                      _buildBacklogAnalysisCard(appState),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildDepartmentSummaryTableCard(appState),
                const SizedBox(height: 16),
                _buildSgpaByDeptCard(appState),
                const SizedBox(height: 16),
                _buildBacklogAnalysisCard(appState),
              ],
            ),
        ],
      ),
    );
  }

  // --- Filter Dropdown Helper ---
  Widget _buildFilterDropdown(String selectedVal, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DeanTheme.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(selectedVal) ? selectedVal : options.first,
          isDense: true,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: DeanTheme.textDark),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: DeanTheme.textMuted),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }



  // --- Row 1 Card 1: Students Trend Line Chart ---
  Widget _buildStudentsTrendCard(DeanAppState appState, String selectedDept) {
    final localStudents = appState.studentsData;

    final filteredStudents = (selectedDept == 'All Departments')
        ? localStudents
        : localStudents.where((s) {
            final d = (s['department'] ?? s['dept'] ?? '').toString();
            return _isDeptMatch(d, selectedDept);
          }).toList();

    final bool hasData = filteredStudents.isNotEmpty;

    return BentoCard(
      title: 'Students Trend',
      headerWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: DeanTheme.primaryBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Batch: 2024-25',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue),
        ),
      ),
      child: Column(
        children: [
          if (!hasData && selectedDept != 'All Departments')
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 28, color: DeanTheme.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'No student records available for $selectedDept department.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: DeanTheme.textMuted),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 180,
              child: CustomPaint(
                size: Size.infinite,
                painter: _StudentsTrendPainter(hasData: hasData, totalStudents: filteredStudents.length),
              ),
            ),
          const SizedBox(height: 12),
          // Legend fixed BELOW the chart
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 3, color: const Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  const Text('2023 - 2024', style: TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(width: 12, height: 3, color: DeanTheme.primaryBlue),
                  const SizedBox(width: 6),
                  const Text('2024 - 2025', style: TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isDeptMatch(String rawDbDept, String targetCode) {
    final d = rawDbDept.trim().toUpperCase();
    final target = targetCode.trim().toUpperCase();
    if (d.isEmpty || target.isEmpty) return false;
    if (d == target) return true;

    final Map<String, List<String>> aliases = {
      'CSE': ['COMPUTER SCIENCE', 'CSE', 'COMPUTER SCIENCE & ENGINEERING', 'COMPUTER SCIENCE AND ENGINEERING'],
      'IT': ['INFORMATION TECHNOLOGY', 'IT'],
      'IOT': ['INTERNET OF THINGS', 'IOT', 'INTERNET OF THINGS (IOT)'],
      'AI & DS': ['ARTIFICIAL INTELLIGENCE', 'AI & DS', 'AIDS', 'AI AND DS', 'DATA SCIENCE'],
      'ECE': ['ELECTRONICS & COMMUNICATION', 'ELECTRONICS AND COMMUNICATION', 'ECE'],
      'EEE': ['ELECTRICAL & ELECTRONICS', 'ELECTRICAL AND ELECTRONICS', 'EEE'],
      'MECH': ['MECHANICAL', 'MECH', 'MECHANICAL ENGINEERING'],
      'CIVIL': ['CIVIL', 'CIVIL ENGINEERING'],
      'MBA': ['BUSINESS ADMINISTRATION', 'MBA', 'MASTER OF BUSINESS ADMINISTRATION'],
      'MCA': ['COMPUTER APPLICATIONS', 'MCA', 'MASTER OF COMPUTER APPLICATIONS'],
    };

    final list = aliases[target];
    if (list != null) {
      for (final a in list) {
        if (d == a || d.contains(a) || a.contains(d)) return true;
      }
    }

    return d.contains(target) || target.contains(d);
  }

  // --- Row 1 Card 2: Pass Percentage by Semester ---
  Widget _buildPassBySemesterCard(DeanAppState appState, String selectedDept) {
    final localStudents = appState.studentsData;

    final filteredStudents = (selectedDept == 'All Departments')
      ? localStudents
      : localStudents.where((s) {
        final d = (s['department'] ?? s['dept'] ?? '').toString();
        return _isDeptMatch(d, selectedDept);
        }).toList();

    final List<String> sems = ['I Sem', 'II Sem', 'III Sem', 'IV Sem', 'V Sem', 'VI Sem', 'VII Sem'];
    final semData = sems.map((sem) {
      if (filteredStudents.isNotEmpty) {
        final semNum = sems.indexOf(sem) + 1;
        final matching = filteredStudents.where((s) {
          final semVal = (s['semester'] ?? s['sem'] ?? '').toString().trim();
          return semVal == sem || semVal == semNum.toString() || semVal == 'Semester $semNum';
        }).toList();
        if (matching.isNotEmpty) {
          int passed = matching.where((s) => (double.tryParse(s['cgpa']?.toString() ?? '0') ?? 0.0) >= 5.0).length;
          return {'sem': sem, 'val': (passed / matching.length) * 100.0};
        }
      }
      return {'sem': sem, 'val': 0.0};
    }).toList();

    final bool hasData = filteredStudents.isNotEmpty;

    return BentoCard(
      title: 'Pass Percentage by Semester',
      headerWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: DeanTheme.primaryBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Batch: 2024-25',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue),
        ),
      ),
      child: (!hasData && selectedDept != 'All Departments')
          ? Container(
              height: 205,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bar_chart, size: 28, color: DeanTheme.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'No student records available for $selectedDept department.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: DeanTheme.textMuted),
                  ),
                ],
              ),
            )
          : SizedBox(
              height: 205,
              child: CustomPaint(
                size: Size.infinite,
                painter: _SemesterPassRatePainter(data: semData),
              ),
            ),
    );
  }

  // --- Row 1 Card 3: Academic Highlights ---
  Widget _buildAcademicHighlightsCard(DeanAppState appState, String selectedDept) {
    final localStudents = appState.studentsData;

    final filteredStudents = (selectedDept == 'All Departments')
        ? localStudents
        : localStudents.where((s) {
            final d = (s['department'] ?? s['dept'] ?? '').toString();
            return _isDeptMatch(d, selectedDept);
          }).toList();

    final hasData = filteredStudents.isNotEmpty;

    double deptPassPct = 0.0;
    double deptAvgSgpa = 0.0;
    double deptBacklogPct = 0.0;

    if (hasData) {
      int passed = 0;
      double sgpaSum = 0;
      int backlog = 0;
      for (final s in filteredStudents) {
        final cgpa = double.tryParse(s['cgpa']?.toString() ?? '0') ?? 0.0;
        sgpaSum += cgpa;
        if (cgpa >= 5.0) passed++;
        if (cgpa > 0 && cgpa < 6.0) backlog++;
      }
      deptPassPct = (passed / filteredStudents.length) * 100.0;
      deptAvgSgpa = sgpaSum / filteredStudents.length;
      deptBacklogPct = (backlog / filteredStudents.length) * 100.0;
    }

    final highlights = [
      {
        'icon': Icons.emoji_events,
        'color': const Color(0xFF9333EA),
        'bg': const Color(0xFFF3E8FF),
        'title': 'Highest Pass Percentage',
        'sub': hasData
            ? (selectedDept == 'All Departments'
                ? 'Calculated Pass Rate: ${appState.calculatedOverallPassPercentage.toStringAsFixed(2)}%'
                : '$selectedDept Pass Rate: ${deptPassPct.toStringAsFixed(2)}%')
            : 'No Data for $selectedDept'
      },
      {
        'icon': Icons.school,
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFE0F2FE),
        'title': 'Highest Average SGPA',
        'sub': hasData
            ? (selectedDept == 'All Departments'
                ? 'Institutional Average: ${appState.calculatedAverageSGPA.toStringAsFixed(2)}'
                : '$selectedDept Average: ${deptAvgSgpa.toStringAsFixed(2)}')
            : 'No Data for $selectedDept'
      },
      {
        'icon': Icons.trending_up,
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFDCFCE7),
        'title': 'Most Improved Department',
        'sub': hasData ? (selectedDept == 'All Departments' ? 'Active Department Benchmark' : '$selectedDept Active') : 'No Data for $selectedDept'
      },
      {
        'icon': Icons.business_center,
        'color': const Color(0xFFEA580C),
        'bg': const Color(0xFFFFEDD5),
        'title': 'Top Placement Rate',
        'sub': hasData ? 'Department Placement Rate' : 'No Data for $selectedDept'
      },
      {
        'icon': Icons.access_time,
        'color': const Color(0xFFE11D48),
        'bg': const Color(0xFFFFE4E6),
        'title': 'Lowest Backlog Percentage',
        'sub': hasData
                ? (selectedDept == 'All Departments'
                ? 'Backlog Rate: ${((appState.backlogStudentsCount / (localStudents.isNotEmpty ? localStudents.length : 1)) * 100).toStringAsFixed(2)}%'
                : '$selectedDept Backlog: ${deptBacklogPct.toStringAsFixed(2)}%')
            : 'No Data for $selectedDept'
      },
    ];

    return BentoCard(
      title: 'Academic Highlights',
      headerWidget: selectedDept != 'All Departments'
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                selectedDept,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
              ),
            )
          : null,
      child: Column(
        children: highlights.map((h) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: h['bg'] as Color, borderRadius: BorderRadius.circular(10)),
                  child: Icon(h['icon'] as IconData, color: h['color'] as Color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h['title'].toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                      Text(h['sub'].toString(), style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Lower-Middle Card 1: Department Summary Table ---
  Widget _buildDepartmentSummaryTableCard(DeanAppState appState) {
    final localStudents = appState.studentsData;
    final localFaculties = appState.facultiesData;
    final localMarkSheets = appState.markSheetsData;

    final totalStudentsStr = localStudents.isNotEmpty ? localStudents.length.toString() : '0';
    final totalFacultyStr = localFaculties.isNotEmpty ? localFaculties.length.toString() : '0';
    final totalCoursesStr = localMarkSheets.isNotEmpty ? localMarkSheets.length.toString() : '0';
    final overallPassStr = appState.calculatedOverallPassPercentage > 0 ? '${appState.calculatedOverallPassPercentage.toStringAsFixed(2)}%' : '0.00%';

    final deptsList = [
      'Computer Science & Engineering',
      'Information Technology',
      'Internet of Things',
      'Electronics & Communication',
      'Mechanical Engineering',
      'Civil Engineering',
      'Artificial Intelligence & DS',
      'MBA',
      'MCA'
    ];

    final rowsData = deptsList.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final deptName = entry.value;

      final deptStudents = localStudents.where((s) {
        final d = (s['department'] ?? s['dept'] ?? '').toString();
        return _isDeptMatch(d, deptName);
      }).toList();

      final deptFaculty = localFaculties.where((f) {
        final d = (f['department'] ?? f['dept'] ?? '').toString();
        return _isDeptMatch(d, deptName);
      }).toList();

      final deptCourses = localMarkSheets.where((m) {
        final d = (m['department'] ?? m['dept'] ?? '').toString();
        return _isDeptMatch(d, deptName);
      }).toList();

      double avgSgpa = 0.0;
      double passPct = 0.0;
      double backlogPct = 0.0;

      if (deptStudents.isNotEmpty) {
        double sgpaSum = 0;
        int passedCount = 0;
        int backlogCount = 0;

        for (final s in deptStudents) {
          final cgpa = double.tryParse(s['cgpa']?.toString() ?? '0') ?? 0.0;
          sgpaSum += cgpa;
          if (cgpa >= 5.0) passedCount++;
          if (cgpa > 0 && cgpa < 6.0) backlogCount++;
        }

        avgSgpa = sgpaSum / deptStudents.length;
        passPct = (passedCount / deptStudents.length) * 100.0;
        backlogPct = (backlogCount / deptStudents.length) * 100.0;
      }

      return {
        'id': '$idx',
        'name': deptName,
        'students': deptStudents.isNotEmpty ? deptStudents.length.toString() : '0',
        'faculty': deptFaculty.isNotEmpty ? deptFaculty.length.toString() : '0',
        'courses': deptCourses.isNotEmpty ? deptCourses.length.toString() : '0',
        'sgpa': avgSgpa > 0 ? avgSgpa.toStringAsFixed(2) : '0.00',
        'pass': passPct > 0 ? '${passPct.toStringAsFixed(2)}%' : '0.00%',
        'backlog': backlogPct > 0 ? '${backlogPct.toStringAsFixed(2)}%' : '0.00%',
        'placement': '0.00%',
      };
    }).toList();

    return BentoCard(
      title: 'Department Wise Academic Summary',
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: DeanTheme.cardBorder, width: 1)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 20, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark))),
                Expanded(flex: 16, child: Text('Department', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark))),
                Expanded(flex: 6, child: Text('Students', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark))),
                Expanded(flex: 6, child: Text('Faculty', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark))),
                Expanded(flex: 6, child: Text('Courses', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark))),
                Expanded(flex: 6, child: Text('Avg SGPA', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark))),
                Expanded(flex: 7, child: Text('Pass %', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark))),
                Expanded(flex: 8, child: Text('Backlog %', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark))),
                Expanded(flex: 9, child: Text('Placement %', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark))),
              ],
            ),
          ),
          // Data Rows
          ...rowsData.map((r) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 0.5)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 20, child: Text(r['id']!, style: const TextStyle(fontSize: 11, color: DeanTheme.textMuted))),
                  Expanded(flex: 16, child: Text(r['name']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 6, child: Text(r['students']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 6, child: Text(r['faculty']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 6, child: Text(r['courses']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 6, child: Text(r['sgpa']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 7, child: Text(r['pass']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: DeanTheme.successGreen, fontWeight: FontWeight.bold))),
                  Expanded(flex: 8, child: Text(r['backlog']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: DeanTheme.dangerRose))),
                  Expanded(flex: 9, child: Text(r['placement']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),
          // Overall Summary Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                const Expanded(flex: 16, child: Text('Overall', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue))),
                Expanded(flex: 6, child: Text(totalStudentsStr, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 6, child: Text(totalFacultyStr, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 6, child: Text(totalCoursesStr, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 6, child: Text(appState.calculatedAverageSGPA > 0 ? appState.calculatedAverageSGPA.toStringAsFixed(2) : '0.00', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 7, child: Text(overallPassStr, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: DeanTheme.successGreen, fontWeight: FontWeight.bold))),
                const Expanded(flex: 8, child: Text('0.00%', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: DeanTheme.dangerRose, fontWeight: FontWeight.bold))),
                const Expanded(flex: 9, child: Text('0.00%', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Lower-Middle Card 2: Average SGPA by Department ---
  Widget _buildSgpaByDeptCard(DeanAppState appState) {
    final deptsList = ['CSE', 'IT', 'IoT', 'AI & DS', 'ECE', 'MCA', 'MBA', 'MECH'];
    final localStudents = appState.studentsData;

    final deptSgpaData = deptsList.map((code) {
      if (localStudents.isNotEmpty) {
        final matching = localStudents.where((s) {
          final d = (s['department'] ?? s['dept'] ?? '').toString();
          return _isDeptMatch(d, code);
        }).toList();
        if (matching.isNotEmpty) {
          double sum = 0;
          for (final s in matching) {
            sum += double.tryParse(s['cgpa']?.toString() ?? '0') ?? 0.0;
          }
          return {'code': code, 'val': sum / matching.length};
        }
      }
      return {'code': code, 'val': 0.0};
    }).toList();

    return BentoCard(
      title: 'Average SGPA by Department',
      child: SizedBox(
        height: 195,
        child: CustomPaint(
          size: Size.infinite,
          painter: _DeptSgpaPainter(depts: deptSgpaData),
        ),
      ),
    );
  }

  // --- Lower-Middle Card 3: Backlog Analysis ---
  Widget _buildBacklogAnalysisCard(DeanAppState appState) {
    final localStudents = appState.studentsData;

    final totalStudents = localStudents.length;
    final backlogCount = appState.backlogStudentsCount;
    final backlogPctStr = totalStudents > 0 ? '${((backlogCount / totalStudents) * 100.0).toStringAsFixed(2)}%' : '0.00%';

    return BentoCard(
      title: 'Backlog Analysis',
      child: SizedBox(
        height: 115,
        child: Row(
          children: [
            // Donut Chart
            SizedBox(
              width: 105,
              height: 105,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(105, 105),
                    painter: _BacklogDonutPainter(hasData: appState.studentsData.isNotEmpty, backlogPct: totalStudents > 0 ? (backlogCount / totalStudents) : 0.0),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(backlogPctStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                      const Text('Overall Backlog', style: TextStyle(fontSize: 8, color: DeanTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Legend
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _buildLegendItem('Less than 5%', localStudents.isNotEmpty ? '(0 Dept.)' : '(0 Dept.)', const Color(0xFF16A34A)),
                  _buildLegendItem('5% - 10%', localStudents.isNotEmpty ? '(0 Dept.)' : '(0 Dept.)', DeanTheme.primaryBlue),
                  _buildLegendItem('10% - 15%', localStudents.isNotEmpty ? '(0 Dept.)' : '(0 Dept.)', const Color(0xFFEA580C)),
                  _buildLegendItem('15% - 20%', localStudents.isNotEmpty ? '(0 Dept.)' : '(0 Dept.)', const Color(0xFFE11D48)),
                  _buildLegendItem('More than 20%', localStudents.isNotEmpty ? '(0 Dept.)' : '(0 Dept.)', const Color(0xFF9333EA)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
          const Spacer(),
          Text(count, style: const TextStyle(fontSize: 9, color: DeanTheme.textMuted)),
        ],
      ),
    );
  }

  // --- Bottom Section: At a Glance 8 Metric Badges ---
  Widget _buildAtAGlanceGrid(BuildContext context, DeanAppState appState) {
    final activeCoursesVal = appState.markSheetsData.isNotEmpty ? appState.markSheetsData.length.toString() : (appState.regulationsData.isNotEmpty ? appState.regulationsData.length.toString() : '0');
    final electiveCoursesVal = appState.regulationsData.isNotEmpty
        ? appState.regulationsData.where((r) => (r['category'] ?? r['course_type'] ?? '').toString().toLowerCase().contains('elective')).length.toString()
        : '0';
    final phdCount = appState.facultiesData.where((f) => (f['qualification'] ?? f['designation'] ?? '').toString().contains('Ph.D')).length;
    final phdVal = appState.facultiesData.isNotEmpty ? '${((phdCount / appState.facultiesData.length) * 100).round()}%' : '0%';
    final fdpCount = appState.calendarEventsData.where((e) => (e['event_type'] ?? e['title'] ?? '').toString().toLowerCase().contains('fdp')).length;
    final internshipCount = appState.studentsData.where((s) => (s['status'] ?? s['placement_status'] ?? '').toString().toLowerCase().contains('internship')).length;

    final items = [
      {'title': 'Active Courses', 'val': activeCoursesVal, 'icon': Icons.menu_book, 'color': DeanTheme.primaryBlue},
      {'title': 'Elective Courses', 'val': electiveCoursesVal, 'icon': Icons.star, 'color': const Color(0xFF0284C7)},
      {'title': 'Value Added Courses', 'val': '0', 'icon': Icons.add_circle, 'color': const Color(0xFF16A34A)},
      {'title': 'Faculty with Ph.D.', 'val': phdVal, 'icon': Icons.school, 'color': const Color(0xFF0284C7)},
      {'title': 'FDPs Conducted', 'val': fdpCount.toString(), 'icon': Icons.co_present, 'color': const Color(0xFF9333EA)},
      {'title': 'Students in Internships', 'val': internshipCount.toString(), 'icon': Icons.work, 'color': const Color(0xFF0284C7)},
      {'title': 'Research Publications (YTD)', 'val': appState.researchProjectsData.isNotEmpty ? '${appState.researchProjectsData.length}' : '0', 'icon': Icons.description, 'color': const Color(0xFF9333EA)},
      {'title': 'Patents Filed (YTD)', 'val': '0', 'icon': Icons.military_tech, 'color': const Color(0xFFE11D48)},
    ];

    return BentoCard(
      title: 'At a Glance',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int count = constraints.maxWidth < 600 ? 2 : (constraints.maxWidth < 1100 ? 4 : 8);
          final double itemWidth = (constraints.maxWidth - (12 * (count - 1))) / count;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
              return Container(
                width: itemWidth,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: DeanTheme.bgCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DeanTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(item['icon'] as IconData, size: 20, color: item['color'] as Color),
                    const SizedBox(height: 4),
                    Text(item['title'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: DeanTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text(item['val'].toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTERS FOR CHARTS
// ==========================================

// 1. Students Trend Painter (Line Chart)
class _StudentsTrendPainter extends CustomPainter {
  final bool hasData;
  final int totalStudents;

  _StudentsTrendPainter({required this.hasData, required this.totalStudents});

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPad = 25.0;
    final double rightPad = 15.0;
    final double bottomPad = 25.0;
    final double topPad = 15.0;

    final double width = size.width - leftPad - rightPad;
    final double height = size.height - topPad - bottomPad;

    final List<String> sems = ['I Sem', 'II Sem', 'III Sem', 'IV Sem', 'V Sem', 'VI Sem', 'VII Sem', 'VIII Sem'];
    final List<double> prevYear = hasData ? List.filled(8, totalStudents * 0.95) : List.filled(8, 0.0);
    final List<double> currYear = hasData ? List.filled(8, totalStudents.toDouble()) : List.filled(8, 0.0);

    final double minVal = 0;
    final double maxVal = hasData ? (totalStudents > 0 ? totalStudents * 1.2 : 100) : 100;

    final Paint gridPaint = Paint()..color = const Color(0xFFF1F5F9)..strokeWidth = 1;
    final Paint linePrevPaint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 2..style = PaintingStyle.stroke;
    final Paint lineCurrPaint = Paint()..color = DeanTheme.primaryBlue..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final Paint dotPaint = Paint()..color = DeanTheme.primaryBlue..style = PaintingStyle.fill;

    for (int i = 0; i <= 5; i++) {
      final double y = topPad + (height * (1 - i / 5));
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      final valLabel = hasData ? '${((maxVal / 5) * i).round()}' : '${i * 20}';
      final TextPainter tp = TextPainter(
        text: TextSpan(text: valLabel, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - 4));
    }

    final double stepX = width / (sems.length - 1);

    final Path prevPath = Path();
    final Path currPath = Path();

    for (int i = 0; i < sems.length; i++) {
      final double x = leftPad + (i * stepX);

      final double prevY = topPad + (height * (1 - (prevYear[i] - minVal) / (maxVal - minVal)));
      final double currY = topPad + (height * (1 - (currYear[i] - minVal) / (maxVal - minVal)));

      if (i == 0) {
        prevPath.moveTo(x, prevY);
        currPath.moveTo(x, currY);
      } else {
        prevPath.lineTo(x, prevY);
        currPath.lineTo(x, currY);
      }

      if (hasData) {
        canvas.drawCircle(Offset(x, currY), 3.5, dotPaint);
      }

      final TextPainter xtp = TextPainter(
        text: TextSpan(text: sems[i], style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
        textDirection: TextDirection.ltr,
      )..layout();
      xtp.paint(canvas, Offset(x - (xtp.width / 2), size.height - bottomPad + 6));
    }

    if (hasData) {
      canvas.drawPath(prevPath, linePrevPaint);
      canvas.drawPath(currPath, lineCurrPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 2. Semester Pass Rate Painter (Bar Chart)
class _SemesterPassRatePainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _SemesterPassRatePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPad = 25.0;
    final double rightPad = 15.0;
    final double bottomPad = 25.0;
    final double topPad = 20.0;

    final double width = size.width - leftPad - rightPad;
    final double height = size.height - topPad - bottomPad;

    final Paint gridPaint = Paint()..color = const Color(0xFFF1F5F9)..strokeWidth = 1;
    final Paint barPaint = Paint()..color = DeanTheme.primaryBlue..style = PaintingStyle.fill;

    for (int i = 0; i <= 5; i++) {
      final double y = topPad + (height * (1 - i / 5));
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      final TextPainter tp = TextPainter(
        text: TextSpan(text: '${i * 20}%', style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - 4));
    }

    final double barGroupWidth = width / data.length;
    final double barWidth = barGroupWidth * 0.45;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double val = (item['val'] as num).toDouble();
      final double centerX = leftPad + (i * barGroupWidth) + (barGroupWidth / 2);
      final double barLeft = centerX - (barWidth / 2);

      final double barHeight = (val / 100.0) * height;
      final double barTop = topPad + (height - barHeight);

      if (val > 0) {
        final RRect rect = RRect.fromRectAndRadius(Rect.fromLTWH(barLeft, barTop, barWidth, barHeight), const Radius.circular(3));
        canvas.drawRRect(rect, barPaint);
      }

      final TextPainter valTp = TextPainter(
        text: TextSpan(text: '${val.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        textDirection: TextDirection.ltr,
      )..layout();
      valTp.paint(canvas, Offset(centerX - (valTp.width / 2), barTop - 12));

      final TextPainter xtp = TextPainter(
        text: TextSpan(text: item['sem'].toString(), style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
        textDirection: TextDirection.ltr,
      )..layout();
      xtp.paint(canvas, Offset(centerX - (xtp.width / 2), size.height - bottomPad + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 3. Dept SGPA Painter (Horizontal Bar Chart)
class _DeptSgpaPainter extends CustomPainter {
  final List<Map<String, dynamic>> depts;

  _DeptSgpaPainter({required this.depts});

  @override
  void paint(Canvas canvas, Size size) {
    final double labelWidth = 45.0;
    final double rightPad = 25.0;
    final double topPad = 10.0;
    final double bottomPad = 20.0;

    final double width = size.width - labelWidth - rightPad;
    final double height = size.height - topPad - bottomPad;

    final double rowHeight = height / depts.length;
    final double barHeight = rowHeight * 0.45;

    final Paint barPaint = Paint()..color = DeanTheme.primaryBlue..style = PaintingStyle.fill;
    final Paint gridPaint = Paint()..color = const Color(0xFFF1F5F9)..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final double x = labelWidth + (width * (i / 5));
      canvas.drawLine(Offset(x, topPad), Offset(x, size.height - bottomPad), gridPaint);

      final TextPainter tp = TextPainter(
        text: TextSpan(text: '${i * 2}', style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - (tp.width / 2), size.height - bottomPad + 4));
    }

    for (int i = 0; i < depts.length; i++) {
      final item = depts[i];
      final double val = (item['val'] as num).toDouble();
      final double y = topPad + (i * rowHeight) + (rowHeight / 2) - (barHeight / 2);

      final TextPainter ltp = TextPainter(
        text: TextSpan(text: item['code'].toString(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        textDirection: TextDirection.ltr,
      )..layout();
      ltp.paint(canvas, Offset(labelWidth - ltp.width - 6, y + (barHeight / 2) - (ltp.height / 2)));

      final double barW = (val / 10.0) * width;
      if (barW > 0) {
        final RRect rect = RRect.fromRectAndRadius(Rect.fromLTWH(labelWidth, y, barW, barHeight), const Radius.circular(3));
        canvas.drawRRect(rect, barPaint);
      }

      final TextPainter vtp = TextPainter(
        text: TextSpan(text: val.toStringAsFixed(2), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        textDirection: TextDirection.ltr,
      )..layout();
      vtp.paint(canvas, Offset(labelWidth + barW + 4, y + (barHeight / 2) - (vtp.height / 2)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 4. Backlog Donut Painter
class _BacklogDonutPainter extends CustomPainter {
  final bool hasData;
  final double backlogPct;

  _BacklogDonutPainter({required this.hasData, required this.backlogPct});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 14.0;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (min(size.width, size.height) - strokeWidth) / 2,
    );

    if (!hasData || backlogPct == 0) {
      final Paint bgPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);
      return;
    }

    final double sweep = backlogPct * 2 * pi;
    final Paint activePaint = Paint()
      ..color = DeanTheme.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final Paint restPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, -pi / 2, sweep, false, activePaint);
    canvas.drawArc(rect, -pi / 2 + sweep, 2 * pi - sweep, false, restPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
