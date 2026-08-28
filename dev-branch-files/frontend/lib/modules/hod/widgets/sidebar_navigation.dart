import 'package:flutter/material.dart';

class SidebarNavigation extends StatefulWidget {
  final String activeRoute;
  final ValueChanged<String> onSelectRoute;

  const SidebarNavigation({
    super.key,
    required this.activeRoute,
    required this.onSelectRoute,
  });

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B), // Dark Navy Background matching screenshots
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── TOP LOGO BRANDING ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.shield,
                          color: Color(0xFF38BDF8),
                          size: 26,
                        ),
                        Text(
                          'KSR',
                          style: TextStyle(
                            color: Colors.amber.shade400,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'KSR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'COLLEGE OF ENGINEERING',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1),

          // ── NAVIGATION SCROLL LIST ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                // 1. PRIMARY NAV ITEMS
                _buildMainNavItem(
                  title: 'Dashboard',
                  icon: Icons.grid_view_rounded,
                  routeKey: 'dashboard',
                ),
                _buildMainNavItem(
                  title: 'My Profile',
                  icon: Icons.person_outline_rounded,
                  routeKey: 'profile',
                ),
                const SizedBox(height: 16),

                // 2. DEPARTMENT ADMINISTRATION
                _buildCategoryHeader(
                  title: 'Department Administration',
                  icon: Icons.domain_rounded,
                ),
                _buildSubNavItem(
                  title: 'Faculty Management',
                  routeKey: 'faculty',
                  activeIcon: Icons.people_outline,
                ),
                _buildSubNavItem(
                  title: 'Student Management',
                  routeKey: 'students',
                  activeIcon: Icons.school_outlined,
                ),
                _buildSubNavItem(
                  title: 'Course & Subject Management',
                  routeKey: 'courses',
                  activeIcon: Icons.menu_book_outlined,
                ),
                const SizedBox(height: 16),

                // 3. ACADEMIC MANAGEMENT
                _buildCategoryHeader(
                  title: 'Academic Management',
                  icon: Icons.access_time_rounded,
                ),
                _buildSubNavItem(
                  title: 'Academic Calendar & Events',
                  routeKey: 'events',
                  activeIcon: Icons.event_available_outlined,
                ),
                _buildSubNavItem(
                  title: 'Timetable Management',
                  routeKey: 'timetable',
                  activeIcon: Icons.calendar_month_outlined,
                ),
                _buildSubNavItem(
                  title: 'Attendance Monitoring',
                  routeKey: 'attendance',
                  activeIcon: Icons.check_circle_outline,
                ),
                _buildSubNavItem(
                  title: 'Class Diary Monitoring',
                  routeKey: 'class_diary_monitoring',
                  activeIcon: Icons.monitor_heart_outlined,
                ),
                _buildSubNavItem(
                  title: 'My Diary Entry',
                  routeKey: 'my_diary_entry',
                  activeIcon: Icons.book_outlined,
                ),
                _buildSubNavItem(
                  title: 'Marks & Performance',
                  routeKey: 'grade_entry',
                  activeIcon: Icons.bar_chart_outlined,
                ),
                _buildSubNavItem(
                  title: 'Syllabus',
                  routeKey: 'syllabus',
                  activeIcon: Icons.import_contacts_outlined,
                ),
                const SizedBox(height: 16),

                // 4. STUDENT MANAGEMENT
                _buildCategoryHeader(
                  title: 'Student Management',
                  icon: Icons.people_outline_rounded,
                ),
                _buildSubNavItem(
                  title: 'Class Advisors & Mentors',
                  routeKey: 'class_advisers',
                  alternativeKeys: const ['mentors'],
                  activeIcon: Icons.groups_outlined,
                ),
                const SizedBox(height: 16),

                // 5. FACULTY SERVICES
                _buildCategoryHeader(
                  title: 'Faculty Services',
                  icon: Icons.laptop_chromebook_rounded,
                ),
                _buildSubNavItem(
                  title: 'Faculty Workload',
                  routeKey: 'my_courses',
                  activeIcon: Icons.work_outline,
                ),
                _buildSubNavItem(
                  title: 'Research',
                  routeKey: 'research',
                  activeIcon: Icons.science_outlined,
                ),
                const SizedBox(height: 16),

                // 6. LEAVE MANAGEMENT
                _buildCategoryHeader(
                  title: 'Leave Management',
                  icon: Icons.event_note_rounded,
                ),
                _buildSubNavItem(
                  title: 'Faculty Leave',
                  routeKey: 'leave_mgmt',
                  activeIcon: Icons.event_busy_outlined,
                ),
                _buildSubNavItem(
                  title: 'Apply Leave',
                  routeKey: 'apply_leave',
                  activeIcon: Icons.edit_calendar_outlined,
                ),
                const SizedBox(height: 16),

                // 7. COMMUNICATION
                _buildCategoryHeader(
                  title: 'Communication',
                  icon: Icons.chat_bubble_outline_rounded,
                ),
                _buildSubNavItem(
                  title: 'Notifications',
                  routeKey: 'notifications',
                  activeIcon: Icons.notifications_none_outlined,
                ),
                _buildSubNavItem(
                  title: 'Notice Board',
                  routeKey: 'notice_board',
                  activeIcon: Icons.campaign_outlined,
                ),
                const SizedBox(height: 16),

                // 8. REPORTS & ANALYTICS
                _buildCategoryHeader(
                  title: 'Reports & Analytics',
                  icon: Icons.bar_chart_rounded,
                ),
                _buildSubNavItem(
                  title: 'Reports',
                  routeKey: 'reports',
                  activeIcon: Icons.analytics_outlined,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── MAIN NAV ITEM (Dashboard, My Profile) ──
  Widget _buildMainNavItem({
    required String title,
    required IconData icon,
    required String routeKey,
  }) {
    final isSelected = widget.activeRoute == routeKey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => widget.onSelectRoute(routeKey),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CATEGORY HEADER (e.g. Department Administration, Student Management) ──
  Widget _buildCategoryHeader({
    required String title,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SUB NAV ITEM WITH ACTIVE BLUE PILL SELECTION ──
  Widget _buildSubNavItem({
    required String title,
    required String routeKey,
    List<String>? alternativeKeys,
    IconData? activeIcon,
  }) {
    final isSelected = widget.activeRoute == routeKey ||
        (alternativeKeys != null && alternativeKeys.contains(widget.activeRoute));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => widget.onSelectRoute(routeKey),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              if (isSelected && activeIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    activeIcon,
                    size: 18,
                    color: Colors.white,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 10),
                  child: Text(
                    '•',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
