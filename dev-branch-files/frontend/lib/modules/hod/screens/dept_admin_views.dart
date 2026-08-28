
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../export_dialog_helper.dart';
import '../../faculty/services/postgres_client.dart';
import '../../faculty/services/profile_service.dart';

// ─── Unified Class Advisors & Mentors View ─────────────────────────────────

class ClassAdviserSubModuleView extends StatefulWidget {
  final int initialTabIndex;
  const ClassAdviserSubModuleView({super.key, this.initialTabIndex = 0});

  @override
  State<ClassAdviserSubModuleView> createState() => _ClassAdviserSubModuleViewState();
}

class MentorSubModuleView extends StatelessWidget {
  const MentorSubModuleView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClassAdviserSubModuleView(initialTabIndex: 1);
  }
}

class _ClassAdviserSubModuleViewState extends State<ClassAdviserSubModuleView> {
  late int _selectedTab;
  final TextEditingController _searchCtrl = TextEditingController();
  final _fs = FirestoreService.instance;

  List<Map<String, dynamic>> _mentorsList = [];
  List<Map<String, dynamic>> _facultiesList = [];
  List<Map<String, dynamic>> _classAdvisersList = [];
  bool _isLoadingMentors = false;
  bool _isLoadingClassAdvisers = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _loadMentorsFromDb();
    _loadClassAdvisersFromDb();
  }

  Future<void> _loadClassAdvisersFromDb() async {
    if (!mounted) return;
    setState(() {
      _isLoadingClassAdvisers = true;
    });
    try {
      var data = await SupabaseClientHelper.select('class_advisors', schema: 'hod');
      if (data.isEmpty) {
        data = await SupabaseClientHelper.select('class_advisors', schema: 'public');
      }

      // Fetch real-time faculties from faculty.faculties database table
      List<Map<String, dynamic>> facs = [];
      try {
        facs = await SupabaseClientHelper.select('faculties', schema: 'faculty');
      } catch (e) {
        debugPrint('Error loading faculties in class advisers module: $e');
      }

      final profile = ProfileService.get();
      final String profileDept = (profile['department'] ?? profile['dept'] ?? 'CSE').toString().toLowerCase();
      final bool isCse = profileDept.contains('cse') || profileDept.contains('computer science');
      final bool isIot = profileDept.contains('iot') || profileDept.contains('internet of things');

      final filteredFacs = facs.where((f) {
        final fDept = (f['department'] ?? f['department_id'] ?? '').toString().toLowerCase();
        if (isCse) {
          return fDept.contains('cse') || fDept.contains('computer science') || fDept == 'dept_cse';
        } else if (isIot) {
          return fDept.contains('iot') || fDept.contains('internet of things') || fDept == 'dept_iot';
        }
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _classAdvisersList = data;
          if (filteredFacs.isNotEmpty) {
            _facultiesList = filteredFacs;
          }
          _isLoadingClassAdvisers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading class advisers from DB: $e');
      if (mounted) {
        setState(() {
          _classAdvisersList = [];
          _isLoadingClassAdvisers = false;
        });
      }
    }
  }

  Future<void> _loadMentorsFromDb() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMentors = true;
    });
    try {
      var data = await SupabaseClientHelper.select('mentor_assignments', schema: 'hod');
      if (data.isEmpty) {
        data = await SupabaseClientHelper.select('mentor_assignments', schema: 'public');
      }

      List<Map<String, dynamic>> facs = [];
      try {
        facs = await SupabaseClientHelper.select('faculties', schema: 'faculty');
      } catch (e) {
        debugPrint('Error loading faculties in mentors module: $e');
      }
      if (facs.isEmpty) {
        try {
          facs = await SupabaseClientHelper.select('faculties', schema: 'public');
        } catch (_) {}
      }

      // Resolve current HOD's department
      final profile = ProfileService.get();
      final String profileDept = (profile['department'] ?? profile['dept'] ?? 'CSE').toString().toLowerCase();
      final bool isCse = profileDept.contains('cse') || profileDept.contains('computer science');
      final bool isIot = profileDept.contains('iot') || profileDept.contains('internet of things');

      // Filter faculties belonging to this department
      final filteredFacs = facs.where((f) {
        final fDept = (f['department'] ?? f['department_id'] ?? '').toString().toLowerCase();
        if (isCse) {
          return fDept.contains('cse') || fDept.contains('computer science') || fDept == 'dept_cse';
        } else if (isIot) {
          return fDept.contains('iot') || fDept.contains('internet of things') || fDept == 'dept_iot';
        }
        return true;
      }).toList();

      final activeFacs = filteredFacs;

      if (mounted) {
        setState(() {
          _mentorsList = data;
          _facultiesList = activeFacs;
          _isLoadingMentors = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mentor assignments from DB: $e');
      if (mounted) {
        setState(() {
          _facultiesList = [];
          _isLoadingMentors = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteMentorAssignment(String id) async {
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: const Text('Are you sure you want to delete this mentor assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoadingMentors = true;
      });
      final success = await SupabaseClientHelper.delete(
        'mentor_assignments',
        'id',
        id,
        schema: 'hod',
      );
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment deleted successfully')),
        );
        _loadMentorsFromDb();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete assignment'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoadingMentors = false;
        });
      }
    }
  }

  void _openAssignMentorSidebar(BuildContext context, {Map<String, dynamic>? initialFaculty, Map<String, dynamic>? existingAssignment}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeInOut),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 480,
                height: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(-4, 0),
                    )
                  ],
                ),
                child: _AssignMentorSidebarContent(
                  initialFaculty: initialFaculty,
                  existingAssignment: existingAssignment,
                  onSuccess: () {
                    Navigator.pop(ctx);
                    _loadMentorsFromDb();
                  },
                  onCancel: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP BREADCRUMB & HEADER BAR ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Class Advisors & Mentors',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Student Management > Class Advisors & Mentors > ${_selectedTab == 0 ? "Class Advisors" : "Mentors"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.stars, size: 14, color: AppTheme.accentBlue),
                        SizedBox(width: 6),
                        Text(
                          'Academic Year 2025 - 2026',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_selectedTab == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Exporting Class Advisor Summary...'),
                            backgroundColor: Color(0xFF2563EB),
                          ),
                        );
                      } else {
                        _openAssignMentorSidebar(context);
                      }
                    },
                    icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
                    label: Text(
                      _selectedTab == 0 ? 'Assign Advisor' : 'Assign Mentor',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── TOP TAB SWITCHER CARDS (Class Advisors / Mentors) ──
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = 0),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedTab == 0 ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: _selectedTab == 0
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? Colors.white.withOpacity(0.2) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.groups,
                            color: _selectedTab == 0 ? Colors.white : AppTheme.accentBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class Advisors',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _selectedTab == 0 ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Section Advisors & Year Incharges',
                              style: TextStyle(
                                fontSize: 11,
                                color: _selectedTab == 0 ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = 1),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedTab == 1 ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: _selectedTab == 1
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? Colors.white.withOpacity(0.2) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.psychology,
                            color: _selectedTab == 1 ? Colors.white : AppTheme.accentBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mentors',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _selectedTab == 1 ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Student Mentoring & Ward Allocations',
                              style: TextStyle(
                                fontSize: 11,
                                color: _selectedTab == 1 ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── TAB CONTENT AREA ──
          _selectedTab == 0 ? _buildClassAdvisorsContent() : _buildMentorsContent(),
        ],
      ),
    );
  }

  // Default fallback data for Class Advisors
  final List<Map<String, dynamic>> _defaultClassAdvisers = [
    {
      'year': 'Year 2',
      'section': 'Section A',
      'batch': '2024-28',
      'class_section': 'Year 2 • Section A (Batch 2024-28)',
      'adviser_name': 'Prof. Muththukumaran',
      'designation': 'Assistant Professor',
      'students': '60 (32M / 28F)',
      'pass_pct': '91.2%',
      'attendance_pct': '96.5%',
    },
    {
      'year': 'Year 3',
      'section': 'Section B',
      'batch': '2023-27',
      'class_section': 'Year 3 • Section B (Batch 2023-27)',
      'adviser_name': 'Dr. S. Karthi',
      'designation': 'Associate Professor',
      'students': '60 (30M / 30F)',
      'pass_pct': '91.2%',
      'attendance_pct': '94.2%',
    },
    {
      'year': 'Year 2',
      'section': 'Section B',
      'batch': '2024-28',
      'class_section': 'Year 2 • Section B (Batch 2024-28)',
      'adviser_name': 'Prof. Ramya',
      'designation': 'Assistant Professor',
      'students': '60 (28M / 32F)',
      'pass_pct': '88.4%',
      'attendance_pct': '92.0%',
    },
    {
      'year': 'Year 3',
      'section': 'Section A',
      'batch': '2023-27',
      'class_section': 'Year 3 • Section A (Batch 2023-27)',
      'adviser_name': 'Mrs. S. Vinothini',
      'designation': 'Assistant Professor',
      'students': '58 (30M / 28F)',
      'pass_pct': '95.0%',
      'attendance_pct': '96.2%',
    },
    {
      'year': 'Year 4',
      'section': 'Section A',
      'batch': '2022-26',
      'class_section': 'Year 4 • Section A (Batch 2022-26)',
      'adviser_name': 'Prof. K. Anand',
      'designation': 'Assistant Professor',
      'students': '62 (34M / 28F)',
      'pass_pct': '98.0%',
      'attendance_pct': '97.4%',
    },
  ];

  final List<Map<String, dynamic>> _defaultFaculties = [
    {'id': '4e60e201-ed5f-4f44-b22b-d8718032bce4', 'employee_id': 'EMP_CSE_002', 'full_name': 'Mr. P. Kalaiyarasan', 'designation': 'Assistant Professor', 'department': 'CSE'},
    {'id': '634500f6-006d-41ed-aca2-d9f9a0babce7', 'employee_id': 'EMP_CSE_006', 'full_name': 'Prof. K. Ramesh', 'designation': 'Assistant Professor', 'department': 'CSE'},
    {'id': '368e2866-53f3-4c19-8cf5-e2fc6f4e42a4', 'employee_id': 'EMP_CSE_005', 'full_name': 'Mrs. P. Chitra', 'designation': 'Assistant Professor', 'department': 'CSE'},
    {'id': 'b3d7c079-2e4b-452d-9037-48ab4bb8be3d', 'employee_id': 'EMP_CSE_004', 'full_name': 'Mr. M. Naveenkumar', 'designation': 'Assistant Professor', 'department': 'CSE'},
    {'id': '416ffd24-772e-49da-8b82-c864cd6ac18b', 'employee_id': 'EMP_CSE_003', 'full_name': 'Mrs. S. Vinothini', 'designation': 'Assistant Professor', 'department': 'CSE'},
    {'id': '1a12a6fd-3233-4e6a-bef9-1d83c7f6f62a', 'employee_id': 'EMP-CSE-010', 'full_name': 'Dr. K. Ravichandran', 'designation': 'Professor & HOD', 'department': 'CSE'},
    {'id': 'd3f5ab61-6242-4f51-9b90-c4ad8738f795', 'employee_id': 'EMP_CSE_008', 'full_name': 'Prof. Muththukumaran', 'designation': 'Assistant Professor', 'department': 'CSE'},
    {'id': '38677400-d237-4862-b17f-6d2c7ab1bf97', 'employee_id': 'EMP_CSE_009', 'full_name': 'Dr. S. Karthi', 'designation': 'Associate Professor', 'department': 'CSE'},
    {'id': '2fd5c00d-88ac-4ba1-81ed-4ee63a3b349b', 'employee_id': 'EMP_CSE_011', 'full_name': 'Prof. Ramya', 'designation': 'Assistant Professor', 'department': 'CSE'},
    {'id': 'eca7e5cd-b588-4c1b-b6a5-a50a78134f92', 'employee_id': 'EMP_CSE_012', 'full_name': 'Prof. K. Anand', 'designation': 'Assistant Professor', 'department': 'CSE'},
  ];

  // ── 1. CLASS ADVISORS TAB CONTENT ──
  Widget _buildClassAdvisorsContent() {
    if (_isLoadingClassAdvisers) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }

    final dataList = _classAdvisersList;
    String query = '';
    try {
      query = _searchCtrl.text.toLowerCase();
    } catch (_) {
      query = '';
    }
    final filtered = dataList.where((d) {
      final name = (d['adviser_name'] ?? d['adviserName'] ?? '').toString().toLowerCase();
      final sec = (d['class_section'] ?? d['classSection'] ?? '').toString().toLowerCase();
      return name.contains(query) || sec.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Header Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Department Class Advisers & Performance Portal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Assign faculty class advisers and co-advisers for department sections and track class performance matrix.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              HodExportDialog.buildExportButton(
                context,
                onPressed: () => HodExportDialog.show(
                  context,
                  title: 'Export Class Advisors Data',
                  subtitle: 'Select export format for Class Advisors records:',
                  moduleName: 'Class Advisors',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Statistics Row
        Row(
          children: [
            Expanded(
              child: _kpiCard('TOTAL ADVISERS', '${dataList.length} Faculty', 'Section leaders', Icons.badge_outlined, AppTheme.accentBlue, const Color(0xFFEFF6FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard('CLASS PASS AVG', '93.2%', 'Academic performance', Icons.check_circle_outline, AppTheme.accentGreen, const Color(0xFFECFDF5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard('MANAGED STUDENTS', '240 Students', 'Full department strength', Icons.groups_outlined, AppTheme.accentOrange, const Color(0xFFFFF7ED)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Full Width Register DataTable Card
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge, size: 18, color: AppTheme.accentBlue),
                        SizedBox(width: 8),
                        Text('Class Adviser Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ],
                    ),
                    SizedBox(
                      width: 260,
                      height: 36,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search adviser...',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    dataRowMaxHeight: 64,
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Expanded(child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold)))),
                      DataColumn(label: Expanded(child: Text('Section', style: TextStyle(fontWeight: FontWeight.bold)))),
                      DataColumn(label: Expanded(child: Text('Class Adviser', style: TextStyle(fontWeight: FontWeight.bold)))),
                      DataColumn(label: Expanded(child: Text('Students', style: TextStyle(fontWeight: FontWeight.bold)))),
                      DataColumn(label: Expanded(child: Text('Pass %', style: TextStyle(fontWeight: FontWeight.bold)))),
                      DataColumn(label: Expanded(child: Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold)))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((d) {
                      final rawYear = (d['year'] ?? '').toString();
                      final rawSec = (d['section'] ?? '').toString();
                      final classSecStr = (d['class_section'] ?? d['classSection'] ?? '').toString();

                      String yearStr = rawYear;
                      if (yearStr.isEmpty && classSecStr.isNotEmpty) {
                        yearStr = classSecStr.contains('•') ? classSecStr.split('•').first.trim() : classSecStr;
                      }
                      String sectionStr = rawSec;
                      if (sectionStr.isEmpty && classSecStr.isNotEmpty) {
                        if (classSecStr.contains('•')) {
                          final p = classSecStr.split('•').last.trim();
                          sectionStr = p.contains('(') ? p.split('(').first.trim() : p;
                        }
                      }

                      final adviserStr = (d['adviser_name'] ?? d['adviserName'] ?? '').toString();
                      final desigStr = (d['designation'] ?? 'Assistant Professor').toString();
                      final studentsStr = (d['students'] ?? d['strength'] ?? '60 (32M / 28F)').toString();
                      final passStr = (d['pass_pct'] ?? d['passPct'] ?? '91.2%').toString();
                      final attStr = (d['attendance_pct'] ?? d['attendancePct'] ?? '96.5%').toString();

                      return DataRow(cells: [
                        DataCell(Text(yearStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        DataCell(Text(sectionStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(adviserStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentBlue)),
                            Text(desigStr, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        )),
                        DataCell(Text(studentsStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentBlue))),
                        DataCell(Text(passStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentGreen))),
                        DataCell(Text(attStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentGreen))),
                        DataCell(OutlinedButton.icon(
                          onPressed: () => _openEditAdviserDialog(context, d),
                          icon: const Icon(Icons.edit, size: 14, color: AppTheme.accentBlue),
                          label: const Text('Edit', style: TextStyle(fontSize: 12, color: AppTheme.accentBlue, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. MENTORS TAB CONTENT ──
  Widget _buildMentorsContent() {
    if (_isLoadingMentors) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(80),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final dataList = _facultiesList;

    String query = '';
    try {
      query = _searchCtrl.text.toLowerCase();
    } catch (_) {
      query = '';
    }
    
    final filteredFaculties = dataList.where((f) {
      final String name = (f['full_name'] ?? '').toString().toLowerCase();
      final String empId = (f['employee_id'] ?? '').toString().toLowerCase();
      return name.contains(query) || empId.contains(query);
    }).toList();

    int totalMentees = 0;
    for (var m in _mentorsList) {
      totalMentees += (m['mentees_count'] ?? 0) as int;
    }
    final int activeMentorsCount = _mentorsList.where((m) => (m['mentees_count'] ?? 0) > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Header Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Faculty Mentor & Student Counseling Hub',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Assign 1:20 faculty mentors, track student counseling logs, academic progress, and parent communication.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              HodExportDialog.buildExportButton(
                context,
                onPressed: () => HodExportDialog.show(
                  context,
                  title: 'Export Mentors Data',
                  subtitle: 'Select export format for Mentors records:',
                  moduleName: 'Mentors',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Statistics Row
        Row(
          children: [
            Expanded(
              child: _kpiCard('TOTAL MENTORS', '$activeMentorsCount Faculty', '1:20 Mentor Ratio', Icons.badge_outlined, AppTheme.accentPurple, const Color(0xFFF3E8FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard('TOTAL MENTEES', '$totalMentees Students', 'Active counseling', Icons.groups_outlined, AppTheme.accentGreen, const Color(0xFFECFDF5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard('COUNSELING LOGS', '100% Completed', 'Monthly sign-off', Icons.check_circle_outline, AppTheme.accentBlue, const Color(0xFFEFF6FF)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Full Width Mentor Register DataTable Card
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.groups, size: 18, color: AppTheme.accentPurple),
                        SizedBox(width: 8),
                        Text('Faculty Mentor Allocation Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ],
                    ),
                    SizedBox(
                      width: 260,
                      height: 36,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search mentor name...',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    dataRowMaxHeight: 64,
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Faculty Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Mentees Count', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Mentees Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filteredFaculties.asMap().entries.map((entry) {
                      final int idx = entry.key + 1;
                      final f = entry.value;
                      final String facultyName = f['full_name'] ?? 'N/A';
                      final String facultyEmployeeId = f['employee_id'] ?? 'N/A';

                      final assignment = _mentorsList.firstWhere(
                        (m) {
                          final fId = (m['faculty_id'] ?? '').toString();
                          final empId = (f['employee_id'] ?? '').toString();
                          final uuidId = (f['id'] ?? '').toString();
                          return fId.isNotEmpty && (fId == empId || fId == uuidId);
                        },
                        orElse: () => <String, dynamic>{},
                      );

                      String menteesName = 'N/A';
                      int menteesCount = 0;
                      if (assignment.isNotEmpty) {
                        menteesCount = (assignment['mentees_count'] ?? 0) as int;
                        final rawList = assignment['student_list'];
                        if (rawList is List) {
                          final names = rawList.map((s) => s['full_name']?.toString() ?? s['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
                          if (names.isNotEmpty) {
                            menteesName = names.join(', ');
                          }
                        }
                      }

                      return DataRow(cells: [
                        DataCell(Text('$idx', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        DataCell(Text('$facultyName ($facultyEmployeeId)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        DataCell(Text('$menteesCount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: menteesCount > 0 ? AppTheme.accentGreen : Colors.grey))),
                        DataCell(
                          SizedBox(
                            width: 320,
                            child: Text(
                              menteesName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _openAssignMentorSidebar(
                                  context,
                                  initialFaculty: f,
                                  existingAssignment: assignment.isEmpty ? null : assignment,
                                ),
                                icon: const Icon(Icons.edit, size: 14, color: AppTheme.accentBlue),
                                label: const Text('Edit', style: TextStyle(fontSize: 12, color: AppTheme.accentBlue, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              if (assignment.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                  onPressed: () => _confirmDeleteMentorAssignment(assignment['id'].toString()),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper KPI card
  Widget _kpiCard(String title, String value, String subtitle, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // Edit Adviser Dialog matching the image with real-time CSE faculty integration
  void _openEditAdviserDialog(BuildContext context, Map<String, dynamic> d) {
    String selectedName = (d['adviser_name'] ?? d['adviserName'] ?? 'Prof. Muththukumaran').toString();
    final String section = (d['class_section'] ?? d['classSection'] ?? 'Year 2 • Section A').toString();

    // Extract real-time faculty list belonging to CSE department
    final List<String> loadedNames = _facultiesList
        .map((f) => (f['full_name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();

    final Set<String> nameSet = loadedNames.toSet();
    if (nameSet.isEmpty) {
      nameSet.addAll([
        'Prof. Muththukumaran',
        'Dr. S. Karthi',
        'Prof. Ramya',
        'Prof. K. Anand',
        'Mr. P. Kalaiyarasan',
        'Prof. K. Ramesh',
        'Mrs. S. Vinothini',
        'Mr. M. Naveenkumar',
        'Mrs. P. Chitra',
        'Dr. K. Ravichandran',
      ]);
    }

    if (selectedName.isNotEmpty) {
      nameSet.add(selectedName);
    }

    final List<String> facultyList = nameSet.toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F9), // Light grayish purple background from image
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Adviser: $section',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Class Adviser Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0), // Filled grey dropdown container
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: facultyList.contains(selectedName) ? selectedName : facultyList.first,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF475569), size: 26),
                        dropdownColor: const Color(0xFFE2E8F0),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        items: facultyList.map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedName = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final selectedFac = _facultiesList.firstWhere(
                            (f) => (f['full_name'] ?? '').toString() == selectedName,
                            orElse: () => <String, dynamic>{},
                          );
                          final String newDesignation = (selectedFac['designation'] ?? d['designation'] ?? 'Assistant Professor').toString();
                          final String? facUuid = selectedFac['id']?.toString();
                          final String docId = (d['id'] ?? '').toString();

                          if (docId.isNotEmpty) {
                            final updatePayload = <String, dynamic>{
                              'adviser_name': selectedName,
                              'designation': newDesignation,
                              'updated_at': DateTime.now().toIso8601String(),
                            };
                            if (facUuid != null && facUuid.isNotEmpty) {
                              updatePayload['faculty_id'] = facUuid;
                            }
                            updatePayload['department_id'] = 'd962eadb-8888-4b8e-bb44-dc6b49fce3cb';

                            await SupabaseClientHelper.update('class_advisors', updatePayload, 'id', docId, schema: 'hod');
                            await SupabaseClientHelper.update('class_advisors', updatePayload, 'id', docId, schema: 'public');
                          } else {
                            setState(() {
                              d['adviser_name'] = selectedName;
                              d['adviserName'] = selectedName;
                              d['designation'] = newDesignation;
                              if (facUuid != null && facUuid.isNotEmpty) {
                                d['faculty_id'] = facUuid;
                              }
                              d['department_id'] = 'd962eadb-8888-4b8e-bb44-dc6b49fce3cb';
                            });
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadClassAdvisersFromDb();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Updated Class Adviser for $section'),
                                backgroundColor: AppTheme.accentBlue,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}

class _AssignMentorSidebarContent extends StatefulWidget {
  final Map<String, dynamic>? initialFaculty;
  final Map<String, dynamic>? existingAssignment;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _AssignMentorSidebarContent({
    this.initialFaculty,
    this.existingAssignment,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<_AssignMentorSidebarContent> createState() => _AssignMentorSidebarContentState();
}

class _AssignMentorSidebarContentState extends State<_AssignMentorSidebarContent> {
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _allAssignments = [];
  bool _loadingData = true;
  String _errorMsg = '';

  Map<String, dynamic>? _selectedFaculty;
  final Set<Map<String, dynamic>> _selectedStudents = {};
  String _searchStudentQuery = '';
  String _selectedYearFilter = 'All';
  String _selectedSectionFilter = 'All';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final facs = await SupabaseClientHelper.select('faculties', schema: 'faculty');
      final studs = await SupabaseClientHelper.select('students', schema: 'student');
      final assignments = await SupabaseClientHelper.select('mentor_assignments', schema: 'hod');

      // Resolve current HOD's department
      final profile = ProfileService.get();
      final String profileDept = (profile['department'] ?? profile['dept'] ?? 'CSE').toString().toLowerCase();
      final bool isCse = profileDept.contains('cse') || profileDept.contains('computer science');
      final bool isIot = profileDept.contains('iot') || profileDept.contains('internet of things');

      // Filter faculties belonging to this department
      final filteredFacs = facs.where((f) {
        final fDept = (f['department'] ?? f['department_id'] ?? '').toString().toLowerCase();
        if (isCse) {
          return fDept.contains('cse') || fDept.contains('computer science') || fDept == 'dept_cse';
        } else if (isIot) {
          return fDept.contains('iot') || fDept.contains('internet of things') || fDept == 'dept_iot';
        }
        return true;
      }).toList();

      // Filter students belonging to this department
      final filteredStuds = studs.where((s) {
        final sDept = (s['department'] ?? '').toString().toLowerCase();
        if (isCse) {
          return sDept.contains('cse') || sDept.contains('computer science');
        } else if (isIot) {
          return sDept.contains('iot') || sDept.contains('internet of things');
        }
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _faculties = filteredFacs;
          _students = filteredStuds;
          _allAssignments = assignments;

          if (widget.initialFaculty != null) {
            _selectedFaculty = filteredFacs.firstWhere(
              (f) => f['id'] == widget.initialFaculty!['id'],
              orElse: () => widget.initialFaculty!,
            );
          }

          if (widget.existingAssignment != null && widget.existingAssignment!['student_list'] != null) {
            final rawList = widget.existingAssignment!['student_list'];
            if (rawList is List) {
              final assignedStudentIds = rawList.map((s) => s['id']?.toString() ?? s['student_id']?.toString() ?? '').toSet();
              final assignedRolls = rawList.map((s) => s['roll_no']?.toString() ?? '').toSet();
              for (final student in filteredStuds) {
                final sId = student['id']?.toString() ?? '';
                final sRoll = student['roll_no']?.toString() ?? '';
                if ((sId.isNotEmpty && assignedStudentIds.contains(sId)) ||
                    (sRoll.isNotEmpty && assignedRolls.contains(sRoll))) {
                  _selectedStudents.add(student);
                }
              }
            }
          }

          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Error loading data: $e';
          _loadingData = false;
        });
      }
    }
  }

  Future<void> _saveAllocation() async {
    if (_selectedFaculty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a faculty member (mentor)'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student (mentee)'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Resolve Department UUID from departments in principal schema
      String? deptUuid;
      try {
        final depts = await SupabaseClientHelper.select('departments', schema: 'principal');
        final match = depts.firstWhere((d) {
          final code = d['code']?.toString().toLowerCase() ?? '';
          final facDept = _selectedFaculty!['department_id']?.toString().replaceAll('DEPT_', '').toLowerCase() ?? '';
          return code == facDept || facDept.contains(code);
        });
        deptUuid = match['id'];
      } catch (e) {
        debugPrint('Could not resolve department UUID from principal.departments: $e');
      }

      final List<Map<String, dynamic>> studentListJson = _selectedStudents.map((s) => {
        'id': s['id'],
        'roll_no': s['roll_no'] ?? s['student_id'] ?? '',
        'full_name': s['full_name'] ?? '',
        'year_of_study': s['year_of_study'] ?? '',
        'section': s['section'] ?? '',
      }).toList();

      final String facultyIdToSave = (_selectedFaculty!['employee_id'] ?? _selectedFaculty!['id']).toString();

      final Map<String, dynamic> insertData = {
        'department_id': deptUuid,
        'faculty_id': facultyIdToSave,
        'section': _selectedStudents.isNotEmpty
            ? 'Year ${_selectedStudents.map((s) => s['year_of_study']).toSet().join(", ")} • Sec ${_selectedStudents.map((s) => s['section']).toSet().join(", ")}'
            : 'N/A',
        'mentees_count': _selectedStudents.length,
        'counselling_status': 'NORMAL',
        'student_list': studentListJson,
      };

      // Check if assignment already exists for this faculty_id in hod.mentor_assignments
      final existing = await SupabaseClientHelper.select(
        'mentor_assignments',
        filterColumn: 'faculty_id',
        filterValue: facultyIdToSave,
        schema: 'hod',
      );

      dynamic result;
      if (existing.isNotEmpty) {
        final existingId = existing.first['id'];
        result = await SupabaseClientHelper.update(
          'mentor_assignments',
          insertData,
          'id',
          existingId.toString(),
          schema: 'hod',
        );
      } else {
        result = await SupabaseClientHelper.insert('mentor_assignments', insertData, schema: 'hod');
      }

      if (result != null) {
        widget.onSuccess();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save assignment in database'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving assignment: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(_errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loadingData = true;
                    _errorMsg = '';
                  });
                  _fetchData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final Set<String> assignedToOthersIds = {};
    final Set<String> assignedToOthersRolls = {};

    final currentFacultyId = _selectedFaculty != null
        ? (_selectedFaculty!['employee_id'] ?? _selectedFaculty!['id']).toString()
        : '';

    for (final a in _allAssignments) {
      final facId = a['faculty_id']?.toString() ?? '';
      if (facId.isNotEmpty && currentFacultyId.isNotEmpty && facId == currentFacultyId) {
        continue;
      }
      final rawList = a['student_list'];
      if (rawList is List) {
        for (final s in rawList) {
          final sId = s['id']?.toString() ?? s['student_id']?.toString() ?? '';
          if (sId.isNotEmpty) {
            assignedToOthersIds.add(sId);
          }
          final sRoll = s['roll_no']?.toString() ?? '';
          if (sRoll.isNotEmpty) {
            assignedToOthersRolls.add(sRoll);
          }
        }
      }
    }

    final filteredStudents = _students.where((student) {
      final sId = student['id']?.toString() ?? '';
      final sRoll = student['roll_no']?.toString() ?? '';

      // Exclude student if assigned to another mentor
      if (assignedToOthersIds.contains(sId) || assignedToOthersRolls.contains(sRoll)) {
        return false;
      }

      final name = (student['full_name'] ?? '').toString().toLowerCase();
      final roll = (student['roll_no'] ?? '').toString().toLowerCase();
      final query = _searchStudentQuery.toLowerCase();
      final matchesQuery = name.contains(query) || roll.contains(query);

      final year = (student['year_of_study'] ?? '').toString();
      final matchesYear = _selectedYearFilter == 'All' || year == _selectedYearFilter;

      final section = (student['section'] ?? '').toString();
      final matchesSection = _selectedSectionFilter == 'All' || section == _selectedSectionFilter;

      return matchesQuery && matchesYear && matchesSection;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assign Faculty Mentor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const Divider(height: 24),

          // Dropdown Faculty Select
          const Text(
            'Select Mentor (Faculty)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedFaculty,
            hint: const Text('Choose a Faculty Member', style: TextStyle(fontSize: 13)),
            items: _faculties.map((fac) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: fac,
                child: Text(
                  '${fac['full_name']} (${fac['designation'] ?? 'Faculty'})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
            onChanged: widget.initialFaculty != null ? null : (val) {
              setState(() {
                _selectedFaculty = val;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.initialFaculty != null ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Filters for Students
          const Text(
            'Select Mentees (Students)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchStudentQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search roll / name...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedYearFilter,
                    style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
                    items: ['All', 'I', 'II', 'III', 'IV'].map((y) {
                      return DropdownMenuItem(value: y, child: Text('Year $y'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedYearFilter = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Select All / Deselect All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mentees Selection (${filteredStudents.length} found)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    final allSelected = filteredStudents.every((s) => _selectedStudents.contains(s));
                    if (allSelected) {
                      for (final s in filteredStudents) {
                        _selectedStudents.remove(s);
                      }
                    } else {
                      _selectedStudents.addAll(filteredStudents);
                    }
                  });
                },
                child: Text(
                  filteredStudents.every((s) => _selectedStudents.contains(s)) ? 'Deselect All' : 'Select All',
                  style: const TextStyle(fontSize: 12, color: AppTheme.accentBlue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Student List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: filteredStudents.isEmpty
                  ? const Center(child: Text('No students match filters', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, idx) {
                        final student = filteredStudents[idx];
                        final isSelected = _selectedStudents.contains(student);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(
                            student['full_name'] ?? 'N/A',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${student['roll_no'] ?? 'N/A'} • Year ${student['year_of_study']} - Sec ${student['section']}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          activeColor: AppTheme.accentPurple,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedStudents.add(student);
                              } else {
                                _selectedStudents.remove(student);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Footer info and action buttons
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected Faculty: ${_selectedFaculty != null ? _selectedFaculty!['full_name'] : 'None selected'}\nTotal Selected Mentees: ${_selectedStudents.length}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAllocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Confirm Allocation',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
