import 'package:flutter/material.dart';
import '../theme.dart';
import '../responsive.dart';
import '../export_dialog_helper.dart';
import '../../faculty/services/postgres_client.dart';

enum MarkPerformanceMode { markView, studentPerformance }

class BatchInfo {
  final String name;
  final String department;
  final int studentCount;
  final int activeSem;
  final Color themeColor;
  final Color bgLight;
  final Color border;
  final Color badgeBg;
  final Color badgeText;
  final IconData icon;

  const BatchInfo({
    required this.name,
    required this.department,
    required this.studentCount,
    required this.activeSem,
    required this.themeColor,
    required this.bgLight,
    required this.border,
    required this.badgeBg,
    required this.badgeText,
    required this.icon,
  });
}

class MarksAndPerformanceView extends StatefulWidget {
  const MarksAndPerformanceView({super.key});

  @override
  State<MarksAndPerformanceView> createState() =>
      _MarksAndPerformanceViewState();
}

class _MarksAndPerformanceViewState extends State<MarksAndPerformanceView> {
  MarkPerformanceMode _selectedMode = MarkPerformanceMode.markView;
  BatchInfo? _selectedBatch;
  String? _selectedSemester;
  String _selectedSubjectCode = 'IOT2301';
  String? _selectedStudentForDetails;

  bool _isLoading = false;
  List<Map<String, dynamic>> _studentsData = [];
  List<Map<String, dynamic>> _marksData = [];
  List<Map<String, String>> _dynamicSubjects = [];
  List<String> _dynamicAssessments = [];
  String? _selectedAssessment;
  String _currentAcademicYear = '2026-2027';

  @override
  void initState() {
    super.initState();
    _loadBatchesFromDatabase();
  }

  final List<BatchInfo> _batches = [];
  /*
    BatchInfo(
      name: 'Batch 2024 - 2028',
      department: 'Computer Science & Engineering (CSE)',
      studentCount: 60,
      activeSem: 3,
      themeColor: Color(0xFF2563EB),
      bgLight: Color(0xFFEFF6FF),
      border: Color(0xFFDBEAFE),
      badgeBg: Color(0xFFEFF6FF),
      badgeText: Color(0xFF1D4ED8),
      icon: Icons.hub_outlined,
    ),
    BatchInfo(
      name: 'Batch 2023 - 2027',
      department: 'Computer Science & Engineering (CSE)',
      studentCount: 58,
      activeSem: 5,
      themeColor: Color(0xFF10B981),
      bgLight: Color(0xFFECFDF5),
      border: Color(0xFFA7F3D0), // Light green border matching screenshot
      badgeBg: Color(0xFFECFDF5),
      badgeText: Color(0xFF047857),
      icon: Icons.devices_outlined,
    ),
    BatchInfo(
      name: 'Batch 2025 - 2029',
      department: 'Computer Science & Engineering (CSE)',
      studentCount: 64,
      activeSem: 1,
      themeColor: Color(0xFF9333EA),
      bgLight: Color(0xFFF3E8FF),
      border: Color(0xFFE9D5FF),
      badgeBg: Color(0xFFF3E8FF),
      badgeText: Color(0xFF7E22CE),
      icon: Icons.memory_outlined,
    ),
  ];
  */

  // Mock Subjects List for Mark View
  final List<Map<String, String>> _subjects = const [
    {
      'code': 'IOT2301',
      'title': 'Sub 1: IOT2301 - Embedded C Programming',
      'name': 'Embedded C Programming',
      'faculty': 'Dr. S. Karthi',
    },
    {
      'code': 'IOT2302',
      'title': 'Sub 2: IOT2302 - Data Structures & Algorithms',
      'name': 'Data Structures & Algorithms',
      'faculty': 'Prof. Muththukumaran',
    },
    {
      'code': 'IOT2303',
      'title': 'Sub 3: IOT2303 - Sensors & Actuators',
      'name': 'Sensors & Actuators',
      'faculty': 'Dr. K. Govindaraj',
    },
  ];

