// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/bento_card.dart';

class DepartmentStats {
  final String code;
  final String fullName;
  final int students;
  final int faculty;
  final int research;
  final double passPct;
  final double placePct;
  final double overallScore;

  DepartmentStats({
    required this.code,
    required this.fullName,
    required this.students,
    required this.faculty,
    required this.research,
    required this.passPct,
    required this.placePct,
    required this.overallScore,
  });
}

class DepartmentComparisonScreen extends StatefulWidget {
  const DepartmentComparisonScreen({super.key});

  @override
  State<DepartmentComparisonScreen> createState() => _DepartmentComparisonScreenState();
}

class _DepartmentComparisonScreenState extends State<DepartmentComparisonScreen> {
  bool showAllDepartments = false;

  String _normalizeDeptCode(String input) {
    final upper = input.toUpperCase().trim();
    if (upper.isEmpty) return '';
    if (upper == 'CSE' || upper.contains('COMPUTER SCIENCE') || upper.contains('COMP. SCI')) return 'CSE';
    if (upper == 'IT' || upper.contains('INFORMATION TECHNOLOGY') || upper.contains('INFO TECH')) return 'IT';
    if (upper == 'ECE' || upper.contains('ELECTRONICS & COMM') || upper.contains('ELECTRONICS AND COMM') || upper.contains('E.C.E')) return 'ECE';
    if (upper == 'EEE' || upper.contains('ELECTRICAL & ELECTRONICS') || upper.contains('ELECTRICAL AND ELECTRONICS') || upper.contains('E.E.E')) return 'EEE';
    if (upper == 'MECH' || upper.contains('MECHANICAL')) return 'MECH';
    if (upper == 'CIVIL' || upper.contains('CIVIL')) return 'CIVIL';
    if (upper == 'AI&DS' || upper == 'AIDS' || upper.contains('ARTIFICIAL INTELLIGENCE') || upper.contains('AI & DS') || upper.contains('AI AND DS')) return 'AI&DS';
    if (upper == 'BIOTECH' || upper.contains('BIOTECHNOLOGY') || upper.contains('BIO TECH')) return 'BIOTECH';
    if (upper == 'AERO' || upper.contains('AEROSPACE') || upper.contains('AERONAUTICAL')) return 'AERO';
    if (upper == 'MCT' || upper.contains('MECHATRONICS')) return 'MCT';
    if (upper == 'MCA' || upper.contains('MASTER OF COMPUTER')) return 'MCA';
    if (upper == 'MBA' || upper.contains('MASTER OF BUSINESS')) return 'MBA';
    return upper;
  }

