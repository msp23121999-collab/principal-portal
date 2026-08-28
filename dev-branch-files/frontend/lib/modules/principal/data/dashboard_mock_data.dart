import '../core/principal_compat.dart';
import '../theme/app_icons.dart';
import '../data/faculty_mock_data.dart';
import '../data/department_mock_data.dart';
import '../data/student_mock_data.dart';
import '../models/calendar_event.dart';
import '../models/dashboard_summary.dart';
import '../models/pending_approval_item.dart';
import '../models/quick_action.dart';
import '../models/recent_activity.dart';

/// Assembles the Dashboard's aggregate view model from the canonical
/// Department/Faculty/Student mock sources instead of duplicating figures,
/// plus a handful of Dashboard-only snapshot numbers (attendance/result/
/// placement) that don't yet have a dedicated module of their own.
class DashboardMockData {
  DashboardMockData._();

  static DashboardSummary summary() {
    final departments = DepartmentMockData.all;

    return DashboardSummary(
      institutionOverview: InstitutionOverview(
        totalStudents: DepartmentMockData.totalStudents,
        totalFaculty: DepartmentMockData.totalFaculty,
        totalDepartments: departments.length,
        studentGrowthPercent: '+4.8%',
        facultyGrowthPercent: '+2.9%',
      ),
      departmentRows: [
        for (final d
            in (departments.toList()..sort((a, b) => a.rank.compareTo(b.rank))))
          DepartmentSummaryRow(
            name: d.name,
            shortCode: d.shortCode,
            studentCount: d.studentCount,
            attendancePercent: d.attendancePercent,
            rank: d.rank,
          ),
      ],
      facultySummary: FacultySummary(
        totalFaculty: DepartmentMockData.totalFaculty,
        averageExperienceYears: FacultyMockData.averageExperience,
        averageAttendancePercent: FacultyMockData.averageAttendance,
        totalResearchPapers: FacultyMockData.totalResearchPapers,
      ),
      studentSummary: StudentSummary(
        totalStudents: DepartmentMockData.totalStudents,
        averageCgpa: StudentMockData.averageCgpa,
        averageAttendancePercent: StudentMockData.averageAttendance,
        topPerformerCount: StudentMockData.topPerformers.length,
        atRiskCount: StudentMockData.atRisk.length,
      ),
      attendanceSnapshot: AttendanceSnapshot(
        todayPercent: DepartmentMockData.averageAttendance,
        weekTrend: const [
          (label: 'Mon', percent: 90.2),
          (label: 'Tue', percent: 91.5),
          (label: 'Wed', percent: 89.8),
          (label: 'Thu', percent: 92.1),
          (label: 'Fri', percent: 88.6),
          (label: 'Sat', percent: 85.4),
        ],
      ),
      resultSummary: ResultSummary(
        semesterLabel: 'Semester 6 — 2025-26',
        overallPassPercent: 87.6,
        byDepartment: [
          for (final d in departments)
            (
              departmentCode: d.shortCode,
              passPercent: (d.avgCgpa / 10 * 100).clamp(60, 99).toDouble(),
            ),
        ],
      ),
      placementSummary: const PlacementSummary(
        totalEligible: 812,
        totalPlaced: 734,
        placementPercent: 90.4,
        averagePackageLpa: 6.8,
        highestPackageLpa: 42.0,
        topRecruiter: 'TCS',
      ),
    );
  }

  static List<QuickAction> quickActions() => const [
    QuickAction(
      icon: AppIcons.faculty,
      label: 'Faculty Performance',
      path: AppRoutes.facultyPerformance,
    ),
    QuickAction(
      icon: AppIcons.students,
      label: 'Student Performance',
      path: AppRoutes.studentPerformance,
    ),
    QuickAction(
      icon: AppIcons.leave,
      label: 'Leave Approval',
      path: AppRoutes.leaveApproval,
    ),
    QuickAction(
      icon: AppIcons.reports,
      label: 'Reports',
      path: AppRoutes.reports,
    ),
  ];

  static List<RecentActivity> recentActivities() {
    final now = DateTime.now();
    return [
      RecentActivity(
        icon: AppIcons.approve,
        title: 'Leave approved for Dr. Anitha Suresh',
        subtitle: 'CSE Department · 3 days sanctioned',
        timestamp: now.subtract(const Duration(minutes: 25)),
      ),
      RecentActivity(
        icon: AppIcons.results,
        title: 'Semester 6 results published',
        subtitle: 'Examination Cell · Overall pass 87.6%',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      RecentActivity(
        icon: AppIcons.placements,
        title: 'TCS placement drive concluded',
        subtitle: '58 students placed across departments',
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      RecentActivity(
        icon: AppIcons.faculty,
        title: 'New faculty onboarded',
        subtitle: 'Mr. Yogesh Waran joined EEE department',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      RecentActivity(
        icon: AppIcons.notifications,
        title: 'Circular issued: Odd semester timetable',
        subtitle: 'Academic Office · Effective next Monday',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  static List<PendingApprovalItem> pendingApprovals() => const [
    PendingApprovalItem(
      id: 'la01',
      requesterName: 'Dr. Karthik Subramani',
      requestType: 'Casual Leave',
      dateRange: 'Aug 3 – Aug 5, 2026',
    ),
    PendingApprovalItem(
      id: 'la02',
      requesterName: 'Ms. Divya Bharathi',
      requestType: 'On-Duty Leave',
      dateRange: 'Aug 6, 2026',
    ),
    PendingApprovalItem(
      id: 'la03',
      requesterName: 'Mr. Suresh Babu',
      requestType: 'Medical Leave',
      dateRange: 'Aug 4 – Aug 8, 2026',
    ),
  ];

  static List<CalendarEvent> calendarEvents() {
    final now = DateTime.now();
    return [
      CalendarEvent(
        date: DateTime(now.year, now.month, 4),
        title: 'Semester 6 Practical Exams',
        type: CalendarEventType.exam,
      ),
      CalendarEvent(
        date: DateTime(now.year, now.month, 9),
        title: 'Independence Day',
        type: CalendarEventType.holiday,
      ),
      CalendarEvent(
        date: DateTime(now.year, now.month, 14),
        title: 'Placement Drive — Infosys',
        type: CalendarEventType.event,
      ),
      CalendarEvent(
        date: DateTime(now.year, now.month, 18),
        title: 'Academic Council Meeting',
        type: CalendarEventType.meeting,
      ),
      CalendarEvent(
        date: DateTime(now.year, now.month, 25),
        title: 'IQAC Review',
        type: CalendarEventType.meeting,
      ),
    ];
  }
}
