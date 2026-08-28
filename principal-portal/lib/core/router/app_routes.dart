/// Route path constants — avoids magic strings scattered across the
/// router, sidebar, and any in-app navigation calls.
///
/// Paths mirror the page names in the Principal Portal module spec, so a
/// URL always reads as the page it opens.
class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/dashboard';
  static const String institutionOverview = '/institution-overview';
  static const String academicPerformance = '/academic-performance';
  static const String resultAnalytics = '/result-analytics';
  static const String departmentPerformance = '/department-performance';
  static const String facultyPerformance = '/faculty-performance';
  static const String studentPerformance = '/student-performance';
  static const String attendanceAnalytics = '/attendance-analytics';
  static const String examinationMonitoring = '/examination-monitoring';
  static const String researchInnovation = '/research-innovation';

  static const String scholarships = '/scholarships';
  static const String placementDashboard = '/placement-dashboard';
  static const String approvals = '/approvals';
  static const String circulars = '/circulars';
  static const String meetingsCalendar = '/meetings-calendar';
  static const String reportsAnalytics = '/reports-analytics';
  static const String auditCompliance = '/audit-compliance';
  static const String notifications = '/notifications';
  static const String myProfile = '/my-profile';
}
