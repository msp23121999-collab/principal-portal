import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'models/hod_models.dart';
import 'widgets/header_bar.dart';
import 'widgets/sidebar_navigation.dart';
import 'screens/dashboard_view.dart';
import 'screens/department_views.dart';
import 'screens/teaching_views.dart';
import 'screens/timetable_view.dart';
import 'screens/management_views.dart';
import 'screens/attendance_view.dart';
import '../faculty/services/profile_service.dart';
import '../faculty/services/local_storage_base.dart';
import '../faculty/services/postgres_client.dart';
import 'screens/class_diary_view.dart';
import 'screens/dept_admin_views.dart';
import 'screens/leave_management_view.dart';
import 'screens/research_view.dart';
import 'screens/notifications_view.dart';
import 'screens/reports_view.dart';
import 'screens/events_view.dart';
import 'screens/files_view.dart';
import 'screens/notice_board_view.dart';
import 'screens/settings_view.dart';
import 'screens/profile_view.dart';
import 'screens/substitute_management_view.dart';
import 'screens/syllabus_view.dart';
import 'screens/marks_performance_view.dart';
import 'responsive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HodPortalApp());
}

class HodPortalApp extends StatelessWidget {
  const HodPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus OS Faculty Portal - HOD Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
      ),
      home: const MainPortalLayout(),
    );
  }
}

class MainPortalLayout extends StatefulWidget {
  const MainPortalLayout({super.key});

  @override
  State<MainPortalLayout> createState() => _MainPortalLayoutState();
}

class _MainPortalLayoutState extends State<MainPortalLayout> {
  String _activeRoute = 'dashboard';
  bool _isSidebarVisible = true;