  // Mock Student Marks List (Matching exact Mark View screenshot)
  final List<Map<String, dynamic>> _studentMarksList = const [
    {
      'sNo': 1,
      'name': 'Kavyaa P S',
      'regNo': '731622IOT001',
      'cgpa': 8.75,
      'ia1': 16,
      'ia2': 18,
      'model': 47,
      'assign': 9,
      'totalMark': 90,
    },
    {
      'sNo': 2,
      'name': 'Arun Kumar R',
      'regNo': '731622IOT004',
      'cgpa': 7.45,
      'ia1': 16,
      'ia2': 14,
      'model': 31,
      'assign': 9,
      'totalMark': 70,
    },
    {
      'sNo': 3,
      'name': 'Harini M',
      'regNo': '731622IOT007',
      'cgpa': 8.98,
      'ia1': 19,
      'ia2': 19,
      'model': 48,
      'assign': 9,
      'totalMark': 95,
    },
    {
      'sNo': 4,
      'name': 'Vignesh S',
      'regNo': '731622IOT010',
      'cgpa': 7.52,
      'ia1': 14,
      'ia2': 16,
      'model': 42,
      'assign': 8,
      'totalMark': 80,
    },
    {
      'sNo': 5,
      'name': 'Deepika V',
      'regNo': '731622IOT012',
      'cgpa': 9.21,
      'ia1': 19,
      'ia2': 19,
      'model': 46,
      'assign': 9,
      'totalMark': 93,
    },
  ];

  // Mock Student Performance List (Matching exact Student Performance screenshot)
  final List<Map<String, dynamic>> _studentPerformanceList = const [
    {
      'sNo': 1,
      'name': 'Kavyaa P S',
      'regNo': '731622IOT001',
      'gpa': 8.92,
      'cgpa': 8.75,
      'attendance': 95.2,
    },
    {
      'sNo': 2,
      'name': 'Arun Kumar R',
      'regNo': '731622IOT004',
      'gpa': 7.21,
      'cgpa': 7.45,
      'attendance': 66.6,
    },
    {
      'sNo': 3,
      'name': 'Harini M',
      'regNo': '731622IOT007',
      'gpa': 9.15,
      'cgpa': 8.98,
      'attendance': 90.5,
    },
    {
      'sNo': 4,
      'name': 'Vignesh S',
      'regNo': '731622IOT010',
      'gpa': 7.68,
      'cgpa': 7.52,
      'attendance': 71.4,
    },
    {
      'sNo': 5,
      'name': 'Deepika V',
      'regNo': '731622IOT012',
      'gpa': 9.42,
      'cgpa': 9.21,
      'attendance': 97.6,
    },
  ];

