import 'package:flutter/material.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/student_profile_screen.dart';
import '../screens/academic/attendance_screen_new.dart';
import '../screens/academic/academic_performance_screen.dart';
import '../screens/academic/examinations_screen.dart';
import '../screens/academic/assignments_screen.dart';
import '../screens/academic/timetable_screen.dart';
import '../screens/financial/fees_screen.dart';
import '../screens/communication/leave_outpass_screen.dart';
import '../screens/communication/notifications_screen.dart';
import '../screens/communication/notices_screen.dart';
import '../screens/communication/documents_screen.dart';
import '../screens/facilities/hostel_transport_screen.dart';
import '../screens/settings/profile_settings_screen.dart';
import '../screens/auth/login_screen.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/core_widgets.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;
  bool _sidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ─── Menu items ─────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _allMenuItems = [
    {'key': 'dashboard',    'title': 'Dashboard',               'icon': Icons.dashboard_rounded,                   'section': ''},
    {'key': 'profile',      'title': 'Student Profile',         'icon': Icons.person_rounded,                      'section': 'ACADEMIC'},
    {'key': 'attendance',   'title': 'Attendance',              'icon': Icons.co_present_rounded,                  'section': ''},
    {'key': 'academics',    'title': 'Academic Performance',    'icon': Icons.school_rounded,                      'section': ''},
    {'key': 'exams',        'title': 'Examinations',            'icon': Icons.assignment_turned_in_rounded,        'section': ''},
    {'key': 'assignments',  'title': 'Assignments',             'icon': Icons.assignment_rounded,                  'section': ''},
    {'key': 'timetable',    'title': 'Timetable',               'icon': Icons.calendar_today_rounded,              'section': ''},
    {'key': 'fees',         'title': 'Fees & Payments',         'icon': Icons.account_balance_wallet_rounded,      'section': 'FINANCE'},
    {'key': 'leave',        'title': 'Leave',                   'icon': Icons.event_busy_rounded,                  'section': 'REQUESTS'},
    {'key': 'outpass',      'title': 'Outpass',                 'icon': Icons.transfer_within_a_station_rounded,   'section': ''},
    {'key': 'hostel',       'title': 'Hostel',                  'icon': Icons.domain_rounded,                      'section': 'FACILITIES'},
    {'key': 'transport',    'title': 'Transport',               'icon': Icons.directions_bus_rounded,              'section': 'FACILITIES'},
    {'key': 'notices',      'title': 'Notices',                 'icon': Icons.campaign_rounded,                    'section': 'COMMUNICATION'},
    {'key': 'documents',    'title': 'Documents',               'icon': Icons.folder_rounded,                      'section': ''},
    {'key': 'settings',     'title': 'Profile & Settings',      'icon': Icons.settings_rounded,                    'section': 'ACCOUNT'},
    {'key': 'logout',       'title': 'Logout',                  'icon': Icons.logout_rounded,                      'section': ''},
  ];

  List<Map<String, dynamic>> get _menuItems {
    final isHosteller = MockData.selectedStudent.isHosteller;
    return _allMenuItems.where((item) {
      final k = item['key'] as String;
      if (isHosteller) {
        return k != 'transport';
      } else {
        return k != 'hostel' && k != 'outpass';
      }
    }).toList();
  }

  void _onMenuItemSelected(int index) {
    final items = _menuItems;
    final key = items[index]['key'] as String;
    if (key == 'logout') {
      _showLogoutConfirmation();
    } else {
      setState(() => _currentIndex = index);
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
        Navigator.pop(context);
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of the Parent Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentScreen() {
    final items = _menuItems;
    if (_currentIndex >= items.length) return _dashboardScreen();
    final key = items[_currentIndex]['key'] as String;
    switch (key) {
      case 'dashboard':   return _dashboardScreen();
      case 'profile':     return const StudentProfileScreen();
      case 'attendance':  return const AttendanceScreenNew();
      case 'academics':   return const AcademicPerformanceScreen();
      case 'exams':       return const ExaminationsScreen();
      case 'assignments': return const AssignmentsScreen();
      case 'timetable':   return const TimetableScreen();
      case 'fees':        return const FeesScreen();
      case 'leave':       return const LeaveOutpassScreen();
      case 'outpass':     return const LeaveOutpassScreen();
      case 'hostel':      return const HostelScreen();
      case 'transport':   return const TransportScreen();
      case 'notices':     return const NoticesScreen();
      case 'documents':   return const DocumentsScreen();
      case 'settings':    return const ProfileSettingsScreen();
      default:            return _dashboardScreen();
    }
  }

  Widget _dashboardScreen() {
    return DashboardScreen(
      onStudentChanged: () => setState(() {}),
      onNavigate: (i) => setState(() => _currentIndex = i),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final parent = MockData.currentParent;
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    final sidebar = _buildSidebar(isDesktop);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(false)),
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(
            child: Column(
              children: [
                _buildHeader(isDesktop, parent),
                Expanded(
                  child: Container(
                    color: AppTheme.backgroundColor,
                    child: _getCurrentScreen(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COLLAPSIBLE SIDEBAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSidebar(bool isDesktop) {
    final collapsed = isDesktop && _sidebarCollapsed;
    final width = collapsed ? 72.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.sidebarGradient,
        ),
      ),
      child: Column(
        children: [
          // ── Logo Header ───────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(collapsed ? 0 : 16, 40, collapsed ? 0 : 16, 20),
            alignment: collapsed ? Alignment.center : Alignment.centerLeft,
            child: collapsed
                ? const Icon(Icons.shield_rounded, color: AppTheme.secondaryColor, size: 32)
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppTheme.secondaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'KSRCE ERP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Parent Portal',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // ── Menu Items ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: collapsed ? 6 : 10),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _currentIndex == index;
                final isLogout = item['key'] == 'logout';
                final section = item['section'] as String;

                Widget tile = _buildMenuTile(index, item, isSelected, isLogout, collapsed);

                if (section.isNotEmpty && !collapsed) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                        child: Text(
                          section,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      tile,
                    ],
                  );
                }
                return tile;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(int index, Map<String, dynamic> item, bool isSelected, bool isLogout, bool collapsed) {
    final Color iconColor = isSelected
        ? AppTheme.secondaryColor
        : (isLogout ? Colors.redAccent.shade100 : Colors.white70);

    if (collapsed) {
      return Tooltip(
        message: item['title'] as String,
        preferBelow: false,
        child: InkWell(
          onTap: () => _onMenuItemSelected(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
            ),
            child: Icon(item['icon'] as IconData, color: iconColor, size: 22),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => _onMenuItemSelected(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          ),
          child: Row(
            children: [
              // Active left-bar indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 3,
                height: 20,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(item['icon'] as IconData, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isLogout ? Colors.redAccent.shade100 : Colors.white70),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPGRADED TOP HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDesktop, parent) {
    final student = MockData.selectedStudent;
    final unread = MockData.mockNotifications.where((n) => !n.isRead).length;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // ── Sidebar Toggle ──────────────────────────────────────────
          if (isDesktop)
            IconButton(
              icon: Icon(
                _sidebarCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                color: AppTheme.primaryColor,
              ),
              onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              tooltip: _sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
            )
          else
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppTheme.primaryColor),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),

          if (isDesktop) ...[
            const SizedBox(width: 12),
            // ── Current Screen Title ─────────────────────────────────
            Text(
              _currentIndex < _menuItems.length ? _menuItems[_currentIndex]['title'] as String : 'Dashboard',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],

          const Spacer(),

          // ── Global Search Button ─────────────────────────────────────
          Container(
            width: isDesktop ? 220 : 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isDesktop
                ? InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const GlobalSearchModal(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Search courses, fees, notices...',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const GlobalSearchModal(),
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // ── Ward Selector Dropdown ──────────────────────────────────
          InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (_) => StudentSelectorModal(
                onStudentSelected: (_) => setState(() {}),
              ),
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(student.photoUrl),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 8),
                  if (isDesktop) ...[
                    Text(
                      student.name.split(' ').first,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Notification Bell ────────────────────────────────────────
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textSecondary, size: 22),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                    child: Text(
                      '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),

          // ── Profile Menu ─────────────────────────────────────────────
          Container(
            height: 36,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade200,
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              final items = _menuItems;
              if (val == 'settings') {
                final settingsIdx = items.indexWhere((i) => i['key'] == 'settings');
                if (settingsIdx != -1) setState(() => _currentIndex = settingsIdx);
              } else if (val == 'logout') {
                _showLogoutConfirmation();
              }
            },
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'info',
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parent.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(parent.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(parent.relationship, style: const TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: Row(children: [Icon(Icons.settings_outlined, size: 18), SizedBox(width: 8), Text('Profile & Settings')]),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(children: [Icon(Icons.logout_rounded, size: 18, color: AppTheme.errorColor), const SizedBox(width: 8), Text('Logout', style: TextStyle(color: AppTheme.errorColor))]),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                if (isDesktop && MediaQuery.of(context).size.width > 1100) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(parent.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary)),
                      Text(parent.relationship, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppTheme.textSecondary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
