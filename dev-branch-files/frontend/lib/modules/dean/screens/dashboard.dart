import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_state.dart';
import '../models/dean_models.dart';
import '../widgets/bento_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/charts/performance_chart.dart';
import '../widgets/charts/pass_donut_chart.dart';
import '../widgets/charts/exam_progress_chart.dart';

class DeanDashboardScreen extends StatelessWidget {
  const DeanDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        final isDesktop = MediaQuery.of(context).size.width >= 1024;

        // Dynamic database metrics from Supabase tables
        final totalStudentsStr = appState.totalStudentsCount.toString();
        final totalFacultyStr = appState.totalFacultyCount.toString();
        final totalDeptsStr = appState.totalDeptsCount.toString();
        final totalProgrammesStr = appState.totalProgrammesCount.toString();
        final overallPassPctStr = appState.calculatedOverallPassPercentage > 0
            ? '${appState.calculatedOverallPassPercentage.toStringAsFixed(2)}%'
            : '0.00%';
        final avgSgpaStr = appState.calculatedAverageSGPA > 0
            ? '${appState.calculatedAverageSGPA.toStringAsFixed(2)} / 10'
            : '0.00 / 10';
        final avgCgpaStr = appState.calculatedAverageCGPA > 0
            ? '${appState.calculatedAverageCGPA.toStringAsFixed(2)} / 10'
            : '0.00 / 10';
        final backlogCountStr = appState.backlogStudentsCount.toString();
        final atRiskCountStr = appState.atRiskStudentsCount.toString();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top 6 Metric Cards Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final double spacing = 14.0;
                  int crossAxisCount = 6;
                  if (constraints.maxWidth < 600) {
                    crossAxisCount = 2;
                  } else if (constraints.maxWidth < 1100) {
                    crossAxisCount = 3;
                  }

