
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/academic/screens/academic_performance_screen.dart';
import '../../features/approvals/screens/approvals_screen.dart';
import '../../features/attendance/screens/attendance_analytics_screen.dart';
import '../../features/audit/screens/audit_compliance_screen.dart';
import '../../features/circulars/screens/circulars_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/department/screens/department_analytics_screen.dart';
import '../../features/examinations/screens/examination_monitoring_screen.dart';
import '../../features/faculty/screens/faculty_performance_screen.dart';
import '../../features/finance/screens/scholarships_screen.dart';
import '../../features/institution/screens/institution_analytics_screen.dart';
import '../../features/meetings/screens/meetings_calendar_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/placements/screens/placement_analytics_screen.dart';
import '../../features/profile/screens/principal_profile_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/research/screens/research_innovation_screen.dart';
import '../../features/results/screens/result_analytics_screen.dart';
import '../../features/students/screens/student_performance_screen.dart';
import '../widgets/layout/app_shell.dart';
import 'app_routes.dart';

/// go_router configuration: one StatefulShellRoute.indexedStack branch per
/// sidebar destination (index-matched to kNavDestinations), each with its
/// own preserved Navigator so scroll/filter state survives tab switches.
///
/// Branch order MUST stay in lockstep with kNavDestinations. Navigation
/// resolves indices through navIndexOf(path) rather than literals so a
/// mismatch surfaces as a route that never opens, not a silent mis-route.

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          _branch(AppRoutes.dashboard, (_, _) => const DashboardScreen()),
          _branch(
            AppRoutes.institutionOverview,
            (_, _) => const InstitutionAnalyticsScreen(),
          ),
          _branch(
            AppRoutes.academicPerformance,
            (_, _) => const AcademicPerformanceScreen(),
          ),
          _branch(
            AppRoutes.resultAnalytics,
            (_, _) => const ResultAnalyticsScreen(),
          ),
          _branch(
            AppRoutes.departmentPerformance,
            (_, _) => const DepartmentAnalyticsScreen(),
          ),
          _branch(
            AppRoutes.facultyPerformance,
            (_, _) => const FacultyPerformanceScreen(),
          ),
          _branch(
            AppRoutes.studentPerformance,
            (_, _) => const StudentPerformanceScreen(),
          ),
          _branch(
            AppRoutes.attendanceAnalytics,
            (_, _) => const AttendanceAnalyticsScreen(),
          ),
          _branch(
            AppRoutes.examinationMonitoring,
            (_, _) => const ExaminationMonitoringScreen(),
          ),
          _branch(
            AppRoutes.researchInnovation,
            (_, _) => const ResearchInnovationScreen(),
          ),

          _branch(AppRoutes.scholarships, (_, _) => const ScholarshipsScreen()),
          _branch(
            AppRoutes.placementDashboard,
            (_, _) => const PlacementAnalyticsScreen(),
          ),
          _branch(AppRoutes.approvals, (_, _) => const ApprovalsScreen()),
          _branch(AppRoutes.circulars, (_, _) => const CircularsScreen()),
          _branch(
            AppRoutes.meetingsCalendar,
            (_, _) => const MeetingsCalendarScreen(),
          ),
          _branch(AppRoutes.reportsAnalytics, (_, _) => const ReportsScreen()),
          _branch(
            AppRoutes.auditCompliance,
            (_, _) => const AuditComplianceScreen(),
          ),
          _branch(
            AppRoutes.notifications,
            (_, _) => const NotificationsScreen(),
          ),
          _branch(
            AppRoutes.myProfile,
            (_, _) => const PrincipalProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(String path, GoRouterWidgetBuilder builder) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: builder)],
  );
}
