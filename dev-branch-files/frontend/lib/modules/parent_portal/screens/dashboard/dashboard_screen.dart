import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';
import '../../models/models.dart';
import '../communication/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onStudentChanged;
  final Function(int)? onNavigate;

  const DashboardScreen({
    super.key,
    this.onStudentChanged,
    this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final student = MockData.selectedStudent;
    final parent = MockData.currentParent;
    final attendance = MockData.mockAttendance;
    final academic = MockData.mockAcademicPerformance;
    final fees = MockData.mockFees;
    final exams = MockData.upcomingExams;

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Hero Welcome Banner ────────────────────────────────────
            _buildWelcomeBanner(parent, student),
            const SizedBox(height: 20),

            // ── 2. Low Attendance Shortage Alert Banner (Conditional) ────
            if (attendance.overallPercentage < 85.0) ...[
              _buildAttendanceShortageAlert(attendance),
              const SizedBox(height: 20),
            ],

            // ── 3. Student Quick Profile Card ─────────────────────────────
            _buildStudentCard(student),
            const SizedBox(height: 24),

            // ── 4. Main 4 Statistics KPI Cards ─────────────────────────────
            _buildKpiGrid(screenWidth, attendance, academic, fees, exams),
            const SizedBox(height: 24),

            // ── 5. Analytics Charts Row ────────────────────────────────────
            _buildChartsRow(screenWidth, academic),
            const SizedBox(height: 24),

            // ── 6. Today's Timetable Timeline ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader(title: "Today's Class Schedule"),
                TextButton(
                  onPressed: () => widget.onNavigate?.call(6), // Timetable tab
                  child: const Text('Full Timetable →', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTodayTimetableTimeline(),
            const SizedBox(height: 24),

            // ── 7. Academic Breakdown: Recent Marks | Notifications | Exams ─
            _buildAcademicRow(screenWidth, academic, exams),
            const SizedBox(height: 24),

            // ── 8. Period-wise Attendance Log Table ────────────────────────
            const SectionHeader(
              title: 'Recent Period-wise Attendance Log',
              subtitle: 'Real-time period updates recorded by class advisors',
            ),
            const SizedBox(height: 8),
            _buildPeriodAttendanceTable(),
            const SizedBox(height: 24),

            // ── 9. Quick Actions Grid ─────────────────────────────────────
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 8),
            _buildQuickActionsGrid(screenWidth),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Welcome Banner Widget
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWelcomeBanner(Parent parent, Student student) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.waving_hand_rounded, color: AppTheme.secondaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Day, ${parent.name}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Academic overview for ward: ${student.name} • ${student.department} (${student.year})',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: AppTheme.primaryColor,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => StudentSelectorModal(
                  onStudentSelected: (_) => setState(() {}),
                ),
              );
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Switch Child'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Attendance Shortage Alert Banner
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAttendanceShortageAlert(Attendance attendance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Shortage Alert!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorColor, fontSize: 15),
                ),
                Text(
                  'Overall attendance is at ${attendance.overallPercentage.toStringAsFixed(1)}%, which is below the mandatory 85% requirement.',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => widget.onNavigate?.call(2), // Attendance screen
            child: const Text('View Attendance'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Student Info Card Widget
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStudentCard(Student student) {
    return CustomCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: NetworkImage(student.photoUrl),
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    StatusBadge(status: student.isHosteller ? 'Hosteller' : 'Day Scholar'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Register No: ${student.registerNumber}',
                  style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _chip(Icons.school_outlined, student.department),
                    _chip(Icons.calendar_month_outlined, '${student.year} • Sec ${student.section}'),
                    _chip(Icons.person_outline_rounded, 'Mentor: ${student.mentor}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main KPI Grid
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildKpiGrid(double width, Attendance att, AcademicPerformance acad, Fee fee, List<Exam> exams) {
    int cols = width >= 1100 ? 4 : (width >= 600 ? 2 : 1);

    return GridView.count(
      crossAxisCount: cols,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: width >= 1100 ? 1.5 : 2.0,
      children: [
        KPICard(
          title: 'Overall Attendance',
          value: '${att.overallPercentage.toStringAsFixed(1)}%',
          subtext: att.overallPercentage >= 85.0 ? '✓ Good standing (Min: 85%)' : '⚠ Attendance Shortage Alert',
          icon: Icons.check_circle_outline_rounded,
          color: att.overallPercentage >= 85.0 ? AppTheme.successColor : AppTheme.errorColor,
          progress: att.overallPercentage / 100,
          onTap: () => widget.onNavigate?.call(2),
        ),
        KPICard(
          title: 'Current CGPA',
          value: acad.currentCgpa.toStringAsFixed(2),
          subtext: '${acad.currentSemester} GPA: ${acad.currentGpa}',
          icon: Icons.grade_rounded,
          color: AppTheme.accentColor,
          progress: acad.currentCgpa / 10.0,
          onTap: () => widget.onNavigate?.call(3),
        ),
        KPICard(
          title: 'Pending Fees',
          value: '₹${fee.pending.toInt()}',
          subtext: fee.pending > 0 ? 'Due date: ${fee.dueDate.day}/${fee.dueDate.month}/${fee.dueDate.year}' : 'All fees cleared',
          icon: Icons.account_balance_wallet_outlined,
          color: fee.pending > 0 ? AppTheme.warningColor : AppTheme.successColor,
          progress: fee.paid / fee.totalFees,
          onTap: () => widget.onNavigate?.call(7),
        ),
        KPICard(
          title: 'Upcoming Exams',
          value: '${exams.length}',
          subtext: 'Next: ${exams.first.subject}',
          icon: Icons.calendar_month_rounded,
          color: AppTheme.purpleColor,
          progress: 0.75,
          onTap: () => widget.onNavigate?.call(4),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Analytics Charts Row
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildChartsRow(double width, AcademicPerformance acad) {
    final isDesktop = width >= 950;

    Widget gpaChart = CustomCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Semester GPA Progression', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Semester 1 through Semester 5 performance graph', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) => Text('Sem ${v.toInt() + 1}', style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 6,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: acad.semesterGpas.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: AppTheme.accentColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppTheme.accentColor.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Widget attendanceChart = CustomCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Attendance Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Monthly percentage distribution over 6 months', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final m = MockData.attendanceMonths;
                        return v.toInt() < m.length ? Text(m[v.toInt()], style: const TextStyle(fontSize: 10)) : const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                maxY: 100,
                barGroups: MockData.monthlyAttendancePercentages.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: AppTheme.primaryColor,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: gpaChart),
          const SizedBox(width: 16),
          Expanded(child: attendanceChart),
        ],
      );
    }
    return Column(
      children: [gpaChart, const SizedBox(height: 16), attendanceChart],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Today's Timetable Timeline Widget
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTodayTimetableTimeline() {
    final timetable = MockData.mockTimetable;

    return CustomCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: timetable.asMap().entries.map((entry) {
          final idx = entry.key;
          final slot = entry.value;
          final isOngoing = idx == 1; // Sample active class

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isOngoing ? AppTheme.accentColor.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isOngoing ? Border.all(color: AppTheme.accentColor, width: 1.5) : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(slot.time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isOngoing ? AppTheme.accentColor : AppTheme.textSecondary)),
                ),
                Expanded(
                  child: Text(slot.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Text(slot.faculty, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                  child: Text(slot.room, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Academic Row: Marks | Notifications | Exams
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAcademicRow(double width, AcademicPerformance acad, List<Exam> exams) {
    final isDesktop = width >= 1050;
    final panels = [
      _buildMarksPanel(acad),
      _buildNotifsPanel(),
      _buildExamsPanel(exams),
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: panels.expand((p) => [Expanded(child: p), const SizedBox(width: 16)]).toList()..removeLast(),
      );
    }
    return Column(
      children: panels.expand((p) => [p, const SizedBox(height: 16)]).toList()..removeLast(),
    );
  }

  Widget _buildMarksPanel(AcademicPerformance acad) {
    return CustomCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Internal Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton(onPressed: () => widget.onNavigate?.call(3), child: const Text('View All', style: TextStyle(fontSize: 12))),
            ],
          ),
          const Divider(),
          ...acad.internalMarks.map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Int1: ${m.internal1} • Int2: ${m.internal2}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Text(m.total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNotifsPanel() {
    final notifs = MockData.mockNotifications;
    return CustomCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Latest Circulars & Notices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton(onPressed: () => widget.onNavigate?.call(11), child: const Text('View All', style: TextStyle(fontSize: 12))),
            ],
          ),
          const Divider(),
          ...notifs.map((n) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.campaign_rounded, color: AppTheme.primaryColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(n.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildExamsPanel(List<Exam> exams) {
    return CustomCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Examinations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton(onPressed: () => widget.onNavigate?.call(4), child: const Text('View All', style: TextStyle(fontSize: 12))),
            ],
          ),
          const Divider(),
          ...exams.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${e.date.day}\nSEP', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.accentColor)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${e.venue} • ${e.time}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Period Attendance Log Table Widget
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPeriodAttendanceTable() {
    final records = MockData.mockPeriodAttendance;

    return CustomCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryColor,
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text('DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 1, child: Text('PERIOD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 3, child: Text('SUBJECT NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              ],
            ),
          ),
          ...records.map((r) {
            final isPresent = r.status == 'Present';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.cardBorderColor))),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('${r.date.day}/${r.date.month}/${r.date.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  Expanded(flex: 1, child: Text('Period ${r.period}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                  Expanded(flex: 3, child: Text(r.subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: StatusBadge(status: isPresent ? 'Present' : 'Absent')),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quick Actions Grid
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionsGrid(double width) {
    int cols = width >= 1100 ? 7 : (width >= 600 ? 4 : 2);

    final actions = [
      {'label': 'Attendance', 'icon': Icons.co_present_rounded, 'index': 2},
      {'label': 'Marks Report', 'icon': Icons.school_rounded, 'index': 3},
      {'label': 'Fee Payment', 'icon': Icons.payments_rounded, 'index': 7},
      {'label': 'Leave / Outpass', 'icon': Icons.event_busy_rounded, 'index': 8},
      {'label': 'Timetable', 'icon': Icons.calendar_today_rounded, 'index': 6},
      {'label': 'Documents', 'icon': Icons.folder_rounded, 'index': 13},
      {'label': 'Settings', 'icon': Icons.settings_rounded, 'index': 14},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final a = actions[index];
        return CustomCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(12),
          onTap: () => widget.onNavigate?.call(a['index'] as int),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(a['icon'] as IconData, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(a['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}

