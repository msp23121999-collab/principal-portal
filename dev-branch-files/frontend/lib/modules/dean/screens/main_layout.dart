import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/dean_sidebar.dart';
import '../widgets/dean_header.dart';
import 'dashboard.dart';
import 'academic_overview.dart';
import 'curriculum_regulations.dart';
import 'programmes_courses.dart';
import 'faculty_performance.dart';
import 'student_performance.dart';
import 'attendance_analytics.dart';
import 'examination_management.dart';
import 'lesson_plan_monitoring.dart';
import 'copo_attainment.dart';
import 'research_innovation.dart';
import 'accreditation_qa.dart';
import 'academic_calendar_events.dart';
import 'academic_approvals.dart';
import 'reports_analytics.dart';
import 'department_comparison.dart';
import 'notifications_circulars.dart';
import 'digital_repository.dart';
import 'meetings_bos.dart';
import 'my_profile.dart';

class DeanMainLayout extends StatefulWidget {
  const DeanMainLayout({super.key});

  @override
  State<DeanMainLayout> createState() => _DeanMainLayoutState();
}

class _DeanMainLayoutState extends State<DeanMainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late DeanAppState _appState;

  @override
  void initState() {
    super.initState();
    print('[DEAN TRACE] main_layout initState');
    _appState = DeanAppState();
    print('[DEAN TRACE] DeanAppState instance created: $_appState');
    unawaited(_appState.initialize());
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  // Strictly maps S.No 1 to 20 from image specification table
  final List<Widget> _screens = const [
    DeanDashboardScreen(), // 1. Dashboard
    AcademicOverviewScreen(), // 2. Academic Overview
    CurriculumRegulationsScreen(), // 3. Curriculum & Regulations
    ProgrammesCoursesScreen(), // 4. Programme & Course
    FacultyPerformanceScreen(), // 5. Faculty Performance
    StudentPerformanceScreen(), // 6. Student Academic Performance
    AttendanceAnalyticsScreen(), // 7. Attendance Analytics
    ExaminationManagementScreen(), // 8. Examination Management
    LessonPlanMonitoringScreen(), // 9. Lesson Plan & Syllabus Monitoring
    CopoAttainmentScreen(), // 10. CO-PO Attainment
    ResearchInnovationScreen(), // 11. Research & Innovation
    AccreditationQaScreen(), // 12. Accreditation & QA
    AcademicCalendarEventsScreen(), // 13. Academic Calendar & Events
    AcademicApprovalsScreen(), // 14. Academic Approvals
    ReportsAnalyticsScreen(), // 15. Reports & Analytics
    DepartmentComparisonScreen(), // 16. Department Comparison Dashboard
    NotificationsCircularsScreen(), // 17. Notifications & Circulars
    DigitalRepositoryScreen(), // 18. Digital Repository
    MeetingsBosScreen(), // 19. Meetings & BOS Management
    DeanProfileScreen(), // 20. My Profile
  ];

  @override
  Widget build(BuildContext context) {
    return DeanAppStateProvider(
      state: _appState,
      child: _DeanMainLayoutContent(
        scaffoldKey: _scaffoldKey,
        screens: _screens,
      ),
    );
  }
}

class _DeanMainLayoutContent extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget> screens;

  const _DeanMainLayoutContent({
    required this.scaffoldKey,
    required this.screens,
  });

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        final isDesktop = MediaQuery.of(context).size.width >= 1024;
        final int index = appState.selectedNavIndex.clamp(
          0,
          screens.length - 1,
        );

        // Show loading indicator while initializing
        if (appState.isLoading && !appState.hasLoaded) {
          return Scaffold(
            key: scaffoldKey,
            body: Container(
              color: DeanTheme.bgCanvas,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Dean Portal...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show error message if initialization failed
        if (appState.lastError != null) {
          return Scaffold(
            key: scaffoldKey,
            body: Container(
              color: DeanTheme.bgCanvas,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Portal',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        appState.lastError ?? 'Unknown error occurred',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          key: scaffoldKey,
          drawer: !isDesktop ? const Drawer(child: DeanSidebar()) : null,
          body: Row(
            children: [
              if (isDesktop) const DeanSidebar(),
              Expanded(
                child: Column(
                  children: [
                    DeanHeader(
                      onToggleSidebar: () {
                        scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    const Divider(height: 1, color: DeanTheme.cardBorder),
                    Expanded(
                      child: Container(
                        color: DeanTheme.bgCanvas,
                        child: IndexedStack(index: index, children: screens),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