  Future<void> _loadDataFromDatabase() async {
    if (_selectedBatch == null || _selectedSemester == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final batchName = _selectedBatch!.name;
      final batchYear = batchName.replaceAll('Batch ', '').replaceAll(' ', '');

      final semTitle = _selectedSemester!;
      final semNumber = int.tryParse(semTitle.split(' ')[1]) ?? 3;

      final students = await SupabaseClientHelper.selectWithFilters(
        'students',
        selectQuery:
            'student_id, roll_no, register_no, full_name, cgpa, attendance_percentage',
        filters: {'batch': batchYear, 'semester': semNumber.toString()},
        schema: 'student',
      );

      final marks = await SupabaseClientHelper.select(
        'marks',
        selectQuery:
            'student_id, subject, subject_code, assessment, total, percentage, grade, max_marks, is_absent, remarks, faculty_employee_id',
        schema: 'faculty',
      );

      final List<Map<String, String>> dbSubjects = [];
      final Set<String> seenSubjects = {};
      final Set<String> dbAssessments = {};

      for (var m in marks) {
        final subName = m['subject'] as String? ?? 'Unknown Subject';
        final subCode = m['subject_code'] as String? ?? '';
        final key = '$subCode-$subName';
        if (subName.isNotEmpty && !seenSubjects.contains(key)) {
          seenSubjects.add(key);
          dbSubjects.add({
            'code': subCode.isNotEmpty ? subCode : subName,
            'name': subName,
            'title': subCode.isNotEmpty ? '$subCode - $subName' : subName,
            'faculty':
                m['faculty_employee_id'] as String? ?? 'Assigned Faculty',
          });
        }

        final assess = m['assessment'] as String?;
        if (assess != null && assess.isNotEmpty) {
          dbAssessments.add(assess);
        }
      }

      final assessmentsList = dbAssessments.toList();

      setState(() {
        _studentsData = students;
        _marksData = marks;
        _dynamicSubjects = dbSubjects;
        _dynamicAssessments = assessmentsList;

        if (_dynamicSubjects.isNotEmpty) {
          final hasSub = _dynamicSubjects.any(
            (s) => s['code'] == _selectedSubjectCode,
          );
          if (!hasSub) {
            _selectedSubjectCode = _dynamicSubjects[0]['code']!;
          }
        }
        if (_selectedAssessment == null ||
            !assessmentsList.contains(_selectedAssessment)) {
          _selectedAssessment = assessmentsList[0];
        }
      });
    } catch (e) {
      debugPrint('Error loading marks data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBatchesFromDatabase() async {
    final rows = await SupabaseClientHelper.select(
      'students',
      selectQuery: 'batch, department, semester',
      schema: 'student',
    );
    if (!mounted) return;
    final seen = <String>{};
    final batches = <BatchInfo>[];
    for (final row in rows) {
      final batch = (row['batch'] ?? '').toString().trim();
      if (batch.isEmpty || !seen.add(batch)) continue;
      final semester = int.tryParse((row['semester'] ?? '0').toString()) ?? 0;
      batches.add(BatchInfo(
        name: 'Batch $batch',
        department: (row['department'] ?? 'null').toString(),
        studentCount: rows.where((student) => student['batch']?.toString() == batch).length,
        activeSem: semester,
        themeColor: const Color(0xFF2563EB),
        bgLight: const Color(0xFFEFF6FF),
        border: const Color(0xFFDBEAFE),
        badgeBg: const Color(0xFFEFF6FF),
        badgeText: const Color(0xFF1D4ED8),
        icon: Icons.school_outlined,
      ));
    }
    setState(() {
      _batches
        ..clear()
        ..addAll(batches);
      _selectedBatch = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = HodResponsive.pagePaddingInsets(context);

    return SingleChildScrollView(
      padding: padding.copyWith(top: 16, bottom: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. TOP HEADER & ACADEMIC YEAR ──
          _buildTopHeader(),
          const SizedBox(height: 12),

          // ── 2. MODE SELECTION TAB CARDS (Mark View vs Student Performance) ──
          _buildModeSelectionCards(),
          const SizedBox(height: 12),

          // ── 3. CENTRAL HUB HEADER & EXPORT ACTION ──
          _buildCentralHubHeader(),
          const SizedBox(height: 12),

          // ── 4. DYNAMIC CONTENT ──
          if (_selectedBatch == null) ...[
            _buildBatchSelectionGrid(),
          ] else if (_selectedSemester == null) ...[
            _buildSemesterSelectionGrid(),
          ] else if (_selectedStudentForDetails != null) ...[
            _buildDetailedStudentPerformanceAnalysis(),
          ] else ...[
            _buildDetailedPerformanceView(),
          ],
        ],
      ),
    );
  }

  // ── TOP HEADER WITH BREADCRUMB & ACADEMIC YEAR PILL ──
  Widget _buildTopHeader() {
    String currentModeTitle = _selectedMode == MarkPerformanceMode.markView
        ? 'Mark View'
        : 'Student Performance';
    String breadcrumbPath = _selectedSemester != null
        ? 'Academic Management > Marks & Performance > ${_selectedBatch?.name} > $_selectedSemester'
        : (_selectedBatch != null
              ? 'Academic Management > Marks & Performance > ${_selectedBatch?.name}'
              : 'Academic Management > Marks & Performance > $currentModeTitle');

    return HodSectionHeader(
      title: 'Marks & Performance',
      breadcrumb: breadcrumbPath,
      academicYear:
          'Academic Year ${_currentAcademicYear.replaceAll('-', ' - ')}',
    );
  }

  Widget _buildModeSelectionCards() {
    final isMarkViewActive = _selectedMode == MarkPerformanceMode.markView;
    final isPerformanceActive =
        _selectedMode == MarkPerformanceMode.studentPerformance;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          _buildCompactTab(
            label: 'Mark View',
            icon: Icons.star_rounded,
            isActive: isMarkViewActive,
            onTap: () {
              if (_selectedMode != MarkPerformanceMode.markView) {
                setState(() {
                  _selectedMode = MarkPerformanceMode.markView;
                  _selectedBatch = null;
                  _selectedSemester = null;
                  _selectedStudentForDetails = null;
                });
              }
            },
          ),
          _buildCompactTab(
            label: 'Student Performance',
            icon: Icons.show_chart_rounded,
            isActive: isPerformanceActive,
            onTap: () {
              if (_selectedMode != MarkPerformanceMode.studentPerformance) {
                setState(() {
                  _selectedMode = MarkPerformanceMode.studentPerformance;
                  _selectedBatch = null;
                  _selectedSemester = null;
                  _selectedStudentForDetails = null;
                });
              }
            },
          ),
        ],
      ),
    );
  }

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

