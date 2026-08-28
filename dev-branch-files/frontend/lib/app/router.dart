import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'home_page.dart';

// Admin Module Imports
import '../modules/admin/app/router/route_names.dart';
import '../modules/admin/widgets/app_scaffold.dart' as admin_scaffold;
import '../modules/admin/pages/dashboard_screen.dart' as admin_dashboard;
import '../modules/admin/pages/user_list_screen.dart' as admin_users;
import '../modules/admin/pages/user_detail_screen.dart' as admin_users_detail;
import '../modules/admin/pages/user_edit_form.dart' as admin_users_edit;
import '../modules/admin/pages/department_list_screen.dart'
    as admin_departments;
import '../modules/admin/pages/courses_subjects_screen.dart' as admin_courses;
import '../modules/admin/pages/programmes_screen.dart' as admin_programmes;
import '../modules/admin/pages/subjects_screen.dart' as admin_subjects;
import '../modules/admin/pages/regulations_screen.dart' as admin_regulations;
import '../modules/admin/pages/academic_config_screen.dart'
    as admin_academic_config;
import '../modules/admin/pages/audit_logs_screen.dart' as admin_audit;
import '../modules/admin/pages/backup_restore_screen.dart' as admin_backup;
import '../modules/admin/pages/notification_config_screen.dart' as admin_notif;
import '../modules/admin/pages/sms_email_config_screen.dart' as admin_sms;
import '../modules/admin/pages/reports_screen.dart' as admin_reports;
import '../modules/admin/pages/medical_dashboard_screen.dart' as admin_medical;
import '../modules/admin/pages/academic_calendar_screen.dart' as admin_calendar;
import '../modules/admin/pages/academic_schedule_screen.dart' as admin_schedule;
import '../modules/admin/pages/attendance_screen.dart' as admin_attendance;
import '../modules/admin/pages/marks_screen.dart' as admin_marks;
import '../modules/admin/pages/certificates_screen.dart' as admin_certificates;
import '../modules/admin/pages/workload_screen.dart' as admin_workload;
import '../modules/admin/pages/leave_screen.dart' as admin_leave;
import '../modules/admin/pages/semester_screen.dart' as admin_semester;
import '../modules/admin/pages/hall_ticket_screen.dart' as admin_hall_ticket;
import '../modules/admin/pages/results_screen.dart' as admin_results;
import '../modules/admin/pages/fees_screen.dart' as admin_fees;
import '../modules/admin/pages/scholarships_screen.dart' as admin_scholarships;
import '../modules/student/screens/library.dart' as admin_library;
import '../modules/student/screens/hostel.dart' as admin_hostel;
import '../modules/student/screens/transport.dart' as admin_transport;
import '../modules/student/screens/placement.dart' as admin_placement;

import '../modules/super_admin/widgets/super_admin_scaffold.dart'
    as superadmin_scaffold;
import '../modules/super_admin/screens/super_admin_dashboard.dart'
    as superadmin_dashboard;
import '../modules/super_admin/screens/system_health_screen.dart'
    as superadmin_health;
import '../modules/super_admin/screens/database_manager_screen.dart'
    as superadmin_db;
import '../modules/super_admin/screens/api_gateway_screen.dart'
    as superadmin_api;
import '../modules/super_admin/screens/security_audit_screen.dart'
    as superadmin_security;
import '../modules/super_admin/screens/user_console_screen.dart'
    as superadmin_user_console;
import '../modules/super_admin/screens/communication_gateway_screen.dart'
    as superadmin_comm;
import '../modules/super_admin/screens/scheduled_jobs_screen.dart'
    as superadmin_jobs;

import '../modules/hod/main.dart' as hod;
import '../modules/dean/screens/main_layout.dart' as dean;
import '../modules/principal/main.dart' as principal;
import '../modules/faculty/screens/dashboard_screen.dart' as faculty;
import '../modules/student/screens/main_layout.dart' as student_layout;
import '../modules/parent_portal/main.dart' as parent_portal;