  @override
  void initState() {
    super.initState();
    _initProfile();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        SupabaseClientHelper.select('faculties', schema: 'faculty'),
        SupabaseClientHelper.select('attendance_table', schema: 'student'),
        SupabaseClientHelper.select('hod_leave_requests', schema: 'hod'),
        SupabaseClientHelper.select('research_publications', schema: 'faculty'),
        SupabaseClientHelper.select('hod_events', schema: 'hod'),
        SupabaseClientHelper.select('hod_class_advisers', schema: 'hod'),
        SupabaseClientHelper.select('hod_course_diaries', schema: 'hod'),
        SupabaseClientHelper.select('hod_department_files', schema: 'hod'),
        SupabaseClientHelper.select('hod_notifications', schema: 'hod'),
        SupabaseClientHelper.select('class_advisors', schema: 'hod'),
        SupabaseClientHelper.select('mentor_assignments', schema: 'hod'),
      ]);
      final faculties = results[0];
      final attendance = results[1];
      final leaves = results[2];
      final research = results[3];
      final events = results[4];
      final classRows = results[5];
      final courseDiaries = results[6];
      final files = results[7];
      final notifications = results[8];
      final classAdvisors = results[9];
      final mentors = results[10];
      final departmentFaculties = faculties
          .where((row) => _belongsToDepartment(row))
          .toList();
      final departmentAttendance = attendance
          .where(
            (row) => _belongsToDepartment(row, fields: ['dept', 'department']),
          )
          .toList();
      final departmentResearch = research
          .where((row) => _belongsToDepartment(row))
          .toList();
      final pendingLeaves = leaves
          .where(
            (row) => (row['status']?.toString().toUpperCase() ?? '').contains(
              'PENDING',
            ),
          )
          .length;
      if (!mounted) return;
      setState(() {
        kpiItems = [
          _buildKpi(
            'faculty',
            'Total Faculty',
            departmentFaculties.length.toString(),
            'faculty.faculties',
            Icons.people_outline,
          ),
          _buildKpi(
            'attendance',
            'Attendance Records',
            departmentAttendance.length.toString(),
            'student.attendance_table',
            Icons.groups_outlined,
          ),
          _buildKpi(
            'leave',
            'Pending HOD Leaves',
            pendingLeaves.toString(),
            'hod.hod_leave_requests',
            Icons.event_note_outlined,
          ),
          _buildKpi(
            'research',
            'Research Publications',
            departmentResearch.length.toString(),
            'faculty.research_publications',
            Icons.science_outlined,
          ),
          _buildKpi(
            'events',
            'Department Events',
            events.length.toString(),
            'hod.hod_events',
            Icons.event_outlined,
          ),
          _buildKpi(
            'diaries',
            'Course Diaries',
            courseDiaries.length.toString(),
            'hod.hod_course_diaries',
            Icons.menu_book_outlined,
          ),
          _buildKpi(
            'files',
            'Department Files',
            files.length.toString(),
            'hod.hod_department_files',
            Icons.folder_outlined,
          ),
          _buildKpi(
            'notifications',
            'Notifications',
            notifications.length.toString(),
            'hod.hod_notifications',
            Icons.notifications_outlined,
          ),
          _buildKpi(
            'advisors',
            'Class Advisers',
            classAdvisors.length.toString(),
            'hod.class_advisors',
            Icons.groups_outlined,
          ),
          _buildKpi(
            'mentors',
            'Mentor Assignments',
            mentors.length.toString(),
            'hod.mentor_assignments',
            Icons.psychology_outlined,
          ),
        ];
        studentSummary = StudentOverviewSummary(
          totalStudents: departmentAttendance.length,
          presentToday: 0,
          lowAttendanceCount: 0,
          feeDefaultersCount: 0,
          onLeaveToday: pendingLeaves,
          examEligiblePct: 0,
          year1Count: 0,
          year2Count: 0,
          year3Count: 0,
          year4Count: 0,
        );
        noticeList = events
            .map(
              (row) => NoticeItem(
                id: (row['display_id'] ?? row['id'] ?? '').toString(),
                title: (row['event_name'] ?? '').toString(),
                category: (row['category'] ?? 'Event').toString(),
                source: (row['venue'] ?? '').toString(),
                date: (row['start_date'] ?? row['dates_description'] ?? '')
                    .toString(),
                isHighPriority: false,
              ),
            )
            .toList();
        this.classRows = classRows;
      });
    } catch (error) {
      debugPrint('Error loading HOD dashboard data: $error');
    }
  }

  bool _belongsToDepartment(
    Map<String, dynamic> row, {
    List<String> fields = const ['code', 'department', 'department_id', 'dept'],
  }) {
    final hodCode = ProfileService.get()['departmentId']?.toString() ?? 'CSE';
    final departmentCode = hodCode.trim().toUpperCase();
    return fields
        .map((field) => row[field]?.toString().trim().toUpperCase() ?? '')
        .where((value) => value.isNotEmpty)
        .any(
          (value) => value == departmentCode || value.contains(departmentCode),
        );
  }

  KpiStatItem _buildKpi(
    String id,
    String title,
    String value,
    String source,
    IconData icon,
  ) {
    return KpiStatItem(
      id: id,
      title: title,
      value: value,
      subtitle: source,
      icon: icon,
      iconColor: const Color(0xFF2563EB),
      iconBgColor: const Color(0xFFEFF6FF),
      trendPct: '',
      trendIsUp: false,
    );
  }

  Future<void> _initProfile() async {
    try {
      LocalStorageBase.writeMap('profile', {
        'employeeId': 'EMP-CSE-010',
        'facultyId': 'EMP-CSE-010',
        'name': 'Dr. K. Ravichandran',
        'designation': 'Professor & HOD',
        'department': 'Computer Science & Engineering (CSE)',
        'departmentId': 'CSE',
        'email': 'hod.cse@ksrce.ac.in',
        'phone': '98427 12345',
        'role': 'HOD & Professor',
      });
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing HOD profile: $e');
    }
  }

  // Header Profile Data
  HodHeaderProfile get headerProfile {
    final profile = ProfileService.get();
    final name = profile['name']?.toString() ?? '';
    return HodHeaderProfile(
      name: name,
      greeting: 'Welcome back,',
      designation: profile['designation']?.toString() ?? '',
      department: profile['department']?.toString() ?? '',
      deptCode: profile['departmentId']?.toString() ?? '',
      academicYear: '',
      semester: '',
      currentDate: '',
      currentTime: '',
      avatarInitial: name.isEmpty ? '' : name[0].toUpperCase(),
      pendingNotificationsCount: 0,
    );
  }

  // Full HOD Profile Data Module
  static const HodFullProfileData fullHodProfileData = HodFullProfileData(
    fullName: '',
    employeeId: '',
    designation: '',
    department: '',
    deptCode: '',
    officialEmail: '',
    personalEmail: '',
    phone: '',
    emergencyContact: '',
    dob: '',
    gender: '',
    bloodGroup: '',
    nationality: '',
    maritalStatus: '',
    address: '',
    dateOfJoining: '',
    employmentType: '',
    officeLocation: '',
    reportingAuthority: '',
    teachingExperienceYears: 0,
    adminExperienceYears: 0,
    ugDegree: '',
    pgDegree: '',
    phdDegree: '',
    specialization: '',
    university: '',
    publicationCount: 0,
    conferenceCount: 0,
    booksCount: 0,
    patentsCount: 0,
    fundedProjectsAmount: '',
    ORCID: '',
    scopusId: '',
    googleScholar: '',
    researchGate: '',
    subjectsHandled: [],
    weeklyWorkloadHours: 0,
    departmentRoles: [],
    awards: [],
    certifications: [],
    documents: [],
    profileCompletionPct: 0.0,
  );

  List<KpiStatItem> kpiItems = [];
  List<ScheduleItem> todaySchedule = [];
  List<FacultyOverviewItem> facultyMembers = [];
  StudentOverviewSummary studentSummary = const StudentOverviewSummary(
    totalStudents: 0,
    presentToday: 0,
    lowAttendanceCount: 0,
    feeDefaultersCount: 0,
    onLeaveToday: 0,
    examEligiblePct: 0.0,
    year1Count: 0,
    year2Count: 0,
    year3Count: 0,
    year4Count: 0,
  );
  List<LeaveRequestItem> leaveRequests = [];
  ResearchMetric researchMetric = const ResearchMetric(
    publicationsCount: 0,
    conferencesCount: 0,
    patentsCount: 0,
    fdpsCount: 0,
    fundedProjectsCount: 0,
    targetCompletionPct: 0.0,
  );
  List<ExamStatusItem> examList = [];
  List<NoticeItem> noticeList = [];
  List<TimelineActivity> activityList = [];
  List<StudentItem> studentList = [];
  List<CourseItem> courseList = [];
  List<Map<String, dynamic>> classRows = [];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showPermanentSidebar = screenWidth >= 992;
    final drawerW = HodResponsive.drawerWidth(context);

    return Scaffold(
      drawer: !showPermanentSidebar
          ? Drawer(
              width: drawerW,
              child: SidebarNavigation(
                activeRoute: _activeRoute,
                onSelectRoute: (route) {
                  setState(() => _activeRoute = route);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Permanent Sidebar for Desktop & Laptop (>= 992px)
          if (showPermanentSidebar && _isSidebarVisible)
            SizedBox(
              width: 260,
              child: SidebarNavigation(
                activeRoute: _activeRoute,
                onSelectRoute: (route) {
                  setState(() => _activeRoute = route);
                },
              ),
            ),

          // Main View Area (HeaderBar + Content)
          Expanded(
            child: Container(
              height: double.infinity,
              color: AppTheme.bgCanvas,
              child: Column(
                children: [
                  // Top Bar placed next to sidebar (starts at 260px)
                  HeaderBar(
                    isSidebarOpen: _isSidebarVisible,
                    onToggleSidebar: () {
                      setState(() {
                        _isSidebarVisible = !_isSidebarVisible;
                      });
                    },
                  ),

                  // Main View Content
                  Expanded(child: _buildCurrentView()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_activeRoute) {
      case 'dashboard':
        return DashboardView(
          profile: headerProfile,
          kpis: kpiItems,
          schedule: todaySchedule,
          facultyMembers: facultyMembers,
          studentSummary: studentSummary,
          leaveRequests: leaveRequests,
          researchMetric: researchMetric,
          exams: examList,
          notices: noticeList,
          activities: activityList,
          classRows: classRows,
        );

      case 'profile':
        return const ProfileView(profileData: fullHodProfileData);

      // Department Section
      case 'faculty':
        return DepartmentModuleView(
          initialTabIndex: 0,
          facultyList: facultyMembers
              .map(
                (f) => FacultyMember(
                  id: f.id,
                  name: f.name,
                  designation: f.designation,
                  email:
                      '${f.name.toLowerCase().replaceAll(' ', '.').replaceAll('.', '')}@ksrce.ac.in',
                  phone: '+91 9876543210',
                  specialization: 'Computer Science & Engineering',
                  status: f.status,
                ),
              )
              .toList(),
          studentList: studentList,
          courseList: courseList,
        );
      case 'students':
        return DepartmentModuleView(
          initialTabIndex: 1,
          facultyList: facultyMembers
              .map(
                (f) => FacultyMember(
                  id: f.id,
                  name: f.name,
                  designation: f.designation,
                  email: 'faculty@ksrce.ac.in',
                  phone: '+91 9876543210',
                  specialization: 'Computer Science & Engineering',
                  status: f.status,
                ),
              )
              .toList(),
          studentList: studentList,
          courseList: courseList,
        );
      case 'courses':
        return DepartmentModuleView(
          initialTabIndex: 2,
          facultyList: facultyMembers
              .map(
                (f) => FacultyMember(
                  id: f.id,
                  name: f.name,
                  designation: f.designation,
                  email: 'faculty@ksrce.ac.in',
                  phone: '+91 9876543210',
                  specialization: 'Computer Science & Engineering',
                  status: f.status,
                ),
              )
              .toList(),
          studentList: studentList,
          courseList: courseList,
        );

      // Teaching Section
      case 'my_courses':
        return const TeachingModuleView(
          initialTabIndex: 0,
          title: 'My Courses',
        );
      case 'timetable':
        return const TimetableManagementView();
      case 'syllabus':
        return const SyllabusModuleView();
      case 'substitute':
      case 'substitute_mgmt':
      case 'course_details':
        return const SubstituteManagementView();
      case 'course_diary':
      case 'class_diary_monitoring':
        return const ClassDiaryMonitoringView(initialTab: 0);
      case 'my_diary_entry':
        return const ClassDiaryMonitoringView(initialTab: 1);

      // Management Section
      case 'attendance':
        return AttendanceMonitoringView();
      case 'assignments':
        return const ManagementModuleView(
          initialTabIndex: 1,
          title: 'Assignments Management',
        );
      case 'grade_entry':
        return const MarksAndPerformanceView();
      case 'exams':
        return const ManagementModuleView(
          initialTabIndex: 3,
          title: 'Exams & Assessment Schedule',
        );

      // Dept Admin Section
      case 'class_advisers':
        return const ClassAdviserSubModuleView();
      case 'mentors':
        return const MentorSubModuleView();

      // Leave Management Section
      case 'leave_mgmt':
        return const LeaveManagementView(
          key: ValueKey('leave_mgmt'),
          forceViewMode: 'Faculty Approvals',
        );
      case 'apply_leave':
        return const LeaveManagementView(
          key: ValueKey('apply_leave'),
          forceViewMode: 'My Sent Requests',
          openApplyModalOnLoad: true,
        );

      // Additional Expanded Core Modules
      case 'research':
        return const ResearchModuleView();
      case 'notifications':
        return const NotificationsModuleView();
      case 'reports':
        return const ReportsModuleView();
      case 'events':
        return const EventsModuleView();
      case 'files':
        return const FilesModuleView();
      case 'notice_board':
        return const NoticeBoardModuleView();
      case 'settings':
        return const SettingsModuleView();

      default:
        return DashboardView(
          profile: headerProfile,
          kpis: kpiItems,
          schedule: todaySchedule,
          facultyMembers: facultyMembers,
          studentSummary: studentSummary,
          leaveRequests: leaveRequests,
          researchMetric: researchMetric,
          exams: examList,
          notices: noticeList,
          activities: activityList,
          classRows: classRows,
        );
    }
  }
}
