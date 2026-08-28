import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/attendance_analytics_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/department_analytics_screen.dart';
import '../../screens/faculty_performance_screen.dart';
import '../../screens/institution_analytics_screen.dart';
import '../../screens/leave_approval_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/placement_analytics_screen.dart';
import '../../screens/principal_profile_screen.dart';
import '../../screens/reports_screen.dart';
import '../../screens/result_analytics_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/student_performance_screen.dart';
import '../principal_compat.dart';
import '../../widgets/layout/app_shell.dart';
import 'app_routes.dart';

/// go_router configuration: one StatefulShellRoute.indexedStack branch per
/// sidebar destination (index-matched to kNavDestinations), each with its
/// own preserved Navigator so scroll/filter state survives tab switches.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const PrincipalProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.institutionAnalytics,
                builder: (context, state) => const InstitutionAnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.departmentAnalytics,
                builder: (context, state) => const DepartmentAnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.facultyPerformance,
                builder: (context, state) => const FacultyPerformanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentPerformance,
                builder: (context, state) => const StudentPerformanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.attendanceAnalytics,
                builder: (context, state) => const AttendanceAnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.resultAnalytics,
                builder: (context, state) => const ResultAnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.placementAnalytics,
                builder: (context, state) => const PlacementAnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.leaveApproval,
                builder: (context, state) => const LeaveApprovalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
