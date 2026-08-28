import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router/route_names.dart';
import '../theme.dart';
import 'app_drawer.dart';
import 'module_preloader.dart';
import '../services/admin_user_service.dart'; // Corrected path
import '../services/admin_supabase_service.dart'; // Corrected path

class AppScaffold extends StatefulWidget {
  const AppScaffold({
    super.key,
    required this.child,
    required this.currentLocation,
  });
  final Widget child;
  final String currentLocation;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _isSidebarVisible = true;
  bool _showPreloader = false;

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _GlobalSearchDialog(),
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
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
                      _isSidebarVisible && !isMobile
                          ? Icons.menu_open_rounded
                          : Icons.menu_rounded,
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
                              const Icon(
                                Icons.search_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isMobile
                                      ? 'Search...'
                                      : 'Global Search or type Ctrl + K...',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isMobile)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Text(
                                    'Ctrl + K',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
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

                // ── Admin Profile Avatar & Popup Menu ──
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tooltip: 'User Profile & Settings',
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.go('/');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Logged out successfully. Returned to Portal Gateway.',
                          ),
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
                          const Text(
                            'Administrator',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const Text(
                            'admin@ksrce.ac.in',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(
                                  0xFF0056A6,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'ERP Admin',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0056A6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Divider(),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0056A6),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 8),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Administrator',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                'ERP Admin',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xFF6B7280),
                          ),
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
      drawer:
          isMobile ? AppDrawer(currentLocation: widget.currentLocation) : null,
      body: Row(
        children: [
          if (!isMobile && _isSidebarVisible)
            AppDrawer(currentLocation: widget.currentLocation),
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
                                  style: TextStyle(
                                    color: Color(0xFF8DA4CE),
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'ERP Version 3.0.1',
                                    style: TextStyle(
                                      color: Color(0xFF8DA4CE),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () {},
                                    child: const Text(
                                      'Help Desk',
                                      style: TextStyle(
                                        color: Color(0xFFD1E0F7),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () {},
                                    child: const Text(
                                      'Support',
                                      style: TextStyle(
                                        color: Color(0xFFD1E0F7),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () {},
                                    child: const Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        color: Color(0xFFD1E0F7),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
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
                          children: [
                            const Text(
                              '© 2026 KSR College of Engineering, Tiruchengode.',
                              style: TextStyle(
                                color: Color(0xFF8DA4CE),
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'ERP v3.0.1',
                                  style: TextStyle(
                                    color: Color(0xFF8DA4CE),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () {},
                                  child: const Text(
                                    'Help',
                                    style: TextStyle(
                                      color: Color(0xFFD1E0F7),
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () {},
                                  child: const Text(
                                    'Support',
                                    style: TextStyle(
                                      color: Color(0xFFD1E0F7),
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () {},
                                  child: const Text(
                                    'Privacy',
                                    style: TextStyle(
                                      color: Color(0xFFD1E0F7),
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
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

class _GlobalSearchDialog extends StatefulWidget {
  const _GlobalSearchDialog();

  @override
  State<_GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<_GlobalSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _dbUsers = []; // Changed from List<UserModel>
  List<Map<String, dynamic>> _dbDepts = [];
  List<Map<String, dynamic>> _dbExams = [];
  List<Map<String, dynamic>> _dbDocs = [];
  String _query = '';

  final List<Map<String, dynamic>> _staticItems = const [
    {
      'title': 'Dashboard',
      'category': 'Dashboard',
      'icon': Icons.grid_view_rounded,
      'route': RouteNames.dashboard,
    },
    {
      'title': 'Academic Year Management',
      'category': 'Academic Management',
      'icon': Icons.calendar_today_rounded,
      'route': RouteNames.academicYear,
    },
    {
      'title': 'Department Management',
      'category': 'Academic Management',
      'icon': Icons.business_rounded,
      'route': RouteNames.departments,
    },
    {
      'title': 'Programme & Subject Management',
      'category': 'Academic Management',
      'icon': Icons.auto_stories_rounded,
      'route': RouteNames.programmesSubjects,
    },
    {
      'title': 'Regulation Management',
      'category': 'Academic Management',
      'icon': Icons.gavel_rounded,
      'route': RouteNames.regulations,
    },
    {
      'title': 'Academic Configuration',
      'category': 'Academic Management',
      'icon': Icons.settings_suggest_rounded,
      'route': RouteNames.academicConfig,
    },
    {
      'title': 'User Management',
      'category': 'User Management',
      'icon': Icons.manage_accounts_rounded,
      'route': RouteNames.users,
    },
    {
      'title': 'Attendance Management',
      'category': 'Academic Operations',
      'icon': Icons.event_available_rounded,
      'route': RouteNames.attendance,
    },
    {
      'title': 'Marks Management',
      'category': 'Academic Operations',
      'icon': Icons.edit_note_rounded,
      'route': RouteNames.marks,
    },
    {
      'title': 'Examination Management',
      'category': 'Academic Operations',
      'icon': Icons.assignment_rounded,
      'route': RouteNames.examinations,
    },
    {
      'title': 'Hall Ticket Management',
      'category': 'Academic Operations',
      'icon': Icons.confirmation_number_rounded,
      'route': RouteNames.hallTicket,
    },
    {
      'title': 'Results Management',
      'category': 'Academic Operations',
      'icon': Icons.grade_rounded,
      'route': RouteNames.results,
    },
    {
      'title': 'Certificates Management',
      'category': 'Academic Operations',
      'icon': Icons.verified_user_rounded,
      'route': RouteNames.certificates,
    },
    {
      'title': 'Notification Management',
      'category': 'Communication',
      'icon': Icons.notifications_active_rounded,
      'route': RouteNames.notificationManagement,
    },
    {
      'title': 'Digital Repository',
      'category': 'Communication',
      'icon': Icons.folder_copy_rounded,
      'route': RouteNames.digitalRepository,
    },
    {
      'title': 'Fees & Scholarships',
      'category': 'Finance & HR',
      'route': RouteNames.digitalRepository,
    },
    {
      'title': 'Audit Logs',
      'category': 'Security',
      'icon': Icons.history_rounded,
      'route': RouteNames.auditLogs,
    },
    {
      'title': 'Backup & Restore',
      'category': 'Security',
      'icon': Icons.backup_rounded,
      'route': RouteNames.backupRestore,
    },
    {
      'title': 'Approval Workflow',
      'category': 'Security',
      'icon': Icons.rule_folder_rounded,
      'route': RouteNames.approvalWorkflow,
    },
    {
      'title': 'Approval',
      'category': 'Security',
      'icon': Icons.rule_folder_rounded,
      'route': RouteNames.approvalWorkflow,
    },
    {
      'title': 'My Profile',
      'category': 'Settings',
      'icon': Icons.account_circle_rounded,
      'route': RouteNames.myProfile,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchDbRecords();
  }

  Future<void> _fetchDbRecords() async {
    try {
      final results = await Future.wait([
        AdminUserService.fetchAllUsers(), // Corrected method name
        AdminSupabaseService.fetchDepartments(),
        AdminSupabaseService.fetchExamSchedules(),
        AdminSupabaseService.fetchRepositoryDocuments(),
      ]);

      if (mounted) {
        setState(() {
          _dbUsers =
              results[0] as List<Map<String, dynamic>>; // Corrected type cast
          _dbDepts = results[1] as List<Map<String, dynamic>>;
          _dbExams = results[2] as List<Map<String, dynamic>>;
          _dbDocs = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _computeResults() {
    final q = _query.trim().toLowerCase();
    final list = <Map<String, dynamic>>[];

    if (q.isEmpty) {
      return _staticItems;
    }

    // 1. Search Live DB Users (Students, Faculty, Staff)
    for (final u in _dbUsers) {
      final nameMatch = (u['name'] ?? '').toString().toLowerCase().contains(q);
      final emailMatch = (u['email'] ?? '').toString().toLowerCase().contains(
            q,
          );
      final deptMatch =
          (u['department'] ?? '').toString().toLowerCase().contains(q);
      final roleMatch = (u['role'] ?? '').toString().toLowerCase().contains(q);
      final regMatch =
          (u['registration_number'] ?? '').toString().toLowerCase().contains(q);
      final rollMatch =
          (u['roll_number'] ?? '').toString().toLowerCase().contains(q);
      final empMatch =
          (u['employee_id'] ?? '').toString().toLowerCase().contains(q);

      if (nameMatch ||
          emailMatch ||
          deptMatch ||
          roleMatch ||
          regMatch ||
          rollMatch ||
          empMatch) {
        final isStudent =
            (u['role'] ?? '').toString().toLowerCase().contains('student');
        final isFaculty =
            (u['role'] ?? '').toString().toLowerCase().contains('faculty') ||
                (u['role'] ?? '').toString().toLowerCase().contains('hod');

        var icon = Icons.person_rounded;
        var color = const Color(0xFF2563EB);
        var categoryBadge = 'Student Directory';

        if (isFaculty) {
          icon = Icons.badge_rounded;
          color = const Color(0xFF059669);
          categoryBadge = 'Faculty Directory';
        } else if (!isStudent) {
          icon = Icons.manage_accounts_rounded;
          color = const Color(0xFFD97706);
          categoryBadge = '${u['role']} Directory';
        }

        var sub = u['role']?.toString() ?? '';
        if ((u['department'] ?? '').toString().isNotEmpty)
          sub += ' • ${u['department']}';
        if ((u['registration_number'] ?? '').toString().isNotEmpty) {
          sub += ' • Reg: ${u['registration_number']}';
        } else if ((u['employee_id'] ?? '').toString().isNotEmpty) {
          sub += ' • Emp ID: ${u['employee_id']}';
        }

        list.add({
          'title': u['name']?.toString() ?? 'Unknown User',
          'category': categoryBadge,
          'subtitle': sub,
          'icon': icon,
          'color': color,
          'route': RouteNames.users,
          'isDb': true,
        });
      }
    }

    // 2. Search Live DB Departments
    for (final d in _dbDepts) {
      final name = (d['name'] ?? d['department_name'] ?? '').toString();
      final code = (d['code'] ?? '').toString();
      final hod = (d['hod'] ?? d['hod_name'] ?? '').toString();
      if (name.toLowerCase().contains(q) ||
          code.toLowerCase().contains(q) ||
          hod.toLowerCase().contains(q)) {
        list.add({
          'title': name,
          'category': 'Department Record',
          'subtitle':
              'Code: ${code.isNotEmpty ? code : 'DEPT'} • HOD: ${hod.isNotEmpty ? hod : 'Unassigned'}',
          'icon': Icons.business_rounded,
          'color': const Color(0xFF7C3AED),
          'route': RouteNames.departments,
          'isDb': true,
        });
      }
    }

    // 3. Search Live DB Exam Schedules / Courses
    for (final ex in _dbExams) {
      final title = (ex['title'] ?? ex['exam_title'] ?? ex['course_name'] ?? '')
          .toString();
      final code = (ex['subject_code'] ?? ex['code'] ?? '').toString();
      final dept = (ex['department'] ?? '').toString();
      if (title.toLowerCase().contains(q) ||
          code.toLowerCase().contains(q) ||
          dept.toLowerCase().contains(q)) {
        list.add({
          'title': title.isNotEmpty ? title : 'Exam ($code)',
          'category': 'Exam & Course Record',
          'subtitle':
              'Subject Code: $code${dept.isNotEmpty ? ' • Dept: $dept' : ''}',
          'icon': Icons.assignment_rounded,
          'color': const Color(0xFF0052CC),
          'route': RouteNames.examinations,
          'isDb': true,
        });
      }
    }

    // 4. Search Live Repository Documents
    for (final doc in _dbDocs) {
      final title =
          (doc['title'] ?? doc['name'] ?? doc['file_name'] ?? '').toString();
      final category = (doc['category'] ?? doc['folder_name'] ?? '').toString();
      if (title.toLowerCase().contains(q) ||
          category.toLowerCase().contains(q)) {
        list.add({
          'title': title,
          'category': 'Digital Document',
          'subtitle':
              'Category: ${category.isNotEmpty ? category : 'Repository File'}',
          'icon': Icons.description_rounded,
          'color': const Color(0xFF0284C7),
          'route': RouteNames.digitalRepository,
          'isDb': true,
        });
      }
    }

    // 5. Search Static System Pages
    for (final item in _staticItems) {
      final t = (item['title'] as String).toLowerCase();
      final c = (item['category'] as String).toLowerCase();
      if (t.contains(q) || c.contains(q)) {
        list.add(item);
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _computeResults();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 580),
        decoration: BoxDecoration(
          color: const Color(0xFFECEFF4),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Header Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search for students, faculty, courses...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF0052CC),
                    size: 20,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _query = val);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Search Results List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No matching pages found for "$_query"',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final icon = (item['icon'] as IconData?) ??
                            Icons.grid_view_rounded;
                        final title = item['title'] as String;
                        final category = item['category'] as String;
                        final route = item['route'] as String;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                icon,
                                color: const Color(0xFF0052CC),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                fontSize: 13.5,
                              ),
                            ),
                            subtitle: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              context.go(route);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
