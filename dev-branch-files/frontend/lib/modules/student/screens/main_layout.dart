import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import 'common_home_screen.dart';
import '../../../app/home_page.dart';
import 'dashboard.dart';
import 'academic_calendar.dart';
import 'my_profile.dart';
import 'timetable.dart';
import 'attendance.dart';
import 'marks.dart';
import 'exam_timetable.dart';
import 'hall_ticket.dart';
import 'fees.dart';
import 'library.dart';
import 'hostel.dart';
import 'transport.dart';
import 'achievements.dart';
import 'extra_courses.dart';
import 'grievance.dart';
import 'placement.dart';
import 'notifications.dart';
import 'notice_board.dart';
import 'syllabus.dart';
import 'reports.dart';
import 'assignments.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, this.role = 'student'});

  final String role;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    if (widget.role != 'faculty') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppState.instance.fetchAllData();
      });
    }
  }

  List<Widget> get _screens {
    if (widget.role == 'faculty') {
      return [DashboardScreen(onNavigate: _onItemTapped)];
    }

    return [
      DashboardScreen(onNavigate: _onItemTapped),
      AcademicCalendarScreen(onNavigate: _onItemTapped),
      MyProfileScreen(onNavigate: _onItemTapped),
      TimetableScreen(onNavigate: _onItemTapped),
      AttendanceScreen(onNavigate: _onItemTapped),
      MarksScreen(onNavigate: _onItemTapped),
      ExamTimetableScreen(onNavigate: _onItemTapped),
      const SizedBox.shrink(), // 7 (Exam Registration Screen Removed)
      HallTicketScreen(onNavigate: _onItemTapped),
      FeesScreen(onNavigate: _onItemTapped),
      LibraryScreen(onNavigate: _onItemTapped),
      HostelScreen(onNavigate: _onItemTapped),
      TransportScreen(onNavigate: _onItemTapped),
      AchievementsScreen(onNavigate: _onItemTapped),
      ExtraCoursesScreen(onNavigate: _onItemTapped),
      GrievanceScreen(onNavigate: _onItemTapped),
      const SizedBox.shrink(), // 16 (Certificates Screen Removed)
      PlacementScreen(onNavigate: _onItemTapped),
      const SizedBox.shrink(), // 18 (Medical & Donation Screen Removed)
      NotificationsScreen(onNavigate: _onItemTapped),
      NoticeBoardScreen(onNavigate: _onItemTapped),
      const SizedBox.shrink(), // 21 (Placeholder for Logout)
      SyllabusScreen(onNavigate: _onItemTapped), // 22
      ReportsScreen(initialWorkflow: 'Course Exit Survey', onNavigate: _onItemTapped), // 23
      const SizedBox.shrink(), // 24 (ERP Admin Removed)
      AssignmentsScreen(onNavigate: _onItemTapped), // 25
      ReportsScreen(initialWorkflow: 'Course Feedback', onNavigate: _onItemTapped), // 26
    ];
  }

  String _getScreenTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Academic Calendar';
      case 2:
        return 'My Profile';
      case 3:
        return 'Timetable';
      case 4:
        return 'Attendance';
      case 5:
        return 'Mark View';
      case 6:
        return 'Exam Timetable';
      case 8:
        return 'No Due Form';
      case 9:
        return 'Fees / Payments';
      case 10:
        return 'Library';
      case 11:
        return 'Hostel';
      case 12:
        return 'Transport';
      case 13:
        return 'Achievements';
      case 14:
        return 'Extra Courses';
      case 15:
        return 'Grievance';
      case 17:
        return 'Placement';
      case 19:
        return 'Notifications';
      case 20:
        return 'Notice Board';
      case 22:
        return 'Syllabus';
      case 23:
        return 'Course Exit Survey';
      case 25:
        return 'Assignments';
      case 26:
        return 'Course Feedback';
      default:
        return 'Student Portal';
    }
  }

  void _onItemTapped(int index) {
    if (index == 21) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ErpHomePage()),
        (route) => false,
      );
      return;
    }
    if (_selectedIndex == index) {
      if (_scaffoldKey.currentState?.isDrawerOpen == true) {
        _scaffoldKey.currentState?.closeDrawer();
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  void _logoutToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ErpHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768; // Desktop & Tablet have permanent sidebar

    return AppStateProvider(
      appState: AppState.instance,
      child: Scaffold(
        key: _scaffoldKey,
      drawer: !isDesktop && widget.role != 'faculty'
          ? SizedBox(
              width: 250,
              child: Drawer(
                backgroundColor: const Color(0xFF1E293B),
                child: Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onItemTapped,
                  isCollapsed: false,
                  showCloseButton: true,
                  role: widget.role,
                  onToggleCollapse: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop && widget.role != 'faculty')
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isSidebarCollapsed ? 80 : 250,
              child: Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: _onItemTapped,
                isCollapsed: _isSidebarCollapsed,
                role: widget.role,
                onToggleCollapse: () {
                  setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                  });
                },
              ),
            ),
          Expanded(
            child: Column(
              children: [
                if (widget.role != 'faculty')
                  TopBar(
                    isDesktop: isDesktop,
                    onNavigate: _onItemTapped,
                    role: widget.role,
                    title: _getScreenTitle(_selectedIndex),
                  ),
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
