import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router/route_names.dart';
import '../theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({
    super.key,
    required this.currentLocation,
  });
  final String currentLocation;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late bool _academicExpanded;
  late bool _userExpanded;
  late bool _operationsExpanded;
  late bool _campusExpanded;
  late bool _commExpanded;
  late bool _securityExpanded;
  late bool _settingsExpanded;

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

    _academicExpanded = loc == RouteNames.academicYear ||
        loc == RouteNames.departments ||
        loc == RouteNames.programmesSubjects ||
        loc == RouteNames.regulations ||
        loc == RouteNames.academicConfig;

    _userExpanded = loc == RouteNames.users;

    _operationsExpanded = loc == RouteNames.attendance ||
        loc == RouteNames.marks ||
        loc == RouteNames.examinations ||
        loc == RouteNames.hallTicket ||
        loc == RouteNames.results;
    _campusExpanded = loc == RouteNames.library ||
        loc == RouteNames.hostel ||
        loc == RouteNames.transport ||
        loc == RouteNames.placement ||
        loc == RouteNames.eventManagement ||
        loc == RouteNames.inventoryAssets ||
        loc == RouteNames.grievanceManagement;

    _commExpanded = loc == RouteNames.notificationManagement ||
        loc == RouteNames.digitalRepository;

    _securityExpanded = loc == RouteNames.auditLogs ||
        loc == RouteNames.backupRestore ||
        loc == RouteNames.approvalWorkflow;

    _settingsExpanded = loc == RouteNames.myProfile;

    setState(() {});
  }

  bool _isActive(String targetPath) => widget.currentLocation == targetPath;

  void _navigate(BuildContext context, String path) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }
    context.go(path);
  }

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 12, top: 14, bottom: 6),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.9,
            fontFamily: AppTypography.fontFamily,
          ),
        ),
      );

  Widget _buildExpandableHeader({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    bool isSelected = false,
  }) =>
      InkWell(
        onTap: onToggle,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF0056A6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? const Color(0xFF0056A6)
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0056A6)
                        : const Color(0xFF374151),
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF0056A6)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String routePath,
  }) {
    final isSelected = _isActive(routePath);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: () => _navigate(context, routePath),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF0056A6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? const Color(0xFF0056A6)
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0056A6)
                        : const Color(0xFF374151),
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String routePath,
  }) {
    final isSelected = _isActive(routePath);

    return Padding(
      padding: const EdgeInsets.only(left: 18, bottom: 2),
      child: InkWell(
        onTap: () => _navigate(context, routePath),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF0056A6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? const Color(0xFF0056A6)
                    : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF0056A6)
                        : const Color(0xFF6B7280),
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        width: 260,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
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
                        color: const Color(0xFF0056A6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Campus OS',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  fontFamily: AppTypography.fontFamily,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFF0056A6)
                                          .withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0056A6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'ERP Admin Portal',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),

              // ── ERP Admin Navigation Modules List (36 Pages) ──────
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  children: [
                    _buildSectionHeader('MAIN DASHBOARD'),
                    _buildNavItem(
                      context: context,
                      title: 'Dashboard',
                      icon: Icons.grid_view_rounded,
                      routePath: RouteNames.dashboard,
                    ),
                    _buildSectionHeader('ACADEMIC MANAGEMENT'),
                    _buildExpandableHeader(
                      title: 'Academic Management',
                      icon: Icons.school_outlined,
                      isExpanded: _academicExpanded,
                      onToggle: () => setState(
                          () => _academicExpanded = !_academicExpanded),
                    ),
                    if (_academicExpanded) ...[
                      _buildSubNavItem(
                          context: context,
                          title: 'Academic Year Management',
                          icon: Icons.calendar_today_rounded,
                          routePath: RouteNames.academicYear),
                      _buildSubNavItem(
                          context: context,
                          title: 'Department Management',
                          icon: Icons.business_rounded,
                          routePath: RouteNames.departments),
                      _buildSubNavItem(
                          context: context,
                          title: 'Programme & Subject',
                          icon: Icons.auto_stories_rounded,
                          routePath: RouteNames.programmesSubjects),
                      _buildSubNavItem(
                          context: context,
                          title: 'Regulation Management',
                          icon: Icons.gavel_rounded,
                          routePath: RouteNames.regulations),
                      _buildSubNavItem(
                          context: context,
                          title: 'Academic Configuration',
                          icon: Icons.settings_suggest_rounded,
                          routePath: RouteNames.academicConfig),
                    ],
                    _buildSectionHeader('USER MANAGEMENT'),
                    _buildExpandableHeader(
                      title: 'User Management',
                      icon: Icons.people_outline_rounded,
                      isExpanded: _userExpanded,
                      onToggle: () =>
                          setState(() => _userExpanded = !_userExpanded),
                    ),
                    if (_userExpanded) ...[
                      _buildSubNavItem(
                          context: context,
                          title: 'User Directory',
                          icon: Icons.manage_accounts_rounded,
                          routePath: RouteNames.users),
                    ],
                    _buildSectionHeader('ACADEMIC OPERATIONS'),
                    _buildExpandableHeader(
                      title: 'Academic Operations',
                      icon: Icons.fact_check_outlined,
                      isExpanded: _operationsExpanded,
                      onToggle: () => setState(
                          () => _operationsExpanded = !_operationsExpanded),
                    ),
                    if (_operationsExpanded) ...[
                      _buildSubNavItem(
                          context: context,
                          title: 'Attendance Management',
                          icon: Icons.event_available_rounded,
                          routePath: RouteNames.attendance),
                      _buildSubNavItem(
                          context: context,
                          title: 'Marks Management',
                          icon: Icons.edit_note_rounded,
                          routePath: RouteNames.marks),
                      _buildSubNavItem(
                          context: context,
                          title: 'Examination Management',
                          icon: Icons.assignment_rounded,
                          routePath: RouteNames.examinations),
                      _buildSubNavItem(
                          context: context,
                          title: 'Hall Ticket Management',
                          icon: Icons.confirmation_number_rounded,
                          routePath: RouteNames.hallTicket),
                      _buildSubNavItem(
                          context: context,
                          title: 'Results Management',
                          icon: Icons.grade_rounded,
                          routePath: RouteNames.results),
                    ],
                    _buildSectionHeader('CAMPUS SERVICES'),
                    _buildExpandableHeader(
                      title: 'Campus Services',
                      icon: Icons.other_houses_outlined,
                      isExpanded: _campusExpanded,
                      onToggle: () =>
                          setState(() => _campusExpanded = !_campusExpanded),
                    ),
                    if (_campusExpanded) ...[
                      _buildSubNavItem(
                        context: context,
                        title: 'Library Management',
                        icon: Icons.local_library_outlined,
                        routePath: RouteNames.library,
                      ),
                      _buildSubNavItem(
                        context: context,
                        title: 'Hostel Management',
                        icon: Icons.holiday_village_outlined,
                        routePath: RouteNames.hostel,
                      ),
                      _buildSubNavItem(
                        context: context,
                        title: 'Transport Management',
                        icon: Icons.directions_bus_outlined,
                        routePath: RouteNames.transport,
                      ),
                      _buildSubNavItem(
                        context: context,
                        title: 'Placement & Training',
                        icon: Icons.work_outline_rounded,
                        routePath: RouteNames.placement,
                      ),
                      _buildSubNavItem(
                        context: context,
                        title: 'Event Management',
                        icon: Icons.event_outlined,
                        routePath: RouteNames.eventManagement,
                      ),
                      _buildSubNavItem(
                          context: context,
                          title: 'Inventory & Assets',
                          icon: Icons.inventory_2_outlined,
                          routePath: RouteNames.inventoryAssets),
                      _buildSubNavItem(
                          context: context,
                          title: 'Grievance Management',
                          icon: Icons.report_problem_outlined,
                          routePath: RouteNames.grievanceManagement),
                    ],
                    _buildSectionHeader('COMMUNICATION'),
                    _buildExpandableHeader(
                      title: 'Communication',
                      icon: Icons.mark_email_unread_outlined,
                      isExpanded: _commExpanded,
                      onToggle: () =>
                          setState(() => _commExpanded = !_commExpanded),
                    ),
                    if (_commExpanded) ...[
                      _buildSubNavItem(
                          context: context,
                          title: 'Notification Management',
                          icon: Icons.notifications_active_rounded,
                          routePath: RouteNames.notificationManagement),
                      _buildSubNavItem(
                          context: context,
                          title: 'Digital Repository',
                          icon: Icons.folder_copy_rounded,
                          routePath: RouteNames.digitalRepository),
                    ],
                    _buildSectionHeader('SECURITY'),
                    _buildExpandableHeader(
                      title: 'Security & Approvals',
                      icon: Icons.security_rounded,
                      isExpanded: _securityExpanded,
                      onToggle: () => setState(
                          () => _securityExpanded = !_securityExpanded),
                    ),
                    if (_securityExpanded) ...[
                      _buildSubNavItem(
                          context: context,
                          title: 'Audit Logs',
                          icon: Icons.history_rounded,
                          routePath: RouteNames.auditLogs),
                      _buildSubNavItem(
                          context: context,
                          title: 'Backup & Restore',
                          icon: Icons.backup_rounded,
                          routePath: RouteNames.backupRestore),
                      _buildSubNavItem(
                          context: context,
                          title: 'Approval',
                          icon: Icons.rule_folder_rounded,
                          routePath: RouteNames.approvalWorkflow),
                    ],
                    _buildSectionHeader('SETTINGS & PROFILE'),
                    _buildExpandableHeader(
                      title: 'Settings & Profile',
                      icon: Icons.settings_outlined,
                      isExpanded: _settingsExpanded,
                      onToggle: () => setState(
                          () => _settingsExpanded = !_settingsExpanded),
                    ),
                    if (_settingsExpanded) ...[
                      _buildSubNavItem(
                          context: context,
                          title: 'My Profile',
                          icon: Icons.account_circle_rounded,
                          routePath: RouteNames.myProfile),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
