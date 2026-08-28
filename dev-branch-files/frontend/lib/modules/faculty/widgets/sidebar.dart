// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final bool showCloseButton;
  final String role;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.showCloseButton = false,
    this.role = 'student',
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isCurriculumExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedIndex == 22 || widget.selectedIndex == 23) {
      _isCurriculumExpanded = true;
    }
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex == 22 || widget.selectedIndex == 23) {
      _isCurriculumExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFaculty = widget.role == 'faculty';

    return Container(
      color: const Color(0xFF0A1930), // Dark blue background matching KSR theme
      child: Column(
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Row(
              mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                    ),
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'KSR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'COLLEGE OF ENGINEERING',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (widget.showCloseButton && !widget.isCollapsed)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
          
          if (!widget.isCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.role == 'faculty' ? 'FACULTY PORTAL' : 'STUDENT PORTAL',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            
          const SizedBox(height: 8),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (isFaculty) ...[
                  _buildNavItem(0, Icons.business, 'ERP Admin'),
                ] else ...[
                  _buildNavItem(0, Icons.home_outlined, 'Dashboard'),
                  _buildNavItem(1, Icons.calendar_today_outlined, 'Academic Calendar'),
                  _buildNavItem(2, Icons.person_outline, 'My Profile'),
                  _buildNavItem(3, Icons.access_time, 'Timetable'),
                  _buildNavItem(4, Icons.check_circle_outline, 'Attendance'),
                  _buildNavItem(5, Icons.trending_up, 'Mark View'),
                  
                  // Curriculum Expandable Menu
                  _buildParentNavItem(Icons.menu_book, 'Curriculum', _isCurriculumExpanded, () {
                    if (widget.isCollapsed) {
                      widget.onToggleCollapse();
                      setState(() {
                        _isCurriculumExpanded = true;
                      });
                    } else {
                      setState(() {
                        _isCurriculumExpanded = !_isCurriculumExpanded;
                      });
                    }
                  }),
                  
                  // Submenu items
                  if (_isCurriculumExpanded && !widget.isCollapsed) ...[
                    _buildSubNavItem(22, Icons.collections_bookmark_outlined, 'Syllabus'),
                    _buildSubNavItem(23, Icons.assessment_outlined, 'Reports'),
                  ],
                  
                  _buildNavItem(6, Icons.event_note, 'Exam Timetable'),
                  _buildNavItem(7, Icons.app_registration, 'Exam Registration'),
                  _buildNavItem(8, Icons.badge_outlined, 'Hall Ticket'),
                  _buildNavItem(9, Icons.attach_money, 'Fees / Payments'),
                  _buildNavItem(10, Icons.local_library_outlined, 'Library'),
                  _buildNavItem(11, Icons.hotel_outlined, 'Hostel'),
                  _buildNavItem(12, Icons.directions_bus_outlined, 'Transport'),
                  _buildNavItem(13, Icons.emoji_events_outlined, 'Achievements'),
                  _buildNavItem(14, Icons.school_outlined, 'Extra Courses'),
                  _buildNavItem(15, Icons.report_problem_outlined, 'Grievance'),
                  _buildNavItem(16, Icons.workspace_premium_outlined, 'Certificates'),
                  _buildNavItem(17, Icons.work_outline, 'Placement'),
                  _buildNavItem(18, Icons.medical_services_outlined, 'Medical & Donation'),
                  _buildNavItem(19, Icons.notifications_outlined, 'Notifications'),
                  _buildNavItem(20, Icons.campaign_outlined, 'Notice Board'),
                  _buildNavItem(24, Icons.business, 'ERP Admin'),
                ],
              ],
            ),
          ),
          
            // Logout
          _buildNavItem(21, Icons.logout, 'Logout'),
          const SizedBox(height: 16),
          
          // Bottom branding
          if (!widget.isCollapsed)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.white24, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'KSRCE ERP',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'v2.0.0',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParentNavItem(IconData icon, String title, bool isExpanded, VoidCallback onTap) {
    final hasActiveChild = widget.selectedIndex == 22 || widget.selectedIndex == 23;
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 4, top: 4),
      child: Tooltip(
        message: widget.isCollapsed ? title : '',
        child: Material(
          color: Colors.transparent,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Container(
              padding: widget.isCollapsed 
                  ? const EdgeInsets.symmetric(vertical: 14)
                  : const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              alignment: widget.isCollapsed ? Alignment.center : Alignment.centerLeft,
              child: widget.isCollapsed
                  ? Icon(
                      icon,
                      color: hasActiveChild ? Colors.white : Colors.white70,
                      size: 22,
                    )
                  : Row(
                      children: [
                        Icon(
                          icon,
                          color: hasActiveChild ? Colors.white : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: hasActiveChild ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight: hasActiveChild ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white30,
                          size: 16,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubNavItem(int index, IconData icon, String title) {
    final isActive = widget.selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 4, top: 4, left: 16),
      child: Tooltip(
        message: widget.isCollapsed ? title : '',
        child: Material(
          color: isActive ? const Color(0xFF1D4ED8) : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: InkWell(
            onTap: () => widget.onItemSelected(index),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isActive ? Colors.white : Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isActive = widget.selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 4, top: 4),
      child: Tooltip(
        message: widget.isCollapsed ? title : '',
            child: Material(
          color: isActive ? const Color(0xFF1D4ED8) : Colors.transparent, // Bright Blue pill
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              if (index <= 24) {
                widget.onItemSelected(index);
              }
            },
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Container(
              padding: widget.isCollapsed 
                  ? const EdgeInsets.symmetric(vertical: 14)
                  : const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              alignment: widget.isCollapsed ? Alignment.center : Alignment.centerLeft,
              child: widget.isCollapsed
                  ? Icon(
                      icon,
                      color: isActive ? Colors.white : Colors.white70,
                      size: 22,
                    )
                  : Row(
                      children: [
                        Icon(
                          icon,
                          color: isActive ? Colors.white : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
