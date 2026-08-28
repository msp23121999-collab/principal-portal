import 'package:flutter/material.dart';
import '../theme.dart';
import '../hod_toast.dart';
import '../pdf_download_helper.dart';
import '../responsive.dart';
import '../../faculty/services/postgres_client.dart';

class ClassDiaryMonitoringView extends StatefulWidget {
  final int initialTab;
  const ClassDiaryMonitoringView({super.key, this.initialTab = 0});

  @override
  State<ClassDiaryMonitoringView> createState() =>
      _ClassDiaryMonitoringViewState();
}

class _ClassDiaryMonitoringViewState extends State<ClassDiaryMonitoringView> {
  late int _activeMainTab; // 0 = Class Diary Monitoring, 1 = My Diary Entry
  int _activeSubTab =
      0; // 0 = Syllabus Completed, 1 = Faculty Entered Logs, 2 = Missed Logs
  int? _editingCourseIndex;

  String _searchQuery = '';
  String _selectedBatch = 'All Batches';
  String _selectedSemester = 'All Semesters';
  String _selectedDelay = 'All Delays';

  final List<String> _batches = [
    'All Batches',
    'Batch 2024 - 2028',
    'Batch 2023 - 2027',
    'Batch 2022 - 2026',
  ];
  final List<String> _semesters = [
    'All Semesters',
    'Semester I',
    'Semester II',
    'Semester III',
    'Semester IV',
    'Semester V',
  ];
  final List<String> _delays = [
    'All Delays',
    'OVERDUE (>24h)',
    'PENDING (<24h)',
  ];

  // Mock data for Course Syllabus Completion Log (Tab 0)
  final List<Map<String, dynamic>> _courses = [
    {
      'sNo': 1,
      'code': 'IOT2028',
      'name': 'IoT Sensors & Actuators',
      'faculty': 'Prof. Muththukumaran M',
      'facultyCode': 'EMP-CSE-008',
      'semester': 'Semester IV',
      'batch': 'Batch 2024 - 2028',
      'covered': 34,
      'total': 45,
      'completion': 80,
      'status': 'On Track',
      'lastUpdated': 'Today, 10:15 AM',
      'conductedClasses': 34,
    },
    {
      'sNo': 2,
      'code': 'IOT2029',
      'name': 'Embedded Systems & RTOS',
      'faculty': 'Prof. K. Nandhini',
      'facultyCode': 'EMP-CSE-006',
      'semester': 'Semester IV',
      'batch': 'Batch 2024 - 2028',
      'covered': 45,
      'total': 45,
      'completion': 100,
      'status': 'Completed',
      'lastUpdated': 'Today, 09:45 AM',
      'conductedClasses': 45,
    },
    {
      'sNo': 3,
      'code': 'IOT2030',
      'name': 'Cloud Protocols & MQTT',
      'faculty': 'Dr. K. Ravichandran',
      'facultyCode': 'EMP-CSE-010',
      'semester': 'Semester IV',
      'batch': 'Batch 2024 - 2028',
      'covered': 32,
      'total': 45,
      'completion': 71,
      'status': 'On Track',
      'lastUpdated': 'Today, 09:30 AM',
      'conductedClasses': 32,
    },
    {
      'sNo': 4,
      'code': 'IOT2031',
      'name': 'Sensors & Interfacing Lab',
      'faculty': 'Prof. Ramakrishnan R',
      'facultyCode': 'EMP-CSE-009',
      'semester': 'Semester IV',
      'batch': 'Batch 2024 - 2028',
      'covered': 15,
      'total': 30,
      'completion': 50,
      'status': 'Behind',
      'lastUpdated': 'Today, 09:00 AM',
      'conductedClasses': 15,
    },
    {
      'sNo': 5,
      'code': 'IOT2032',
      'name': 'Hardware Interface Design',
      'faculty': 'Prof. R. Kavitha',
      'facultyCode': 'EMP-CSE-004',
      'semester': 'Semester IV',
      'batch': 'Batch 2024 - 2028',
      'covered': 28,
      'total': 30,
      'completion': 93,
      'status': 'Completed',
      'lastUpdated': 'Today, 08:45 AM',
      'conductedClasses': 28,
    },
  ];