  // ── CENTRAL HUB HEADER & EXPORT ACTION ──
  Widget _buildCentralHubHeader() {
    final isMobile = HodResponsive.isMobile(context);

    final exportBtn = HodExportDialog.buildExportButton(
      context,
      onPressed: () => HodExportDialog.show(
        context,
        title: 'Export Management Data',
        subtitle: 'Select export format for Marks & Performance reports:',
        moduleName: 'Marks & Performance',
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Management Central Hub',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Management > Attendance, Assignments, Grade Entry & Exams',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (_selectedSemester != null) ...[
            const SizedBox(height: 12),
            exportBtn,
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic Management Central Hub',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Management > Attendance, Assignments, Grade Entry & Exams',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        if (_selectedSemester != null) exportBtn,
      ],
    );
  }

  // ── BATCH SELECTION GRID ──
  Widget _buildBatchSelectionGrid() {
    final modeLabel = _selectedMode == MarkPerformanceMode.markView
        ? 'Grade Entry'
        : 'Student Performance';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Active Batch for $modeLabel',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final cols = (availableWidth / 260).floor().clamp(1, 3);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 215,
              ),
              itemCount: _batches.length,
              itemBuilder: (context, index) {
                return _buildBatchCard(_batches[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBatchCard(BatchInfo batch) {
    final batchStartYear =
        int.tryParse(
          batch.name.replaceAll(RegExp(r'[^0-9]'), '').substring(0, 4),
        ) ??
        2024;
    final acadStartYear =
        int.tryParse(_currentAcademicYear.split('-')[0]) ?? 2026;

    final yearOfStudy = acadStartYear - batchStartYear + 1;
    String yearLabel = 'Year I';
    if (yearOfStudy == 2)
      yearLabel = 'Year II';
    else if (yearOfStudy == 3)
      yearLabel = 'Year III';
    else if (yearOfStudy == 4)
      yearLabel = 'Year IV';
    else if (yearOfStudy > 4)
      yearLabel = 'Graduated';

    int activeSem = 1;
    if (yearOfStudy == 2)
      activeSem = 3;
    else if (yearOfStudy == 3)
      activeSem = 5;
    else if (yearOfStudy >= 4)
      activeSem = 7;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedBatch = batch;
          _selectedSemester = null;
          _selectedStudentForDetails = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: batch.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Left Circle Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: batch.bgLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(batch.icon, color: batch.themeColor, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Batch Title
            Text(
              '${batch.name} ($yearLabel)',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Department Subtext
            Text(
              batch.department,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),

            // Bottom Info Row (Students & Semester Pill)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${batch.studentCount} Students',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: batch.badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Sem $activeSem',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: batch.badgeText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── SEMESTER SELECTION GRID (Images 3 & 4) ──
  Widget _buildSemesterSelectionGrid() {
    final batch = _selectedBatch!;

    final batchStartYear =
        int.tryParse(
          batch.name.replaceAll(RegExp(r'[^0-9]'), '').substring(0, 4),
        ) ??
        2024;
    final acadStartYear =
        int.tryParse(_currentAcademicYear.split('-')[0]) ?? 2026;
    final yearOfStudy = acadStartYear - batchStartYear + 1;
    int activeSem = 1;
    if (yearOfStudy == 2)
      activeSem = 3;
    else if (yearOfStudy == 3)
      activeSem = 5;
    else if (yearOfStudy >= 4)
      activeSem = 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-breadcrumb Navigation Link
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _selectedBatch = null;
                  _selectedSemester = null;
                  _selectedStudentForDetails = null;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  'All Batches',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              batch.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Section Title
        Text(
          'Select Semester for ${batch.name}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Semester Cards Grid
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(activeSem, (index) {
            final semNum = index + 1;
            final semTitle = 'Semester $semNum';

            return _buildSemesterCard(semTitle, batch);
          }),
        ),
      ],
    );
  }

  Widget _buildSemesterCard(String semTitle, BatchInfo batch) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSemester = semTitle;
          _selectedStudentForDetails = null;
        });
        _loadDataFromDatabase();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_rounded,
              size: 24,
              color:
                  batch.themeColor, // Theme color matches the selected batch!
            ),
            const SizedBox(height: 12),
            Text(
              semTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DETAILED PERFORMANCE VIEW (When a Semester Card is clicked) ──
  Widget _buildDetailedPerformanceView() {
    final batch = _selectedBatch!;
    final sem = _selectedSemester!;
    final isMarkView = _selectedMode == MarkPerformanceMode.markView;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-breadcrumb Navigation Links
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _selectedBatch = null;
                  _selectedSemester = null;
                  _selectedStudentForDetails = null;
                });
              },
              child: const Text(
                'All Batches',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentBlue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedSemester = null;
                  _selectedStudentForDetails = null;
                });
              },
              child: Text(
                batch.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentBlue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              sem,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (isMarkView) ...[
          _buildMarkViewSubjectMarksTable(batch, sem),
        ] else ...[
          _buildStudentPerformanceAnalyticsView(batch, sem),
        ],
      ],
    );
  }

  Widget _buildMarkViewSubjectMarksTable(BatchInfo batch, String semester) {
    final subjectsToUse = _dynamicSubjects;
    Map<String, String> selectedSubject = subjectsToUse[0];
    for (var sub in subjectsToUse) {
      if (sub['code'] == _selectedSubjectCode) {
        selectedSubject = sub;
        break;
      }
    }

    final assessmentsToUse = _dynamicAssessments.isNotEmpty
        ? _dynamicAssessments
        : ['CIA - I', 'CIA - II', 'Model Exam'];
    if (_selectedAssessment == null ||
        !assessmentsToUse.contains(_selectedAssessment)) {
      _selectedAssessment = assessmentsToUse[0];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Subject Selection Header & Buttons
        const Text(
          'Subject Selection',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: subjectsToUse.map((sub) {
              final isSelected = sub['code'] == _selectedSubjectCode;
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedSubjectCode = sub['code']!;
                    });
                  },
                  icon: Icon(
                    Icons.bookmark_rounded,
                    size: 16,
                    color: isSelected ? Colors.white : AppTheme.accentBlue,
                  ),
                  label: Text(
                    sub['title'] ?? sub['name']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? AppTheme.accentBlue
                        : Colors.white,
                    elevation: isSelected ? 2 : 0,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.accentBlue
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Assessment Selection Header & Buttons
        const Text(
          'Assessment (Exam) Selection',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: assessmentsToUse.map((assess) {
              final isSelected = assess == _selectedAssessment;
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedAssessment = assess;
                    });
                  },
                  icon: Icon(
                    Icons.assessment_rounded,
                    size: 16,
                    color: isSelected ? Colors.white : AppTheme.accentBlue,
                  ),
                  label: Text(
                    assess,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? AppTheme.accentBlue
                        : Colors.white,
                    elevation: isSelected ? 2 : 0,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.accentBlue
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // 3. Student Marks Table Container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Marks: ${selectedSubject['code']} - ${selectedSubject['name']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Faculty Assigned: ${selectedSubject['faculty'] ?? 'Assigned Faculty'}  |  $semester',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(
                      color: AppTheme.accentBlue,
                    ),
                  ),
                )
              else if (_studentsData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No students found matching this batch and semester.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                // DataTable (Full Width)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF8FAFC),
                          ),
                          horizontalMargin: 16,
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'S.No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Student Name & Reg No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'CGPA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Obtained Mark',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Percentage %',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Grade',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          rows: List.generate(_studentsData.length, (idx) {
                            final student = _studentsData[idx];
                            final studentId = student['student_id'] as String?;
                            final name =
                                student['full_name'] as String? ?? 'Unknown';
                            final regNo =
                                student['register_no'] as String? ??
                                student['roll_no'] as String? ??
                                '-';
                            final cgpaVal = student['cgpa'] as num? ?? 0.0;

                            // Find mark record in _marksData for this student, selected subject, and selected assessment
                            final markRecord = _marksData.firstWhere(
                              (m) =>
                                  m['student_id'] == studentId &&
                                  (m['subject_code'] == _selectedSubjectCode ||
                                      m['subject'] ==
                                          selectedSubject['name']) &&
                                  m['assessment'] == _selectedAssessment,
                              orElse: () => <String, dynamic>{},
                            );

                            final hasRecord = markRecord.isNotEmpty;
                            final isAbsent =
                                hasRecord && (markRecord['is_absent'] == true);

                            String markStr = '-';
                            String pctStr = '-';
                            String gradeStr = '-';
                            bool isHighMark = false;

                            if (hasRecord) {
                              if (isAbsent) {
                                markStr = 'Absent';
                              } else {
                                final totalMark =
                                    markRecord['total'] as num? ?? 0;
                                final maxMark =
                                    markRecord['max_marks'] as num? ?? 100;
                                markStr = '$totalMark / $maxMark';
                                isHighMark = totalMark >= (maxMark * 0.75);

                                final pct =
                                    markRecord['percentage'] as num? ?? 0;
                                pctStr = '${pct.toStringAsFixed(1)}%';
                              }
                              gradeStr = markRecord['grade'] as String? ?? '-';
                            }

                            return DataRow(
                              cells: [
                                // S.No
                                DataCell(
                                  Text(
                                    (idx + 1).toString(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),

                                // Student Name & Reg No
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        regNo,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // CGPA
                                DataCell(
                                  Text(
                                    cgpaVal.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),

                                // Obtained Mark
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAbsent
                                          ? const Color(0xFFFEE2E2)
                                          : (isHighMark
                                                ? const Color(0xFFDCFCE7)
                                                : const Color(0xFFFFEDD5)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      markStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isAbsent
                                            ? const Color(0xFFEF4444)
                                            : (isHighMark
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFFEA580C)),
                                      ),
                                    ),
                                  ),
                                ),

                                // Percentage %
                                DataCell(
                                  Text(
                                    pctStr,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),

                                // Grade
                                DataCell(
                                  Text(
                                    gradeStr,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget to build colorful mark badges
  Widget _buildMarkBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // ── STUDENT PERFORMANCE: EXACT MATCH TO STUDENT PERFORMANCE SCREENSHOT ──
  Widget _buildStudentPerformanceAnalyticsView(
    BatchInfo batch,
    String semester,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Performance Table - $semester (${batch.name})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(color: AppTheme.accentBlue),
              ),
            )
          else if (_studentsData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'No students found matching this batch and semester.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),
            )
          else
            // Table (Full Width)
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF8FAFC),
                      ),
                      horizontalMargin: 16,
                      columnSpacing: 32,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'S.No',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Student Name & Reg No',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'GPA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'CGPA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Attendance %',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Action',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      rows: List.generate(_studentsData.length, (idx) {
                        final student = _studentsData[idx];
                        final name =
                            student['full_name'] as String? ?? 'Unknown';
                        final regNo =
                            student['register_no'] as String? ??
                            student['roll_no'] as String? ??
                            '-';
                        final cgpaVal = student['cgpa'] as num? ?? 0.0;
                        final attendance =
                            student['attendance_percentage'] as num? ?? 100.0;

                        final double gpaVal = cgpaVal > 0
                            ? (cgpaVal * 0.98 + 0.1).clamp(0.0, 10.0)
                            : 0.0;
                        final bool isHighAtt = attendance >= 85.0;

                        return DataRow(
                          cells: [
                            // S.No
                            DataCell(
                              Text(
                                (idx + 1).toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),

                            // Student Name & Reg No
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    regNo,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // GPA Pill (Light Blue)
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  gpaVal.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),

                            // CGPA Pill (Light Purple)
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  cgpaVal.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9333EA),
                                  ),
                                ),
                              ),
                            ),

                            // Attendance % Pill (Green / Orange)
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isHighAtt
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${attendance.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isHighAtt
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEA580C),
                                  ),
                                ),
                              ),
                            ),

                            // Action Button (Triggers 2x2 Bento Box Detailed View!)
                            DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedStudentForDetails = name;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'View Detailed Performance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── DETAILED STUDENT PERFORMANCE ANALYSIS (2x2 Bento Box Grid matching Images 1 & 2) ──
  Widget _buildDetailedStudentPerformanceAnalysis() {
    final batch = _selectedBatch!;
    final sem = _selectedSemester!;
    final studentName = _selectedStudentForDetails!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Breadcrumb & Back Arrow Link
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _selectedStudentForDetails = null;
                });
              },
              child: const Row(
                children: [
                  Icon(Icons.arrow_back, size: 18, color: AppTheme.accentBlue),
                  SizedBox(width: 8),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedStudentForDetails = null;
                });
              },
              child: Text(
                '${batch.name} > $sem',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentBlue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              'Detailed Performance Analysis - $studentName',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 2x2 Bento Box Grid
        Column(
          children: [
            // Row 1: Cards 1 & 2
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCgpaTrendCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildSubjectAttendanceCard()),
              ],
            ),
            const SizedBox(height: 20),

            // Row 2: Cards 3 & 4
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInternalMarkDistributionCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildMarksDistributionCard()),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── CARD 1: 1. Semester CGPA Trend ──
  Widget _buildCgpaTrendCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.trending_up, size: 18, color: AppTheme.accentBlue),
              SizedBox(width: 8),
              Text(
                '1. Semester CGPA Trend',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Stat Summary Boxes
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall CGPA',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '8.72 / 10',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '▲ 0.52 from last sem',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Highest Semester',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '9.10 / 10',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Semester V',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average CGPA',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '8.23 / 10',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9333EA),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Across 6 Semesters',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Line Chart Area
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(painter: _CgpaTrendPainter()),
          ),
          const SizedBox(height: 16),

          // Bottom Green Pill Banner
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
                SizedBox(width: 4),
                Text(
                  '0.52 improvement from last semester',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CARD 2: 2. Subject-wise Attendance (This Semester) ──
  Widget _buildSubjectAttendanceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 18,
                    color: AppTheme.accentBlue,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '2. Subject-wise Attendance (This Semester)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Attendance %',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart Area with 75% Threshold Line
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(painter: _SubjectAttendancePainter()),
          ),
          const SizedBox(height: 20),

          // 3 Stat Summary Boxes
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Attendance',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '89.7%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Highest Attendance',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '96% (DSP)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lowest Attendance',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '82% (Data Structures)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CARD 3: 3. Internal Mark Distribution (This Semester) ──
  Widget _buildInternalMarkDistributionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: AppTheme.accentBlue,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '3. Internal Mark Distribution (This Semester)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem('IA 1', const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _buildLegendItem('IA 2', const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildLegendItem('Model Exam', const Color(0xFF9333EA)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grouped Bar Chart Area
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(painter: _InternalMarkDistributionPainter()),
          ),
          const SizedBox(height: 20),

          // Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF1D4ED8)),
                SizedBox(width: 8),
                Text(
                  'Internal Assessment marks are out of 100 for each component.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CARD 4: 4. Marks Distribution - All Subjects (This Semester) ──
  Widget _buildMarksDistributionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 18,
                color: AppTheme.accentBlue,
              ),
              SizedBox(width: 8),
              Text(
                '4. Marks Distribution - All Subjects (This Semester)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Histogram Chart Area
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(painter: _MarksHistogramPainter()),
          ),
          const SizedBox(height: 20),

          // 4 Summary Pill Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '>= 80%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF047857),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '14 Subjects (58.3%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '>= 70%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '20 Subjects (83.3%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '>= 60%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '22 Subjects (91.7%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Below 60%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '1 Subject (4.2%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── CUSTOM PAINTER 1: Semester CGPA Trend Line Chart ──
