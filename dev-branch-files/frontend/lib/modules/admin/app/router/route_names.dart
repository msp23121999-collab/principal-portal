class RouteNames {
  RouteNames._();

  // Root & Portal Entry
  static const String home = '/';
  static const String login = '/admin/login';

  // Portal Entry Routes
  static const String hodPortal = '/hod';
  static const String deanPortal = '/dean';
  static const String principalPortal = '/principal';
  static const String facultyPortal = '/faculty';
  static const String studentPortal = '/student';

  // ── Super Admin Portal Module Routes (20 Final Pages Matrix) ──────────────
  static const String superAdminDashboard = '/superadmin';
  static const String superAdminUsers = '/superadmin/users';
  static const String superAdminRolesPermissions =
      '/superadmin/roles-permissions';
  static const String superAdminOrganizationManagement =
      '/superadmin/organization-management';
  static const String superAdminAcademicConfig = '/superadmin/academic-config';
  static const String superAdminModuleManagement =
      '/superadmin/module-management';
  static const String superAdminSystemSettings = '/superadmin/system-settings';
  static const String superAdminNotificationManagement =
      '/superadmin/notification-management';
  static const String superAdminDatabaseManager =
      '/superadmin/database-manager';
  static const String superAdminBackupRestore = '/superadmin/backup-restore';
  static const String superAdminStorageManagement =
      '/superadmin/storage-management';
  static const String superAdminApiGateway = '/superadmin/api-gateway';
  static const String superAdminScheduledJobs = '/superadmin/scheduled-jobs';
  static const String superAdminSystemHealth = '/superadmin/system-health';
  static const String superAdminErrorMonitoring =
      '/superadmin/error-monitoring';
  static const String superAdminAuditLogs = '/superadmin/audit-logs';
  static const String superAdminLicenseSubscription =
      '/superadmin/license-subscription';
  static const String superAdminAnalyticsDashboard =
      '/superadmin/analytics-dashboard';
  static const String superAdminDigitalRepository =
      '/superadmin/digital-repository';
  static const String superAdminProfile = '/superadmin/profile';

  // Legacy route aliases for super admin
  static const String superAdminSmsEmailConfig =
      superAdminNotificationManagement;
  static const String superAdminNotificationConfig =
      superAdminNotificationManagement;
  static const String superAdminSecurityAudit = superAdminAuditLogs;
  static const String superAdminUserConsole = superAdminUsers;
  static const String superAdminCommunicationGateway =
      superAdminNotificationManagement;

  // ── ERP Admin Portal Module Routes (36 Final Pages Matrix) ──────────────

  // 1. Overview
  static const String dashboard = '/admin'; // 1. Dashboard

  // 2. Academic Management
  static const String academicYear =
      '/admin/academic-year'; // 2. Academic Year Management
  static const String departments =
      '/admin/departments'; // 3. Department Management
  static const String programmesSubjects =
      '/admin/programmes-subjects'; // 4. Programme & Subject Management
  static const String regulations =
      '/admin/regulations'; // 5. Regulation Management
  static const String academicConfig =
      '/admin/academic-config'; // 6. Academic Configuration
  static const String timetable = '/admin/timetable'; // 7. Timetable Management

  // 3. User Management
  static const String users = '/admin/users'; // 8. User Management
  static const String userDetail = '/admin/users/:id';
  static const String userEdit = '/admin/users/:id/edit';
  static const String students = '/admin/students'; // 9. Student Management
  static const String faculty = '/admin/faculty'; // 10. Faculty Management

  // 4. Academic Operations
  static const String attendance =
      '/admin/attendance'; // 11. Attendance Management
  static const String marks = '/admin/marks'; // 12. Marks Management
  static const String examinations =
      '/admin/examinations'; // 13. Examination Management
  static const String hallTicket =
      '/admin/hall-ticket'; // 14. Hall Ticket Management
  static const String results = '/admin/results'; // 15. Results Management
  static const String certificates =
      '/admin/certificates'; // 16. Certificates Management

  // 5. Finance & HR
  static const String feesScholarships =
      '/admin/fees-scholarships'; // 17. Fees & Scholarships
  static const String hr = '/admin/hr'; // 18. HR & Payroll
  static const String medicalManagement =
      '/admin/medical'; // 30. Medical Management (renamed)

  // 6. Campus Services
  static const String library = '/admin/library';
  static const String hostel = '/admin/hostel';
  static const String transport = '/admin/transport';
  static const String placement = '/admin/placement';
  static const String eventManagement = '/admin/events';
  static const String inventoryAssets ='/admin/inventory-assets'; // 34. Inventory & Assets [⭐ New]
  static const String grievanceManagement ='/admin/grievances'; // 33. Grievance Management [⭐ New]

  // 7. Communication
  static const String notificationManagement ='/admin/notifications'; // 24. Notification Management
  static const String digitalRepository ='/admin/digital-repository'; // 31. Digital Repository [⭐ New]

  // 8. Reports
  static const String reports = '/admin/reports'; // 25. Reports & Analytics

  // 9. Security
  static const String rolesPermissions =
      '/admin/roles-permissions'; // 26. Roles & Permissions
  static const String auditLogs = '/admin/audit-logs'; // 27. Audit Logs
  static const String backupRestore =
      '/admin/backup-restore'; // 28. Backup & Restore
  static const String approvalWorkflow =
      '/admin/approvals'; // 32. Approval Workflow [⭐ New]

  // 10. Settings & Profile
  static const String systemSettings =
      '/admin/system-settings'; // 29. System Settings
  static const String myProfile = '/admin/my-profile'; // 36. My Profile [⭐ New]

  // Legacy route aliases for backward compatibility if any reference exists
  static const String programmes = programmesSubjects;
  static const String courses = programmesSubjects;
  static const String subjects = programmesSubjects;
  static const String academicCalendar = academicConfig;
  static const String academicSchedule = timetable;
  static const String workload = faculty;
  static const String leave = approvalWorkflow;
  static const String cia = examinations;
  static const String semester = examinations;
  static const String fees = feesScholarships;
  static const String scholarships = feesScholarships;
  static const String notificationConfig = notificationManagement;
  static const String smsEmailConfig = notificationManagement;
  static const String medicalDashboard = medicalManagement;
}