  // Faculty Log Entries Data (Tab 1)
  final List<Map<String, dynamic>> _facultyLogs = [
    {
      'ref': 'LOG-9081',
      'date': '29-Jul-2026',
      'period': 'Period 2 (10:30 AM - 11:30 AM)',
      'code': 'IOT2028',
      'subject': 'Sensors & Actuators',
      'section': 'Year 2 - Sec A',
      'faculty': 'Prof. Muththukumaran M',
      'facultyCode': 'EMP-CSE-008',
      'topic': 'Unit 4: Digital Interfaces - SPI Clock Polarity & Phase',
      'method': 'Interactive PPT + Board Code',
      'attendance': '38/40',
      'status': 'Verified',
    },
    {
      'ref': 'LOG-9082',
      'date': '29-Jul-2026',
      'period': 'Period 4 (02:00 PM - 03:00 PM)',
      'code': 'IOT2031',
      'subject': 'Sensors & Interfacing Lab',
      'section': 'Year 2 - Sec A',
      'faculty': 'Prof. Ramakrishnan R',
      'facultyCode': 'EMP-CSE-009',
      'topic': 'Exp 9: MPU6050 Accelerometer & Gyro Yaw Pitch Roll',
      'method': 'Hands-on Lab Practice',
      'attendance': '40/40',
      'status': 'Verified',
    },
    {
      'ref': 'LOG-9083',
      'date': '29-Jul-2026',
      'period': 'Period 1 (08:45 AM - 09:45 AM)',
      'code': 'IOT2030',
      'subject': 'Cloud Protocols & MQTT',
      'section': 'Year 4 - Sec A',
      'faculty': 'Dr. K. Ravichandran',
      'facultyCode': 'EMP-CSE-010',
      'topic': 'Unit 3: MQTT Publisher & Subscriber implementation',
      'method': 'Smartboard Lecture',
      'attendance': '39/40',
      'status': 'Verified',
    },
    {
      'ref': 'LOG-9084',
      'date': '28-Jul-2026',
      'period': 'Period 3 (11:45 AM - 12:45 PM)',
      'code': 'IOT2029',
      'subject': 'Embedded Systems & RTOS',
      'section': 'Year 3 - Sec B',
      'faculty': 'Prof. K. Nandhini',
      'facultyCode': 'EMP-CSE-006',
      'topic': 'Unit 3: Task Scheduling and RTOS Semaphores',
      'method': 'Projector Slides + Q&A',
      'attendance': '38/40',
      'status': 'Verified',
    },
    {
      'ref': 'LOG-9085',
      'date': '28-Jul-2026',
      'period': 'Period 2 (10:30 AM - 11:30 AM)',
      'code': 'IOT2028',
      'subject': 'Sensors & Actuators',
      'section': 'Year 2 - Sec B',
      'faculty': 'Prof. R. Kavitha',
      'facultyCode': 'EMP-CSE-004',
      'topic': 'Unit 4: I2C communication protocol registers',
      'method': 'Blackboard Derivation',
      'attendance': '37/40',
      'status': 'Verified',
    },
  ];

  // Missed Logs Data (Tab 2)
  final List<Map<String, dynamic>> _missedLogs = [
    {
      'ref': 'MISSED-104',
      'date': '29-Jul-2026',
      'period': 'Period 3 (11:45 AM - 12:45 PM)',
      'code': 'IOT2030',
      'subject': 'Cloud Protocols & MQTT',
      'section': 'Year 4 - Sec A',
      'faculty': 'Dr. K. Ravichandran',
      'facultyCode': 'EMP-CSE-010',
      'severity': 'OVERDUE (>24h)',
      'reason': 'Medical Leave (No substitute assigned)',
    },
    {
      'ref': 'MISSED-105',
      'date': '29-Jul-2026',
      'period': 'Period 1 (08:45 AM - 09:45 AM)',
      'code': 'IOT2028',
      'subject': 'Sensors & Actuators',
      'section': 'Year 2 - Sec A',
      'faculty': 'Prof. Muththukumaran M',
      'facultyCode': 'EMP-CSE-008',
      'severity': 'OVERDUE (>24h)',
      'reason': 'Technical Seminar Duty',
    },
    {
      'ref': 'MISSED-106',
      'date': '28-Jul-2026',
      'period': 'Period 5 (03:15 PM - 04:15 PM)',
      'code': 'IOT2031',
      'subject': 'Sensors & Interfacing Lab',
      'section': 'Year 2 - Sec A',
      'faculty': 'Prof. Ramakrishnan R',
      'facultyCode': 'EMP-CSE-009',
      'severity': 'PENDING (<24h)',
      'reason': 'Clash with Practical Exam coordination',
    },
  ];