                  final double itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                  final metrics = [
                    DeanMetricCard(
                      icon: Icons.school,
                      iconBg: const Color(0xFFDBEAFE),
                      iconColor: const Color(0xFF2563EB),
                      label: 'Total Students',
                      value: totalStudentsStr,
                    ),
                    DeanMetricCard(
                      icon: Icons.people_alt,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      label: 'Total Faculty',
                      value: totalFacultyStr,
                    ),
                    DeanMetricCard(
                      icon: Icons.domain,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      label: 'Total Departments',
                      value: totalDeptsStr,
                    ),
                    DeanMetricCard(
                      icon: Icons.auto_stories,
                      iconBg: const Color(0xFFFFEDD5),
                      iconColor: const Color(0xFFEA580C),
                      label: 'Total Programmes',
                      value: totalProgrammesStr,
                    ),
                    DeanMetricCard(
                      icon: Icons.show_chart,
                      iconBg: const Color(0xFFFFE4E6),
                      iconColor: const Color(0xFFE11D48),
                      label: 'Overall Pass %',
                      value: overallPassPctStr,
                    ),
                    DeanMetricCard(
                      icon: Icons.work_outline,
                      iconBg: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      label: 'Placement Rate',
                      value: '88.67%',
                    ),
                  ];

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: metrics.map((m) => SizedBox(width: itemWidth, height: 86, child: m)).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 2. Middle Row: Academic Performance Overview + Alerts & Notifications
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _buildAcademicPerformanceOverview(
                        context,
                        appState,
                        avgSgpaStr,
                        avgCgpaStr,
                        backlogCountStr,
                        atRiskCountStr,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _buildAlertsAndNotifications(context, appState)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildAcademicPerformanceOverview(
                      context,
                      appState,
                      avgSgpaStr,
                      avgCgpaStr,
                      backlogCountStr,
                      atRiskCountStr,
                    ),
                    const SizedBox(height: 20),
                    _buildAlertsAndNotifications(context, appState),
                  ],
                ),
              const SizedBox(height: 20),

              // 3. Bottom Row: Department Wise Pass % + Examination Status + Upcoming Appointments
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _buildDepartmentWisePassPercentage(appState)),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _buildExaminationStatusCard(appState)),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _buildUpcomingAppointments(context, appState)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildDepartmentWisePassPercentage(appState),
                    const SizedBox(height: 20),
                    _buildExaminationStatusCard(appState),
                    const SizedBox(height: 20),
                    _buildUpcomingAppointments(context, appState),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // --- Academic Performance Overview Card ---
  Widget _buildAcademicPerformanceOverview(
    BuildContext context,
    DeanAppState appState,
    String avgSgpaStr,
    String avgCgpaStr,
    String backlogCountStr,
    String atRiskCountStr,
  ) {
    return BentoCard(
      title: 'Academic Performance Overview',
      headerWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: DeanTheme.bgCanvas,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DeanTheme.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('View By: ', style: TextStyle(fontSize: 11, color: DeanTheme.textMuted)),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: appState.selectedViewBy,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: DeanTheme.primaryBlue),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
                items: ['Overall', 'UG Programmes', 'PG Programmes', 'Autonomous Regulations']
                    .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    appState.setViewBy(val);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          // 4 Sub-metrics summary pills
          Row(
            children: [
              Expanded(child: _buildOverviewSubMetric(Icons.trending_up, 'Average SGPA', avgSgpaStr, const Color(0xFFDCFCE7), const Color(0xFF16A34A))),
              const SizedBox(width: 12),
              Expanded(child: _buildOverviewSubMetric(Icons.show_chart, 'Average CGPA', avgCgpaStr, const Color(0xFFF3E8FF), const Color(0xFF9333EA))),
              const SizedBox(width: 12),
              Expanded(child: _buildOverviewSubMetric(Icons.assignment_late_outlined, 'Backlog Students', backlogCountStr, const Color(0xFFFFE4E6), const Color(0xFFE11D48))),
              const SizedBox(width: 12),
              Expanded(child: _buildOverviewSubMetric(Icons.warning_amber_outlined, 'At Risk Students', atRiskCountStr, const Color(0xFFFEF3C7), const Color(0xFFD97706))),
            ],
          ),
          const SizedBox(height: 20),

          // Department Performance Combo Chart
          DepartmentPerformanceComboChart(
            studentsData: appState.studentsData,
            departmentsData: appState.departmentsData,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSubMetric(IconData icon, String label, String val, Color bg, Color color, {String? subBadge}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                    if (subBadge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text(subBadge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                      ),
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

  // --- Alerts & Notifications Card (Connected to Database) ---
  Widget _buildAlertsAndNotifications(BuildContext context, DeanAppState appState) {
    final List<DeanAlert> alertsData = appState.approvalsData.isNotEmpty
        ? appState.approvalsData.map((item) {
            return DeanAlert(
              title: item['update_type'] != null
                  ? '${item['faculty_name'] ?? 'Faculty'} profile update request'
                  : item['title'] ?? 'Pending Approval Request',
              subtitle: item['hod_remarks'] ?? 'Requires Dean verification & sign-off',
              timeAgo: 'Recently',
              icon: Icons.notifications_active_outlined,
              iconColor: DeanTheme.dangerRose,
              iconBg: const Color(0xFFFFE4E6),
            );
          }).toList()
        : [];

    return BentoCard(
      title: 'Alerts & Notifications',
      actionText: 'View All',
      onAction: () {
        appState.setNavIndex(16);
      },
      child: alertsData.isNotEmpty
          ? Column(
              children: alertsData.map((a) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: a.iconBg, borderRadius: BorderRadius.circular(10)),
                        child: Icon(a.icon, color: a.iconColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                            const SizedBox(height: 2),
                            Text(a.subtitle, style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
                          ],
                        ),
                      ),
                      Text(a.timeAgo, style: const TextStyle(fontSize: 9, color: DeanTheme.textSubtle)),
                    ],
                  ),
                );
              }).toList(),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_outline, color: DeanTheme.successGreen, size: 28),
                  SizedBox(height: 8),
                  Text(
                    'No Pending Alerts',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
                  ),
                  Text(
                    'All approvals and notifications are up to date.',
                    style: TextStyle(fontSize: 10, color: DeanTheme.textMuted),
                  ),
                ],
              ),
            ),
    );
  }

  // --- Department Wise Pass Percentage Card (Connected to Database) ---
  Widget _buildDepartmentWisePassPercentage(DeanAppState appState) {
    return BentoCard(
      title: 'Department Wise Pass Percentage',
      actionText: 'View Report',
      onAction: () => appState.setNavIndex(1),
      child: DepartmentPassDonutChart(
        overallPassPercentage: appState.calculatedOverallPassPercentage,
        studentsData: appState.studentsData,
      ),
    );
  }

  // --- Examination Status Card (Connected to Database) ---
  Widget _buildExaminationStatusCard(DeanAppState appState) {
    return BentoCard(
      title: 'Examination Status',
      actionText: 'View Details',
      onAction: () => appState.setNavIndex(7),
      child: ExaminationStatusProgressChart(
        markSheetsData: appState.markSheetsData,
        totalDeptsCount: appState.totalDeptsCount,
      ),
    );
  }

  // --- Upcoming Appointments Card (Connected to Database) ---
  Widget _buildUpcomingAppointments(BuildContext context, DeanAppState appState) {
    final events = appState.calendarEventsData.isNotEmpty
        ? appState.calendarEventsData.map((e) {
            final String dateStr = e['event_date']?.toString() ?? '';
            String month = 'FEB';
            String day = '05';
            if (dateStr.length >= 10) {
              final DateTime? parsed = DateTime.tryParse(dateStr);
              if (parsed != null) {
                day = parsed.day.toString().padLeft(2, '0');
                const monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
                month = monthNames[parsed.month - 1];
              }
            }

            return AcademicEventItem(
              month: month,
              day: day,
              title: e['title'] ?? 'Appointment',
              dateRange: dateStr.isNotEmpty ? dateStr : 'Upcoming',
              category: e['category'] ?? 'Meeting',
              categoryBg: const Color(0xFFDBEAFE),
              categoryColor: const Color(0xFF2563EB),
            );
          }).toList()
        : <AcademicEventItem>[];

    return BentoCard(
      title: 'Upcoming Appointments',
      actionText: 'View Calendar',
      onAction: () => appState.setNavIndex(12),
      child: events.isNotEmpty
          ? Column(
              children: events.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(color: DeanTheme.bgCanvas, borderRadius: BorderRadius.circular(8), border: Border.all(color: DeanTheme.cardBorder)),
                        child: Column(
                          children: [
                            Text(e.month, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: DeanTheme.dangerRose)),
                            Text(e.day, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                            const SizedBox(height: 2),
                            Text(e.dateRange, style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: e.categoryBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(e.category, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: e.categoryColor)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.event_available, color: DeanTheme.primaryBlue, size: 28),
                  SizedBox(height: 8),
                  Text(
                    'No Upcoming Appointments',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
                  ),
                  Text(
                    'No upcoming appointments scheduled.',
                    style: TextStyle(fontSize: 10, color: DeanTheme.textMuted),
                  ),
                ],
              ),
            ),
    );
  }
}
