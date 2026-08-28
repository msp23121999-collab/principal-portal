import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_unified/modules/admin/app/router/route_names.dart';
import 'package:erp_unified/modules/admin/app/theme/app_typography.dart';

class AppDrawer extends StatefulWidget {
  final String currentLocation;

  const AppDrawer({
    super.key,
    required this.currentLocation,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late bool _academicsExpanded;
  late bool _studentsExpanded;
  late bool _facultyExpanded;
  late bool _examExpanded;
  late bool _servicesExpanded;

  @override
  void initState() {
    super.initState();
    _updateExpandedStates();
  }

  @override
  void didUpdateWidget(covariant AppDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      _updateExpandedStates();
    }
  }

  void _updateExpandedStates() {
    final loc = widget.currentLocation;

    final isAcademic = loc == RouteNames.departments ||
        loc == RouteNames.programmes ||
        loc == RouteNames.courses ||
        loc == RouteNames.regulations ||
        loc == RouteNames.academicCalendar ||
        loc == RouteNames.academicSchedule;

    final isStudent = loc == RouteNames.students ||
        loc == RouteNames.attendance ||
        loc == RouteNames.marks ||
        loc == RouteNames.certificates;

    final isFaculty = loc == RouteNames.faculty ||
        loc == RouteNames.workload ||
        loc == RouteNames.leave;

    final isExam = loc == RouteNames.cia ||
        loc == RouteNames.semester ||
        loc == RouteNames.hallTicket ||
        loc == RouteNames.results;

    final isServices = loc == RouteNames.fees ||
        loc == RouteNames.scholarships ||
        loc == RouteNames.hr ||
        loc == RouteNames.library ||
        loc == RouteNames.hostel ||
        loc == RouteNames.transport ||
        loc == RouteNames.placement ||
        loc == RouteNames.eventManagement ||
        loc == RouteNames.reports;

    setState(() {
      _academicsExpanded = isAcademic;
      _studentsExpanded = isStudent;
      _facultyExpanded = isFaculty;
      _examExpanded = isExam;
      _servicesExpanded = isServices;
    });
  }

  bool _isActive(String targetPath) {
    return widget.currentLocation == targetPath;
  }

  void _navigate(BuildContext context, String path) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
    context.go(path);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF627DAB),
          letterSpacing: 0.9,
          fontFamily: AppTypography.fontFamily,
        ),
      ),
    );
  }

  Widget _buildExpandableHeader({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    bool isSelected = false,
  }) {
    return _HoverableItem(
      builder: (isHovered) {
        return InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isHovered ? const Color(0xFF0C387A).withOpacity(0.5) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isSelected || isHovered ? Colors.white : const Color(0xFF8DA4CE),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isHovered ? FontWeight.bold : FontWeight.w500,
                      color: isSelected || isHovered ? Colors.white : const Color(0xFFD1E0F7),
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isHovered ? Colors.white : const Color(0xFF627DAB),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String routePath,
  }) {
    final isSelected = _isActive(routePath);

    return _HoverableItem(
      builder: (isHovered) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: InkWell(
            onTap: () => _navigate(context, routePath),
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFB800)
                    : (isHovered ? const Color(0xFF0C387A).withOpacity(0.5) : Colors.transparent),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: isSelected
                        ? const Color(0xFF001B44)
                        : (isHovered ? Colors.white : const Color(0xFF8DA4CE)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : (isHovered ? FontWeight.w600 : FontWeight.w500),
                        color: isSelected
                            ? const Color(0xFF001B44)
                            : (isHovered ? Colors.white : const Color(0xFFD1E0F7)),
                        fontFamily: AppTypography.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String routePath,
  }) {
    final isSelected = _isActive(routePath);

    return _HoverableItem(
      builder: (isHovered) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 2),
          child: InkWell(
            onTap: () => _navigate(context, routePath),
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFB800)
                    : (isHovered ? const Color(0xFF0C387A).withOpacity(0.5) : Colors.transparent),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected
                        ? const Color(0xFF001B44)
                        : (isHovered ? Colors.white : const Color(0xFF8DA4CE)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : (isHovered ? FontWeight.w600 : FontWeight.normal),
                        color: isSelected
                            ? const Color(0xFF001B44)
                            : (isHovered ? Colors.white : const Color(0xFFB0C4DE)),
                        fontFamily: AppTypography.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF001B44),
        border: Border(
          right: BorderSide(color: Color(0xFF00102B), width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── ERP Admin Brand Header ───────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF001B44),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KSRCE ERP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                        Text(
                          'KSR COLLEGE OF ENGINEERING',
                          style: TextStyle(
                            color: Color(0xFF8DA4CE),
                            fontSize: 8.5,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                        Text(
                          'TIRUCHENGODE',
                          style: TextStyle(
                            color: Color(0xFF627DAB),
                            fontSize: 8,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF0C387A), height: 1, thickness: 1),

            // ── ERP Admin Navigation Modules List ────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                children: [
                  _buildSectionHeader('PORTAL OVERVIEW'),
                  _buildNavItem(
                    context: context,
                    title: 'Dashboard',
                    icon: Icons.grid_view_rounded,
                    routePath: RouteNames.dashboard,
                  ),

                  _buildSectionHeader('ERP ADMIN MODULES'),

                  // Academics
                  _buildExpandableHeader(
                    title: 'Academics Setup',
                    icon: Icons.school_outlined,
                    isExpanded: _academicsExpanded,
                    onToggle: () => setState(() => _academicsExpanded = !_academicsExpanded),
                  ),
                  if (_academicsExpanded) ...[
                    _buildSubNavItem(
                      context: context,
                      title: 'Departments',
                      icon: Icons.business_rounded,
                      routePath: RouteNames.departments,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Programmes & Degrees',
                      icon: Icons.school_rounded,
                      routePath: RouteNames.programmes,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Courses & Curriculum',
                      icon: Icons.menu_book_rounded,
                      routePath: RouteNames.courses,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Academic Regulations',
                      icon: Icons.gavel_rounded,
                      routePath: RouteNames.regulations,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Academic Calendar',
                      icon: Icons.calendar_month_outlined,
                      routePath: RouteNames.academicCalendar,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Academic Schedule',
                      icon: Icons.schedule_rounded,
                      routePath: RouteNames.academicSchedule,
                    ),
                  ],

                  // Student Management
                  _buildExpandableHeader(
                    title: 'Student Management',
                    icon: Icons.groups_outlined,
                    isExpanded: _studentsExpanded,
                    onToggle: () => setState(() => _studentsExpanded = !_studentsExpanded),
                  ),
                  if (_studentsExpanded) ...[
                    _buildSubNavItem(
                      context: context,
                      title: 'Student Directory',
                      icon: Icons.person_outline_rounded,
                      routePath: RouteNames.students,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Attendance Records',
                      icon: Icons.fact_check_outlined,
                      routePath: RouteNames.attendance,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Student Marks',
                      icon: Icons.assignment_outlined,
                      routePath: RouteNames.marks,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Certificates & Documents',
                      icon: Icons.workspace_premium_outlined,
                      routePath: RouteNames.certificates,
                    ),
                  ],

                  // Faculty Management
                  _buildExpandableHeader(
                    title: 'Faculty Management',
                    icon: Icons.badge_outlined,
                    isExpanded: _facultyExpanded,
                    onToggle: () => setState(() => _facultyExpanded = !_facultyExpanded),
                  ),
                  if (_facultyExpanded) ...[
                    _buildSubNavItem(
                      context: context,
                      title: 'Faculty Directory',
                      icon: Icons.person_search_outlined,
                      routePath: RouteNames.faculty,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Workload & Allocation',
                      icon: Icons.pie_chart_outline_rounded,
                      routePath: RouteNames.workload,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Faculty Leave Management',
                      icon: Icons.event_note_outlined,
                      routePath: RouteNames.leave,
                    ),
                  ],

                  // Examination Cell
                  _buildExpandableHeader(
                    title: 'Examination Cell',
                    icon: Icons.quiz_outlined,
                    isExpanded: _examExpanded,
                    onToggle: () => setState(() => _examExpanded = !_examExpanded),
                  ),
                  if (_examExpanded) ...[
                    _buildSubNavItem(
                      context: context,
                      title: 'Continuous Assessment (CIA)',
                      icon: Icons.edit_note_rounded,
                      routePath: RouteNames.cia,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'End Semester Exams',
                      icon: Icons.draw_outlined,
                      routePath: RouteNames.semester,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Hall Ticket Generation',
                      icon: Icons.badge_outlined,
                      routePath: RouteNames.hallTicket,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Results & Grade Sheets',
                      icon: Icons.grade_outlined,
                      routePath: RouteNames.results,
                    ),
                  ],

                  // Finance & Campus Services
                  _buildExpandableHeader(
                    title: 'Finance & Services',
                    icon: Icons.account_balance_outlined,
                    isExpanded: _servicesExpanded,
                    onToggle: () => setState(() => _servicesExpanded = !_servicesExpanded),
                  ),
                  if (_servicesExpanded) ...[
                    _buildSubNavItem(
                      context: context,
                      title: 'Fee Structure & Collection',
                      icon: Icons.payments_outlined,
                      routePath: RouteNames.fees,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Scholarships & Concessions',
                      icon: Icons.card_giftcard_rounded,
                      routePath: RouteNames.scholarships,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'HR & Payroll',
                      icon: Icons.work_outline_rounded,
                      routePath: RouteNames.hr,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Central Library System',
                      icon: Icons.local_library_outlined,
                      routePath: RouteNames.library,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Hostel & Mess Management',
                      icon: Icons.night_shelter_outlined,
                      routePath: RouteNames.hostel,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Transport & Routes',
                      icon: Icons.directions_bus_outlined,
                      routePath: RouteNames.transport,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Campus Placements',
                      icon: Icons.business_center_outlined,
                      routePath: RouteNames.placement,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Event Management',
                      icon: Icons.event_available_outlined,
                      routePath: RouteNames.eventManagement,
                    ),
                    _buildSubNavItem(
                      context: context,
                      title: 'Analytics & Reports',
                      icon: Icons.insert_chart_outlined_rounded,
                      routePath: RouteNames.reports,
                    ),
                  ],
                ],
              ),
            ),

            const Divider(color: Color(0xFF0C387A), height: 1, thickness: 1),

            // ── Footer Badge ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0052CC),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ERP Admin Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('KSRCE ERP Enterprise v1.0', style: TextStyle(fontSize: 9, color: Color(0xFF8DA4CE))),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
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

class _HoverableItem extends StatefulWidget {
  final Widget Function(bool isHovered) builder;

  const _HoverableItem({required this.builder});

  @override
  State<_HoverableItem> createState() => _HoverableItemState();
}

class _HoverableItemState extends State<_HoverableItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.builder(_isHovered),
    );
  }
}