  @override
  void initState() {
    super.initState();
    _activeMainTab = widget.initialTab;
    _courses.clear();
    _facultyLogs.clear();
    _missedLogs.clear();
    _loadCoursesFromDatabase();
  }

  Future<void> _loadCoursesFromDatabase() async {
    final rows = await SupabaseClientHelper.select(
      'hod_course_diaries',
      schema: 'hod',
    );
    if (!mounted) return;
    setState(() {
      _courses
        ..clear()
        ..addAll(rows.asMap().entries.map((entry) {
          final row = entry.value;
          final completed = row['classes_completed'] ?? 0;
          final planned = row['total_classes_planned'] ?? 0;
          return {
            'sNo': entry.key + 1,
            'code': row['subject_code'] ?? 'null',
            'name': row['subject_name'] ?? 'null',
            'faculty': row['faculty_name'] ?? 'null',
            'facultyCode': 'null',
            'semester': row['semester'] ?? 'null',
            'batch': 'null',
            'covered': completed,
            'total': planned,
            'completion': row['syllabus_completion_pct'] ?? 0,
            'status': row['status'] ?? 'null',
            'lastUpdated': row['updated_at'] ?? 'null',
            'conductedClasses': completed,
          };
        }));
    });
  }

  @override
  void didUpdateWidget(covariant ClassDiaryMonitoringView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      setState(() {
        _activeMainTab = widget.initialTab;
        _editingCourseIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeMainTab == 1) {
      return _buildPersonalClassDiaryLayout();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMonitoring: true),
          const SizedBox(height: 12),

          // ── TABS FOR SYLLABUS COMPLETED, FACULTY ENTERED LOGS, MISSED LOGS ──
          _buildTopTabsRow(),
          const SizedBox(height: 12),

          // ── KPI CARDS DYNAMICALLY RENDERED ──
          _buildActiveKpiCards(),
          const SizedBox(height: 12),

          // ── SEARCH AND FILTERS ROW ──
          _buildFilterRow(),
          const SizedBox(height: 12),

          // ── MASTER SHEET TABLE CARD ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildSubTabContent(),
          ),
        ],
      ),
    );
  }

  // ── HEADER & BREADCRUMBS ──
  Widget _buildHeader({required bool isMonitoring}) {
    final String pageTitle = isMonitoring
        ? 'Class Diary Monitoring'
        : 'My Diary Entry';
    final String breadcrumbs = isMonitoring
        ? 'Academic Management > Lesson Plan & Class Diary > Class Diary Monitoring'
        : 'Academic Management > Lesson Plan & Class Diary > My Diary Entry';

    return HodSectionHeader(
      title: pageTitle,
      breadcrumb: breadcrumbs,
      academicYear: 'Academic Year 2025 - 2026',
    );
  }

  // ── TOP LEVEL SEGMENTED TABS ROW (Syllabus Completed, Faculty Entered Logs, Missed Logs) ──
  Widget _buildTopTabsRow() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          _buildTabSegment(
            0,
            'Syllabus Completed',
            Icons.verified_user_outlined,
          ),
          _buildTabSegment(1, 'Faculty Entered Logs', Icons.laptop_chromebook),
          _buildTabSegment(2, 'Missed Logs', Icons.calendar_today_outlined),
        ],
      ),
    );
  }

  Widget _buildTabSegment(int index, String label, IconData icon) {
    final bool isActive = _activeSubTab == index;
    return InkWell(
      onTap: () => setState(() {
        _activeSubTab = index;
        _searchQuery = '';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ACTIVE KPI CARDS RENDERER ──
  Widget _buildActiveKpiCards() {
    if (_activeSubTab == 0) {
      return _buildKpiRow(
        cards: [
          _KpiCardData(
            'Total Courses Monitored',
            '5',
            'Theory & Lab Courses',
            Icons.auto_stories_outlined,
            const Color(0xFF2563EB),
            const Color(0xFFEFF6FF),
          ),
          _KpiCardData(
            'Avg Syllabus Completion',
            '78.0%',
            'Across All Semesters',
            Icons.pie_chart_outline_rounded,
            const Color(0xFF9333EA),
            const Color(0xFFF5F3FF),
          ),
          _KpiCardData(
            'On Track / Completed',
            '4',
            'Meeting Target Milestones',
            Icons.check_circle_outline,
            const Color(0xFF10B981),
            const Color(0xFFECFDF5),
          ),
          _KpiCardData(
            'Behind Schedule Alert',
            '1',
            'Requires HOD Attention',
            Icons.report_problem_outlined,
            const Color(0xFFEF4444),
            const Color(0xFFFEF2F2),
          ),
        ],
      );
    } else if (_activeSubTab == 1) {
      return _buildKpiRow(
        cards: [
          _KpiCardData(
            'Total Logs Entered',
            '5',
            'Class Diary Records',
            Icons.description_outlined,
            const Color(0xFF2563EB),
            const Color(0xFFEFF6FF),
          ),
          _KpiCardData(
            'Logged Today',
            '2',
            'Recent Class Sessions',
            Icons.calendar_today_rounded,
            const Color(0xFF10B981),
            const Color(0xFFECFDF5),
          ),
          _KpiCardData(
            'Avg Student Attendance',
            '94.6%',
            'Across Logged Classes',
            Icons.people_outline,
            const Color(0xFF9333EA),
            const Color(0xFFF5F3FF),
          ),
          _KpiCardData(
            'Practical / Lab Logs',
            '1',
            'Hands-on Hardware',
            Icons.science_outlined,
            const Color(0xFF0D9488),
            const Color(0xFFF0FDFA),
          ),
        ],
      );
    } else {
      return _buildKpiRow(
        cards: [
          _KpiCardData(
            'Total Missed Diaries',
            '3',
            'Faculty Pending Entries',
            Icons.calendar_today_outlined,
            const Color(0xFFEF4444),
            const Color(0xFFFEF2F2),
          ),
          _KpiCardData(
            'Overdue (> 24 Hours)',
            '2',
            'High Severity Delays',
            Icons.error_outline,
            const Color(0xFFEF4444),
            const Color(0xFFFEF2F2),
          ),
          _KpiCardData(
            'Pending Entry (< 24h)',
            '1',
            'Recent Class Sessions',
            Icons.schedule,
            const Color(0xFFF97316),
            const Color(0xFFFFF7ED),
          ),
          _KpiCardData(
            'Log Compliance Score',
            '94.2%',
            'Department Standard',
            Icons.check_circle_outline,
            const Color(0xFF10B981),
            const Color(0xFFECFDF5),
          ),
        ],
      );
    }
  }

  Widget _buildKpiRow({required List<_KpiCardData> cards}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 3 * 16) / 4;
        return Row(
          children: cards.map((c) {
            return Padding(
              padding: EdgeInsets.only(right: cards.indexOf(c) == 3 ? 0 : 16),
              child: _buildKpiCard(
                title: c.title,
                value: c.value,
                subtitle: c.subtitle,
                icon: c.icon,
                accentColor: c.accentColor,
                bgColor: c.bgColor,
                width: cardWidth,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.005),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accentColor, size: 16),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ── SEARCH AND FILTERS ROW ──
  Widget _buildFilterRow() {
    String placeholderText = '';
    if (_activeSubTab == 0) {
      placeholderText = 'Search course code, subject name, or faculty...';
    } else if (_activeSubTab == 1) {
      placeholderText =
          'Search entered log by faculty name, course, or topic taught...';
    } else {
      placeholderText =
          'Search missed log by faculty member, course, or scheduled topic...';
    }

    return Row(
      children: [
        // Search field
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: placeholderText,
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_activeSubTab == 0) ...[
          const SizedBox(width: 16),
          _buildDropdownFilter(
            value: _selectedBatch,
            items: _batches,
            onChanged: (val) => setState(() => _selectedBatch = val!),
          ),
        ] else if (_activeSubTab == 2) ...[
          const SizedBox(width: 16),
          _buildDropdownFilter(
            value: _selectedDelay,
            items: _delays,
            onChanged: (val) => setState(() => _selectedDelay = val!),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
            size: 18,
          ),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── SUB-TAB CONTENT ROUTER ──
  Widget _buildSubTabContent() {
    if (_activeSubTab == 0) {
      return _buildSyllabusCompletedTable();
    } else if (_activeSubTab == 1) {
      return _buildFacultyLogsTable();
    } else {
      return _buildMissedLogsTable();
    }
  }

  // ── SUB-TAB 0: SYLLABUS COMPLETED TABLE ──
  Widget _buildSyllabusCompletedTable() {
    final filtered = _courses.where((c) {
      final codeMatches = c['code']!.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final nameMatches = c['name']!.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final facultyMatches = c['faculty']!.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final batchMatches =
          _selectedBatch == 'All Batches' || c['batch'] == _selectedBatch;
      final semMatches =
          _selectedSemester == 'All Semesters' ||
          c['semester'] == _selectedSemester;
      return (codeMatches || nameMatches || facultyMatches) &&
          batchMatches &&
          semMatches;
    }).toList();

    return Column(
      children: [
        // Table Header Label Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Department Syllabus Completion Master Sheet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Showing ${filtered.length} Courses',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Column Titles
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: const [
              SizedBox(
                width: 50,
                child: Text(
                  'S.No',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  'Course Code',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Course Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                child: Text(
                  'Topics Covered',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Per Completed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: Text(
                  'Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table Rows
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No matching courses found.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          Column(
            children: filtered.map((c) {
              final int completion = c['completion'];
              final String status = c['status'];

              Color progressBarColor;
              if (completion >= 85) {
                progressBarColor = const Color(0xFF10B981);
              } else if (completion >= 70) {
                progressBarColor = const Color(0xFF2563EB);
              } else {
                progressBarColor = const Color(0xFFF97316);
              }

              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // S.No
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${c['sNo']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    // Course Code
                    SizedBox(
                      width: 120,
                      child: Text(
                        c['code'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // Course Name
                    Expanded(
                      flex: 3,
                      child: Text(
                        c['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    // Topics Covered Badge
                    SizedBox(
                      width: 140,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${c['covered']}/${c['total']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Progress Bar
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: completion / 100.0,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressBarColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$completion%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions: View Breakdown
                    SizedBox(
                      width: 160,
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showDetailedLogsDialog(c),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                            label: const Text(
                              'View Breakdown',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
      ],
    );
  }

  // ── SUB-TAB 1: FACULTY LOGS TABLE ──
  Widget _buildFacultyLogsTable() {
    final filtered = _facultyLogs.where((log) {
      final codeMatches = log['code']!.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final facultyMatches = log['faculty']!.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final topicMatches = log['topic']!.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final methodMatches = log['method']!.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return codeMatches || facultyMatches || topicMatches || methodMatches;
    }).toList();

    return Column(
      children: [
        // Table Title Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Faculty Entered Class Diary Log Records',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Showing ${filtered.length} Entries',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Column Titles
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Log Ref & Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Faculty Member',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Course & Section',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  'Topic / Experiment Taught',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Pedagogy Method',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rows
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No matching entries found.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          Column(
            children: filtered.map((log) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ref & Date & Period
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['ref'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${log['date']}\n${log['period']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Faculty Member
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['faculty'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            log['facultyCode'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Course & Section
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log['code']}: ${log['subject']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            log['section'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Topic
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          log['topic'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                    // Pedagogy Method Badge
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            log['method'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── SUB-TAB 2: MISSED LOGS TABLE ──
  Widget _buildMissedLogsTable() {
    final filtered = _missedLogs.where((log) {
      final codeMatches = log['code']!.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final facultyMatches = log['faculty']!.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final subjectMatches = log['subject']!.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final severityMatches =
          _selectedDelay == 'All Delays' || log['severity'] == _selectedDelay;
      return (codeMatches || facultyMatches || subjectMatches) &&
          severityMatches;
    }).toList();

    return Column(
      children: [
        // Table Title Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Unsubmitted Faculty Class Diary Records',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Showing ${filtered.length} Missed Logs',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Column Titles
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Ref ID & Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Faculty Member',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Course & Section',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Delay Severity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: Text(
                  'HOD Action',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rows
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No missed class diary entries.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          Column(
            children: filtered.map((log) {
              final bool isOverdue = log['severity'] == 'OVERDUE (>24h)';
              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Ref & Date & Period
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['ref'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${log['date']}\n${log['period']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Faculty Member
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['faculty'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            log['facultyCode'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Course & Section
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log['code']}: ${log['subject']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            log['section'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Severity
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            log['severity'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isOverdue
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF97316),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Action button: Send Reminder
                    SizedBox(
                      width: 160,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HodToast.show(
                              context,
                              message:
                                  'Reminder notification alert sent to ${log['faculty']}.',
                              isSuccess: true,
                            );
                          },
                          icon: const Icon(
                            Icons.campaign_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Send Reminder',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── VIEW DETAILS LOG DIALOG ──
  void _showDetailedLogsDialog(Map<String, dynamic> c) {
    final List<Map<String, String>> breakdownData = [
      {
        'sNo': '1',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'Classical encryption techniques',
        'date': '21/06/2026 Hour 3',
        'hours': '1',
        'mode': 'Chalk & Talk',
        'order': '1',
      },
      {
        'sNo': '2',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'OSI security architecture',
        'date': '22/06/2026 Hour 1',
        'hours': '1',
        'mode': 'Chalk & Talk',
        'order': '2',
      },
      {
        'sNo': '3',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'product cryptosystem - cryptanalysis',
        'date': '23/06/2026 Hour 4',
        'hours': '1',
        'mode': 'Lecture',
        'order': '3',
      },
      {
        'sNo': '4',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic':
            'Model of network security - Security attacks, services and mechanisms',
        'date': '24/06/2026 Hour 2',
        'hours': '1',
        'mode': 'Lecture',
        'order': '4',
      },
      {
        'sNo': '5',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'perfect security - information theory',
        'date': '25/06/2026 Hour 5',
        'hours': '1',
        'mode': 'Lecture',
        'order': '5',
      },
      {
        'sNo': '6',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'Need for Security at Multiple levels, Security Policies',
        'date': '26/06/2026 Hour 3',
        'hours': '1',
        'mode': 'Lecture',
        'order': '6',
      },
      {
        'sNo': '7',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'Foundations of modern cryptography',
        'date': '27/06/2026 Hour 1',
        'hours': '1',
        'mode': 'Chalk & Talk',
        'order': '7',
      },
      {
        'sNo': '8',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic':
            'Security trends - Legal, Ethical and Professional Aspects of Security',
        'date': '28/06/2026 Hour 4',
        'hours': '1',
        'mode': 'Lecture',
        'order': '8',
      },
      {
        'sNo': '9',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic':
            'substitution techniques, transposition techniques, steganography',
        'date': '29/06/2026 Hour 2',
        'hours': '1',
        'mode': 'Lecture',
        'order': '9',
      },
      {
        'sNo': '10',
        'unit': 'Unit 2 - SYMMETRIC CRYPTOGRAPHY',
        'topic':
            'Algebraic structures - Modular arithmetic-Euclid\'s algorithm',
        'date': '01/07/2026 Hour 3',
        'hours': '1',
        'mode': 'Chalk & Talk',
        'order': '10',
      },
      {
        'sNo': '11',
        'unit': 'Unit 2 - SYMMETRIC CRYPTOGRAPHY',
        'topic': 'Congruence and matrices',
        'date': '02/07/2026 Hour 1',
        'hours': '1',
        'mode': 'Chalk & Talk',
        'order': '11',
      },
      {
        'sNo': '12',
        'unit': 'Unit 2 - SYMMETRIC CRYPTOGRAPHY',
        'topic': 'Groups, Rings, Fields- Finite fields',
        'date': '03/07/2026 Hour 4',
        'hours': '1',
        'mode': 'Chalk & Talk',
        'order': '12',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 1200,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Syllabus Completion Breakdown: ${c['code']} - ${c['name']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Detailed syllabus tracking entries for ${c['faculty']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),

              // Scrollable table container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                          columnWidths: const {
                            0: FixedColumnWidth(60), // S.No
                            1: FixedColumnWidth(240), // Unit
                            2: FixedColumnWidth(420), // Topic
                            3: FixedColumnWidth(180), // Date & Period
                            4: FixedColumnWidth(80), // Hours
                            5: FixedColumnWidth(130), // Mode
                            6: FixedColumnWidth(80), // Order
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            // Table Header Row
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                              ),
                              children: [
                                _buildGridHeaderCell('S.No'),
                                _buildGridHeaderCell('Unit'),
                                _buildGridHeaderCell('Topic'),
                                _buildGridHeaderCell('Date & Period'),
                                _buildGridHeaderCell('Hours'),
                                _buildGridHeaderCell('Mode'),
                                _buildGridHeaderCell('Order'),
                              ],
                            ),
                            // Data Rows
                            ...breakdownData.map((row) {
                              return TableRow(
                                children: [
                                  _buildGridTableCell(
                                    row['sNo']!,
                                    isSNo: true,
                                    isBold: true,
                                  ),
                                  _buildGridTableCell(row['unit']!),
                                  _buildGridTableCell(row['topic']!),
                                  _buildGridTableCell(row['date']!),
                                  _buildGridTableCell(row['hours']!),
                                  _buildGridTableCell(row['mode']!),
                                  _buildGridTableCell(row['order']!),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer Close Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Close Breakdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildGridTableCell(
    String text, {
    bool isSNo = false,
    bool isBold = false,
  }) {
    return Container(
      color: isSNo ? const Color(0xFFF8FAFC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  // ── PERSONAL CLASS DIARY LAYOUT (My Diary Entry - TAB 1 ACTIVE) ──
  Widget _buildPersonalClassDiaryLayout() {
    final List<Map<String, dynamic>> myCourses = [
      {
        'sNo': 1,
        'code': 'IOT2028',
        'name': 'IoT Sensors & Actuators',
        'covered': 32,
        'total': 40,
        'completion': 80,
      },
      {
        'sNo': 2,
        'code': 'IOT2029',
        'name': 'Embedded C Architecture & RTOS',
        'covered': 45,
        'total': 45,
        'completion': 100,
      },
      {
        'sNo': 3,
        'code': 'IOT2030',
        'name': 'Cloud Protocols (MQTT/CoAP)',
        'covered': 18,
        'total': 45,
        'completion': 40,
      },
      {
        'sNo': 4,
        'code': 'EC2045',
        'name': 'Digital Signal Processing',
        'covered': 28,
        'total': 40,
        'completion': 70,
      },
      {
        'sNo': 5,
        'code': 'EC2047',
        'name': 'Communication Systems',
        'covered': 36,
        'total': 40,
        'completion': 90,
      },
    ];

    final List<Map<String, String>> selectedBreakdown = [
      {
        'sNo': '1',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'Classical encryption techniques',
        'date': '21/06/2026 Hour 3',
        'hours': '1',
        'mode': 'Chalk & Talk',
        'order': '1',
      },
      {
        'sNo': '2',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'OSI security architecture',
        'date': '22/06/2026 Hour 1',
        'hours': '1',
        'mode': 'Chalk & Talk',
        'order': '2',
      },
      {
        'sNo': '3',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'product cryptosystem - cryptanalysis',
        'date': '23/06/2026 Hour 4',
        'hours': '1',
        'mode': 'Lecture',
        'order': '3',
      },
      {
        'sNo': '4',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic':
            'Model of network security - Security attacks, services and mechanisms',
        'date': '24/06/2026 Hour 2',
        'hours': '1',
        'mode': 'Lecture',
        'order': '4',
      },
      {
        'sNo': '5',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'perfect security - information theory',
        'date': '25/06/2026 Hour 5',
        'hours': '1',
        'mode': 'Lecture',
        'order': '5',
      },
      {
        'sNo': '6',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'Need for Security at Multiple levels, Security Policies',
        'date': '26/06/2026 Hour 3',
        'hours': '1',
        'mode': 'Lecture',
        'order': '6',
      },
      {
        'sNo': '7',
        'unit': 'Unit 1 - INTRODUCTION',
        'topic': 'Foundations of modern cryptography',
        'date': '27/06/2026 Hour 1',
        'hours': '1',
        'mode': 'Chalk & Talk',
        'order': '7',
      },
    ];

    if (_editingCourseIndex != null) {
      final selectedCourse = myCourses.firstWhere(
        (c) => c['sNo'] == _editingCourseIndex,
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            HodSectionHeader(
              title: 'Teaching & Academic Curriculum Module',
              breadcrumb:
                  'Teaching > Courses, Timetable, Syllabus, Details & Course Diary',
              academicYear: 'Academic Year 2025 - 2026',
              actions: [
                ElevatedButton.icon(
                  onPressed: () {
                    HodToast.show(
                      context,
                      message: 'Teaching File PDF export started...',
                      isSuccess: true,
                    );
                  },
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Export Teaching File',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Back button and Selected Course Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _editingCourseIndex = null;
                    });
                  },
                  icon: const Icon(
                    Icons.keyboard_arrow_left_rounded,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                  label: const Text(
                    'Back to Class Diary',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${selectedCourse['code']} - ${selectedCourse['name']}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Faculty: Prof. Muththukumaran M | Batch 2023-2027 | Sem IV',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Unit-wise topics card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Unit-Wise Topics and Hours Order',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Table(
                      border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                      columnWidths: const {
                        0: FixedColumnWidth(60), // S.No
                        1: FixedColumnWidth(240), // Unit
                        2: FixedColumnWidth(420), // Topic
                        3: FixedColumnWidth(180), // Date & Period
                        4: FixedColumnWidth(80), // Hours
                        5: FixedColumnWidth(130), // Mode
                        6: FixedColumnWidth(80), // Order
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                          ),
                          children: [
                            _buildGridHeaderCell('S.No'),
                            _buildGridHeaderCell('Unit'),
                            _buildGridHeaderCell('Topic'),
                            _buildGridHeaderCell('Date & Period'),
                            _buildGridHeaderCell('Hours'),
                            _buildGridHeaderCell('Mode'),
                            _buildGridHeaderCell('Order'),
                          ],
                        ),
                        ...selectedBreakdown.map((row) {
                          return TableRow(
                            children: [
                              _buildGridTableCell(
                                row['sNo']!,
                                isSNo: true,
                                isBold: true,
                              ),
                              _buildGridTableCell(row['unit']!),
                              _buildGridTableCell(row['topic']!),
                              _buildGridTableCell(row['date']!),
                              _buildGridTableCell(row['hours']!),
                              _buildGridTableCell(row['mode']!),
                              _buildGridTableCell(row['order']!),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          HodSectionHeader(
            title: 'Teaching & Academic Curriculum Module',
            breadcrumb:
                'Teaching > Courses, Timetable, Syllabus, Details & Course Diary',
            academicYear: 'Academic Year 2025 - 2026',
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  HodToast.show(
                    context,
                    message: 'Teaching File PDF export started...',
                    isSuccess: true,
                  );
                },
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Export Teaching File',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // KPI Cards
          _buildKpiRow(
            cards: [
              const _KpiCardData(
                'Classes Conducted',
                '42 Classes',
                'Semester Total',
                Icons.calendar_today_rounded,
                Color(0xFF2563EB),
                Color(0xFFEFF6FF),
              ),
              const _KpiCardData(
                'Classes Missed',
                '0 Missed',
                '100% Conducted',
                Icons.check_circle_outline,
                Color(0xFF10B981),
                Color(0xFFECFDF5),
              ),
              const _KpiCardData(
                'Extra Classes',
                '4 Classes',
                'Lab Practicals',
                Icons.add_circle_outline_rounded,
                Color(0xFF9333EA),
                Color(0xFFF5F3FF),
              ),
              const _KpiCardData(
                'Pending Entries',
                '0 Entry',
                'Requires Sign-off',
                Icons.pending_actions_rounded,
                Color(0xFFF97316),
                Color(0xFFFFF7ED),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tracker Table Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Class Diary & Course Topics Tracker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Table Header row
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 50,
                        child: Text(
                          'S.No',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          'Course Code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Course Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: Text(
                          'Topics Covered',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Per Completed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows
                Column(
                  children: myCourses.map((c) {
                    final int completion = c['completion'];
                    Color progressBarColor;
                    if (completion >= 85) {
                      progressBarColor = const Color(0xFF10B981);
                    } else if (completion >= 70) {
                      progressBarColor = const Color(0xFF2563EB);
                    } else {
                      progressBarColor = const Color(0xFFF97316);
                    }

                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${c['sNo']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Text(
                              c['code'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              c['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${c['covered']}/${c['total']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: completion / 100.0,
                                      minHeight: 6,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progressBarColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$completion%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _editingCourseIndex = c['sNo'];
                                  });
                                },
                                icon: const Icon(
                                  Icons.playlist_add_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Enter the Diary',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
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
          ),
        ],
      ),
    );
  }
}

class _KpiCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  const _KpiCardData(
    this.title,
    this.value,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.bgColor,
  );
}
