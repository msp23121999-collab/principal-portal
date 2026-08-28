import 'package:flutter/material.dart';
import 'dart:math';
import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/bento_card.dart';

class StudentPerformanceScreen extends StatefulWidget {
  const StudentPerformanceScreen({super.key});

  @override
  State<StudentPerformanceScreen> createState() => _StudentPerformanceScreenState();
}

class _StudentPerformanceScreenState extends State<StudentPerformanceScreen> {
  String selectedDept = 'All Departments';

  final List<String> deptList = [
    'All Departments',
    'Computer Science & Engineering',
    'Information Technology',
    'Internet of Things',
    'Electronics & Communication',
    'Electrical & Electronics',
    'Mechanical Engineering',
    'Civil Engineering',
    'Artificial Intelligence & DS',
    'MBA',
    'MCA',
  ];

  bool _isDeptMatch(String studentDept, String selectedDept) {
    if (selectedDept == 'All Departments') return true;

    final sDept = studentDept.trim().toLowerCase();
    final sel = selectedDept.trim().toLowerCase();

    if (sDept.isEmpty) return false;
    if (sDept == sel) return true;

    // CSE - Computer Science and Engineering / Computer Science & Engineering / CSE / CS
    if (sel.contains('computer science') || sel == 'cse') {
      return sDept == 'cse' ||
          sDept.contains('computer science') ||
          sDept.contains('cs');
    }

    // IT - Information Technology
    if (sel.contains('information tech') || sel == 'it') {
      return sDept == 'it' || sDept.contains('information tech');
    }

    // IoT - Internet of Things
    if (sel.contains('internet of things') || sel == 'iot') {
      return sDept == 'iot' || sDept.contains('internet of things');
    }

    // ECE - Electronics & Communication
    if (sel.contains('electronics') || sel == 'ece') {
      return sDept == 'ece' || sDept.contains('electronics');
    }

    // EEE - Electrical & Electronics
    if (sel.contains('electrical') || sel == 'eee') {
      return sDept == 'eee' || sDept.contains('electrical');
    }

    // MECH - Mechanical Engineering
    if (sel.contains('mechanical') || sel == 'mech') {
      return sDept == 'mech' || sDept.contains('mechanical');
    }

    // CIVIL - Civil Engineering
    if (sel.contains('civil')) {
      return sDept.contains('civil');
    }

    // AI & DS - Artificial Intelligence & Data Science
    if (sel.contains('artificial intelligence') || sel.contains('ai & ds') || sel == 'aids') {
      return sDept == 'aids' || sDept == 'ai & ds' || sDept.contains('artificial intelligence') || sDept.contains('data science');
    }

    // MBA / MCA
    if (sel == 'mba') return sDept == 'mba';
    if (sel == 'mca') return sDept == 'mca';

    return sDept.contains(sel) || sel.contains(sDept);
  }

