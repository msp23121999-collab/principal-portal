import 'package:flutter/material.dart';
import '../theme.dart';
import '../responsive.dart';
import '../../faculty/services/postgres_client.dart';

class SyllabusModuleView extends StatefulWidget {
  const SyllabusModuleView({super.key});

  @override
  State<SyllabusModuleView> createState() => _SyllabusModuleViewState();
}

class _SyllabusModuleViewState extends State<SyllabusModuleView> {
  int _activeTab = 0; // 0 = Syllabus Management, 1 = My Teaching Syllabus
  String _selectedBatch = 'Batch 2024 - 2028';
  String _selectedSemester = 'Semester I';

  @override
  void initState() {
    super.initState();
    _syllabusManagementCourses.clear();
    _myTeachingCourses.clear();
    _loadSyllabusCourses();
  }

  Future<void> _loadSyllabusCourses() async {
    final rows = await SupabaseClientHelper.select(
      'hod_syllabus_courses',
      schema: 'hod',
    );
    if (!mounted) return;
    final courses = rows
        .map(
          (row) => {
            'code': row['course_code'] ?? '',
            'title': row['title'] ?? '',
            'L': row['lecture_hours'] ?? 0,
            'T': row['tutorial_hours'] ?? 0,
            'P': row['practical_hours'] ?? 0,
            'C': row['credits'] ?? 0,
            'minIn': 0,
            'maxIn': 0,
            'minEx': 0,
            'maxEx': 0,
            'order': 0,
            'type': row['course_type'] ?? '',
            'color': const Color(0xFF2563EB),
          },
        )
        .toList();
    setState(() {
      _syllabusManagementCourses
        ..clear()
        ..addAll(courses);
      _myTeachingCourses
        ..clear()
        ..addAll(courses);
    });
  }

  final List<String> _semesters = [
    'Semester I',
    'Semester II',
    'Semester III',
    'Semester IV',
    'Semester V',
    'Semester VI',
    'Semester VII',
    'Semester VIII',
  ];

  // Course Data for Tab 1: Syllabus Management (Semester I)
  final List<Map<String, dynamic>> _syllabusManagementCourses = [];
  /*
    {
      'code': '24ENT19',
      'title': 'Professional Communication',
      'L': 3,
      'T': 0,
      'P': 0,
      'C': 3,
      'minIn': 16,
      'maxIn': 40,
      'minEx': 24,
      'maxEx': 60,
      'order': 1,
      'type': 'HSMC',
      'color': const Color(0xFF10B981), // Green bar
    },
    {
      'code': '24EET06',
      'title': 'Basics of Electrical and Electronics Engineering',
      'L': 3,
      'T': 0,
      'P': 0,
      'C': 3,
      'minIn': 16,
      'maxIn': 40,
      'minEx': 24,
      'maxEx': 60,
      'order': 2,
      'type': 'ESC',
      'color': const Color(0xFF10B981), // Green bar
    },
    {
      'code': '24ITT16',
      'title': 'Programming for Problem Solving',
      'L': 3,
      'T': 0,
      'P': 0,
      'C': 3,
      'minIn': 20,
      'maxIn': 50,
      'minEx': 20,
      'maxEx': 50,
      'order': 3,
      'type': 'ESC',
      'color': const Color(0xFF2563EB), // Blue bar
    },
    {
      'code': '24GET19',
      'title': 'தமிழ் மரபு / Heritage of Tamils',
      'L': 1,
      'T': 0,
      'P': 0,
      'C': 1,
      'minIn': 16,
      'maxIn': 40,
      'minEx': 24,
      'maxEx': 60,
      'order': 4,
      'type': 'HSMC',
      'color': const Color(0xFFEC4899), // Pink bar
    },
    {
      'code': '24MAI19',
      'title': 'Matrices and Calculus',
      'L': 2,
      'T': 1,
      'P': 2,
      'C': 4,
      'minIn': 20,
      'maxIn': 50,
      'minEx': 20,
      'maxEx': 50,
      'order': 5,
      'type': 'BSC',
      'color': const Color(0xFF10B981), // Green bar
    },
    {
      'code': '24CHI06',
      'title': 'Chemistry for Engineers',
      'L': 3,
      'T': 0,
      'P': 2,
      'C': 4,
      'minIn': 20,
      'maxIn': 50,
      'minEx': 20,
      'maxEx': 50,
      'order': 6,
      'type': 'BSC',
      'color': const Color(0xFF2563EB), // Blue bar
    },
    {
      'code': '24ITP16',
      'title': 'Programming for Problem Solving Lab',
      'L': 0,
      'T': 0,
      'P': 2,
      'C': 1,
      'minIn': 24,
      'maxIn': 60,
      'minEx': 16,
      'maxEx': 40,
      'order': 7,
      'type': 'ESC',
      'color': const Color(0xFF2563EB), // Blue bar
    },
  ];
  */

