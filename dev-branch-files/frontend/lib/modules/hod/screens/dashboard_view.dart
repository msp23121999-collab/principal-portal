import 'package:flutter/material.dart';
import '../models/hod_models.dart';
import '../widgets/kpi_cards_grid.dart';
import '../widgets/notifications_calendar_widget.dart';
import '../widgets/department_classes_widget.dart';
import '../responsive.dart';

import '../pdf_download_helper.dart';

class DashboardView extends StatelessWidget {
  final HodHeaderProfile profile;
  final List<KpiStatItem> kpis;
  final List<ScheduleItem> schedule;
  final List<FacultyOverviewItem> facultyMembers;
  final StudentOverviewSummary studentSummary;
  final List<LeaveRequestItem> leaveRequests;
  final ResearchMetric researchMetric;
  final List<ExamStatusItem> exams;
  final List<NoticeItem> notices;
  final List<TimelineActivity> activities;
  final List<Map<String, dynamic>> classRows;

  const DashboardView({
    super.key,
    required this.profile,
    required this.kpis,
    required this.schedule,
    required this.facultyMembers,
    required this.studentSummary,
    required this.leaveRequests,
    required this.researchMetric,
    required this.exams,
    required this.notices,
    required this.activities,
    this.classRows = const [],
  });

  @override
  Widget build(BuildContext context) {
    final dashboardKpis = kpis.isNotEmpty ? kpis : _fallbackKpis;

    return SingleChildScrollView(
      padding: HodResponsive.pagePaddingInsets(context),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Top Title & Header Action Bar
          HodSectionHeader(
            title: 'Department Central Management Module',
            breadcrumb: 'Department › Overview (Faculty, Students & Courses)',
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  PdfDownloadHelper.showExportConfirmation(context);
                },
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Export as PDF',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          KpiCardsGrid(kpis: dashboardKpis),
          const SizedBox(height: 24),
          DepartmentClassesWidget(rows: classRows),
          const SizedBox(height: 24),
          NotificationsCalendarWidget(notices: notices),
        ],
      ),
    );
  }

  List<KpiStatItem> get _fallbackKpis => [
    _fallbackKpi(
      'students',
      'Total Students',
      '0',
      Icons.groups_outlined,
      const Color(0xFF9333EA),
      const Color(0xFFF3E8FF),
    ),
    _fallbackKpi(
      'faculty',
      'Total Faculty',
      '0',
      Icons.person_outline,
      const Color(0xFF2563EB),
      const Color(0xFFEFF6FF),
    ),
    _fallbackKpi(
      'student_attendance',
      'Student Attendance (Today)',
      '0%',
      Icons.school_outlined,
      const Color(0xFF16A34A),
      const Color(0xFFDCFCE7),
    ),
    _fallbackKpi(
      'faculty_attendance',
      'Faculty Attendance (Today)',
      '0%',
      Icons.badge_outlined,
      const Color(0xFFEA580C),
      const Color(0xFFFFEDD5),
    ),
  ];

  KpiStatItem _fallbackKpi(
    String id,
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color iconBgColor,
  ) {
    return KpiStatItem(
      id: id,
      title: title,
      value: value,
      subtitle: 'No data available',
      icon: icon,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
      trendPct: '0',
      trendIsUp: false,
    );
  }
}
