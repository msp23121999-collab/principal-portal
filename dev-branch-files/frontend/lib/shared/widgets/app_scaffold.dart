import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_unified/modules/admin/app/router/route_names.dart';
import 'package:erp_unified/modules/admin/app/theme/app_colors.dart';
import 'app_drawer.dart';
import 'module_preloader.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;
  final String currentLocation;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _isSidebarVisible = true;
  bool _showPreloader = true;

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final searchItems = [
          {'title': 'Dashboard', 'category': 'Overview', 'icon': Icons.grid_view_rounded, 'route': RouteNames.dashboard},
          {'title': 'User Management', 'category': 'Super Admin - Security', 'icon': Icons.people_outline_rounded, 'route': RouteNames.users},
          {'title': 'Role & Permission Matrix', 'category': 'Super Admin - Security', 'icon': Icons.security_outlined, 'route': RouteNames.rolesPermissions},
          {'title': 'Department Management', 'category': 'Super Admin - Academics', 'icon': Icons.domain_outlined, 'route': RouteNames.departments},
          {'title': 'Programme Management', 'category': 'Super Admin - Academics', 'icon': Icons.school_rounded, 'route': RouteNames.programmes},
          {'title': 'Course & Subject Setup', 'category': 'Super Admin - Academics', 'icon': Icons.book_outlined, 'route': RouteNames.courses},
          {'title': 'Regulation Master', 'category': 'Super Admin - Academics', 'icon': Icons.gavel_outlined, 'route': RouteNames.regulations},
          {'title': 'Academic Year Config', 'category': 'Super Admin - System', 'icon': Icons.settings_suggest_outlined, 'route': RouteNames.academicConfig},
          {'title': 'Academic Calendar', 'category': 'ERP Admin - Academics', 'icon': Icons.calendar_month_outlined, 'route': RouteNames.academicCalendar},
          {'title': 'Academic Schedule Grid', 'category': 'ERP Admin - Academics', 'icon': Icons.schedule_rounded, 'route': RouteNames.academicSchedule},
          {'title': 'Student Directory & Documents', 'category': 'ERP Admin - Students', 'icon': Icons.person_outline_rounded, 'route': RouteNames.students},
          {'title': 'Student Attendance Monitoring', 'category': 'ERP Admin - Students', 'icon': Icons.fact_check_outlined, 'route': RouteNames.attendance},
          {'title': 'Student Marks Entry & Grades', 'category': 'ERP Admin - Students', 'icon': Icons.assignment_outlined, 'route': RouteNames.marks},
          {'title': 'Student Certificates', 'category': 'ERP Admin - Students', 'icon': Icons.workspace_premium_outlined, 'route': RouteNames.certificates},
          {'title': 'Faculty Management & Advisors', 'category': 'ERP Admin - Faculty', 'icon': Icons.badge_outlined, 'route': RouteNames.faculty},
          {'title': 'Faculty Workload Allocation', 'category': 'ERP Admin - Faculty', 'icon': Icons.bar_chart_outlined, 'route': RouteNames.workload},
          {'title': 'Faculty Leave Approvals', 'category': 'ERP Admin - Faculty', 'icon': Icons.time_to_leave_outlined, 'route': RouteNames.leave},
          {'title': 'CIA Internal Assessment', 'category': 'ERP Admin - Exams', 'icon': Icons.edit_note_outlined, 'route': RouteNames.cia},
          {'title': 'Semester Examinations', 'category': 'ERP Admin - Exams', 'icon': Icons.event_note_outlined, 'route': RouteNames.semester},
          {'title': 'Hall Ticket Generation', 'category': 'ERP Admin - Exams', 'icon': Icons.confirmation_number_outlined, 'route': RouteNames.hallTicket},
          {'title': 'Result Publishing', 'category': 'ERP Admin - Exams', 'icon': Icons.grade_outlined, 'route': RouteNames.results},
          {'title': 'Fee Structure & Collection', 'category': 'ERP Admin - Finance', 'icon': Icons.receipt_long_outlined, 'route': RouteNames.fees},
          {'title': 'Scholarships & Fines', 'category': 'ERP Admin - Finance', 'icon': Icons.card_giftcard_outlined, 'route': RouteNames.scholarships},
          {'title': 'Human Resources & Payroll (HR)', 'category': 'ERP Admin - HR', 'icon': Icons.badge_outlined, 'route': RouteNames.hr},
          {'title': 'Library Information & Books', 'category': 'ERP Admin - Services', 'icon': Icons.local_library_outlined, 'route': RouteNames.library},
          {'title': 'Hostel Room Allocation', 'category': 'ERP Admin - Services', 'icon': Icons.night_shelter_outlined, 'route': RouteNames.hostel},
          {'title': 'Transport Bus Routes & Pass', 'category': 'ERP Admin - Services', 'icon': Icons.directions_bus_outlined, 'route': RouteNames.transport},
          {'title': 'Campus Placement Drives & Offers', 'category': 'ERP Admin - Services', 'icon': Icons.business_center_outlined, 'route': RouteNames.placement},
          {'title': 'Event Management', 'category': 'Administration', 'icon': Icons.event_outlined, 'route': RouteNames.eventManagement},
          {'title': 'Analytics & Reports', 'category': 'System & Reports', 'icon': Icons.bar_chart_outlined, 'route': RouteNames.reports},
          {'title': 'Notifications Configuration', 'category': 'Super Admin - Communication', 'icon': Icons.notifications_none_outlined, 'route': RouteNames.notificationConfig},
          {'title': 'SMS & Email Gateway Config', 'category': 'Super Admin - Communication', 'icon': Icons.email_outlined, 'route': RouteNames.smsEmailConfig},
          {'title': 'System Settings & Policies', 'category': 'Super Admin - System', 'icon': Icons.settings_outlined, 'route': RouteNames.systemSettings},
          {'title': 'Audit Logs & Login History', 'category': 'Super Admin - Monitoring', 'icon': Icons.history_outlined, 'route': RouteNames.auditLogs},
          {'title': 'Backup & System Restore', 'category': 'Super Admin - Monitoring', 'icon': Icons.backup_outlined, 'route': RouteNames.backupRestore},
        ];

        String query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = searchItems.where((item) {
              final t = (item['title'] as String).toLowerCase();
              final c = (item['category'] as String).toLowerCase();
              return t.contains(query.toLowerCase()) || c.contains(query.toLowerCase());
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 540, maxHeight: 520),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search for students, faculty, courses...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0052CC)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          query = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching items found',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(item['icon'] as IconData, color: const Color(0xFF0052CC), size: 20),
                                  ),
                                  title: Text(
                                    item['title'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                  ),
                                  subtitle: Text(
                                    item['category'] as String,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context.go(item['route'] as String);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_showPreloader) {
      return ModulePreloader(
        moduleName: 'ERP Admin Portal',
        moduleSubtitle: 'KSRCE Unified Enterprise Management System',
        icon: Icons.admin_panel_settings_rounded,
        accentColor: const Color(0xFF0052CC),
        badge: 'OPERATIONS CONTROL',
        child: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _showPreloader = false);
            });
            return const SizedBox.shrink();
          },
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktop = screenWidth > 1100;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // ── Hamburger Toggle Button ──
                Builder(
                  builder: (context) => IconButton(
                    onPressed: () {
                      if (isMobile) {
                        Scaffold.of(context).openDrawer();
                      } else {
                        setState(() {
                          _isSidebarVisible = !_isSidebarVisible;
                        });
                      }
                    },
                    icon: Icon(
                      _isSidebarVisible && !isMobile ? Icons.menu_open_rounded : Icons.menu_rounded,
                      color: const Color(0xFF0F172A),
                      size: 22,
                    ),
                    tooltip: 'Toggle Navigation',
                  ),
                ),
                const SizedBox(width: 8),

                // ── Search Input Box (Middle Header with Command Palette) ──
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: InkWell(
                        onTap: () => _showSearchDialog(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Global Search or type Ctrl + K...',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Text(
                                  'Ctrl + K',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(Icons.dark_mode_outlined, color: Color(0xFF0F172A), size: 20),
                  onPressed: () {},
                  tooltip: 'Toggle Theme',
                ),

                const SizedBox(width: 6),

                // ── Admin Profile Avatar & Popup Menu ──
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tooltip: 'User Profile & Settings',
                  onSelected: (value) {
                    if (value == 'settings') {
                      context.go(RouteNames.systemSettings);
                    } else if (value == 'roles') {
                      context.go(RouteNames.rolesPermissions);
                    } else if (value == 'logout') {
                      context.go('/');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out successfully. Returned to Portal Gateway.'),
                          backgroundColor: Color(0xFF0052CC),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Administrator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const Text('admin@ksrce.ac.in', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Text('Super Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0052CC))),
                          ),
                          const SizedBox(height: 6),
                          const Divider(),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 18, color: Color(0xFF0F172A)),
                          SizedBox(width: 10),
                          Text('System Settings', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'roles',
                      child: Row(
                        children: [
                          Icon(Icons.security_outlined, size: 18, color: Color(0xFF0F172A)),
                          SizedBox(width: 10),
                          Text('Roles & Permissions', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Log Out', style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: Color(0xFF0052CC), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 8),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Administrator', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text('System Administrator', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: isMobile ? AppDrawer(currentLocation: widget.currentLocation) : null,
      body: Row(
        children: [
          if (!isMobile && _isSidebarVisible) AppDrawer(currentLocation: widget.currentLocation),
          Expanded(
            child: Column(
              children: [
                Expanded(child: widget.child),

                // ── Deep Navy Bottom Footer Bar ──
                Container(
                  color: const Color(0xFF001B44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 620;
                      if (isWide) {
                        // Desktop: single row with copyright left + links right
                        return SizedBox(
                          height: 32,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  '© 2026 KSR College of Engineering, Tiruchengode. All Rights Reserved.',
                                  style: TextStyle(color: Color(0xFF8DA4CE), fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('ERP Version 3.0.1', style: TextStyle(color: Color(0xFF8DA4CE), fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 16),
                                  InkWell(onTap: () {}, child: const Text('Help Desk', style: TextStyle(color: Color(0xFFD1E0F7), fontSize: 10))),
                                  const SizedBox(width: 12),
                                  InkWell(onTap: () {}, child: const Text('Support', style: TextStyle(color: Color(0xFFD1E0F7), fontSize: 10))),
                                  const SizedBox(width: 12),
                                  InkWell(onTap: () {}, child: const Text('Privacy Policy', style: TextStyle(color: Color(0xFFD1E0F7), fontSize: 10))),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      // Mobile: compact two-line footer
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              '© 2026 KSR College of Engineering, Tiruchengode.',
                              style: TextStyle(color: Color(0xFF8DA4CE), fontSize: 9),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('ERP v3.0.1', style: TextStyle(color: Color(0xFF8DA4CE), fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                InkWell(onTap: () {}, child: const Text('Help', style: TextStyle(color: Color(0xFFD1E0F7), fontSize: 9))),
                                const SizedBox(width: 10),
                                InkWell(onTap: () {}, child: const Text('Support', style: TextStyle(color: Color(0xFFD1E0F7), fontSize: 9))),
                                const SizedBox(width: 10),
                                InkWell(onTap: () {}, child: const Text('Privacy', style: TextStyle(color: Color(0xFFD1E0F7), fontSize: 9))),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