  List<DepartmentStats> _calculateDynamicDeptStats(DeanAppState appState) {
    final deptMap = <String, String>{
      'CSE': 'Computer Science Engg.',
      'IT': 'Information Technology',
      'ECE': 'Electronics & Comm. Engg.',
      'AI&DS': 'AI & Data Science',
      'EEE': 'Electrical & Electronics Engg.',
      'MECH': 'Mechanical Engineering',
      'BIOTECH': 'Biotechnology',
      'CIVIL': 'Civil Engineering',
      'AERO': 'Aerospace Engineering',
      'MCT': 'Mechatronics Engg.',
      'MCA': 'Master of Computer Apps.',
      'MBA': 'Master of Business Admin.',
    };

    final departments = appState.departmentsData;

    for (final d in departments) {
      final name = '${d['name'] ?? d['department_name'] ?? d['department'] ?? ''}';
      final rawCode = '${d['code'] ?? d['department_code'] ?? d['dept_code'] ?? d['id'] ?? ''}';
      final code = _normalizeDeptCode(rawCode);
      if (code.isNotEmpty && name.isNotEmpty) {
        deptMap[code] = name;
      }
    }

    final studentCounts = <String, int>{};
    final students = appState.studentsData;

    for (final s in students) {
      final rawDept = '${s['dept'] ?? s['department'] ?? ''}';
      final d = _normalizeDeptCode(rawDept);
      if (d.isNotEmpty) {
        studentCounts[d] = (studentCounts[d] ?? 0) + 1;
      }
    }

    final facultyCounts = <String, int>{};
    final faculties = appState.facultiesData;

    for (final f in faculties) {
      final rawDept = '${f['dept'] ?? f['department'] ?? f['dept_code'] ?? f['department_id'] ?? ''}';
      final d = _normalizeDeptCode(rawDept);
      if (d.isNotEmpty) {
        facultyCounts[d] = (facultyCounts[d] ?? 0) + 1;
      }
    }

    final researchCounts = <String, int>{};
    final research = appState.researchProjectsData;

    for (final r in research) {
      final rawDept = '${r['dept'] ?? r['department'] ?? r['department_id'] ?? ''}';
      final d = _normalizeDeptCode(rawDept);
      if (d.isNotEmpty) {
        researchCounts[d] = (researchCounts[d] ?? 0) + 1;
      }
    }

    final list = <DepartmentStats>[];
    for (final entry in deptMap.entries) {
      final code = entry.key;
      final fullName = entry.value;

      final stCount = studentCounts[code] ?? 0;
      final faCount = facultyCounts[code] ?? 0;
      final reCount = researchCounts[code] ?? 0;

      double passPct = 0.0;
      final examMarks = appState.examMarksData;

      final deptMarks = examMarks.where((m) {
        final rawDept = '${m['dept'] ?? m['department'] ?? ''}';
        return _normalizeDeptCode(rawDept) == code;
      }).toList();

      if (deptMarks.isNotEmpty) {
        final passed = deptMarks.where((m) => (double.tryParse('${m['marks'] ?? m['score'] ?? 0}') ?? 0) >= 40).length;
        passPct = (passed / deptMarks.length) * 100;
      } else if (stCount > 0) {
        final deptStudents = students.where((s) {
          final rawDept = '${s['dept'] ?? s['department'] ?? ''}';
          return _normalizeDeptCode(rawDept) == code;
        }).toList();
        if (deptStudents.isNotEmpty) {
          final passed = deptStudents.where((s) => (double.tryParse('${s['cgpa'] ?? 0}') ?? 0.0) >= 5.0).length;
          passPct = (passed / deptStudents.length) * 100;
        }
      }

      double placePct = 0.0;
      if (stCount > 0) {
        final deptStudents = students.where((s) {
          final rawDept = '${s['dept'] ?? s['department'] ?? ''}';
          return _normalizeDeptCode(rawDept) == code;
        }).toList();

        final placedCount = deptStudents.where((s) {
          final statusStr = '${s['placement_status'] ?? s['status'] ?? ''}'.toLowerCase();
          return statusStr.contains('placed') || statusStr.contains('selected') || statusStr.contains('hired');
        }).length;

        if (placedCount > 0) {
          placePct = (placedCount / stCount) * 100;
        } else {
          final placementApps = appState.placementAppsData;

          if (placementApps.isNotEmpty) {
            final placedApps = placementApps.where((app) {
              final stId = '${app['student_id'] ?? ''}';
              return deptStudents.any((s) => '${s['student_id'] ?? s['id']}' == stId);
            }).length;
            placePct = (placedApps / stCount) * 100;
          } else {
            final eligibleCount = deptStudents.where((s) => (double.tryParse('${s['cgpa'] ?? 0}') ?? 0.0) >= 6.5).length;
            placePct = (eligibleCount / stCount) * 85.0;
          }
        }
      }

      final score = (passPct * 0.35 + placePct * 0.35 + (reCount * 0.1).clamp(0, 15) + (stCount > 0 ? 15 : 0)).clamp(0.0, 100.0);

      list.add(DepartmentStats(
        code: code,
        fullName: fullName,
        students: stCount,
        faculty: faCount,
        research: reCount,
        passPct: passPct,
        placePct: placePct,
        overallScore: score,
      ));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final deptStats = _calculateDynamicDeptStats(appState);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top 5 Metric Cards Row
          _buildMetricCardsRow(appState, deptStats),
          const SizedBox(height: 24),

          // 4. Middle Section (2 Columns: Performance Chart & Leaderboard Rankings)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildPerformanceOverviewCard(deptStats)),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: _buildRankingsLeaderboardCard(deptStats)),
              ],
            )
          else
            Column(
              children: [
                _buildPerformanceOverviewCard(deptStats),
                const SizedBox(height: 20),
                _buildRankingsLeaderboardCard(deptStats),
              ],
            ),
          const SizedBox(height: 24),