  // Course Data for Tab 2: My Teaching Syllabus
  final List<Map<String, dynamic>> _myTeachingCourses = [];
  /*
    {
      'code': 'IOT2028',
      'title': 'IoT Sensors & Actuators',
      'L': 3,
      'T': 0,
      'P': 2,
      'C': 4,
      'minIn': 20,
      'maxIn': 50,
      'minEx': 20,
      'maxEx': 50,
      'order': 1,
      'type': 'PCC',
      'color': const Color(0xFF10B981), // Green bar
    },
    {
      'code': 'IOT2029',
      'title': 'Embedded C & RTOS',
      'L': 3,
      'T': 1,
      'P': 0,
      'C': 4,
      'minIn': 20,
      'maxIn': 50,
      'minEx': 20,
      'maxEx': 50,
      'order': 2,
      'type': 'PCC',
      'color': const Color(0xFF2563EB), // Blue bar
    },
    {
      'code': 'IOT3030',
      'title': 'Cloud Protocols (MQTT/CoAP)',
      'L': 3,
      'T': 0,
      'P': 0,
      'C': 3,
      'minIn': 16,
      'maxIn': 40,
      'minEx': 24,
      'maxEx': 60,
      'order': 3,
      'type': 'PEC',
      'color': const Color(0xFFA855F7), // Purple bar
    },
  ];
  */

  Widget _buildCompactTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTab0 = _activeTab == 0;
    final currentCourses = isTab0
        ? _syllabusManagementCourses
        : _myTeachingCourses;