final GoRouter unifiedRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const ErpHomePage(),
    ),
    GoRoute(
      path: RouteNames.login,
      redirect: (BuildContext context, GoRouterState state) => '/',
    ),

    // ── Parent Portal Routes ───────────────────────────────────────
    GoRoute(
      path: '/parent',
      builder: (BuildContext context, GoRouterState state) => const parent_portal.ParentPortalApp(),
      routes: [
        GoRoute(path: 'attendance', builder: (c, s) => const parent_portal.ParentPortalApp()),
        GoRoute(path: 'marks', builder: (c, s) => const parent_portal.ParentPortalApp()),
        GoRoute(path: 'fees', builder: (c, s) => const parent_portal.ParentPortalApp()),
        GoRoute(path: 'adviser', builder: (c, s) => const parent_portal.ParentPortalApp()),
        GoRoute(path: 'notices', builder: (c, s) => const parent_portal.ParentPortalApp()),
      ],
    ),

    // ── HOD Routes ───────────────────────────────────────────────
    GoRoute(
      path: '/hod',
      builder: (BuildContext context, GoRouterState state) => const hod.MainPortalLayout(),
      routes: [
        GoRoute(path: 'profile', builder: (c, s) => const hod.MainPortalLayout()),
        GoRoute(path: 'leaves', builder: (c, s) => const hod.MainPortalLayout()),
        GoRoute(path: 'profile-approvals', builder: (c, s) => const hod.MainPortalLayout()),
        GoRoute(path: 'class-advisers', builder: (c, s) => const hod.MainPortalLayout()),
        GoRoute(path: 'mentors', builder: (c, s) => const hod.MainPortalLayout()),
        GoRoute(path: 'files', builder: (c, s) => const hod.MainPortalLayout()),
        GoRoute(path: 'timetable', builder: (c, s) => const hod.MainPortalLayout()),
        GoRoute(path: 'attendance', builder: (c, s) => const hod.MainPortalLayout()),
        GoRoute(path: 'notices', builder: (c, s) => const hod.MainPortalLayout()),
      ],
    ),

    // ── Dean Routes ───────────────────────────────────────────────
    GoRoute(
      path: '/dean',
      builder: (BuildContext context, GoRouterState state) => const dean.DeanMainLayout(),
      routes: [
        GoRoute(path: 'academic-overview', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'curriculum-regulations', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'programmes-courses', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'faculty-performance', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'student-performance', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'attendance-analytics', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'examination-management', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'lesson-plan-monitoring', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'copo-attainment', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'research-innovation', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'accreditation-qa', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'calendar-events', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'academic-approvals', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'reports', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'department-comparison', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'notifications', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'digital-repository', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'meetings-bos', builder: (c, s) => const dean.DeanMainLayout()),
        GoRoute(path: 'profile', builder: (c, s) => const dean.DeanMainLayout()),
      ],
    ),

    // ── Principal Routes ──────────────────────────────────────────
    GoRoute(
      path: '/principal',
      builder: (BuildContext context, GoRouterState state) => const principal.PrincipalPortalPage(),
      routes: [
        GoRoute(path: 'departments', builder: (c, s) => const principal.PrincipalPortalPage()),
        GoRoute(path: 'timetable', builder: (c, s) => const principal.PrincipalPortalPage()),
        GoRoute(path: 'workload', builder: (c, s) => const principal.PrincipalPortalPage()),
        GoRoute(path: 'approvals', builder: (c, s) => const principal.PrincipalPortalPage()),
        GoRoute(path: 'reports', builder: (c, s) => const principal.PrincipalPortalPage()),
      ],
    ),

    // ── Faculty Routes ───────────────────────────────────────────
    GoRoute(
      path: '/faculty',
      builder: (BuildContext context, GoRouterState state) => const faculty.DashboardScreen(),
      routes: [
        GoRoute(path: 'timetable', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'attendance', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'marks', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'assignments', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'courses', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'lesson-plan', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'leave', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'class-adviser', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'mentoring', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'research', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'question-bank', builder: (c, s) => const faculty.DashboardScreen()),
        GoRoute(path: 'profile', builder: (c, s) => const faculty.DashboardScreen()),
      ],
    ),

    // ── Student Routes ───────────────────────────────────────────
    GoRoute(
      path: '/student',
      builder: (BuildContext context, GoRouterState state) => const student_layout.MainLayout(),
      routes: [
        GoRoute(path: 'profile', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'timetable', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'attendance', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'marks', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'exam-timetable', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'hall-ticket', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'syllabus', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'assignments', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'fees', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'calendar', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'library', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'hostel', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'transport', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'placement', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'certificates', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'grievance', builder: (c, s) => const student_layout.MainLayout()),
        GoRoute(path: 'notifications', builder: (c, s) => const student_layout.MainLayout()),
      ],
    ),

    // ── Super Admin Module Shell Route ────────────────────────────
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return superadmin_scaffold.SuperAdminScaffold(
          currentLocation: state.uri.path,
          child: child,
        );
      },
      routes: <RouteBase>[
        GoRoute(
          path: RouteNames.superAdminDashboard,
          builder: (BuildContext context, GoRouterState state) =>
              const superadmin_dashboard.SuperAdminDashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminUsers,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_users.UserListScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminAcademicConfig,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_academic_config.AcademicConfigScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminSmsEmailConfig,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_sms.SmsEmailConfigScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminNotificationConfig,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_notif.NotificationConfigScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminAuditLogs,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_audit.AuditLogsScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminBackupRestore,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_backup.BackupRestoreScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminSystemHealth,
          builder: (BuildContext context, GoRouterState state) =>
              const superadmin_health.SystemHealthScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminDatabaseManager,
          builder: (BuildContext context, GoRouterState state) =>
              const superadmin_db.DatabaseManagerScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminApiGateway,
          builder: (BuildContext context, GoRouterState state) =>
              const superadmin_api.ApiGatewayScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminSecurityAudit,
          builder: (BuildContext context, GoRouterState state) =>
              const superadmin_security.SecurityAuditScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminUserConsole,
          builder: (BuildContext context, GoRouterState state) =>
              const superadmin_user_console.UserConsoleScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminCommunicationGateway,
          builder: (BuildContext context, GoRouterState state) =>
              const superadmin_comm.CommunicationGatewayScreen(),
        ),
        GoRoute(
          path: RouteNames.superAdminScheduledJobs,
          builder: (BuildContext context, GoRouterState state) =>
              const superadmin_jobs.ScheduledJobsScreen(),
        ),
      ],
    ),

    // ── Admin Module Shell Route with Sidebar Nav ───────────────────
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return admin_scaffold.AppScaffold(
          currentLocation: state.uri.path,
          child: child,
        );
      },
      routes: <RouteBase>[
        GoRoute(
          path: RouteNames.dashboard,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_dashboard.DashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.users,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_users.UserListScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: ':id',
              builder: (BuildContext context, GoRouterState state) {
                final id = state.pathParameters['id'] ?? '';
                return admin_users_detail.UserDetailScreen(userId: id);
              },
            ),
            GoRoute(
              path: ':id/edit',
              builder: (BuildContext context, GoRouterState state) {
                final id = state.pathParameters['id'] ?? '';
                return admin_users_edit.UserEditForm(userId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: RouteNames.departments,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_departments.DepartmentListScreen(),
        ),
        GoRoute(
          path: RouteNames.courses,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_courses.CoursesSubjectsScreen(),
        ),
        GoRoute(
          path: RouteNames.programmes,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_programmes.ProgrammesScreen(),
        ),
        GoRoute(
          path: RouteNames.subjects,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_subjects.SubjectsScreen(),
        ),
        GoRoute(
          path: RouteNames.regulations,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_regulations.RegulationsScreen(),
        ),
        GoRoute(
          path: RouteNames.academicConfig,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_academic_config.AcademicConfigScreen(),
        ),
        GoRoute(
          path: RouteNames.academicCalendar,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_calendar.AcademicCalendarScreen(),
        ),
        GoRoute(
          path: RouteNames.academicSchedule,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_schedule.AcademicScheduleScreen(),
        ),
        GoRoute(
          path: RouteNames.students,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_users.UserListScreen(),
        ),
        GoRoute(
          path: RouteNames.attendance,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_attendance.AttendanceScreen(),
        ),
        GoRoute(
          path: RouteNames.marks,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_marks.MarksScreen(),
        ),
        GoRoute(
          path: RouteNames.certificates,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_certificates.CertificatesScreen(),
        ),
        GoRoute(
          path: RouteNames.workload,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_workload.WorkloadScreen(),
        ),
        GoRoute(
          path: RouteNames.leave,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_leave.LeaveScreen(),
        ),
        GoRoute(
          path: RouteNames.cia,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_academic_config.AcademicConfigScreen(),
        ),
        GoRoute(
          path: RouteNames.semester,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_semester.SemesterScreen(),
        ),
        GoRoute(
          path: RouteNames.hallTicket,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_hall_ticket.HallTicketScreen(),
        ),
        GoRoute(
          path: RouteNames.results,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_results.ResultsScreen(),
        ),
        GoRoute(
          path: RouteNames.fees,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_fees.FeesScreen(),
        ),
        GoRoute(
          path: RouteNames.scholarships,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_scholarships.ScholarshipsScreen(),
        ),
        GoRoute(
          path: RouteNames.auditLogs,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_audit.AuditLogsScreen(),
        ),
        GoRoute(
          path: RouteNames.backupRestore,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_backup.BackupRestoreScreen(),
        ),
        GoRoute(
          path: RouteNames.notificationConfig,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_notif.NotificationConfigScreen(),
        ),
        GoRoute(
          path: RouteNames.smsEmailConfig,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_sms.SmsEmailConfigScreen(),
        ),
        GoRoute(
          path: RouteNames.reports,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_reports.ReportsScreen(),
        ),
        GoRoute(
          path: RouteNames.medicalDashboard,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_medical.MedicalDashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.hr,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_leave.LeaveScreen(),
        ),
        GoRoute(
          path: RouteNames.library,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_library.LibraryScreen(),
        ),
        GoRoute(
          path: RouteNames.hostel,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_hostel.HostelScreen(),
        ),
        GoRoute(
          path: RouteNames.transport,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_transport.TransportScreen(),
        ),
        GoRoute(
          path: RouteNames.placement,
          builder: (BuildContext context, GoRouterState state) =>
              const admin_placement.PlacementScreen(),
        ),
      ],
    ),
  ],
);