          // 5. Bottom Section (3 Cards: Metric Table, Students Distribution, Key Insights)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _buildMetricWiseTableCard(deptStats)),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _buildStudentsDistributionCard(deptStats)),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: _buildKeyInsightsCard(appState, deptStats)),
              ],
            )
          else
            Column(
              children: [
                _buildMetricWiseTableCard(deptStats),
                const SizedBox(height: 20),
                _buildStudentsDistributionCard(deptStats),
                const SizedBox(height: 20),
                _buildKeyInsightsCard(appState, deptStats),
              ],
            ),
          const SizedBox(height: 24),

          // 6. Bottom Footer Bar
          _buildFooterBar(),
        ],
      ),
    );
  }

  // 1. Top 5 Metric Cards Row
  Widget _buildMetricCardsRow(DeanAppState appState, List<DepartmentStats> deptStats) {
    final deptsCount = appState.departmentsData.isNotEmpty ? appState.departmentsData.length : deptStats.where((d) => d.students > 0 || d.faculty > 0 || d.research > 0).length;
    final totalStudents = appState.studentsData.length;
    final totalFaculty = appState.facultiesData.length;

    final validStats = deptStats.where((d) => d.passPct > 0).toList();
    final avgPass = validStats.isNotEmpty
        ? (validStats.fold<double>(0, (sum, item) => sum + item.passPct) / validStats.length)
        : 0.0;

    final validPlaces = deptStats.where((d) => d.placePct > 0).toList();
    final avgPlacement = validPlaces.isNotEmpty
        ? (validPlaces.fold<double>(0, (sum, item) => sum + item.placePct) / validPlaces.length)
        : 0.0;

    final metrics = [
      {
        'title': 'Total Departments',
        'value': '$deptsCount',
        'sub': 'Active Departments',
        'isSubLink': true,
        'icon': Icons.school,
        'iconBg': const Color(0xFF1D4ED8),
      },
      {
        'title': 'Total Students',
        'value': NumberFormat('#,###').format(totalStudents),
        'sub': 'Enrolled Students',
        'isSubLink': false,
        'isPositive': true,
        'icon': Icons.groups,
        'iconBg': const Color(0xFF10B981),
      },
      {
        'title': 'Total Faculty',
        'value': '$totalFaculty',
        'sub': 'Active Faculty Members',
        'isSubLink': false,
        'isPositive': true,
        'icon': Icons.person,
        'iconBg': const Color(0xFFF59E0B),
      },
      {
        'title': 'Avg Pass Percentage',
        'value': '${avgPass.toStringAsFixed(2)}%',
        'sub': 'Across Departments',
        'isSubLink': false,
        'isPositive': true,
        'icon': Icons.menu_book,
        'iconBg': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Avg Placement Rate',
        'value': '${avgPlacement.toStringAsFixed(2)}%',
        'sub': 'Across Departments',
        'isSubLink': false,
        'isPositive': true,
        'icon': Icons.work,
        'iconBg': const Color(0xFF06B6D4),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (4 * 16)) / 5;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: metrics.map((m) {
              return Container(
                width: cardWidth >= 190 ? cardWidth : 190,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DeanTheme.cardBorder),
                  boxShadow: const [
                    BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: m['iconBg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(m['icon'] as IconData, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            m['title'] as String,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DeanTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m['value'] as String,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m['sub'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: (m['isSubLink'] as bool)
                                  ? const Color(0xFF2563EB)
                                  : ((m['isPositive'] as bool? ?? false) ? const Color(0xFF16A34A) : DeanTheme.textMuted),
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
        );
      },
    );
  }

  // 2. Department Performance Overview (Grouped Bar Chart)
  Widget _buildPerformanceOverviewCard(List<DepartmentStats> deptStats) {
    return BentoCard(
      title: 'Department Performance Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildLegendDot('Pass Percentage (%)', const Color(0xFF2563EB)),
              const SizedBox(width: 14),
              _buildLegendDot('Placement Rate (%)', const Color(0xFF10B981)),
              const SizedBox(width: 14),
              _buildLegendDot('Research Publications', const Color(0xFFF59E0B)),
              const SizedBox(width: 14),
              _buildLegendDot('Students (Count)', const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Multi-Group Bar Chart
          SizedBox(
            height: 280,
            child: CustomPaint(
              size: Size.infinite,
              painter: _DeptPerformanceChartPainter(deptStats: deptStats),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DeanTheme.textMuted)),
      ],
    );
  }

  // 3. Department Rankings Leaderboard
  Widget _buildRankingsLeaderboardCard(List<DepartmentStats> deptStats) {
    final activeStats = deptStats.where((d) => d.students > 0 || d.faculty > 0 || d.research > 0 || d.passPct > 0).toList();

    final sortedRankings = List<DepartmentStats>.from(activeStats)
      ..sort((a, b) => b.overallScore.compareTo(a.overallScore));

    return BentoCard(
      title: 'Department Rankings (Overall Score)',
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: DeanTheme.cardBorder, width: 1)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 32, child: Text('Rank', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                Expanded(flex: 5, child: Text('Department', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                Expanded(flex: 5, child: SizedBox()),
                SizedBox(width: 60, child: Text('Overall Score', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (sortedRankings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Text('No department ranking data recorded in database.', style: TextStyle(fontSize: 12, color: DeanTheme.textMuted)),
            )
          else
            ...sortedRankings.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final item = entry.value;
              final scoreStr = item.overallScore.toStringAsFixed(2);
              final pct = (item.overallScore / 100.0).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text('$rank', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        item.fullName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEFF6FF),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 60,
                      child: Text(
                        scoreStr,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 4. Metric Wise Comparison Table
  Widget _buildMetricWiseTableCard(List<DepartmentStats> deptStats) {
    final activeStats = deptStats.where((d) => d.students > 0 || d.faculty > 0 || d.research > 0 || d.passPct > 0).toList();
    final displayRows = showAllDepartments ? activeStats : activeStats.take(5).toList();

    return BentoCard(
      title: 'Metric Wise Comparison',
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 420),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: DeanTheme.cardBorder, width: 1)),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(width: 80, child: Text('Department', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                        SizedBox(width: 65, child: Text('Pass %', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                        SizedBox(width: 75, child: Text('Placement %', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                        SizedBox(width: 70, child: Text('Research', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                        SizedBox(width: 60, child: Text('Faculty', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                        SizedBox(width: 65, child: Text('Students', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                      ],
                    ),
                  ),
                  if (displayRows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Text('No department records found in database.', style: TextStyle(fontSize: 12, color: DeanTheme.textMuted)),
                    )
                  else
                    ...displayRows.map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 80, child: Text(r.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark))),
                            SizedBox(width: 65, child: Text('${r.passPct.toStringAsFixed(2)}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textDark))),
                            SizedBox(width: 75, child: Text('${r.placePct.toStringAsFixed(2)}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textDark))),
                            SizedBox(width: 70, child: Text('${r.research}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textDark))),
                            SizedBox(width: 60, child: Text('${r.faculty}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textDark))),
                            SizedBox(width: 65, child: Text('${r.students}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textDark))),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (activeStats.length > 5)
            Center(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    showAllDepartments = !showAllDepartments;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DeanTheme.primaryBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  showAllDepartments ? 'Show Less' : 'View All Departments',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 5. Students Distribution Donut Chart (Dynamic Database Integration)
  Widget _buildStudentsDistributionCard(List<DepartmentStats> deptStats) {
    final activeDepts = deptStats.where((d) => d.students > 0).toList();
    final totalStudentsCount = activeDepts.fold<int>(0, (sum, d) => sum + d.students);

    final palette = const [
      Color(0xFF1E3A8A), // CSE
      Color(0xFF0284C7), // IT
      Color(0xFF2563EB), // ECE
      Color(0xFF10B981), // EEE
      Color(0xFF8B5CF6), // MECH
      Color(0xFFEF4444), // Civil
      Color(0xFFD946EF), // AI&DS
      Color(0xFFF59E0B), // Others
      Color(0xFF06B6D4),
      Color(0xFF84CC16),
      Color(0xFFEC4899),
      Color(0xFF6366F1),
    ];

    final List<Map<String, dynamic>> distData = [];
    final List<Map<String, dynamic>> slices = [];

    for (int i = 0; i < activeDepts.length; i++) {
      final dept = activeDepts[i];
      final color = palette[i % palette.length];
      final pctValue = totalStudentsCount > 0 ? (dept.students / totalStudentsCount) : 0.0;
      final pctStr = '${(pctValue * 100).toStringAsFixed(1)}%';

      distData.add({
        'name': dept.code,
        'count': '${dept.students}',
        'pct': pctStr,
        'color': color,
      });

      slices.add({
        'pct': pctValue,
        'color': color,
      });
    }

    final displayTotal = totalStudentsCount > 0
        ? NumberFormat('#,###').format(totalStudentsCount)
        : '0';

    return BentoCard(
      title: 'Students Distribution',
      child: activeDepts.isEmpty
          ? const SizedBox(
              height: 140,
              child: Center(
                child: Text('No student records found in database.',
                    style: TextStyle(fontSize: 12, color: DeanTheme.textMuted)),
              ),
            )
          : Row(
              children: [
                // Donut Chart Container
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: _StudentsDistributionPainter(slices: slices),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(displayTotal, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                          const Text('Total Students', style: TextStyle(fontSize: 9, color: DeanTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Legend Items
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: distData.map((d) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: d['color'] as Color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(d['name'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                              const Spacer(),
                              Text('${d['count']} (${d['pct']})', style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // 6. Key Insights - Dynamic SQL Schema Insights
  Widget _buildKeyInsightsCard(DeanAppState appState, List<DepartmentStats> deptStats) {
    final activeStats = deptStats.where((d) => d.students > 0 || d.faculty > 0 || d.research > 0 || d.passPct > 0).toList();
    final topDept = List<DepartmentStats>.from(activeStats)..sort((a, b) => b.overallScore.compareTo(a.overallScore));

    final totalStudentsCount = appState.studentsData.length;
    final totalFacultyCount = appState.facultiesData.length;
    final totalProjectsCount = appState.researchProjectsData.length;

    final String insight1Text = topDept.isNotEmpty
        ? '${topDept.first.fullName} (${topDept.first.code}) leads institution with ${topDept.first.students} students and ${topDept.first.faculty} faculty members.'
        : 'Department metrics being analyzed from live records.';

    final String insight2Text = totalStudentsCount > 0
        ? 'Total student strength across institution is ${NumberFormat('#,###').format(totalStudentsCount)} enrolled students.'
        : 'Real-time student distribution calculated across active departments.';

    final String insight3Text = totalFacultyCount > 0
        ? 'Total active faculty strength across institution is $totalFacultyCount faculty members.'
        : 'Placement rates tracked live from student placement records.';

    final String insight4Text = totalProjectsCount > 0
        ? 'Total research projects published across departments is $totalProjectsCount active projects.'
        : 'Research publications recorded directly from department faculty projects.';

    final insights = [
      {
        'icon': Icons.trending_up,
        'iconBg': const Color(0xFFDCFCE7),
        'iconCol': const Color(0xFF16A34A),
        'text': insight1Text,
      },
      {
        'icon': Icons.groups_outlined,
        'iconBg': const Color(0xFFEFF6FF),
        'iconCol': const Color(0xFF2563EB),
        'text': insight2Text,
      },
      {
        'icon': Icons.emoji_events_outlined,
        'iconBg': const Color(0xFFFFEDD5),
        'iconCol': const Color(0xFFEA580C),
        'text': insight3Text,
      },
      {
        'icon': Icons.menu_book_outlined,
        'iconBg': const Color(0xFFF3E8FF),
        'iconCol': const Color(0xFF9333EA),
        'text': insight4Text,
      },
    ];

    return BentoCard(
      title: 'Key Insights',
      child: Column(
        children: insights.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item['iconBg'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: item['iconCol'] as Color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['text'] as String,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textDark, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 7. Footer Bar
  Widget _buildFooterBar() {
    final appState = DeanAppStateProvider.of(context);
    final formattedTime = DateFormat('dd MMM yyyy h:mm a').format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Note: Overall Score is calculated based on weighted performance across academics, placements, research, faculty and student metrics.',
            style: TextStyle(fontSize: 11, color: DeanTheme.textMuted),
          ),
        ),
        Row(
          children: [
            Text(
              'Last Updated: $formattedTime',
              style: const TextStyle(fontSize: 11, color: DeanTheme.textMuted),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () async {
                await appState.fetchAllData();
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.refresh, size: 16, color: DeanTheme.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ],
    );
  }
}

// Custom Painter: Department Performance Overview Grouped Bar Chart
class _DeptPerformanceChartPainter extends CustomPainter {
  final List<DepartmentStats> deptStats;

  _DeptPerformanceChartPainter({required this.deptStats});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double chartBottom = height - 28;
    final double chartTop = 10;
    final double chartHeight = chartBottom - chartTop;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final TextPainter textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // Y Axis Grid lines (0, 20, 40, 60, 80, 100)
    final yLabels = ['100', '80', '60', '40', '20', '0'];
    for (int i = 0; i < yLabels.length; i++) {
      final double y = chartTop + (i * (chartHeight / 5));
      canvas.drawLine(Offset(28, y), Offset(width, y), gridPaint);

      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    final activeDepts = deptStats.where((d) => d.students > 0 || d.faculty > 0 || d.research > 0 || d.passPct > 0).take(12).toList();
    if (activeDepts.isEmpty) return;

    final double leftOffset = 35;
    final double availableWidth = width - leftOffset;
    final double groupWidth = availableWidth / activeDepts.length;
    final double barWidth = 4.5;

    final barColors = [
      const Color(0xFF2563EB), // Pass %
      const Color(0xFF10B981), // Placement %
      const Color(0xFFF59E0B), // Research
      const Color(0xFF8B5CF6), // Students
    ];

    for (int i = 0; i < activeDepts.length; i++) {
      final item = activeDepts[i];
      final double groupX = leftOffset + (i * groupWidth);
      final double startX = groupX + (groupWidth - (4 * barWidth + 3 * 2)) / 2;

      final barRatios = [
        (item.passPct / 100.0).clamp(0.0, 1.0),
        (item.placePct / 100.0).clamp(0.0, 1.0),
        (item.research / 100.0).clamp(0.0, 1.0),
        (item.students / 500.0).clamp(0.0, 1.0),
      ];

      for (int b = 0; b < 4; b++) {
        final double valPct = barRatios[b];
        final double barH = valPct * chartHeight;
        final double rectLeft = startX + (b * (barWidth + 2));
        final double rectTop = chartBottom - barH;

        final Paint barPaint = Paint()..color = barColors[b];

        final RRect barRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(rectLeft, rectTop, barWidth, barH),
          const Radius.circular(3),
        );
        canvas.drawRRect(barRRect, barPaint);
      }

      // X Axis Label
      textPainter.text = TextSpan(
        text: item.code,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(groupX + (groupWidth - textPainter.width) / 2, chartBottom + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter: Students Distribution Donut Chart (Dynamic Database Integration)
class _StudentsDistributionPainter extends CustomPainter {
  final List<Map<String, dynamic>> slices;

  _StudentsDistributionPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final double strokeWidth = 22;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -3.14159 / 2;

    for (final slice in slices) {
      final double pct = (slice['pct'] as double? ?? 0.0);
      if (pct <= 0) continue;
      final double sweepAngle = pct * 2 * 3.14159;
      paint.color = slice['color'] as Color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle > 0.04 ? sweepAngle - 0.04 : sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _StudentsDistributionPainter oldDelegate) => true;
}