class _CgpaTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = 30.0;
    final double paddingBottom = 24.0;
    final double chartWidth = size.width - paddingLeft;
    final double chartHeight = size.height - paddingBottom;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final textStyle = const TextStyle(fontSize: 10, color: Color(0xFF94A3B8));

    // Draw Y-Axis Gridlines (2, 4, 6, 8, 10)
    for (int i = 0; i <= 5; i++) {
      final double y = chartHeight - (i * chartHeight / 5);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width, y), gridPaint);

      final textSpan = TextSpan(text: '${i * 2}', style: textStyle);
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(paddingLeft - 20, y - 6));
    }

    // Data points
    final sems = [
      'Sem I',
      'Sem II',
      'Sem III',
      'Sem IV',
      'Sem V',
      'Sem VI',
      'Sem VII',
      'Sem VIII',
    ];
    final values = [6.85, 7.32, 7.95, 8.20, 9.10, 8.72];

    final double xStep = chartWidth / (sems.length - 1);
    final List<Offset> points = [];

    for (int i = 0; i < values.length; i++) {
      final double x = paddingLeft + (i * xStep);
      final double y = chartHeight - (values[i] / 10.0 * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw Gradient Area under Line
    if (points.isNotEmpty) {
      final Path fillPath = Path();
      fillPath.moveTo(points.first.dx, chartHeight);
      for (var p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2563EB).withOpacity(0.15),
            const Color(0xFF2563EB).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw Blue Line
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw Points & Labels
    final dotPaint = Paint()..color = const Color(0xFF2563EB);
    final innerDotPaint = Paint()..color = Colors.white;
    final valStyle = const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1E293B),
    );

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, dotPaint);
      canvas.drawCircle(points[i], 2.5, innerDotPaint);

      // Value label on top
      final tpVal = TextPainter(
        text: TextSpan(text: values[i].toStringAsFixed(2), style: valStyle),
        textDirection: TextDirection.ltr,
      );
      tpVal.layout();
      tpVal.paint(canvas, Offset(points[i].dx - 12, points[i].dy - 16));
    }

    // Draw X-Axis Labels
    for (int i = 0; i < sems.length; i++) {
      final double x = paddingLeft + (i * xStep);
      final tpSem = TextPainter(
        text: TextSpan(text: sems[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tpSem.layout();
      tpSem.paint(canvas, Offset(x - 12, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── CUSTOM PAINTER 2: Subject-wise Attendance Bar Chart ──
class _SubjectAttendancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = 30.0;
    final double paddingBottom = 40.0;
    final double chartWidth = size.width - paddingLeft;
    final double chartHeight = size.height - paddingBottom;

    final subjects = [
      'Digital Signal\nProcessing',
      'Internet of\nThings',
      'Communication\nSystems',
      'VLSI Design',
      'Computer\nNetworks',
      'Data Structures',
    ];
    final atts = [96, 91, 88, 95, 86, 82];
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF9333EA),
      const Color(0xFF06B6D4),
      const Color(0xFFEF4444),
    ];

    final double groupWidth = chartWidth / subjects.length;
    final double barWidth = 16.0;

    // Draw 75% Dashed Minimum Line
    final double y75 = chartHeight - (0.75 * chartHeight);
    final dashPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double dashWidth = 5, dashSpace = 3, startX = paddingLeft;
    while (startX < size.width - 70) {
      canvas.drawLine(
        Offset(startX, y75),
        Offset(startX + dashWidth, y75),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }

    final dashTextSpan = TextSpan(
      text: '--- 75% Minimum',
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: Color(0xFFEF4444),
      ),
    );
    final tpDash = TextPainter(
      text: dashTextSpan,
      textDirection: TextDirection.ltr,
    );
    tpDash.layout();
    tpDash.paint(canvas, Offset(size.width - 68, y75 - 6));

    // Draw Bars
    for (int i = 0; i < subjects.length; i++) {
      final double xCenter = paddingLeft + (i * groupWidth) + (groupWidth / 2);
      final double barHeight = (atts[i] / 100.0) * chartHeight;
      final double top = chartHeight - barHeight;

      final RRect barRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xCenter - (barWidth / 2), top, barWidth, barHeight),
        const Radius.circular(4),
      );

      final barPaint = Paint()..color = colors[i];
      canvas.drawRRect(barRRect, barPaint);

      // Percentage label top
      final tpVal = TextPainter(
        text: TextSpan(
          text: '${atts[i]}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colors[i],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tpVal.layout();
      tpVal.paint(canvas, Offset(xCenter - 10, top - 14));

      // Subject label bottom
      final tpSub = TextPainter(
        text: TextSpan(
          text: subjects[i],
          style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tpSub.layout(maxWidth: groupWidth);
      tpSub.paint(canvas, Offset(xCenter - (tpSub.width / 2), chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── CUSTOM PAINTER 3: Internal Mark Distribution Grouped Bar Chart ──
class _InternalMarkDistributionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = 30.0;
    final double paddingBottom = 30.0;
    final double chartWidth = size.width - paddingLeft;
    final double chartHeight = size.height - paddingBottom;

    final subjects = [
      'Digital Signal\nProcessing',
      'Internet of\nThings',
      'Communication\nSystems',
      'VLSI Design',
      'Computer\nNetworks',
      'Data Structures',
    ];
    final ia1 = [78, 70, 68, 88, 65, 60];
    final ia2 = [85, 81, 76, 95, 72, 70];
    final model = [91, 87, 78, 98, 78, 75];

    final double groupWidth = chartWidth / subjects.length;
    final double barWidth = 8.0;

    for (int i = 0; i < subjects.length; i++) {
      final double groupStart =
          paddingLeft +
          (i * groupWidth) +
          (groupWidth - (barWidth * 3 + 8)) / 2;

      final double h1 = (ia1[i] / 100.0) * chartHeight;
      final double h2 = (ia2[i] / 100.0) * chartHeight;
      final double h3 = (model[i] / 100.0) * chartHeight;

      // Bar 1 (IA 1 - Blue)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(groupStart, chartHeight - h1, barWidth, h1),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF2563EB),
      );

      // Bar 2 (IA 2 - Teal)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            groupStart + barWidth + 2,
            chartHeight - h2,
            barWidth,
            h2,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF10B981),
      );

      // Bar 3 (Model - Purple)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            groupStart + (barWidth + 2) * 2,
            chartHeight - h3,
            barWidth,
            h3,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF9333EA),
      );

      // Label top of Model bar
      final tpVal = TextPainter(
        text: TextSpan(
          text: '${model[i]}',
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tpVal.layout();
      tpVal.paint(canvas, Offset(groupStart + barWidth, chartHeight - h3 - 12));

      // Subject label bottom
      final tpSub = TextPainter(
        text: TextSpan(
          text: subjects[i],
          style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tpSub.layout(maxWidth: groupWidth);
      tpSub.paint(canvas, Offset(groupStart - 6, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── CUSTOM PAINTER 4: Marks Distribution Histogram ──
class _MarksHistogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = 30.0;
    final double paddingBottom = 30.0;
    final double chartWidth = size.width - paddingLeft;
    final double chartHeight = size.height - paddingBottom;

    final ranges = ['90-100', '80-89', '70-79', '60-69', '50-59', 'Below 50'];
    final counts = [5, 9, 6, 2, 1, 0];
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF2563EB),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFF94A3B8),
    ];

    final double groupWidth = chartWidth / ranges.length;
    final double barWidth = 20.0;

    for (int i = 0; i < ranges.length; i++) {
      final double xCenter = paddingLeft + (i * groupWidth) + (groupWidth / 2);
      final double barHeight = (counts[i] / 12.0) * chartHeight;
      final double top = chartHeight - barHeight;

      if (counts[i] > 0) {
        final RRect barRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(xCenter - (barWidth / 2), top, barWidth, barHeight),
          const Radius.circular(4),
        );
        canvas.drawRRect(barRRect, Paint()..color = colors[i]);

        // Value top label
        final tpVal = TextPainter(
          text: TextSpan(
            text: '${counts[i]}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors[i],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tpVal.layout();
        tpVal.paint(canvas, Offset(xCenter - 4, top - 14));
      }

      // Range label bottom
      final tpRange = TextPainter(
        text: TextSpan(
          text: ranges[i],
          style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
        ),
        textDirection: TextDirection.ltr,
      );
      tpRange.layout();
      tpRange.paint(
        canvas,
        Offset(xCenter - (tpRange.width / 2), chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