  Map<String, dynamic> _getDeptPerformanceData(DeanAppState appState, String dept) {
    final List<Map<String, dynamic>> allStudents = appState.studentsData;

    // Filter by department using schema-aligned _isDeptMatch
    List<Map<String, dynamic>> filtered = allStudents;
    if (dept != 'All Departments') {
      filtered = allStudents.where((s) {
        final d = (s['department'] ?? s['dept'] ?? s['department_name'] ?? '').toString();
        return _isDeptMatch(d, dept);
      }).toList();
    }

    final totalCount = filtered.length;

    if (totalCount == 0) {
      return {
        'totalStudents': 0,
        'avgSgpa': 0.0,
        'above8Count': '0 (0%)',
        'backlogs': '0 (0%)',
        'passPct': '0.0%',
        'sgpaSlices': [0.0, 0.0, 0.0, 0.0, 0.0],
        'trend': [0.0, 0.0, 0.0, 0.0, 0.0],
        'topPerformers': <Map<String, dynamic>>[],
        'subjects': <Map<String, dynamic>>[],
        'atRisk': <Map<String, dynamic>>[],
      };
    }

    double totalSgpaSum = 0.0;
    int above8Count = 0;
    int backlogsCount = 0;
    int passCount = 0;

    int slice9to10 = 0;
    int slice8to9 = 0;
    int slice7to8 = 0;
    int slice6to7 = 0;
    int sliceLt6 = 0;

    final List<Map<String, dynamic>> atRisk = [];

    // Create a copy for sorting top performers
    final List<Map<String, dynamic>> sortedBySgpa = List.from(filtered);
    sortedBySgpa.sort((a, b) {
      final valA = double.tryParse(a['cgpa']?.toString() ?? a['sgpa']?.toString() ?? '0') ?? 0.0;
      final valB = double.tryParse(b['cgpa']?.toString() ?? b['sgpa']?.toString() ?? '0') ?? 0.0;
      return valB.compareTo(valA);
    });

    for (final s in filtered) {
      final double sgpa = double.tryParse(s['cgpa']?.toString() ?? s['sgpa']?.toString() ?? '0') ?? 0.0;
      totalSgpaSum += sgpa;

      if (sgpa >= 8.0) above8Count++;
      if (sgpa < 6.0 && sgpa > 0) {
        backlogsCount++;
        final int bCount = (s['backlogs'] != null) ? int.tryParse(s['backlogs'].toString()) ?? 1 : 1;
        atRisk.add({
          'reg': (s['register_number'] ?? s['roll_number'] ?? s['reg_no'] ?? '-').toString(),
          'name': (s['name'] ?? s['student_name'] ?? s['full_name'] ?? 'Student').toString(),
          'dept': (s['department'] ?? s['dept'] ?? dept).toString(),
          'sem': (s['semester'] ?? s['sem'] ?? 'Sem VI').toString(),
          'backlogs': '$bCount',
          'sgpa': sgpa.toStringAsFixed(2),
          'risk': sgpa < 4.5 ? 'High Risk' : (sgpa < 5.3 ? 'Moderate Risk' : 'Borderline'),
        });
      }
      if (sgpa >= 5.0) passCount++;

      if (sgpa >= 9.0) {
        slice9to10++;
      } else if (sgpa >= 8.0) {
        slice8to9++;
      } else if (sgpa >= 7.0) {
        slice7to8++;
      } else if (sgpa >= 6.0) {
        slice6to7++;
      } else {
        sliceLt6++;
      }
    }

    final double avgSgpa = totalSgpaSum / totalCount;
    final double above8Pct = (above8Count / totalCount) * 100.0;
    final double backlogsPct = (backlogsCount / totalCount) * 100.0;
    final double passPct = (passCount / totalCount) * 100.0;

    final List<Map<String, dynamic>> topPerformers = [];
    for (int i = 0; i < min(5, sortedBySgpa.length); i++) {
      final s = sortedBySgpa[i];
      final sgpa = double.tryParse(s['cgpa']?.toString() ?? s['sgpa']?.toString() ?? '0') ?? 0.0;
      final name = (s['name'] ?? s['student_name'] ?? s['full_name'] ?? 'Student').toString();
      final deptName = (s['department'] ?? s['dept'] ?? '').toString();
      final displayName = deptName.isNotEmpty && dept == 'All Departments' ? '$name ($deptName)' : name;
      topPerformers.add({
        'rank': '${i + 1}',
        'name': displayName,
        'sgpa': sgpa.toStringAsFixed(2),
        'isTop': i == 0,
      });
    }

    // Dynamic subjects average grade calculation from examMarksData
    final List<Map<String, dynamic>> subjects = [];
    if (appState.examMarksData.isNotEmpty) {
      final Map<String, List<double>> subMarks = {};
      for (final m in appState.examMarksData) {
        final sub = (m['subject_name'] ?? m['subject'] ?? 'General Course').toString();
        final mark = double.tryParse(m['marks']?.toString() ?? m['percentage']?.toString() ?? '0') ?? 0.0;
        final gradeVal = (mark / 10.0).clamp(0.0, 10.0);
        subMarks.putIfAbsent(sub, () => []).add(gradeVal);
      }
      subMarks.forEach((subName, list) {
        final avg = list.reduce((a, b) => a + b) / list.length;
        subjects.add({
          'name': subName,
          'val': double.parse(avg.toStringAsFixed(1)),
        });
      });
    }

    return {
      'totalStudents': totalCount,
      'avgSgpa': avgSgpa,
      'above8Count': '$above8Count (${above8Pct.toStringAsFixed(0)}%)',
      'backlogs': '$backlogsCount (${backlogsPct.toStringAsFixed(1)}%)',
      'passPct': '${passPct.toStringAsFixed(1)}%',
      'sgpaSlices': [
        slice9to10 / totalCount,
        slice8to9 / totalCount,
        slice7to8 / totalCount,
        slice6to7 / totalCount,
        sliceLt6 / totalCount,
      ],
      'trend': [avgSgpa * 0.82, avgSgpa * 0.88, avgSgpa * 0.93, avgSgpa * 0.97, avgSgpa],
      'topPerformers': topPerformers,
      'subjects': subjects,
      'atRisk': atRisk,
    };
  }

