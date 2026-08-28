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
  bool _isReportsExpanded = false;
  final ScrollController _scrollController = ScrollController();

  int _getPositionOfIndex(int selectedIndex) {
    final list = [0, 1, 2, 3, 4, 5];
    if (_isCurriculumExpanded) {
      list.add(22);
      if (_isReportsExpanded) {
        list.add(23);
        list.add(26);
      }
    }
    list.addAll([6, 8, 9, 10, 11, 12, 13, 14, 15, 17, 25, 19, 20]);
    final pos = list.indexOf(selectedIndex);
    return pos >= 0 ? pos : 0;
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final pos = _getPositionOfIndex(widget.selectedIndex);
    const double itemHeight = 50.0;
    final double targetOffset = pos * itemHeight;
    final double viewportHeight = _scrollController.position.viewportDimension;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    
    double scrollOffset = targetOffset - (viewportHeight / 2) + (itemHeight / 2);
    scrollOffset = scrollOffset.clamp(0.0, maxScroll);
    
    _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scheduleScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedIndex == 22 || widget.selectedIndex == 23 || widget.selectedIndex == 26) {
      _isCurriculumExpanded = true;
    }
    if (widget.selectedIndex == 23 || widget.selectedIndex == 26) {
      _isReportsExpanded = true;
    }
    _scheduleScroll();
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex == 22 || widget.selectedIndex == 23 || widget.selectedIndex == 26) {
      _isCurriculumExpanded = true;
    }
    if (widget.selectedIndex == 23 || widget.selectedIndex == 26) {
      _isReportsExpanded = true;
    }
    _scheduleScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            padding: const EdgeInsets.only(left: 12.0, right: 8.0, top: 24.0, bottom: 24.0),
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
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'KSR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
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
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
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
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                if (isFaculty) ...[
                  _buildNavItem(0, Icons.home_outlined, 'Dashboard'),
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
                    _buildSubParentNavItem(Icons.assessment_outlined, 'Reports', _isReportsExpanded, () {
                      setState(() {
                        _isReportsExpanded = !_isReportsExpanded;
                      });
                    }),
                    if (_isReportsExpanded) ...[
                      _buildNestedSubNavItem(23, Icons.school_outlined, 'Course Exit Survey'),
                      _buildNestedSubNavItem(26, Icons.rate_review_outlined, 'Course Feedback'),
                    ],
                  ],
                  
                  _buildNavItem(6, Icons.event_note, 'Exam Timetable'),
                  _buildNavItem(8, Icons.assignment_turned_in_outlined, 'No Due'),
                  _buildNavItem(9, Icons.attach_money, 'Fees / Payments'),
                  _buildNavItem(10, Icons.local_library_outlined, 'Library'),
                  _buildNavItem(11, Icons.hotel_outlined, 'Hostel'),
                  _buildNavItem(12, Icons.directions_bus_outlined, 'Transport'),
                  _buildNavItem(13, Icons.emoji_events_outlined, 'Achievements'),
                  _buildNavItem(14, Icons.school_outlined, 'Extra Courses'),
                  _buildNavItem(15, Icons.report_problem_outlined, 'Grievance'),
                  _buildNavItem(17, Icons.work_outline, 'Placement'),
                  _buildNavItem(25, Icons.assignment_outlined, 'Assignments'),
                  _buildNavItem(19, Icons.notifications_outlined, 'Notifications'),
                  _buildNavItem(20, Icons.campaign_outlined, 'Notice Board'),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildParentNavItem(IconData icon, String title, bool isExpanded, VoidCallback onTap) {
    final hasActiveChild = widget.selectedIndex == 22 || widget.selectedIndex == 23 || widget.selectedIndex == 26;
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

  Widget _buildSubParentNavItem(IconData icon, String title, bool isExpanded, VoidCallback onTap) {
    final hasActiveChild = widget.selectedIndex == 23 || widget.selectedIndex == 26;
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 4, top: 4, left: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: hasActiveChild ? Colors.white : Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: hasActiveChild ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: hasActiveChild ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white30,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNestedSubNavItem(int index, IconData icon, String title) {
    final isActive = widget.selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 4, top: 4, left: 32),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isActive ? Colors.white : Colors.white54,
                    size: 14,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontSize: 11,
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
              widget.onItemSelected(index);
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
                              fontSize: 13,
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
