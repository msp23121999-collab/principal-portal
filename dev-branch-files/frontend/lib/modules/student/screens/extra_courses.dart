import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/app_state.dart';

class CourseModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String instructor;
  final String department;
  final double progress;
  final String duration;
  final String dueDate;
  final String status; // In Progress, Not Started, Completed

  CourseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.instructor,
    required this.department,
    required this.progress,
    required this.duration,
    required this.dueDate,
    required this.status,
  });
}

class ExtraCoursesScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const ExtraCoursesScreen({super.key, this.onNavigate});

  @override
  State<ExtraCoursesScreen> createState() => _ExtraCoursesScreenState();
}

class _ExtraCoursesScreenState extends State<ExtraCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _activeTab = 'All'; // All, In Progress, Completed, Not Started
  String _searchQuery = '';
  String _selectedDept = 'All Departments';
  String _selectedMentor = 'All Mentors';
  String _selectedStatus = 'All Status';
  String _selectedSem = 'All Semesters';

  List<CourseModel> _getCoursesFromDb() {
    try {
      final appState = AppStateProvider.of(context);
      final dbCourses = appState.extraCourses;

      if (dbCourses.isEmpty) {
        return [];
      }

      final List<CourseModel> list = [];
      for (var c in dbCourses) {
        list.add(CourseModel(
          id: c.id,
          title: c.title,
          category: c.category,
          description: c.desc,
          instructor: c.instructor,
          department: 'CSE Department',
          progress: c.isEnrolled ? 0.0 : 0.0,
          duration: c.duration,
          dueDate: c.startDate,
          status: c.isEnrolled ? 'In Progress' : 'Not Started',
        ));
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  List<CourseModel> get _courses {
    final dbList = _getCoursesFromDb();
    if (dbList.isNotEmpty) return dbList;
    return [];
  }

  final List<CourseModel> _allCourses = [];

  List<CourseModel> get _filteredCourses {
    return _courses.where((c) {
      final matchesSearch = c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.instructor.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedDept != 'All Departments') {
        if (!c.department.toLowerCase().contains(_selectedDept.split(' ')[0].toLowerCase())) return false;
      }
      if (_selectedMentor != 'All Mentors') {
        final mentorName = _selectedMentor.replaceAll('Prof. ', '').replaceAll('Dr. ', '').split(' ')[0];
        if (!c.instructor.contains(mentorName)) return false;
      }
      if (_selectedStatus != 'All Status') {
        if (c.status != _selectedStatus) return false;
      }

      switch (_activeTab) {
        case 'In Progress':
          return c.status == 'In Progress';
        case 'Completed':
          return c.status == 'Completed';
        case 'Not Started':
          return c.status == 'Not Started';
        default:
          return true;
      }
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedDept = 'All Departments';
      _selectedMentor = 'All Mentors';
      _selectedStatus = 'All Status';
      _selectedSem = 'All Semesters';
      _activeTab = 'All';
    });
  }

  void _showCertificateDialog(CourseModel course) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Certificate: ${course.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.workspace_premium, size: 54, color: Color(0xFF2563EB)),
                      const SizedBox(height: 8),
                      Text(course.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Instructor: ${course.instructor}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton.icon(
              onPressed: () {
                try {
                  final csv = 'Mock Certificate PDF for ${course.title}\nAssigned by ${course.instructor}\nDepartment: ${course.department}\nStatus: Completed';
                  final bytes = utf8.encode(csv);
                  final blob = html.Blob([bytes], 'application/pdf');
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  final filename = 'Certificate_${course.title.replaceAll(' ', '_')}.pdf';
                  html.AnchorElement(href: url)
                    ..setAttribute("download", filename)
                    ..click();
                  html.Url.revokeObjectUrl(url);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$filename downloaded successfully!'), backgroundColor: const Color(0xFF16A34A)),
                  );
                } catch (e) {
                  debugPrint('Download error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading Certificate for ${course.title}...'), backgroundColor: const Color(0xFF16A34A)),
                  );
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.download, size: 14),
              label: const Text('Download PDF'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(isDesktop),
          const SizedBox(height: 24),

          _buildFiltersToolbar(isDesktop),
          const SizedBox(height: 24),

          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: _buildLeftContentColumn()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildRightSidebar()),
                  ],
                )
              : Column(
                  children: [
                    _buildLeftContentColumn(),
                    const SizedBox(height: 24),
                    _buildRightSidebar(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDesktop) {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = (constraints.maxWidth - 4 * 12) / 5;
      final showScroll = constraints.maxWidth < 950;

      final List<Widget> cards = [
        _buildStatCard('Total Assigned Courses', '', Icons.library_books_outlined, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
        _buildStatCard('In Progress Courses', '', Icons.play_circle_outline, const Color(0xFFEA580C), const Color(0xFFFFF7ED)),
        _buildStatCard('Completed Courses', '', Icons.verified_user_outlined, const Color(0xFF10B981), const Color(0xFFF0FDF4)),
        _buildStatCard('Certificates Earned', '', Icons.workspace_premium_outlined, const Color(0xFF8B5CF6), const Color(0xFFF3E8FF)),
        _buildStatCard('Learning Hours', '', Icons.schedule, const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
      ];

      if (showScroll) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cards.map((c) => Padding(padding: const EdgeInsets.only(right: 12.0), child: SizedBox(width: 170, child: c))).toList(),
          ),
        );
      } else {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
        );
      }
    });
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildFiltersToolbar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolbarDropdown(_selectedDept, ['All Departments', 'CSE Department', 'IT Department'], (val) {
              if (val != null) setState(() => _selectedDept = val);
            }),
            const SizedBox(width: 8),
            _buildToolbarDropdown(_selectedMentor, ['All Mentors', 'Dr. R. Senthil Kumar', 'Prof. M. Kavitha', 'Dr. P. Aravind', 'Prof. S. Deepa'], (val) {
              if (val != null) setState(() => _selectedMentor = val);
            }),
            const SizedBox(width: 8),
            _buildToolbarDropdown(_selectedStatus, ['All Status', 'In Progress', 'Completed', 'Not Started'], (val) {
              if (val != null) setState(() => _selectedStatus = val);
            }),
            const SizedBox(width: 8),
            _buildToolbarDropdown(_selectedSem, ['All Semesters', 'Semester I', 'Semester IV', 'Semester V'], (val) {
              if (val != null) setState(() => _selectedSem = val);
            }),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh, size: 12),
              label: const Text('Reset', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))))).toList(),
        ),
      ),
    );
  }

  Widget _buildLeftContentColumn() {
    final list = _filteredCourses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Assigned Courses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Row(
                    children: [
                      const Text('Sort by: Due Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(width: 8),
                      Icon(Icons.list, color: const Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 6),
                      Icon(Icons.grid_view_outlined, color: const Color(0xFF64748B), size: 16),
                    ],
                  ),
                ],
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final showRow = constraints.maxWidth > 650;
                  final searchBar = SizedBox(
                    width: showRow ? 300 : double.infinity,
                    height: 38,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search courses, instructors...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                  );
                  final chips = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'In Progress', 'Completed', 'Not Started'].map((tab) {
                        final isSel = _activeTab == tab;
                        int count = 0;
                        if (tab == 'All') count = 0;
                        if (tab == 'In Progress') count = 0;
                        if (tab == 'Completed') count = 0;
                        if (tab == 'Not Started') count = 0;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(
                              '$tab ($count)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                            selected: isSel,
                            selectedColor: const Color(0xFF2563EB),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onSelected: (val) {
                              setState(() {
                                _activeTab = tab;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );

                  if (showRow) {
                    return Row(
                      children: [
                        searchBar,
                        const SizedBox(width: 16),
                        Expanded(child: chips),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchBar,
                        const SizedBox(height: 12),
                        chips,
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              ...list.map((c) => _buildCourseRowCard(c)),
              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: const Text('No courses found matching selected filters.', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseBanner(String category, String title) {
    Color startColor;
    Color endColor;
    String codeText;
    IconData icon;

    if (category.toLowerCase().contains('programming') || title.toLowerCase().contains('python')) {
      startColor = const Color(0xFF1E3A8A); // Dark Blue
      endColor = const Color(0xFF3B82F6); // Light Blue
      codeText = 'PYTHON';
      icon = Icons.terminal;
    } else if (category.toLowerCase().contains('technical') || title.toLowerCase().contains('structure')) {
      startColor = const Color(0xFF065F46); // Dark Green
      endColor = const Color(0xFF10B981); // Emerald
      codeText = 'DATA STRUCT';
      icon = Icons.schema_outlined;
    } else if (category.toLowerCase().contains('web')) {
      startColor = const Color(0xFF7C2D12); // Dark Orange
      endColor = const Color(0xFFF97316); // Orange
      codeText = 'WEB DEV';
      icon = Icons.language;
    } else if (category.toLowerCase().contains('database') || title.toLowerCase().contains('dbms')) {
      startColor = const Color(0xFF111827); // Charcoal
      endColor = const Color(0xFF4B5563); // Gray
      codeText = 'DBMS';
      icon = Icons.storage;
    } else {
      startColor = const Color(0xFF581C87); // Purple
      endColor = const Color(0xFFA855F7); // Light Purple
      codeText = 'COURSE';
      icon = Icons.school_outlined;
    }

    return Container(
      width: 110,
      height: 75,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [startColor, endColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.15)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  codeText,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseRowCard(CourseModel c) {
    Color themeColor;
    Color lightBg;
    if (c.category.toLowerCase().contains('programming')) {
      themeColor = const Color(0xFF2563EB); // Royal Blue
      lightBg = const Color(0xFFEFF6FF);
    } else if (c.category.toLowerCase().contains('technical')) {
      themeColor = const Color(0xFF10B981); // Emerald
      lightBg = const Color(0xFFF0FDF4);
    } else if (c.category.toLowerCase().contains('web')) {
      themeColor = const Color(0xFFF97316); // Orange
      lightBg = const Color(0xFFFFF7ED);
    } else {
      themeColor = const Color(0xFF6366F1); // Indigo
      lightBg = const Color(0xFFEEF2FF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Banner
          _buildCourseBanner(c.category, c.title),
          const SizedBox(width: 20),

          // Middle Details
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        c.category,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: themeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.person_outline, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned by ',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      c.instructor,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    Text(
                      '  |  ${c.department}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Right Progress
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.status,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c.status == 'Completed' ? const Color(0xFF10B981) : themeColor),
                    ),
                    Text(
                      '${(c.progress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: c.progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(c.status == 'Completed' ? const Color(0xFF10B981) : themeColor),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      'Duration: ${c.duration}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      c.status == 'Completed' ? Icons.check_circle_outline : Icons.calendar_today_outlined,
                      size: 12,
                      color: c.status == 'Completed' ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c.status == 'Completed' ? c.dueDate : 'Due: ${c.dueDate}',
                      style: TextStyle(
                        fontSize: 10,
                        color: c.status == 'Completed' ? const Color(0xFF10B981) : const Color(0xFF64748B),
                        fontWeight: c.status == 'Completed' ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    if (c.status == 'Completed') {
                      _showCertificateDialog(c);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Starting course ${c.title}...'), backgroundColor: const Color(0xFF2563EB)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.status == 'In Progress' ? const Color(0xFF2563EB) : Colors.white,
                    side: BorderSide(color: const Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    c.status == 'Completed'
                        ? 'View Certificate'
                        : c.status == 'In Progress'
                            ? 'Continue Learning'
                            : 'Start Learning',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: c.status == 'In Progress' ? Colors.white : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Options for ${c.title}')),
                  );
                },
                icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildRecommendedSection() {
    final list = [
      {
        'title': '',
        'hours': '',
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'icon': Icons.emoji_events_outlined,
      },
      {
        'title': '',
        'hours': '',
        'color': const Color(0xFFEC4899),
        'bg': const Color(0xFFFDF2F8),
        'icon': Icons.palette_outlined,
      },
      {
        'title': '',
        'hours': '',
        'color': const Color(0xFF0EA5E9),
        'bg': const Color(0xFFF0F9FF),
        'icon': Icons.cloud_outlined,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Recommended For You', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          ...list.map((item) {
            final textCol = item['color'] as Color;
            return InkWell(
              onTap: () {
                setState(() {
                  _searchQuery = item['title'] as String;
                  _searchController.text = _searchQuery;
                  _activeTab = 'All';
                  _selectedDept = 'All Departments';
                  _selectedMentor = 'All Mentors';
                  _selectedStatus = 'All Status';
                  _selectedSem = 'All Semesters';
                });
                _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item['bg'] as Color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: textCol.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: textCol.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(item['icon'] as IconData, color: textCol, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: textCol.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['hours'] as String,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textCol),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Removed recommended card chevron arrow per user request
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Column(
      children: [
        _buildUpcomingDeadlinesCard(),
        const SizedBox(height: 20),
        _buildCertificatesEarnedCard(),
        const SizedBox(height: 20),
        _buildRecommendedSection(),
        const SizedBox(height: 20),
        _buildLearningProgressCard(),
        const SizedBox(height: 20),
        _buildMentorAnnouncementsCard(),
      ],
    );
  }

  Widget _buildUpcomingDeadlinesCard() {
    final items = [
      {'title': '', 'sub': '', 'date': '', 'badge': '', 'col': const Color(0xFFEF4444), 'bg': const Color(0xFFFEF2F2)},
      {'title': '', 'sub': '', 'date': '', 'badge': '', 'col': const Color(0xFFEA580C), 'bg': const Color(0xFFFFF7ED)},
      {'title': '', 'sub': '', 'date': '', 'badge': '', 'col': const Color(0xFFEA580C), 'bg': const Color(0xFFFFF7ED)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Upcoming Deadlines', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: item['bg'] as Color, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.calendar_today, size: 12, color: item['col'] as Color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text(item['sub'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: item['bg'] as Color, borderRadius: BorderRadius.circular(4)),
                    child: Text(item['badge'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: item['col'] as Color)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }



  Widget _buildCertificatesEarnedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Certificates Earned', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.workspace_premium, size: 36, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Total Certificates', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (idx) {
              return Expanded(
                child: Container(
                  height: 45,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 16),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Learning Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('This Semester ▾', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: LearningProgressPainter(),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _buildProgressLegend('Programming', '', const Color(0xFF2563EB)),
                    const SizedBox(height: 5),
                    _buildProgressLegend('Technical', '', const Color(0xFF8B5CF6)),
                    const SizedBox(height: 5),
                    _buildProgressLegend('Web Dev', '', const Color(0xFFEA580C)),
                    const SizedBox(height: 5),
                    _buildProgressLegend('Database', '', const Color(0xFF0D9488)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLegend(String label, String val, Color col) {
    return Row(
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
        Text(val, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildMentorAnnouncementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Mentor Announcements', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.volume_up, size: 16, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '',
                    style: TextStyle(fontSize: 9, color: Color(0xFF1E293B), height: 1.4),
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

class LearningProgressPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;
    final double strokeWidth = 9.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius - strokeWidth / 2);

    paint.color = const Color(0xFF2563EB);
    canvas.drawArc(rect, -1.57, 2.38, false, paint); // 38%

    paint.color = const Color(0xFF8B5CF6);
    canvas.drawArc(rect, 0.81, 1.82, false, paint); // 29%

    paint.color = const Color(0xFFEA580C);
    canvas.drawArc(rect, 2.63, 1.19, false, paint); // 19%

    paint.color = const Color(0xFF0D9488);
    canvas.drawArc(rect, 3.82, 0.88, false, paint); // 14%
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
