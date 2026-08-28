import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../utils/file_downloader.dart';
import '../erp_repository.dart';
import '../services/student_service.dart';
import '../services/faculty_service.dart';
import '../services/department_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _selectedTab =
      0; // 0: Analytics, 1: Generator, 2: Quick Catalog, 3: Student Roster, 4: Archives

  String _classification = 'Academic Attendance & Defaulter Registry';
  String _selectedYear = '2025-2026';
  String _selectedSemester = 'All Semesters';
  String _selectedDept = 'All Departments';
  String _selectedBatch = 'All Batches';
  bool _includeDetails = true;
  bool _isGenerating = false;

  // Student Roster Filters
  String _rptDept = 'All';
  String _rptBatch = 'All';
  String _rptSection = 'All';
  String _rosterSearch = '';

  // Chart Filters
  String _chartDept = 'All';

  bool _hasInitializedQueryParam = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedQueryParam) {
      final typeParam = GoRouter.of(
        context,
      ).routerDelegate.currentConfiguration.uri.queryParameters['type'];
      if (typeParam == 'attendance') {
        _classification = 'Academic Attendance & Defaulter Registry';
        _selectedTab = 1;
      } else if (typeParam == 'marks' || typeParam == 'results') {
        _classification = 'Semester Examination Results & Rank List';
        _selectedTab = 1;
      } else if (typeParam == 'fees') {
        _classification = 'Tuition & Hostel Fee Collection Status';
        _selectedTab = 1;
      } else if (typeParam == 'workload') {
        _classification = 'Faculty Workload & Research Publications';
        _selectedTab = 1;
      } else if (typeParam == 'certificates') {
        _classification = 'Certificates & Bonafide Issuance Registry';
        _selectedTab = 1;
      }
      _hasInitializedQueryParam = true;
    }
  }

  Future<void> _generateReport(String format) async {
    if (_formKey.currentState?.validate() ?? true) {
      setState(() => _isGenerating = true);

      try {
        final reportCode =
            'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        final todayStr = DateTime.now().toIso8601String().split('T')[0];

        // Fetch live records directly from Supabase DB
        final students = await StudentService.fetchStudents();
        final faculty = await FacultyService.fetchFaculty();
        final departments = await DepartmentService.fetchDepartments();

        final newReport = ReportModel(
          id: 'REP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          code: reportCode,
          title: '$_classification [$_selectedYear]',
          status: 'Completed',
          format: format,
        );

        ref.read(reportsProvider.notifier).addReport(newReport);

        if (format == 'PDF') {
          final pdfSummary =
              'Institutional Report: $_classification\n'
              'Academic Year: $_selectedYear | Department: $_selectedDept\n'
              'Total Active Students: ${students.length}\n'
              'Total Active Faculty: ${faculty.length}\n'
              'Total Departments: ${departments.length}\n'
              'Generated Date: $todayStr';
          FileDownloader.downloadPdf(
            filename:
                '${newReport.code}_${_classification.replaceAll(" ", "_")}_$todayStr.pdf',
            title: pdfSummary,
            content: pdfSummary,
          );
        } else {
          final buffer = StringBuffer();
          buffer.writeln(
            'Report Code,Classification,Academic Year,Department,Total Students,Total Faculty,Total Departments,Generated Date',
          );
          buffer.writeln(
            '"${newReport.code}","$_classification","$_selectedYear","$_selectedDept",${students.length},${faculty.length},${departments.length},"$todayStr"',
          );
          buffer.writeln();
          buffer.writeln('Detailed Student Directory:');
          buffer.writeln('ID,Name,Email,Department,Status');
          for (final s in students) {
            final id =
                s['student_id']?.toString() ??
                s['roll_no']?.toString() ??
                'STU';
            final name =
                s['full_name']?.toString() ??
                s['name']?.toString() ??
                'Student';
            final email =
                s['institute_email']?.toString() ??
                s['personal_email']?.toString() ??
                '';
            final dept =
                s['department']?.toString() ?? s['dept']?.toString() ?? 'CSE';
            buffer.writeln(
              '$id,"$name",$email,$dept,${s['status'] ?? 'Active'}',
            );
          }
          FileDownloader.downloadString(
            filename:
                '${newReport.code}_${_classification.replaceAll(" ", "_")}_$todayStr.${format == 'CSV' ? 'csv' : 'xlsx'}',
            content: buffer.toString(),
          );
        }

        setState(() => _isGenerating = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Report generated & downloaded: ${newReport.code} ($format)',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() => _isGenerating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to fetch latest data from database. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _quickDownload(String title, String format) async {
    final reportCode =
        'QREP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    final newReport = ReportModel(
      id: 'QREP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      code: reportCode,
      title: '$title [2025-2026]',
      status: 'Completed',
      format: format,
    );
    ref.read(reportsProvider.notifier).addReport(newReport);

    final students = await StudentService.fetchStudents();
    final faculty = await FacultyService.fetchFaculty();

    if (format == 'PDF') {
      final summary =
          '$title Report (Academic Year 2025-2026)\n'
          'Total Students Enrolled: ${students.length}\n'
          'Total Faculty Members: ${faculty.length}\n'
          'Export Date: $todayStr';
      FileDownloader.downloadPdf(
        filename: '${title.replaceAll(" ", "_")}_$todayStr.pdf',
        title: summary,
        content: summary,
      );
    } else {
      final buffer = StringBuffer();
      buffer.writeln(
        'Report Title,Academic Year,Total Students,Total Faculty,Export Date',
      );
      buffer.writeln(
        '"$title","2025-2026",${students.length},${faculty.length},"$todayStr"',
      );
      FileDownloader.downloadString(
        filename:
            '${title.replaceAll(" ", "_")}_$todayStr.${format.toLowerCase()}',
        content: buffer.toString(),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded $title ($format) successfully!'),
          backgroundColor: const Color(0xFF0052CC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6F9),
    appBar: AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reports & Analytics Hub',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            'Institutional Academic, Attendance, Financial & Administrative Intelligence',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add_chart_rounded, size: 16),
            label: const Text(
              'Generate Report',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () => setState(() => _selectedTab = 1),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. EXECUTIVE ERP KPI METRICS CARDS ───────────────────
            _buildExecutiveKpiGrid(),
            const SizedBox(height: 16),

            // ── 2. SEGMENTED NAVIGATION TABS ─────────────────────────
            _buildSegmentedTabBar(),
            const SizedBox(height: 16),

            // ── 3. TAB CONTENT VIEWS ──────────────────────────────────
            IndexedStack(
              index: _selectedTab,
              children: [
                _buildTab0VisualAnalytics(),
                _buildTab1ReportGenerator(),
                _buildTab2QuickCatalog(),
                _buildTab3StudentRoster(),
                _buildTab4ArchivesHistory(),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // ── EXECUTIVE KPI METRICS (5 CARDS) ───────────────────────────────────
  Widget _buildExecutiveKpiGrid() {
    final archives = ref.watch(reportsProvider);
    final totalReports = archives.length + 1480;

    final kpis = [
      {
        'title': 'Overall Attendance',
        'value': '94.2%',
        'badge': '↑ 1.4% MoM',
        'badgeColor': const Color(0xFF16A34A),
        'sub': 'Target >= 85% | 4,206 Students',
        'icon': Icons.fact_check_rounded,
        'color': const Color(0xFF0052CC),
      },
      {
        'title': 'Academic Pass Rate',
        'value': '88.5%',
        'badge': '↑ 2.1% YoY',
        'badgeColor': const Color(0xFF16A34A),
        'sub': '2025-26 Semester Results',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Fee Collection',
        'value': '₹4.82 Cr',
        'badge': '92.4% Target',
        'badgeColor': const Color(0xFF0284C7),
        'sub': 'Tuition & Hostel Balance',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF0D9488),
      },
      {
        'title': 'Campus Placement',
        'value': '84.6%',
        'badge': '340 Placed',
        'badgeColor': const Color(0xFFD97706),
        'sub': '2025-26 Eligible Directory',
        'icon': Icons.work_history_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'title': 'Reports Generated',
        'value': '$totalReports',
        'badge': 'Updated Today',
        'badgeColor': const Color(0xFF4F46E5),
        'sub': 'Archived & Downloaded',
        'icon': Icons.file_present_rounded,
        'color': const Color(0xFF4F46E5),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100
            ? 5
            : (constraints.maxWidth > 700 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 104,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, idx) {
            final item = kpis[idx];
            final color = item['color']! as Color;
            final badgeColor = item['badgeColor']! as Color;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['title']! as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          item['icon']! as IconData,
                          size: 15,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    item['value']! as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['badge']! as String,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item['sub']! as String,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── SEGMENTED TAB BAR ────────────────────────────────────────────────
  Widget _buildSegmentedTabBar() {
    final tabs = [
      {'label': 'Visual Analytics', 'icon': Icons.bar_chart_rounded},
      {'label': 'Custom Report Generator', 'icon': Icons.tune_rounded},
      {'label': 'Quick Report Catalog', 'icon': Icons.flash_on_rounded},
      {'label': 'Student Directory', 'icon': Icons.groups_rounded},
      {'label': 'Download Archives', 'icon': Icons.folder_zip_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isSelected = _selectedTab == idx;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => setState(() => _selectedTab = idx),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0052CC)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item['icon']! as IconData,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['label']! as String,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── TAB 0: VISUAL ANALYTICS ──────────────────────────────────────────
  Widget _buildTab0VisualAnalytics() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Charts Row
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 850) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAttendanceBarChartCard()),
                const SizedBox(width: 14),
                Expanded(child: _buildGradePieChartCard()),
              ],
            );
          }
          return Column(
            children: [
              _buildAttendanceBarChartCard(),
              const SizedBox(height: 14),
              _buildGradePieChartCard(),
            ],
          );
        },
      ),
      const SizedBox(height: 16),

      // Department Performance Matrix Card
      _buildDepartmentPerformanceMatrix(),
    ],
  );

  Widget _buildAttendanceBarChartCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Monthly Attendance Rate (%)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _chartDept,
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0052CC),
                  ),
                  items: ['All', 'CSE', 'ECE', 'IT', 'AIDS', 'IoT']
                      .map(
                        (d) =>
                            DropdownMenuItem(value: d, child: Text('Dept: $d')),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _chartDept = v!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Institutional average attendance trend over months',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF0F172A),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                    return BarTooltipItem(
                      '${months[group.x]}: ${rod.toY.toInt()}%',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                      if (v.toInt() >= 0 && v.toInt() < months.length) {
                        return Text(
                          months[v.toInt()],
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (v, meta) {
                      if (v % 25 == 0)
                        return Text(
                          '${v.toInt()}%',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF94A3B8),
                          ),
                        );
                      return const Text('');
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: 92,
                      color: const Color(0xFF0052CC),
                      width: 14,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: 95,
                      color: const Color(0xFF0052CC),
                      width: 14,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: 89,
                      color: const Color(0xFF0052CC),
                      width: 14,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 3,
                  barRods: [
                    BarChartRodData(
                      toY: 96,
                      color: const Color(0xFF0052CC),
                      width: 14,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 4,
                  barRods: [
                    BarChartRodData(
                      toY: 94,
                      color: const Color(0xFF0052CC),
                      width: 14,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 5,
                  barRods: [
                    BarChartRodData(
                      toY: 97,
                      color: const Color(0xFF16A34A),
                      width: 14,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildGradePieChartCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Semester Grade Distribution',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Student academic performance breakdown',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 34,
                  sections: [
                    PieChartSectionData(
                      color: const Color(0xFF16A34A),
                      value: 35,
                      title: '35%',
                      radius: 32,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      color: const Color(0xFF0052CC),
                      value: 40,
                      title: '40%',
                      radius: 32,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      color: const Color(0xFFF59E0B),
                      value: 20,
                      title: '20%',
                      radius: 32,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      color: const Color(0xFFEF4444),
                      value: 5,
                      title: '5%',
                      radius: 32,
                      titleStyle: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GradeLegendRow(
                    color: Color(0xFF16A34A),
                    label: 'O (Outstanding)',
                    pct: '35% (1,472)',
                  ),
                  SizedBox(height: 6),
                  _GradeLegendRow(
                    color: Color(0xFF0052CC),
                    label: 'A+ (Excellent)',
                    pct: '40% (1,682)',
                  ),
                  SizedBox(height: 6),
                  _GradeLegendRow(
                    color: Color(0xFFF59E0B),
                    label: 'B / B+ (Good)',
                    pct: '20% (841)',
                  ),
                  SizedBox(height: 6),
                  _GradeLegendRow(
                    color: Color(0xFFEF4444),
                    label: 'F (Re-Appear)',
                    pct: '5% (211)',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildDepartmentPerformanceMatrix() {
    final matrixData = [
      {
        'dept': 'CSE - Computer Science',
        'students': 1350,
        'att': '95.4%',
        'pass': '91.2%',
        'fee': '94.8%',
        'placement': '89.2%',
        'status': 'Excellent',
      },
      {
        'dept': 'ECE - Electronics & Comm.',
        'students': 1020,
        'att': '93.8%',
        'pass': '88.5%',
        'fee': '92.1%',
        'placement': '85.0%',
        'status': 'Good',
      },
      {
        'dept': 'IT - Information Tech.',
        'students': 840,
        'att': '94.6%',
        'pass': '89.0%',
        'fee': '93.5%',
        'placement': '87.4%',
        'status': 'Excellent',
      },
      {
        'dept': 'AIDS - Artificial Intel.',
        'students': 640,
        'att': '93.2%',
        'pass': '87.8%',
        'fee': '90.4%',
        'placement': '82.6%',
        'status': 'Good',
      },
      {
        'dept': 'IoT - Internet of Things',
        'students': 356,
        'att': '92.5%',
        'pass': '85.0%',
        'fee': '88.9%',
        'placement': '78.5%',
        'status': 'Average',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Department Performance Scorecard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Comparative metrics across academic units',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(
                  Icons.download_rounded,
                  size: 14,
                  color: Color(0xFF0052CC),
                ),
                label: const Text(
                  'Export Scorecard',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0052CC),
                  ),
                ),
                onPressed: () =>
                    _quickDownload('Department_Performance_Scorecard', 'PDF'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMaxHeight: 44,
              columnSpacing: 24,
              horizontalMargin: 8,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(
                  label: Text(
                    'Department',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Pass %',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Fee Cleared',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Placement',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
              rows: matrixData.map((row) {
                final status = row['status']! as String;
                final badgeColor = status == 'Excellent'
                    ? const Color(0xFF16A34A)
                    : (status == 'Good'
                          ? const Color(0xFF0052CC)
                          : const Color(0xFFD97706));

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        row['dept']! as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${row['students']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        row['att']! as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0052CC),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        row['pass']! as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        row['fee']! as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        row['placement']! as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 1: CUSTOM REPORT GENERATOR ────────────────────────────────────
  Widget _buildTab1ReportGenerator() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052CC).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF0052CC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure & Generate ERP Report',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Select specific criteria to compile custom institutional datasets & exports',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Report Classification
          const Text(
            'Report Classification / Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _classification,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              fillColor: const Color(0xFFF8FAFC),
              filled: true,
            ),
            items:
                [
                      'Academic Attendance & Defaulter Registry',
                      'Semester Examination Results & Rank List',
                      'Student Grade & Marksheet Summary',
                      'Tuition & Hostel Fee Collection Status',
                      'Financial Defaulters & Dues Breakdown',
                      'Faculty Workload & Research Publications',
                      'Campus Placement & Drive Eligibility Directory',
                      'Student Admission & Quota Demographics',
                      'Hall Ticket & Exam Clearance Eligibility',
                      'Certificates & Bonafide Issuance Registry',
                    ]
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _classification = val);
            },
          ),
          const SizedBox(height: 16),

          // 2 Column Grid for Year & Semester
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Academic Year',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedYear,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                              ),
                              items: ['2025-2026', '2024-2025', '2023-2024']
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text(
                                        y,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedYear = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Semester Scope',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSemester,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                              ),
                              items:
                                  [
                                        'All Semesters',
                                        'Odd Semesters (1,3,5,7)',
                                        'Even Semesters (2,4,6,8)',
                                        'Semester 1',
                                        'Semester 2',
                                        'Semester 3',
                                        'Semester 4',
                                        'Semester 5',
                                        'Semester 6',
                                        'Semester 7',
                                        'Semester 8',
                                      ]
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedSemester = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Department Filter',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedDept,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                              ),
                              items:
                                  [
                                        'All Departments',
                                        'CSE - Computer Science',
                                        'ECE - Electronics & Comm.',
                                        'IT - Information Tech.',
                                        'AIDS - Artificial Intel.',
                                        'IoT - Internet of Things',
                                        'Mechanical Engineering',
                                      ]
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(
                                            d,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedDept = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Batch Filter',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedBatch,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                              ),
                              items:
                                  [
                                        'All Batches',
                                        '2022-2026',
                                        '2023-2027',
                                        '2024-2028',
                                        '2025-2029',
                                      ]
                                      .map(
                                        (b) => DropdownMenuItem(
                                          value: b,
                                          child: Text(
                                            b,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedBatch = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Toggle switch for detailed tables
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SwitchListTile(
              title: const Text(
                'Include Detailed Student Directory & Record List',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              subtitle: const Text(
                'Appends individual student entries table alongside summary metrics.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              value: _includeDetails,
              activeThumbColor: const Color(0xFF0052CC),
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _includeDetails = val),
            ),
          ),
          const SizedBox(height: 20),

          // Export Buttons Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text(
                    'Export PDF Report',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isGenerating
                      ? null
                      : () => _generateReport('PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.table_chart_rounded, size: 18),
                  label: const Text(
                    'Export Excel (.xlsx)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isGenerating
                      ? null
                      : () => _generateReport('Excel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF0052CC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(
                    Icons.description_rounded,
                    size: 18,
                    color: Color(0xFF0052CC),
                  ),
                  label: const Text(
                    'Export CSV Data',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0052CC),
                    ),
                  ),
                  onPressed: _isGenerating
                      ? null
                      : () => _generateReport('CSV'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ── TAB 2: QUICK REPORT CATALOG (1-CLICK DOWNLOADS) ───────────────────
  Widget _buildTab2QuickCatalog() {
    final catalog = [
      {
        'title': 'Attendance Defaulters List (<75%)',
        'sub':
            'Comprehensive directory of students ineligible for end-semester examinations due to shortage.',
        'tag': 'Exam Eligibility',
        'format': 'PDF',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFDC2626),
      },
      {
        'title': 'Semester Merit Rank & Toppers List',
        'sub':
            'Top 10 GPA performers list categorized by department and batch for academic awards.',
        'tag': 'Academic Honors',
        'format': 'Excel',
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'title': 'Tuition & Hostel Fee Pending Summary',
        'sub':
            'Student-wise outstanding balance ledger with payment deadline tracking.',
        'tag': 'Finance & Fees',
        'format': 'PDF',
        'icon': Icons.payments_rounded,
        'color': const Color(0xFF0052CC),
      },
      {
        'title': 'Placement Drive Eligible Directory (CGPA >= 6.5)',
        'sub':
            'Verified list of final year students meeting minimum placement eligibility thresholds.',
        'tag': 'Campus Placements',
        'format': 'Excel',
        'icon': Icons.work_rounded,
        'color': const Color(0xFF16A34A),
      },
      {
        'title': 'Institutional NAAC / NBA Demographic Summary',
        'sub':
            'Community (OC/BC/MBC/SC/ST) & gender ratio distribution report for accreditation audits.',
        'tag': 'Accreditation',
        'format': 'PDF',
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Issued Certificates & Transcripts Log',
        'sub':
            'Registry of Bonafide, Transfer (TC), and Conduct certificates issued during this academic session.',
        'tag': 'Administrative',
        'format': 'CSV',
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFF0284C7),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 850 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 140,
          ),
          itemCount: catalog.length,
          itemBuilder: (context, idx) {
            final item = catalog[idx];
            final color = item['color']! as Color;
            final title = item['title']! as String;
            final format = item['format']! as String;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon']! as IconData,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item['tag']! as String,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    format,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['sub']! as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => _quickDownload(title, format),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Instant Download',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.file_download_rounded,
                                  size: 15,
                                  color: color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── TAB 3: STUDENT DEMOGRAPHICS & ROSTER ─────────────────────────────
  Widget _buildTab3StudentRoster() {
    final allUsers = ref.watch(usersProvider);
    final allStudents = allUsers.where((u) => u.isStudent).toList();

    final filtered = allStudents.where((s) {
      if (_rptDept != 'All' && s.department != _rptDept) return false;
      if (_rptBatch != 'All' && s.batch != _rptBatch) return false;
      if (_rptSection != 'All' && s.section != _rptSection) return false;
      if (_rosterSearch.isNotEmpty &&
          !s.name.toLowerCase().contains(_rosterSearch.toLowerCase()) &&
          !(s.rollNumber?.toLowerCase().contains(_rosterSearch.toLowerCase()) ??
              false)) {
        return false;
      }
      return true;
    }).toList();

    final mCount = filtered.where((s) => s.gender == 'Male').length;
    final fCount = filtered.where((s) => s.gender == 'Female').length;

    final depts = ['All', ...allStudents.map((s) => s.department).toSet()];
    final batches = [
      'All',
      ...allStudents
          .map((s) => s.batch ?? '')
          .where((b) => b.isNotEmpty)
          .toSet(),
    ];
    final sections = ['All', 'A', 'B', 'C', 'D'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Directory & Demographics',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search student name or roll no...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (v) => setState(() => _rosterSearch = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _rptDropdown(
                            'Department',
                            _rptDept,
                            depts,
                            (v) => setState(() => _rptDept = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _rptDropdown(
                            'Batch',
                            _rptBatch,
                            batches,
                            (v) => setState(() => _rptBatch = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _rptDropdown(
                            'Section',
                            _rptSection,
                            sections,
                            (v) => setState(() => _rptSection = v!),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search student name or roll no...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (v) => setState(() => _rosterSearch = v),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _rptDropdown(
                              'Department',
                              _rptDept,
                              depts,
                              (v) => setState(() => _rptDept = v!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _rptDropdown(
                              'Batch',
                              _rptBatch,
                              batches,
                              (v) => setState(() => _rptBatch = v!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _rptDropdown(
                              'Section',
                              _rptSection,
                              sections,
                              (v) => setState(() => _rptSection = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Count stat pills
        Row(
          children: [
            _demographicPill(
              'Total Filtered',
              '${filtered.length}',
              Icons.groups_rounded,
              const Color(0xFF0052CC),
            ),
            const SizedBox(width: 10),
            _demographicPill(
              'Male Students',
              '$mCount',
              Icons.male_rounded,
              const Color(0xFF2563EB),
            ),
            const SizedBox(width: 10),
            _demographicPill(
              'Female Students',
              '$fCount',
              Icons.female_rounded,
              Colors.pink,
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
              label: const Text(
                'Export Filtered Directory PDF',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _quickDownload(
                'Filtered_Student_Demographics_Directory',
                'PDF',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Student Table
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live Filtered Student Directory Table',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No student records match the selected filter criteria.',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 38,
                    dataRowMaxHeight: 44,
                    columnSpacing: 24,
                    horizontalMargin: 8,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'S.No',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Roll No',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Student Name',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Department',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Section',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Community',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                    rows: filtered.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              s.rollNumber ?? '—',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0052CC),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              s.department.split(' ').first,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              s.section ?? 'A',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              s.gender ?? 'Male',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              s.community ?? 'BC',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _demographicPill(
    String label,
    String value,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withAlpha(51)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _rptDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ],
  );

  // ── TAB 4: DOWNLOAD ARCHIVES & HISTORY ────────────────────────────────
  Widget _buildTab4ArchivesHistory() {
    final archives = ref.watch(reportsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generated Report Archives Log',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'History of compiled institutional reports and downloads',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${archives.length} Records',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMaxHeight: 44,
              columnSpacing: 28,
              horizontalMargin: 8,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(
                  label: Text(
                    'Report Code',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Report Title',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Format',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Action',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
              rows: archives.map((rpt) {
                final isPdf = rpt.format == 'PDF';

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        rpt.code,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0052CC),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        rpt.title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isPdf
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A))
                                  .withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rpt.format,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPdf
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 18,
                          color: Color(0xFF0052CC),
                        ),
                        onPressed: () => _quickDownload(rpt.title, rpt.format),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeLegendRow extends StatelessWidget {
  const _GradeLegendRow({
    required this.color,
    required this.label,
    required this.pct,
  });
  final Color color;
  final String label;
  final String pct;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Text(
        pct,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    ],
  );
}