    final tabRow = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          _buildCompactTab(
            label: 'Syllabus Management',
            icon: Icons.menu_book_rounded,
            isActive: isTab0,
            onTap: () => setState(() => _activeTab = 0),
          ),
          _buildCompactTab(
            label: 'My Teaching Syllabus',
            icon: Icons.assignment_turned_in_rounded,
            isActive: !isTab0,
            onTap: () => setState(() => _activeTab = 1),
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: HodResponsive.pagePaddingInsets(
        context,
      ).copyWith(top: 16, bottom: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header Row (Title, Subtitle/Breadcrumbs & Academic Year Badge)
          HodSectionHeader(
            title: 'Syllabus & Courses',
            breadcrumb:
                'Academic Management > Syllabus & Courses > ${isTab0 ? 'Syllabus Management' : 'My Teaching Syllabus'}',
            academicYear: 'Academic Year 2025 - 2026',
          ),
          const SizedBox(height: 12),

          // 2. Secondary Tab Navigation Row
          tabRow,
          const SizedBox(height: 12),

          // 3. Sub-Header Strip (Different for Tab 0 vs Tab 1)
          if (isTab0) ...[
            // Tab 0 Sub-Header: Manage and allocate subjects + Select Batch Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage and allocate subjects for different semesters',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Select Batch: ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBatch,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          items:
                              [
                                    'Batch 2024 - 2028',
                                    'Batch 2023 - 2027',
                                    'Batch 2022 - 2026',
                                    'Batch 2025 - 2029',
                                  ]
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.school_outlined,
                                            size: 16,
                                            color: Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(b),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _selectedBatch = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Semester Strip Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _semesters.map((sem) {
                          final isSemSelected = _selectedSemester == sem;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedSemester = sem),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isSemSelected
                                      ? const Color(0xFF1E3A8A)
                                      : Colors.transparent, // Dark Navy/Blue
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  sem,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSemSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSemSelected
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // View All Semesters Button
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: const [
                          Text(
                            'View All Semesters',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.grid_view_rounded,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Tab 1 Sub-Header: My Assigned Teaching Subjects + HOD Assigned Classes Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Assigned Teaching Subjects (${_myTeachingCourses.length} Courses)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'HOD Assigned Classes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // 4. Data Table Card (Full Width Responsive)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowMinHeight: 58,
                      dataRowMaxHeight: 62,
                      horizontalMargin: 20,
                      columnSpacing: 22,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF8FAFC),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Course Code',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Title of the Course',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'L',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'T',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'P',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'C',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'MinIn',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'MaxIn',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'MinEx',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'MaxEx',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Order',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Course Type',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Action',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      rows: currentCourses.map((c) {
                        final Color barColor =
                            c['color'] as Color? ?? const Color(0xFF2563EB);
                        final String type = c['type'] as String? ?? 'PCC';

                        return DataRow(
                          cells: [
                            // Course Code with Left Colored Indicator Bar
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 3,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c['code'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Title of the Course
                            DataCell(
                              Text(
                                c['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),

                            // L, T, P, C Hours
                            DataCell(
                              Text(
                                '${c['L']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${c['T']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${c['P']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${c['C']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),

                            // MinIn, MaxIn, MinEx, MaxEx
                            DataCell(
                              Text(
                                '${c['minIn']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${c['maxIn']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${c['minEx']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${c['maxEx']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),

                            // Order
                            DataCell(
                              Text(
                                '${c['order']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),

                            // Course Type Badge (HSMC, ESC, BSC, PCC, PEC)
                            DataCell(_buildCourseTypeBadge(type)),

                            // Action: View Details Button with Eye Icon
                            DataCell(
                              OutlinedButton.icon(
                                onPressed: () => _showCourseSyllabusModal(
                                  context,
                                  c['code'],
                                  c['title'],
                                ),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                  color: Color(0xFF2563EB),
                                ),
                                label: const Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  side: const BorderSide(
                                    color: Color(0xFFDBEAFE),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Course Type Badge Builder
  Widget _buildCourseTypeBadge(String type) {
    Color bg;
    Color text;

    if (type == 'HSMC') {
      bg = const Color(0xFFFCE7F3); // Pink badge
      text = const Color(0xFFDB2777);
    } else if (type == 'ESC') {
      bg = const Color(0xFFE0F2FE); // Light blue badge
      text = const Color(0xFF0284C7);
    } else if (type == 'BSC') {
      bg = const Color(0xFFDCFCE7); // Light green badge
      text = const Color(0xFF16A34A);
    } else if (type == 'PCC') {
      bg = const Color(0xFFEFF6FF); // Indigo badge
      text = const Color(0xFF2563EB);
    } else {
      bg = const Color(0xFFFEF3C7); // Amber badge
      text = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  // View Details Modal for Official Syllabus Document Paper Layout
  void _showCourseSyllabusModal(
    BuildContext context,
    String code,
    String title,
  ) {
    // Dynamic sample data based on course
    final String displayCode = code.isNotEmpty ? code : '24ADI56';
    final String displayTitle = title.isNotEmpty
        ? title.toUpperCase()
        : 'ARTIFICIAL INTELLIGENCE';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          width: 820,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Dialog Actions (Print & Close)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.description_outlined,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Course Syllabus Document',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.print_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Print Document',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable Paper Syllabus Document Container
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Top Table Grid Row (Course Code | Title | Category L T P SL C)
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              // Course Code Cell
                              Container(
                                width: 110,
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Colors.black,
                                      width: 1.2,
                                    ),
                                    bottom: BorderSide(
                                      color: Colors.black,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  displayCode,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              // Title of Course Cell
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.black,
                                        width: 1.2,
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.black,
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    displayTitle,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),

                              // L, T, P, SL, C Grid Table
                              Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.black,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Header Row
                                    Row(
                                      children: [
                                        _buildGridHeaderCell(
                                          'Category',
                                          width: 80,
                                        ),
                                        _buildGridHeaderCell('L', width: 36),
                                        _buildGridHeaderCell('T', width: 36),
                                        _buildGridHeaderCell('P', width: 36),
                                        _buildGridHeaderCell('SL', width: 40),
                                        _buildGridHeaderCell(
                                          'C',
                                          width: 36,
                                          isLast: true,
                                        ),
                                      ],
                                    ),
                                    // Value Row
                                    Row(
                                      children: [
                                        _buildGridValueCell(
                                          'PCC',
                                          width: 80,
                                          isBold: true,
                                        ),
                                        _buildGridValueCell('45', width: 36),
                                        _buildGridValueCell('0', width: 36),
                                        _buildGridValueCell('30', width: 36),
                                        _buildGridValueCell('45', width: 40),
                                        _buildGridValueCell(
                                          '4',
                                          width: 36,
                                          isBold: true,
                                          isLast: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Common Branch Allocation Line
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                                width: 1.2,
                              ),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '(Common to AIDS, CSE, CSE(CS), IT, and IOT)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                        // 3. PREREQUISITE Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'PREREQUISITE:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Basic knowledge of programming python along with understanding of data structures and algorithms. Familiarity with mathematics such as linear algebra, probability, statistics and core computer science fundamentals is required.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.black,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 4. OBJECTIVES Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'OBJECTIVES:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'To understand core concepts of Artificial Intelligence, including problem-solving, search techniques and knowledge representation. To explore machine learning and real-world AI applications, enabling students to design intelligent systems for practical problems.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.black,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 5. UNIT Breakdown (UNIT I to UNIT V)
                        _buildPaperUnitBlock(
                          unitLabel: 'UNIT - I',
                          unitTitle: 'INTELLIGENT AGENTS',
                          hours: '(9)',
                          content:
                              'Introduction to AI – Agents and Environments – Concept of rationality – Nature of environments – structure of agents – Weak AI – Strong AI – Ethics and risks of developing AI – Problem-solving agents – Search algorithms – Uninformed search strategies.',
                        ),
                        _buildPaperUnitBlock(
                          unitLabel: 'UNIT - II',
                          unitTitle: 'PROBLEM SOLVING AND SEARCH TECHNIQUES',
                          hours: '(9)',
                          content:
                              'Informed search strategies – Heuristic Functions-Heuristic search strategies – Local search and optimization problems – Local search in continuous space – Search with non-deterministic actions – Search in partially observable environments – Online search agents and unknown environments.',
                        ),
                        _buildPaperUnitBlock(
                          unitLabel: 'UNIT - III',
                          unitTitle: 'KNOWLEDGE REPRESENTATION',
                          hours: '(9)',
                          content:
                              'Solving Problems by Searching: Problem solving agents – Example problems – Searching for solutions – Uninformed search strategies – Beyond classical search: Local search algorithms and Optimization problems. Adversarial search: Games – Optimal decisions in games – Alpha-beta pruning.',
                        ),
                        _buildPaperUnitBlock(
                          unitLabel: 'UNIT - IV',
                          unitTitle: 'LOGICAL REASONING AND REASONING',
                          hours: '(9)',
                          content:
                              'Knowledge-based agents – Propositional logic – Propositional theorem proving – Propositional model checking – Agents based on propositional logic. First-order logic – Syntax and Semantics – Knowledge representation and engineering – Inferences in first-order logic – Forward chaining – Backward chaining.',
                        ),
                        _buildPaperUnitBlock(
                          unitLabel: 'UNIT - V',
                          unitTitle: 'PROBABILISTIC REASONING AND ACTING',
                          hours: '(9)',
                          content:
                              'Acting under uncertainty – Bayesian inference – Naive Bayes models- Probabilistic reasoning – Bayesian networks – Exact inference in BN – Approximate inference in BN – Causal networks. Robotics: Introduction – Robot Hardware – Robotic Perception – Planning to move – Application Domains.',
                        ),

                        // 6. List of Experiments Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'List of Experiments:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          '1. Uninformed Search Techniques.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          '2. Informed Search Techniques.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          '3. Develop a Problem-Solving Agent using state-space representation.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          '4. Implement Hill Climbing Algorithm.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          '5. Adversarial Search techniques.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          '6. Improve Minimax using Alpha-Beta Pruning.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          '7. Develop a Knowledge-Based Agent using logical rules.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          '8. Inference from knowledge base.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          '9. Simulate a simple Causal Network.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          '10. Implement simple path planning algorithm for robot movement.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 7. Bottom Summary Bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                                width: 1.2,
                              ),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'L = 45   |   T = 0   |   P = 30   |   SL = 45   |   TOTAL: 120 PERIODS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        // 8. COURSE OUTCOMES Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'COURSE OUTCOMES:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'At the end of the course, the students will be able to:',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Course Outcomes Grid Table
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Header Row
                                    IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          _buildOutcomesHeaderCell(
                                            'COs',
                                            width: 64,
                                          ),
                                          Expanded(
                                            child: _buildOutcomesHeaderCell(
                                              'Course Outcome',
                                            ),
                                          ),
                                          _buildOutcomesHeaderCell(
                                            'Cognitive Level',
                                            width: 130,
                                            isLast: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // CO1 Row
                                    IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          _buildOutcomesValueCell(
                                            'CO1',
                                            width: 64,
                                            isBold: true,
                                          ),
                                          Expanded(
                                            child: _buildOutcomesValueCell(
                                              'Describe the concepts of intelligent agents, environments, rationality, AI types and uninformed search strategies in AI systems',
                                            ),
                                          ),
                                          _buildOutcomesValueCell(
                                            'Understand',
                                            width: 130,
                                            isLast: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // CO2 Row
                                    IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          _buildOutcomesValueCell(
                                            'CO2',
                                            width: 64,
                                            isBold: true,
                                          ),
                                          Expanded(
                                            child: _buildOutcomesValueCell(
                                              'Utilize informed search strategies, heuristic functions and local search methods to solve optimization problems.',
                                            ),
                                          ),
                                          _buildOutcomesValueCell(
                                            'Apply',
                                            width: 130,
                                            isLast: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // CO3 Row
                                    IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          _buildOutcomesValueCell(
                                            'CO3',
                                            width: 64,
                                            isBold: true,
                                          ),
                                          Expanded(
                                            child: _buildOutcomesValueCell(
                                              'Demonstrate search algorithms and adversarial search techniques for solving AI-based problems and game strategies.',
                                            ),
                                          ),
                                          _buildOutcomesValueCell(
                                            'Apply',
                                            width: 130,
                                            isLast: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // CO4 Row
                                    IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          _buildOutcomesValueCell(
                                            'CO4',
                                            width: 64,
                                            isBold: true,
                                          ),
                                          Expanded(
                                            child: _buildOutcomesValueCell(
                                              'Apply logical reasoning using propositional and first-order logic for problem solving.',
                                            ),
                                          ),
                                          _buildOutcomesValueCell(
                                            'Apply',
                                            width: 130,
                                            isLast: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // CO5 Row
                                    IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          _buildOutcomesValueCell(
                                            'CO5',
                                            width: 64,
                                            isBold: true,
                                            isBottomLast: true,
                                          ),
                                          Expanded(
                                            child: _buildOutcomesValueCell(
                                              'Examine probabilistic reasoning models, Bayesian networks and robotic systems for intelligent decision making.',
                                              isBottomLast: true,
                                            ),
                                          ),
                                          _buildOutcomesValueCell(
                                            'Analyze',
                                            width: 130,
                                            isLast: true,
                                            isBottomLast: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 9. TEXT BOOKS & REFERENCES Side-by-Side Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Side: TEXT BOOKS
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.only(right: 12),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'TEXT BOOKS:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          '1.  Stuart Russell, Peter Norvig, Artificial Intelligence – A Modern Approach, Fourth Edition, Pearson Education / Prentice Hall of India, 2020.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                            height: 1.35,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          '2.  Deepak Khemani A First Course in Artificial Intelligence, McGraw Hill, First Edition, 2014.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Right Side: REFERENCES
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'REFERENCES:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        '1.  Elaine Rich, Kevin Knight, Artificial Intelligence, Third Edition, Tata McGraw-Hill, 2017.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black,
                                          height: 1.35,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        '2.  Dawn W Patterson, Introduction to Artificial Intelligence and Expert Systems, First Edition, Pearson Education India, 2015.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black,
                                          height: 1.35,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        '3.  Andreas Muller, Sarah Guido, Introduction to Machine Learning with Python: A Guide for Data Scientists, Shroff/O\' Reilly, Second Edition, 2025.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black,
                                          height: 1.35,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        '4.  Prateek Joshi, Artificial Intelligence with Python, Packt Publishing Limited, Second Edition, 2022.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black,
                                          height: 1.35,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        '5.  David Poole, Alan Mackworth, Artificial Intelligence: Foundation of Computational Agents, Third Edition, Cambridge University Press, 2023.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 10. MAPPING OF COs WITH POs AND PSOs Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title Bar
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'MAPPING OF COs WITH POs AND PSOs',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              // CO-PO Matrix Table (Pixel-Perfect Table Grid)
                              Table(
                                border: TableBorder.all(
                                  color: Colors.black,
                                  width: 1.0,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(1.8),
                                  1: FlexColumnWidth(1.0),
                                  2: FlexColumnWidth(1.0),
                                  3: FlexColumnWidth(1.0),
                                  4: FlexColumnWidth(1.0),
                                  5: FlexColumnWidth(1.0),
                                  6: FlexColumnWidth(1.0),
                                  7: FlexColumnWidth(1.0),
                                  8: FlexColumnWidth(1.0),
                                  9: FlexColumnWidth(1.0),
                                  10: FlexColumnWidth(1.0),
                                  11: FlexColumnWidth(1.0),
                                  12: FlexColumnWidth(1.0),
                                  13: FlexColumnWidth(1.0),
                                },
                                children: [
                                  // Header Row
                                  TableRow(
                                    children: [
                                      _buildTableCell(
                                        'COs / POs',
                                        isHeader: true,
                                        isBold: true,
                                      ),
                                      _buildTableCell('PO1', isHeader: true),
                                      _buildTableCell('PO2', isHeader: true),
                                      _buildTableCell('PO3', isHeader: true),
                                      _buildTableCell('PO4', isHeader: true),
                                      _buildTableCell('PO6', isHeader: true),
                                      _buildTableCell('PO7', isHeader: true),
                                      _buildTableCell('PO8', isHeader: true),
                                      _buildTableCell('PO8', isHeader: true),
                                      _buildTableCell('PO9', isHeader: true),
                                      _buildTableCell('PO10', isHeader: true),
                                      _buildTableCell('PO11', isHeader: true),
                                      _buildTableCell('PSO1', isHeader: true),
                                      _buildTableCell('PSO2', isHeader: true),
                                    ],
                                  ),
                                  // CO1 Row
                                  TableRow(
                                    children: [
                                      _buildTableCell('CO1', isBold: true),
                                      _buildTableCell('3'),
                                      _buildTableCell('2'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('1'),
                                      _buildTableCell('1'),
                                      _buildTableCell('-'),
                                      _buildTableCell('1'),
                                      _buildTableCell('2'),
                                      _buildTableCell('1'),
                                    ],
                                  ),
                                  // CO2 Row
                                  TableRow(
                                    children: [
                                      _buildTableCell('CO2', isBold: true),
                                      _buildTableCell('3'),
                                      _buildTableCell('3'),
                                      _buildTableCell('2'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('1'),
                                      _buildTableCell('1'),
                                      _buildTableCell('-'),
                                      _buildTableCell('1'),
                                      _buildTableCell('2'),
                                      _buildTableCell('1'),
                                    ],
                                  ),
                                  // CO3 Row
                                  TableRow(
                                    children: [
                                      _buildTableCell('CO3', isBold: true),
                                      _buildTableCell('3'),
                                      _buildTableCell('3'),
                                      _buildTableCell('2'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('1'),
                                      _buildTableCell('1'),
                                      _buildTableCell('-'),
                                      _buildTableCell('1'),
                                      _buildTableCell('2'),
                                      _buildTableCell('1'),
                                    ],
                                  ),
                                  // CO4 Row
                                  TableRow(
                                    children: [
                                      _buildTableCell('CO4', isBold: true),
                                      _buildTableCell('3'),
                                      _buildTableCell('3'),
                                      _buildTableCell('2'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('1'),
                                      _buildTableCell('1'),
                                      _buildTableCell('-'),
                                      _buildTableCell('1'),
                                      _buildTableCell('2'),
                                      _buildTableCell('1'),
                                    ],
                                  ),
                                  // CO5 Row
                                  TableRow(
                                    children: [
                                      _buildTableCell('CO5', isBold: true),
                                      _buildTableCell('3'),
                                      _buildTableCell('3'),
                                      _buildTableCell('3'),
                                      _buildTableCell('2'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('-'),
                                      _buildTableCell('1'),
                                      _buildTableCell('1'),
                                      _buildTableCell('-'),
                                      _buildTableCell('1'),
                                      _buildTableCell('2'),
                                      _buildTableCell('1'),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Bottom Mapping Scale Legend
                              const Text(
                                '1 – Low, 2 – Medium, 3 – High',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Table Cell Helper for CO-PO Matrix Table
  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: (isHeader || isBold)
              ? FontWeight.bold
              : FontWeight.normal,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Course Outcome Table Cell Helpers
  Widget _buildOutcomesHeaderCell(
    String label, {
    double? width,
    bool isLast = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: isLast
              ? BorderSide.none
              : const BorderSide(color: Colors.black, width: 1.0),
          bottom: const BorderSide(color: Colors.black, width: 1.0),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildOutcomesValueCell(
    String value, {
    double? width,
    bool isBold = false,
    bool isLast = false,
    bool isBottomLast = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: isLast
              ? BorderSide.none
              : const BorderSide(color: Colors.black, width: 1.0),
          bottom: isBottomLast
              ? BorderSide.none
              : const BorderSide(color: Colors.black, width: 1.0),
        ),
      ),
      alignment: width != null && width < 150
          ? Alignment.center
          : Alignment.centerLeft,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }

  // Matrix Cell Helper Widgets for Full-Width Alignment
  Widget _buildMatrixHeaderCell(
    String label, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Expanded(
      flex: isFirst ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            right: isLast
                ? BorderSide.none
                : const BorderSide(color: Colors.black, width: 1.0),
            bottom: const BorderSide(color: Colors.black, width: 1.0),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMatrixValueCell(
    String value, {
    bool isFirst = false,
    bool isLast = false,
    bool isBottomLast = false,
  }) {
    return Expanded(
      flex: isFirst ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            right: isLast
                ? BorderSide.none
                : const BorderSide(color: Colors.black, width: 1.0),
            bottom: isBottomLast
                ? BorderSide.none
                : const BorderSide(color: Colors.black, width: 1.0),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Grid Cell Helper Widgets
  Widget _buildGridHeaderCell(
    String label, {
    required double width,
    bool isLast = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          right: isLast
              ? BorderSide.none
              : const BorderSide(color: Colors.black, width: 1.0),
          bottom: const BorderSide(color: Colors.black, width: 1.0),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildGridValueCell(
    String value, {
    required double width,
    bool isBold = false,
    bool isLast = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          right: isLast
              ? BorderSide.none
              : const BorderSide(color: Colors.black, width: 1.0),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }

  // Unit Block Helper Widget
  Widget _buildPaperUnitBlock({
    required String unitLabel,
    required String unitTitle,
    required String hours,
    required String content,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Unit Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      unitLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      unitTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Text(
                  hours,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Unit Content Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.black,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