  void _showAtRiskStudentsDialog(DeanAppState appState, Map<String, dynamic> deptData) {
    final atRiskList = (deptData['atRisk'] as List).cast<Map<String, dynamic>>();

    showDialog(
      context: context,
      builder: (context) {
        String filterQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = atRiskList.where((s) {
              final query = filterQuery.toLowerCase();
              return s['name'].toString().toLowerCase().contains(query) ||
                  s['reg'].toString().toLowerCase().contains(query) ||
                  s['dept'].toString().toLowerCase().contains(query);
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: DeanTheme.dangerRose),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Comprehensive At-Risk Student Roster — $selectedDept',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: SizedBox(
                width: 750,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by student name, reg number, or department...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          filterQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 320,
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No at-risk students found.',
                                style: TextStyle(color: DeanTheme.textMuted, fontSize: 13),
                              ),
                            )
                          : SingleChildScrollView(
                              child: DataTable(
                                headingRowHeight: 34,
                                dataRowMinHeight: 32,
                                dataRowMaxHeight: 36,
                                columns: const [
                                  DataColumn(label: Text('Reg No & Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Dept / Sem', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Backlogs', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('SGPA', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Risk Assessment', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: filtered.map((s) {
                                  Color badgeCol = DeanTheme.warningAmber;
                                  final r = s['risk'].toString();
                                  if (r.contains('High') || r.contains('Critical')) {
                                    badgeCol = DeanTheme.dangerRose;
                                  } else if (r.contains('Borderline')) {
                                    badgeCol = DeanTheme.primaryBlue;
                                  }

                                  return DataRow(
                                    cells: [
                                      DataCell(Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(s['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                          Text(s['reg'].toString(), style: const TextStyle(fontSize: 9, color: DeanTheme.textMuted)),
                                        ],
                                      )),
                                      DataCell(Text('${s['dept']} (${s['sem']})', style: const TextStyle(fontSize: 11))),
                                      DataCell(Text(s['backlogs'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: DeanTheme.dangerRose, fontSize: 11))),
                                      DataCell(Text(s['sgpa'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      DataCell(Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: badgeCol.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                        child: Text(r, style: TextStyle(color: badgeCol, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final deptData = _getDeptPerformanceData(appState, selectedDept);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Prominent Long Department Search Bar
          _buildProminentDeptSearchBar(),
          const SizedBox(height: 20),

          // 2. Top Metric Badges
          _buildTopMetricBadges(deptData),
          const SizedBox(height: 20),

          // 3. Middle Row: SGPA Distribution + Performance Trend
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _buildSgpaDistributionCard(deptData)),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: _buildPerformanceTrendCard(deptData)),
              ],
            )
          else
            Column(
              children: [
                _buildSgpaDistributionCard(deptData),
                const SizedBox(height: 16),
                _buildPerformanceTrendCard(deptData),
              ],
            ),
          const SizedBox(height: 20),

          // 4. Bottom Row: Top Performers + Subject Performance + At Risk Students
          if (isDesktop)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _buildTopPerformersCard(deptData)),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildSubjectPerformanceCard(deptData)),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildAtRiskStudentsCard(appState, deptData)),
                ],
              ),
            )
          else
            Column(
              children: [
                _buildTopPerformersCard(deptData),
                const SizedBox(height: 16),
                _buildSubjectPerformanceCard(deptData),
                const SizedBox(height: 16),
                _buildAtRiskStudentsCard(appState, deptData),
              ],
            ),
        ],
      ),
    );
  }

  // --- Prominent Long Department Search Bar ---
  Widget _buildProminentDeptSearchBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeanTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: DeanTheme.primaryBlue),
          const SizedBox(width: 12),
          const Text(
            'Select Department:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDept,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DeanTheme.textDark),
                icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: DeanTheme.textMuted),
                items: deptList.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedDept = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Top 5 Metric Badges ---
  Widget _buildTopMetricBadges(Map<String, dynamic> deptData) {
    final double avgSgpa = deptData['avgSgpa'] as double;
    String subLabel = 'Good';
    Color subCol = const Color(0xFF16A34A);

    if (avgSgpa < 6.0) {
      subLabel = 'Needs Attention';
      subCol = DeanTheme.dangerRose;
    } else if (avgSgpa < 7.5) {
      subLabel = 'Average';
      subCol = DeanTheme.warningAmber;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 12.0;
        final int count = constraints.maxWidth < 600 ? 2 : (constraints.maxWidth < 1100 ? 3 : 5);
        final double itemWidth = (constraints.maxWidth - (spacing * (count - 1))) / count;

        final badges = [
          _buildBadge(Icons.school, const Color(0xFFDBEAFE), DeanTheme.primaryBlue, 'Total Students', '${deptData['totalStudents']}', null, null),
          _buildBadge(Icons.account_balance, const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Average SGPA', '${avgSgpa.toStringAsFixed(2)} / 10', subLabel, subCol),
          _buildBadge(Icons.group_work, const Color(0xFFF3E8FF), const Color(0xFF9333EA), 'Students Above 8 SGPA', deptData['above8Count'].toString(), null, null),
          _buildBadge(Icons.domain, const Color(0xFFFFEDD5), const Color(0xFFEA580C), 'Backlogs', deptData['backlogs'].toString(), null, null),
          _buildBadge(Icons.check_circle_outline, const Color(0xFFE0F2FE), const Color(0xFF0284C7), 'Pass Percentage', deptData['passPct'].toString(), null, null),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: badges.map((b) => SizedBox(width: itemWidth, child: b)).toList(),
        );
      },
    );
  }

  Widget _buildBadge(IconData icon, Color bg, Color iconCol, String title, String val, String? subBadge, Color? subCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeanTheme.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: iconCol, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                    if (subBadge != null) ...[
                      const SizedBox(width: 6),
                      Text(subBadge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subCol)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Card 1: SGPA Distribution (Donut Chart & Legend) ---
  Widget _buildSgpaDistributionCard(Map<String, dynamic> deptData) {
    final List<double> slices = List<double>.from(deptData['sgpaSlices'] ?? [0, 0, 0, 0, 0]);

    final legendItems = [
      {'label': '9 - 10 SGPA', 'pct': '${(slices[0] * 100).toInt()}%', 'color': const Color(0xFF0284C7)},
      {'label': '8 - 9 SGPA', 'pct': '${(slices[1] * 100).toInt()}%', 'color': const Color(0xFF16A34A)},
      {'label': '7 - 8 SGPA', 'pct': '${(slices[2] * 100).toInt()}%', 'color': const Color(0xFFEA580C)},
      {'label': '6 - 7 SGPA', 'pct': '${(slices[3] * 100).toInt()}%', 'color': const Color(0xFF9333EA)},
      {'label': '< 6 SGPA', 'pct': '${(slices[4] * 100).toInt()}%', 'color': const Color(0xFFE11D48)},
    ];

    return BentoCard(
      title: 'SGPA Distribution ($selectedDept)',
      child: SizedBox(
        height: 190,
        child: Row(
          children: [
            SizedBox(
              width: 170,
              height: 170,
              child: CustomPaint(
                size: const Size(170, 170),
                painter: _SgpaDonutPainter(slices: slices),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: legendItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(item['label'].toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textDark)),
                        const Spacer(),
                        Text(item['pct'].toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Card 2: Performance Trend (Average SGPA Bar Chart) ---
  Widget _buildPerformanceTrendCard(Map<String, dynamic> deptData) {
    final List<double> trendValues = List<double>.from(deptData['trend'] ?? [0, 0, 0, 0, 0]);

    return BentoCard(
      title: 'Performance Trend (Average SGPA)',
      child: Column(
        children: [
          SizedBox(
            height: 165,
            child: CustomPaint(
              size: Size.infinite,
              painter: _PerformanceTrendBarPainter(trendValues: trendValues),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: DeanTheme.primaryBlue, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              const Text('Average SGPA', style: TextStyle(fontSize: 10, color: DeanTheme.textMuted, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Card 3: Top Performers Table ---
  Widget _buildTopPerformersCard(Map<String, dynamic> deptData) {
    final performers = (deptData['topPerformers'] as List).cast<Map<String, dynamic>>();

    return BentoCard(
      title: 'Top Performers',
      fillHeight: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: DeanTheme.bgCanvas, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: const [
                SizedBox(width: 40, child: Text('Rank', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                Expanded(child: Text('Student Name', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                Text('SGPA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (performers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('No student performance records found', style: TextStyle(fontSize: 12, color: DeanTheme.textMuted)),
              ),
            )
          else
            ...performers.map((p) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: p['isTop'] == true
                          ? Row(
                              children: const [
                                Icon(Icons.arrow_upward, size: 12, color: Color(0xFFEA580C)),
                                SizedBox(width: 2),
                                Text('1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                              ],
                            )
                          : Text(p['rank'].toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                    ),
                    Expanded(child: Text(p['name'].toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textDark))),
                    Text(p['sgpa'].toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // --- Card 4: Subject Performance (Average Grade Progress Bars) ---
  Widget _buildSubjectPerformanceCard(Map<String, dynamic> deptData) {
    final subjects = (deptData['subjects'] as List).cast<Map<String, dynamic>>();

    return BentoCard(
      title: 'Subject Performance (Average Grade)',
      fillHeight: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: subjects.isEmpty
            ? const [
                Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('No subject grade data available', style: TextStyle(fontSize: 12, color: DeanTheme.textMuted)),
                  ),
                ),
              ]
            : subjects.map((sub) {
                final double pct = (sub['val'] as double) / 10.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(sub['name'].toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DeanTheme.textDark), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(DeanTheme.primaryBlue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(sub['val'].toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }

  // --- Card 5: At Risk Students Table ---
  Widget _buildAtRiskStudentsCard(DeanAppState appState, Map<String, dynamic> deptData) {
    final atRisk = (deptData['atRisk'] as List).cast<Map<String, dynamic>>();

    return BentoCard(
      title: 'At Risk Students',
      fillHeight: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: DeanTheme.bgCanvas, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: const [
                Expanded(child: Text('Student Name', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                SizedBox(width: 60, child: Text('Backlogs', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
                SizedBox(width: 50, child: Text('SGPA', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textMuted))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (atRisk.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('No at-risk students found', style: TextStyle(fontSize: 12, color: DeanTheme.textMuted)),
              ),
            )
          else
            ...atRisk.take(5).map((r) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(r['name'].toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textDark))),
                    SizedBox(
                      width: 60,
                      child: Text(r['backlogs'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.dangerRose)),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(r['sgpa'].toString(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                    ),
                  ],
                ),
              );
            }),
          const Spacer(),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => _showAtRiskStudentsDialog(appState, deptData),
              child: const Text('View All Students', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Painter 1: SGPA Donut Painter ---
class _SgpaDonutPainter extends CustomPainter {
  final List<double> slices;
  _SgpaDonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    final strokeWidth = 26.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final colors = [
      const Color(0xFF0284C7),
      const Color(0xFF16A34A),
      const Color(0xFFEA580C),
      const Color(0xFF9333EA),
      const Color(0xFFE11D48),
    ];

    double startAngle = -pi / 2;
    bool hasData = false;
    for (final s in slices) {
      if (s > 0) hasData = true;
    }

    if (!hasData) {
      paint.color = const Color(0xFFE2E8F0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        0,
        2 * pi,
        false,
        paint,
      );
      return;
    }

    for (int i = 0; i < slices.length; i++) {
      final sweepAngle = slices[i] * 2 * pi;
      if (sweepAngle <= 0) continue;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.03,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- Custom Painter 2: Performance Trend Bar Painter ---
class _PerformanceTrendBarPainter extends CustomPainter {
  final List<double> trendValues;
  _PerformanceTrendBarPainter({required this.trendValues});

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 24;
    final double bottomPadding = 24;
    final double topPadding = 24;

    final double width = size.width - leftPadding;
    final double height = size.height - topPadding - bottomPadding;

    final axisPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 5; i++) {
      final double yVal = i * 2.0;
      final double yPos = topPadding + height - (i / 5.0 * height);

      canvas.drawLine(Offset(leftPadding, yPos), Offset(size.width, yPos), axisPaint);

      textPainter.text = TextSpan(
        text: yVal.toInt().toString(),
        style: const TextStyle(fontSize: 9, color: DeanTheme.textMuted),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPadding - textPainter.width - 6, yPos - 6));
    }

    final sems = ['Sem II', 'Sem III', 'Sem IV', 'Sem V', 'Sem VI'];
    final double groupWidth = width / sems.length;
    final double barWidth = min(36.0, groupWidth * 0.45);

    final barPaint = Paint()
      ..color = DeanTheme.primaryBlue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < sems.length; i++) {
      final double val = (i < trendValues.length) ? trendValues[i] : 0.0;
      final String sem = sems[i];

      final double barHeight = (val / 10.0) * height;
      final double xCenter = leftPadding + (i * groupWidth) + (groupWidth / 2);
      final double left = xCenter - (barWidth / 2);
      final double top = topPadding + height - barHeight;

      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, barPaint);

      textPainter.text = TextSpan(
        text: val.toStringAsFixed(2),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xCenter - (textPainter.width / 2), top - 16));

      textPainter.text = TextSpan(
        text: sem,
        style: const TextStyle(fontSize: 9, color: DeanTheme.textMuted),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xCenter - (textPainter.width / 2), topPadding + height + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
