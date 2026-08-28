import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';

/// Comprehensive Attendance Screen with statistics, charts, and detailed breakdowns.
class AttendanceScreenNew extends StatefulWidget {
  const AttendanceScreenNew({super.key});

  @override
  State<AttendanceScreenNew> createState() => _AttendanceScreenNewState();
}

class _AttendanceScreenNewState extends State<AttendanceScreenNew> {
  late PageController _pageController;
  int _currentChart = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendance = MockData.mockAttendance;
    final student = MockData.selectedStudent;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            _buildHeader(student),
            const SizedBox(height: 24),

            // ── Attendance Statistics Cards ─────────────────────────────
            const SectionHeader(title: 'Attendance Overview'),
            const SizedBox(height: 12),
            _buildAttendanceStats(attendance),
            const SizedBox(height: 24),

            // ── Monthly Attendance Trend Chart ──────────────────────────
            const SectionHeader(title: 'Monthly Attendance Trend'),
            const SizedBox(height: 12),
            _buildMonthlyTrendChart(),
            const SizedBox(height: 24),

            // ── Attendance Insights ─────────────────────────────────────
            const SectionHeader(title: 'Attendance Insights'),
            const SizedBox(height: 12),
            _buildAttendanceInsights(attendance),
            const SizedBox(height: 24),

            // ── Class-wise Attendance by Subject ────────────────────────
            const SectionHeader(title: 'Class-wise Attendance by Subject'),
            const SizedBox(height: 12),
            _buildSubjectWiseAttendanceTable(attendance),
            const SizedBox(height: 24),

            // ── Subject Absent Status Charts ────────────────────────────
            const SectionHeader(title: 'Subject Absent Status'),
            const SizedBox(height: 12),
            _buildSubjectAbsentCharts(attendance),
            const SizedBox(height: 24),

            // ── Monthly Attendance Calendar ─────────────────────────────
            const SectionHeader(title: 'Monthly Attendance Calendar'),
            const SizedBox(height: 12),
            _buildAttendanceCalendar(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Header with student name and attendance percentage
  Widget _buildHeader(student) {
    final attendance = MockData.mockAttendance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '${student.name} • ${student.registerNumber}',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Attendance Statistics Cards (Overall %, Present, Absent, etc.)
  Widget _buildAttendanceStats(attendance) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            '${attendance.overallPercentage.toStringAsFixed(1)}%',
            'Overall Attendance',
            Color(0xFF8B5CF6),
            icon: Icons.trending_up,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            '${attendance.totalPresent}',
            'Days Present',
            Color(0xFF10B981),
            icon: Icons.check_circle,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            '${attendance.totalAbsent}',
            'Days Absent',
            Color(0xFFEF4444),
            icon: Icons.cancel,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            '${attendance.totalPresent + attendance.totalAbsent}',
            'Total Days',
            Color(0xFF06B6D4),
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  /// Monthly Attendance Trend Chart
  Widget _buildMonthlyTrendChart() {
    final percentages = MockData.monthlyAttendancePercentages;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 10,
                  verticalInterval: 1,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = MockData.attendanceMonths;
                        if (value >= 0 && value < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(percentages.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: percentages[index],
                        color: AppTheme.accentColor,
                        width: 24,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Attendance Insights
  Widget _buildAttendanceInsights(attendance) {
    final insights = [
      {'label': 'Attendance Status', 'value': 'Good', 'color': Color(0xFF10B981)},
      {'label': 'Trend', 'value': 'Improving ↑', 'color': Color(0xFF8B5CF6)},
      {'label': 'Warning', 'value': 'None', 'color': Color(0xFF06B6D4)},
    ];

    return Row(
      children: List.generate(
        insights.length,
        (index) => Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: (insights[index]['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (insights[index]['color'] as Color).withOpacity(0.3),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insights[index]['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: insights[index]['color'] as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insights[index]['value'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: insights[index]['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Subject-wise Attendance Table
  Widget _buildSubjectWiseAttendanceTable(attendance) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text('Subject',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Center(
                    child: Text('Present',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('Absent',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('%',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ...List.generate(
            attendance.subjectAttendance.length,
            (index) {
              final subject = attendance.subjectAttendance[index];
              final statusColor = subject.percentage >= 85
                  ? Color(0xFF10B981)
                  : Color(0xFFF59E0B);

              return Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            subject.subject,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${subject.present}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${subject.absent}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${subject.percentage.toStringAsFixed(1)}%',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < attendance.subjectAttendance.length - 1)
                    Divider(height: 0, color: Colors.grey.shade100),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Subject Absent Status Charts
  Widget _buildSubjectAbsentCharts(attendance) {
    final subjects = attendance.subjectAttendance
        .map((s) => s.subject)
        .toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = attendance.subjectAttendance[index];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject.subject,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: subject.present.toDouble(),
                        color: Color(0xFF10B981),
                        radius: 40,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: subject.absent.toDouble(),
                        color: Color(0xFFEF4444),
                        radius: 40,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'P: ${subject.present}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A: ${subject.absent}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Attendance Calendar (Monthly view)
  Widget _buildAttendanceCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'August 2026',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Present', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Absent', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Holiday', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  /// Calendar Grid
  Widget _buildCalendarGrid() {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = List.generate(31, (i) => i + 1);

    // Sample attendance data for August 2026
    final attendanceData = {
      1: 'present',
      2: 'present',
      3: 'absent',
      4: 'present',
      5: 'present',
      6: 'holiday',
      7: 'holiday',
      8: 'present',
      9: 'present',
      10: 'present',
      11: 'absent',
      12: 'present',
      13: 'holiday',
      14: 'holiday',
      15: 'present',
      16: 'present',
      17: 'present',
      18: 'present',
      19: 'absent',
      20: 'holiday',
      21: 'holiday',
      22: 'present',
      23: 'present',
      24: 'present',
      25: 'present',
      26: 'present',
      27: 'holiday',
      28: 'holiday',
      29: 'present',
      30: 'absent',
      31: 'present',
    };

    return Column(
      children: [
        // Week day headers
        Row(
          children: weekDays
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        // Calendar days
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 31,
          itemBuilder: (context, index) {
            final day = index + 1;
            final status = attendanceData[day] ?? 'holiday';

            Color dayColor;
            if (status == 'present') {
              dayColor = Color(0xFF10B981);
            } else if (status == 'absent') {
              dayColor = Color(0xFFEF4444);
            } else {
              dayColor = Colors.grey.shade300;
            }

            return Container(
              decoration: BoxDecoration(
                color: dayColor.withOpacity(0.1),
                border: Border.all(color: dayColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: dayColor,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Helper: Stat Card
  Widget _buildStatCard(String value, String label, Color color,
      {required IconData icon}) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
