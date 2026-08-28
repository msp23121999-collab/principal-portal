import 'package:flutter/material.dart';
import '../models/hod_models.dart';
import '../theme.dart';
import '../export_dialog_helper.dart';
import '../hod_toast.dart';
import '../../faculty/services/postgres_client.dart';
import '../../faculty/services/profile_service.dart';

class DepartmentModuleView extends StatefulWidget {
  final int initialTabIndex;
  final List<FacultyMember> facultyList;
  final List<StudentItem> studentList;
  final List<CourseItem> courseList;

  const DepartmentModuleView({
    super.key,
    this.initialTabIndex = 0,
    required this.facultyList,
    required this.studentList,
    required this.courseList,
  });

  @override
  State<DepartmentModuleView> createState() => _DepartmentModuleViewState();
}

class _DepartmentModuleViewState extends State<DepartmentModuleView> {
  List<Map<String, dynamic>> _dbFacultyList = [];
  List<Map<String, dynamic>> _dbRegulationsList = [];
  List<Map<String, dynamic>> _dbCourseAllocationsList = [];
  List<Map<String, dynamic>> _myTeachingCoursesList = [];
  List<Map<String, dynamic>> _dbStudentList = [];
  String _hodDeptCode = 'CSE';

  @override
  void initState() {
    super.initState();
    _initHodDeptCode();
  }

  /// Extract short dept code (e.g. 'CSE') from profile or full name string.
  String _extractDeptCode(String raw) {
    // If it matches a known short code directly, return it
    final knownCodes = [
      'CSE',
      'IT',
      'ECE',
      'EEE',
      'MECH',
      'CIVIL',
      'IOT',
      'AIDS',
      'MBA',
      'MCA',
    ];
    final upper = raw.trim().toUpperCase();
    if (knownCodes.contains(upper)) return upper;
    // Try to extract code from inside parentheses e.g. "Computer Science & Engineering (CSE)"
    final parenMatch = RegExp(r'\(([A-Z]+)\)').firstMatch(raw);
    if (parenMatch != null) return parenMatch.group(1)!.toUpperCase();
    // Try DEPT_ or DEP- prefix patterns
    final clean = upper
        .replaceAll('DEPT_', '')
        .replaceAll('DEP-', '')
        .split('-')
        .first
        .split('_')
        .first;
    if (knownCodes.contains(clean)) return clean;
    return 'CSE';
  }

  Future<void> _initHodDeptCode() async {
    final profile = ProfileService.get();

    // Prefer the short departmentId from profile (e.g. 'CSE')
    final profileDeptId = profile['departmentId']?.toString() ?? '';
    if (profileDeptId.isNotEmpty) {
      _hodDeptCode = _extractDeptCode(profileDeptId);
    } else {
      // Fallback: extract from full department name
      final profileDept = profile['department']?.toString() ?? 'CSE';
      _hodDeptCode = _extractDeptCode(profileDept);
    }

    // Also try DB lookup to get authoritative code
    try {
      final employeeId =
          profile['employeeId'] ?? profile['facultyId'] ?? 'EMP-CSE-010';
      final facultyRows = await SupabaseClientHelper.select(
        'faculties',
        schema: 'faculty',
        filterColumn: 'employee_id',
        filterValue: employeeId,
      );
      if (facultyRows.isNotEmpty) {
        final raw =
            facultyRows.first['department']?.toString() ??
            facultyRows.first['code']?.toString() ??
            '';
        if (raw.isNotEmpty) {
          _hodDeptCode = _extractDeptCode(raw);
        }
      }
    } catch (e) {
      debugPrint('Error resolving HOD dept: $e');
    }

    debugPrint('HOD dept code resolved to: $_hodDeptCode');
    _fetchSupabaseFaculties();
    _fetchSupabaseStudents();
    _fetchRegulationsAndAllocations();
  }

  Future<void> _fetchSupabaseStudents() async {
    try {
      var rows = await SupabaseClientHelper.select(
        'students',
        schema: 'public',
      );
      if (rows.isEmpty) {
        rows = await SupabaseClientHelper.select(
          'attendance_table',
          schema: 'student',
        );
      }
      final hodCode = _hodDeptCode.trim().toUpperCase();
      rows = rows.where((row) {
        final departmentValues = [
          row['code'],
          row['department'],
          row['department_id'],
          row['dept'],
        ].whereType<String>().map((value) => value.trim().toUpperCase());
        return departmentValues.any(
          (department) => department == hodCode || department.contains(hodCode),
        );
      }).toList();
      if (mounted) setState(() => _dbStudentList = rows);
    } catch (e) {
      debugPrint('Error fetching students: $e');
    }
  }

  Future<void> _fetchSupabaseFaculties() async {
    try {
      var rows = await SupabaseClientHelper.select(
        'faculties',
        schema: 'faculty',
      );

      var filteredRows = rows.where((r) {
        final departmentValues = [
          r['code'],
          r['department'],
          r['department_id'],
        ].whereType<String>().map((value) => value.trim().toUpperCase());
        final hodCode = _hodDeptCode.trim().toUpperCase();
        return departmentValues.any(
          (department) => department == hodCode || department.contains(hodCode),
        );
      }).toList();

      List<Map<String, dynamic>> timetables = [];
      List<Map<String, dynamic>> allocations = [];
      try {
        timetables = await SupabaseClientHelper.select(
          'class_timetables',
          schema: 'timetable',
        );
      } catch (e) {
        debugPrint('Error fetching class_timetables for workload: $e');
      }
      try {
        allocations = await SupabaseClientHelper.select(
          'faculty_course_allocations',
          schema: 'faculty',
        );
      } catch (e) {
        debugPrint(
          'Error fetching faculty_course_allocations for workload: $e',
        );
      }

      final Map<String, String> courseToFaculty = {};
      for (final a in allocations) {
        final courseCode = (a['course_code'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
        final facultyId = (a['faculty_employee_id'] ?? '')
            .toString()
            .trim()
            .toUpperCase()
            .replaceAll('-', '_');
        if (courseCode.isNotEmpty && facultyId.isNotEmpty) {
          courseToFaculty[courseCode] = facultyId;
        }
      }

      final Map<String, int> facultyWorkload = {};
      for (final row in timetables) {
        final status = (row['status'] ?? '').toString().trim().toLowerCase();
        if (status != 'confirmed') continue;
        for (int p = 1; p <= 8; p++) {
          final code = (row['p${p}_code'] ?? '')
              .toString()
              .trim()
              .toUpperCase();
          if (code.isNotEmpty) {
            final facId = courseToFaculty[code];
            if (facId != null) {
              facultyWorkload[facId] = (facultyWorkload[facId] ?? 0) + 1;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _dbFacultyList = filteredRows.map((r) {
            final name =
                r['full_name']?.toString() ??
                r['name']?.toString() ??
                'Faculty Member';
            final cleanName = name
                .replaceAll(RegExp(r'^(Dr\.|Prof\.|Mr\.|Ms\.|Mrs\.)\s*'), '')
                .trim();
            final parts = cleanName.split(' ');
            final initials = parts
                .take(2)
                .map((w) => w.isNotEmpty ? w[0] : '')
                .join()
                .toUpperCase();
            final empId =
                r['employee_id']?.toString() ?? r['id']?.toString() ?? 'FAC01';

            return {
              'name': name,
              'id': empId,
              'designation': r['designation']?.toString() ?? 'Faculty',
              'department':
                  r['department']?.toString() ??
                  r['department_id']?.toString() ??
                  _hodDeptCode,
              'qualification': r['qualification']?.toString() ?? 'Ph.D.',
              'subjects':
                  r['assigned_subjects'] is List &&
                      (r['assigned_subjects'] as List).isNotEmpty
                  ? '${(r['assigned_subjects'] as List).length} Subjects'
                  : '1 Subject',
              'subjectsSubtitle':
                  r['assigned_subjects'] is List &&
                      (r['assigned_subjects'] as List).isNotEmpty
                  ? '(${(r['assigned_subjects'] as List).join(", ")})'
                  : '(24${_hodDeptCode}T31)',
              'publications': '${r['publication_count'] ?? 10} Papers',
              'status': r['status']?.toString() == 'Active'
                  ? 'Present'
                  : (r['status']?.toString() ?? 'Present'),
              'avatarText': initials.isEmpty ? 'FA' : initials,
              'avatarBg': const Color(0xFFEFF6FF),
              'avatarFg': const Color(0xFF2563EB),
              'workload': facultyWorkload[empId] ?? 0,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching faculty list from Supabase: $e');
    }
  }

  Future<void> _fetchRegulationsAndAllocations() async {
    try {
      // Fetch regulations list strictly from public.regulations table
      final regs = await SupabaseClientHelper.select(
        'regulations',
        schema: 'public',
      );

      List<Map<String, dynamic>> allocs = [];
      try {
        allocs = await SupabaseClientHelper.select(
          'faculty_course_allocations',
          schema: 'faculty',
        );
      } catch (_) {}

      final filteredRegs = regs.where((r) {
        final dept = (r['department'] ?? '').toString().toUpperCase();
        return dept == _hodDeptCode.toUpperCase() ||
            dept.contains(_hodDeptCode.toUpperCase());
      }).toList();

      final filteredAllocs = allocs.where((a) {
        final dept = (a['department'] ?? '').toString().toUpperCase();
        return dept == _hodDeptCode.toUpperCase() ||
            dept.contains(_hodDeptCode.toUpperCase());
      }).toList();

      final targetRegs = filteredRegs;

      final Map<String, String> facNames = {};
      try {
        final facs = await SupabaseClientHelper.select(
          'faculties',
          schema: 'faculty',
        );
        for (final f in facs) {
          final empId = (f['employee_id'] ?? f['id'] ?? '').toString();
          final name = (f['full_name'] ?? f['name'] ?? '').toString();
          if (empId.isNotEmpty && name.isNotEmpty) {
            facNames[empId] = name;
          }
        }
      } catch (_) {}

      if (targetRegs.isNotEmpty && mounted) {
        setState(() {
          _dbRegulationsList = targetRegs;
          _dbCourseAllocationsList = filteredAllocs;

          // Map dynamic teaching courses for the logged-in HOD
          final profile = ProfileService.get();
          final employeeId =
              profile['employeeId'] ?? profile['facultyId'] ?? 'EMP-CSE-010';

          final myAllocs = filteredAllocs
              .where(
                (a) =>
                    a['faculty_employee_id']?.toString().toUpperCase() ==
                    employeeId.toUpperCase(),
              )
              .toList();

          final List<Map<String, dynamic>> resolvedMyCourses = [];
          for (final a in myAllocs) {
            final code = (a['course_code'] ?? '').toString().trim();
            if (code.isEmpty) continue;

            final reg = targetRegs.firstWhere(
              (r) => (r['course_code'] ?? '').toString().trim() == code,
              orElse: () => <String, dynamic>{},
            );

            final cName = (reg['course_name'] ?? 'Theory/Lab Course')
                .toString();
            final credits = (reg['credits'] ?? '3.0').toString();
            final cType = (reg['course_type'] ?? 'Theory').toString();
            final sem = (reg['semester'] ?? 'V').toString();
            final sec = (a['section'] ?? 'A').toString();

            resolvedMyCourses.add({
              'code': code,
              'name': cName,
              'subtext': '$cType Course',
              'credits': '$credits Credits',
              'semesterSec': 'Sem $sem - Sec $sec',
              'students': '60 Students',
              'attendance': '95.0%',
              'attendanceText': 'Excellent',
              'syllabus': '80% (Unit 4/5)',
              'progress': 0.80,
              'diary': 'Updated Up to Date',
            });
          }
          _myTeachingCoursesList = resolvedMyCourses;

          for (final r in targetRegs) {
            final code = (r['course_code'] ?? '').toString().trim();
            if (code.isNotEmpty) {
              final alloc = filteredAllocs.firstWhere(
                (a) => (a['course_code'] ?? '').toString().trim() == code,
                orElse: () => <String, dynamic>{},
              );
              if (alloc.isNotEmpty) {
                final empId = (alloc['faculty_employee_id'] ?? '').toString();
                final fName =
                    (alloc['assigned_fac_name'] ??
                            facNames[empId] ??
                            alloc['faculty_name'] ??
                            empId)
                        .toString();
                if (fName.isNotEmpty) {
                  _subjectFacultyAssignments[code] = '$fName (14 Hrs)';
                }
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching regulations & allocations: $e');
    }
  }

  Future<void> _onFacultyAllocationChanged(
    BuildContext context,
    String code,
    String subjectName,
    String newVal,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text(
              'Confirm Subject Allocation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          newVal == 'Not Allocated (Clear)'
              ? 'Are you sure you want to deallocate the assigned faculty from $code ($subjectName)?'
              : 'Are you sure you want to assign "$newVal" to $code ($subjectName)?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Confirm Update',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _subjectFacultyAssignments[code] = newVal;
    });

    if (newVal == 'Not Allocated (Clear)') {
      final existing = _dbCourseAllocationsList.firstWhere(
        (a) => (a['course_code'] ?? '').toString().trim() == code,
        orElse: () => <String, dynamic>{},
      );
      if (existing.isNotEmpty && existing['id'] != null) {
        await SupabaseClientHelper.delete(
          'faculty_course_allocations',
          'id',
          existing['id'].toString(),
          schema: 'faculty',
        );
      }
      if (context.mounted) {
        HodToast.show(
          context,
          message: 'Deallocated faculty from $code in database.',
          isError: true,
        );
      }
    } else {
      String cleanName = newVal
          .replaceAll(RegExp(r'\s*\([\d/]+(?:\s*Hrs)?\)'), '')
          .trim();
      String empId = 'EMP_CSE_001';
      for (final f in _dbFacultyList) {
        final name = (f['name'] ?? f['full_name'] ?? '').toString();
        if (name.contains(cleanName) || cleanName.contains(name)) {
          empId = (f['employee_id'] ?? f['id'] ?? '').toString();
          cleanName = name;
          break;
        }
      }

      final existing = _dbCourseAllocationsList.firstWhere(
        (a) => (a['course_code'] ?? '').toString().trim() == code,
        orElse: () => <String, dynamic>{},
      );

      if (existing.isNotEmpty && existing['id'] != null) {
        await SupabaseClientHelper.update(
          'faculty_course_allocations',
          {'faculty_employee_id': empId, 'assigned_fac_name': cleanName},
          'id',
          existing['id'].toString(),
          schema: 'faculty',
        );
      } else {
        await SupabaseClientHelper.insert('faculty_course_allocations', {
          'course_code': code,
          'faculty_employee_id': empId,
          'assigned_fac_name': cleanName,
          'department': _hodDeptCode,
          'section': 'A',
          'academic_year': '2025-2026',
          'regulation_year': 'R2024',
        }, schema: 'faculty');
      }

      if (context.mounted) {
        HodToast.show(
          context,
          message:
              'Assigned $cleanName to $code in faculty.faculty_course_allocations.',
          isSuccess: true,
        );
      }
    }

    _fetchRegulationsAndAllocations();
  }

  // Faculty search & filters
  String _facultySearchQuery = '';
  String _selectedDesignation = 'All Designations';
  String _selectedStatus = 'All Status';

  // Student search & filters
  String _studentSearchQuery = '';
  String _selectedFilterYear = 'All';
  String _selectedFilterSection = 'All';
  String _selectedFilterFeeStatus = 'All';
  String _selectedFilterAttendance = 'All';

  // Course sub-tabs (Image 1, 2, 3)
  int _courseSubTab =
      0; // 0: Course Management, 1: Subject Allocation, 2: My Courses

  // Course Management sub-tab filters
  String _courseQuery = '';
  String _courseSemester = 'All';
  String _courseFaculty = 'All';
  String _courseStatus = 'All';

  // Subject Allocation sub-tab filters & assignments
  String _allocationBatch = 'Batch 2022 - 2026 (Year IV)';
  String _allocationQuery = '';
  String _allocationStatus = 'All';

  // Faculty mapping for subject assignment dropdown
  final Map<String, String> _subjectFacultyAssignments = {
    'CS8402': 'Dr. K. Ravichandran (18 Hrs)',
    'IOT2031': 'Not Allocated (Clear)',
    'IOT2032': 'Prof. Muthukumaran (12/16 Hrs)',
    'IOT2033': 'Dr. S. Karthi (14/14 Hrs)',
    'IOT2034': 'Not Allocated (Clear)',
  };

  // My Courses sub-tab filters
  String _myCoursesQuery = '';
  String _myCoursesSemester = 'All';
  String _myCoursesSection = 'All';
  String _myCoursesAttendance = 'All';
  String _myCoursesStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Breadcrumb
          if (widget.initialTabIndex == 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Course Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _courseSubTab == 0
                          ? 'Department > Course Management > Course Directory'
                          : _courseSubTab == 1
                          ? 'Department > Course Management > Subject Allocation'
                          : 'Department > Course Management > My Courses',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, color: Color(0xFF2563EB), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Academic Year 2025 - 2026',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Department Central Management Module',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Department > Overview (Faculty, Students & Courses)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Tab View Body
          if (widget.initialTabIndex == 0)
            _buildFacultySubmodule(context)
          else if (widget.initialTabIndex == 1)
            _buildStudentsSubmodule(context)
          else
            _buildCoursesSubmodule(context),
        ],
      ),
    );
  }

  // 1. FACULTY SUBMODULE (Matching image exactly)
  Widget _buildFacultySubmodule(BuildContext context) {
    // 3 Bento KPI Cards
    Widget kpiGrid = LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = (availableWidth / 260).floor().clamp(1, 3);
        final double itemHeight = 112.0;
        final double spacing = 12.0;
        final double itemWidth =
            (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
        final double aspectRatio = itemWidth / itemHeight;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
          children: [
            _buildFacultyKpiCard(
              title: 'Total Faculty',
              value: _dbFacultyList.length.toString(),
              subtitle: 'Faculty records',
              icon: Icons.people_alt_rounded,
              iconColor: const Color(0xFF2563EB),
              iconBgColor: const Color(0xFFEFF6FF),
            ),
            _buildFacultyKpiCard(
              title: 'Faculty Present Today',
              value: _dbFacultyList
                  .where(
                    (f) =>
                        (f['status'] ?? '').toString().toLowerCase() ==
                        'active',
                  )
                  .length
                  .toString(),
              subtitle: 'Active faculty',
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF16A34A),
              iconBgColor: const Color(0xFFDCFCE7),
            ),
            _buildFacultyKpiCard(
              title: 'Faculty on Leave',
              value: '0',
              subtitle: 'No leave data',
              icon: Icons.person_remove_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBgColor: const Color(0xFFFEE2E2),
            ),
          ],
        );
      },
    );

    // Use only records returned by PostgreSQL.
    final targetFacultyData = _dbFacultyList;
    // Filter faculty data
    final filteredData = targetFacultyData.where((f) {
      final nameMatches =
          f['name'].toLowerCase().contains(_facultySearchQuery.toLowerCase()) ||
          f['id'].toLowerCase().contains(_facultySearchQuery.toLowerCase()) ||
          f['subjectsSubtitle'].toLowerCase().contains(
            _facultySearchQuery.toLowerCase(),
          );

      final designationMatches =
          _selectedDesignation == 'All Designations' ||
          f['designation'] == _selectedDesignation;

      final statusMatches =
          _selectedStatus == 'All Status' || f['status'] == _selectedStatus;

      return nameMatches && designationMatches && statusMatches;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kpiGrid,
        const SizedBox(height: 18),

        // Table & Search Filter Box
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
                // Title and Filters row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 950;

                    Widget titleWidget = const Text(
                      'Faculty Directory & Workload Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    );

                    Widget filterRow = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search Box
                        SizedBox(
                          width: 240,
                          height: 38,
                          child: TextField(
                            onChanged: (val) =>
                                setState(() => _facultySearchQuery = val),
                            decoration: InputDecoration(
                              hintText:
                                  'Search faculty by name, ID or subjec...',
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Designations Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedDesignation,
                              items:
                                  [
                                        'All Designations',
                                        'Head of Department',
                                        'Associate Professor',
                                        'Assistant Professor',
                                      ]
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(
                                            d,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedDesignation = val!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              items: ['All Status', 'Present', 'On Leave']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedStatus = val!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        HodExportDialog.buildExportButton(
                          context,
                          onPressed: () => HodExportDialog.show(
                            context,
                            title: 'Export Faculty Directory Data',
                            subtitle:
                                'Select export format for Faculty Directory records:',
                            moduleName: 'Faculty Directory',
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleWidget,
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: filterRow,
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [titleWidget, filterRow],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Data Table with headers (full width)
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
                          columnSpacing: 34,
                          horizontalMargin: 12,
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 56,
                          columns: [
                            _buildSortableColumn('Faculty Name & ID'),
                            _buildSortableColumn('Designation'),
                            _buildSortableColumn('Department'),
                            const DataColumn(
                              label: Text(
                                'Qualification',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Assigned Subjects',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Workload',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Publications',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'View Profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                          rows: filteredData.map((f) {
                            final isPresent = f['status'] == 'Present';

                            return DataRow(
                              cells: [
                                // Name & ID
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: f['avatarBg'],
                                        child: Text(
                                          f['avatarText'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: f['avatarFg'],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            f['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            f['id'],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Designation
                                DataCell(
                                  Text(
                                    f['designation'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                // Department
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEFF6FF,
                                      ), // blue badge background
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'IoT Department',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                                // Qualification
                                DataCell(
                                  Text(
                                    f['qualification'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                // Assigned Subjects
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        f['subjects'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        f['subjectsSubtitle'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Workload (periods count)
                                DataCell(
                                  Text(
                                    '${f['workload'] ?? 0} Periods',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                // Publications
                                DataCell(
                                  Text(
                                    f['publications'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                // Status
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? const Color(
                                              0xFFDCFCE7,
                                            ) // Present green bg
                                          : const Color(
                                              0xFFFEE2E2,
                                            ), // Leave red bg
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: isPresent
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFDC2626),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isPresent ? 'Present' : 'On Leave',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isPresent
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // View Profile
                                DataCell(
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      HodToast.show(
                                        context,
                                        message:
                                            'Viewing profile for ${f['name']}...',
                                        isSuccess: true,
                                      );
                                    },
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper sort columns
  DataColumn _buildSortableColumn(String label) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.swap_vert_rounded,
            size: 14,
            color: Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    String? trend,
    Color? trendColor,
    Color? trendBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          if (trend != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendBgColor ?? const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: trendColor ?? const Color(0xFF15803D),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStyledFilterDropdown({
    required String prefix,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF64748B),
            size: 18,
          ),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Row(
                children: [
                  Text(
                    '$prefix: ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    item,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Text(
                    '$prefix: ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    item,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }

  // 2. STUDENTS SUBMODULE
  Widget _buildStudentsSubmodule(BuildContext context) {
    final targetStudentData = _dbStudentList.map(_studentRow).toList();

    // Filter students
    final filteredStudents = targetStudentData.where((s) {
      final query = _studentSearchQuery.toLowerCase();
      final nameMatches =
          s['name'].toLowerCase().contains(query) ||
          s['rollNo'].toLowerCase().contains(query) ||
          s['regNo'].toLowerCase().contains(query);

      final yearMatches =
          _selectedFilterYear == 'All' || s['year'] == _selectedFilterYear;
      final sectionMatches =
          _selectedFilterSection == 'All' ||
          s['section'] == _selectedFilterSection;
      final feeMatches =
          _selectedFilterFeeStatus == 'All' ||
          s['feeStatus'] == _selectedFilterFeeStatus;

      bool attendanceMatches = true;
      if (_selectedFilterAttendance == 'Low (<75%)') {
        attendanceMatches = s['attendance'] < 75.0;
      } else if (_selectedFilterAttendance == 'Good (>=75%)') {
        attendanceMatches = s['attendance'] >= 75.0;
      }

      return nameMatches &&
          yearMatches &&
          sectionMatches &&
          feeMatches &&
          attendanceMatches;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final crossAxisCount = (availableWidth / 260).floor().clamp(1, 3);
            final double itemHeight = 135.0;
            final double spacing = 12.0;
            final double itemWidth =
                (availableWidth - (crossAxisCount - 1) * spacing) /
                crossAxisCount;
            final double aspectRatio = itemWidth / itemHeight;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
              children: [
                _buildStudentKpiCard(
                  title: 'Total Students',
                  value: targetStudentData.length.toString(),
                  subtitle: 'Database records',
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFEFF6FF),
                ),
                _buildStudentKpiCard(
                  title: 'Present Today',
                  value: targetStudentData
                      .where((s) => s['attendance'] > 0)
                      .length
                      .toString(),
                  subtitle: 'Attendance records',
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF16A34A),
                  iconBgColor: const Color(0xFFDCFCE7),
                  trend: '▲ 2.3%',
                  trendColor: const Color(0xFF15803D),
                  trendBgColor: const Color(0xFFDCFCE7),
                ),
                _buildStudentKpiCard(
                  title: 'Low Attendance',
                  value: targetStudentData
                      .where((s) => s['attendance'] > 0 && s['attendance'] < 75)
                      .length
                      .toString(),
                  subtitle: '< 75% Alert Level',
                  icon: Icons.warning_rounded,
                  iconColor: const Color(0xFFDC2626),
                  iconBgColor: const Color(0xFFFEE2E2),
                  trend: '▲ 1.1%',
                  trendColor: const Color(0xFFB91C1C),
                  trendBgColor: const Color(0xFFFEE2E2),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Table & Search Filter Box
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
                // Title and Filters row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 1200;

                    Widget titleWidget = const Text(
                      'Student Directory & Academic Register',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    );

                    Widget filtersWidget = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Year filter dropdown
                        _buildStyledFilterDropdown(
                          prefix: 'Year',
                          value: _selectedFilterYear,
                          items: [
                            'All',
                            '1st Year',
                            '2nd Year',
                            '3rd Year',
                            '4th Year',
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedFilterYear = val),
                        ),
                        const SizedBox(width: 8),

                        // Section filter dropdown
                        _buildStyledFilterDropdown(
                          prefix: 'Section',
                          value: _selectedFilterSection,
                          items: ['All', 'Section A', 'Section B', 'Section C'],
                          onChanged: (val) =>
                              setState(() => _selectedFilterSection = val),
                        ),
                        const SizedBox(width: 8),

                        // Fee Status filter dropdown
                        _buildStyledFilterDropdown(
                          prefix: 'Fee Status',
                          value: _selectedFilterFeeStatus,
                          items: ['All', 'Paid', 'Pending', 'Defaulter'],
                          onChanged: (val) =>
                              setState(() => _selectedFilterFeeStatus = val),
                        ),
                        const SizedBox(width: 8),

                        // Attendance filter dropdown
                        _buildStyledFilterDropdown(
                          prefix: 'Attendance',
                          value: _selectedFilterAttendance,
                          items: ['All', 'Low (<75%)', 'Good (>=75%)'],
                          onChanged: (val) =>
                              setState(() => _selectedFilterAttendance = val),
                        ),
                        const SizedBox(width: 8),

                        // Search Field
                        SizedBox(
                          width: 200,
                          height: 38,
                          child: TextField(
                            onChanged: (val) =>
                                setState(() => _studentSearchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search Reg No, Name...',
                              hintStyle: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        HodExportDialog.buildExportButton(
                          context,
                          onPressed: () => HodExportDialog.show(
                            context,
                            title: 'Export Student Directory Data',
                            subtitle:
                                'Select export format for Student Directory records:',
                            moduleName: 'Student Directory',
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleWidget,
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: filtersWidget,
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          titleWidget,
                          const SizedBox(width: 16),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: filtersWidget,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Table
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
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Roll No & Reg No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Student Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Class & Section',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Assigned Mentor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Attendance %',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Fee Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'View Profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                          rows: filteredStudents.map((s) {
                            // Section color coding
                            final bool isSecA = s['section'] == 'Section A';
                            final sectionBg = isSecA
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF0FDF4);
                            final sectionFg = isSecA
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF16A34A);

                            // Attendance color coding
                            final attendance = s['attendance'] as double;
                            final isLowAttendance = attendance < 75.0;
                            final attendanceColor = isLowAttendance
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A);

                            // Fee Status color coding
                            final status = s['feeStatus'] as String;
                            Color statusBg;
                            Color statusFg;
                            Color dotColor;
                            if (status == 'Paid') {
                              statusBg = const Color(0xFFF0FDF4);
                              statusFg = const Color(0xFF16A34A);
                              dotColor = const Color(0xFF16A34A);
                            } else if (status == 'Pending') {
                              statusBg = const Color(0xFFFFFBEB);
                              statusFg = const Color(0xFFD97706);
                              dotColor = const Color(0xFFD97706);
                            } else {
                              statusBg = const Color(0xFFFEF2F2);
                              statusFg = const Color(0xFFDC2626);
                              dotColor = const Color(0xFFDC2626);
                            }

                            return DataRow(
                              cells: [
                                // Roll & Reg No (with Avatar)
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: s['avatarBg'],
                                        child: Text(
                                          s['avatarText'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: s['avatarFg'],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s['rollNo'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            s['regNo'],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Student Name
                                DataCell(
                                  Text(
                                    s['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),

                                // Class & Section
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sectionBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: sectionFg.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      s['yearSection'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: sectionFg,
                                      ),
                                    ),
                                  ),
                                ),

                                // Assigned Mentor
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s['mentor'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            s['mentorDept'],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Attendance % (with Progress Bar)
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${s['attendance']}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: attendanceColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 80,
                                        child: LinearProgressIndicator(
                                          value: attendance / 100,
                                          minHeight: 4,
                                          valueColor: AlwaysStoppedAnimation(
                                            attendanceColor,
                                          ),
                                          backgroundColor: const Color(
                                            0xFFE2E8F0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Fee Status (Pill with dot)
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: dotColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: statusFg,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Action Arrow
                                DataCell(
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: Color(0xFF2563EB),
                                    ),
                                    onPressed: () {
                                      final studentItem = StudentItem(
                                        rollNo: s['rollNo'],
                                        name: s['name'],
                                        yearSection: s['yearSection'],
                                        email:
                                            '${s['name'].replaceAll(' ', '').toLowerCase()}@ksr.edu.in',
                                        phone: '+91 98401 23456',
                                        status: s['feeStatus'],
                                      );
                                      _showStudentDetailsModal(
                                        context,
                                        studentItem,
                                      );
                                    },
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _studentRow(Map<String, dynamic> row) {
    final name = (row['full_name'] ?? row['name'] ?? 'null').toString();
    final attendance =
        double.tryParse(
          (row['attendance_percentage'] ?? row['attendance'] ?? '0').toString(),
        ) ??
        0;
    final year = (row['year_of_study'] ?? row['year'] ?? 'null').toString();
    final section = (row['section'] ?? 'null').toString();
    final fee =
        double.tryParse((row['pending_fees_total'] ?? '0').toString()) ?? 0;
    return {
      'rollNo':
          (row['roll_number'] ?? row['reg_no'] ?? row['roll_no'] ?? 'null')
              .toString(),
      'regNo':
          (row['register_number'] ??
                  row['reg_no'] ??
                  row['register_no'] ??
                  row['student_id'] ??
                  'null')
              .toString(),
      'name': name,
      'year': year,
      'section': section.startsWith('Section') ? section : 'Section $section',
      'yearSection': '$year - $section',
      'mentor': (row['class_advisor_name'] ?? 'null').toString(),
      'mentorDept': (row['department'] ?? row['department_id'] ?? 'null')
          .toString(),
      'attendance': attendance,
      'feeStatus': fee > 0 ? 'Pending' : 'Paid',
      'avatarText': name.isEmpty ? '?' : name[0].toUpperCase(),
      'avatarBg': const Color(0xFFEFF6FF),
      'avatarFg': const Color(0xFF2563EB),
    };
  }

  // 3. COURSES SUBMODULE
  Widget _buildCoursesSubmodule(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Tab Bar (as per image layout)
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSegmentTab(
                  0,
                  'Course Management',
                  Icons.menu_book_rounded,
                ),
                _buildSegmentTab(
                  1,
                  'Subject Allocation',
                  Icons.assignment_ind_outlined,
                ),
                _buildSegmentTab(2, 'My Courses', Icons.school_outlined),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sub Tab Body
        if (_courseSubTab == 0)
          _buildCourseManagementTab(context)
        else if (_courseSubTab == 1)
          _buildSubjectAllocationTab(context)
        else
          _buildMyCoursesTab(context),
      ],
    );
  }

  Widget _buildSegmentTab(int index, String label, IconData icon) {
    final bool isActive = _courseSubTab == index;
    return InkWell(
      onTap: () => setState(() => _courseSubTab = index),
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

  Widget _buildCourseManagementTab(BuildContext context) {
    // Dynamic list of courses from public.regulations database table
    final List<Map<String, dynamic>> allCourses = _dbRegulationsList.map((r) {
      final code = (r['course_code'] ?? '').toString().trim();
      final name = (r['course_name'] ?? '').toString().trim();
      final typeStr = (r['course_type'] ?? 'Theory').toString().trim();
      final creditsStr = (r['credits'] ?? '3.0').toString().trim();
      final semNum = r['semester'] != null
          ? 'Semester ${r['semester']}'
          : 'Semester IV';

      final alloc = _dbCourseAllocationsList.firstWhere(
        (a) => (a['course_code'] ?? '').toString().trim() == code,
        orElse: () => <String, dynamic>{},
      );

      String facName = 'Not Allocated';
      if (_subjectFacultyAssignments.containsKey(code) &&
          _subjectFacultyAssignments[code] != 'Not Allocated (Clear)') {
        facName = _subjectFacultyAssignments[code]!.split('(').first.trim();
      } else if (alloc.isNotEmpty) {
        final empId = (alloc['faculty_employee_id'] ?? '').toString();
        facName = empId;
      }

      final String avatarLetter =
          facName.isNotEmpty && facName != 'Not Allocated'
          ? facName
                .replaceAll(RegExp(r'^(Dr\.|Prof\.|Mr\.|Ms\.|Mrs\.)\s*'), '')
                .trim()
                .substring(0, 1)
                .toUpperCase()
          : 'N';

      return {
        'code': code,
        'name': name,
        'type': '$typeStr • $creditsStr Credits',
        'semester': semNum,
        'faculty': facName,
        'avatar': avatarLetter,
        'students': '120 Students',
        'progress': alloc.isNotEmpty ? 0.85 : 0.70,
        'status': 'Active',
      };
    }).toList();

    // Dynamic dropdown filter choices
    final Set<String> availableSemesters = {'Semester: All'};
    final Set<String> availableFaculties = {'Faculty: All'};
    for (final c in allCourses) {
      if (c['semester'] != null)
        availableSemesters.add(c['semester'].toString());
      if (c['faculty'] != null && c['faculty'] != 'Not Allocated')
        availableFaculties.add(c['faculty'].toString());
    }

    final currentSemVal =
        availableSemesters.contains(
          _courseSemester == 'All' ? 'Semester: All' : _courseSemester,
        )
        ? (_courseSemester == 'All' ? 'Semester: All' : _courseSemester)
        : 'Semester: All';
    final currentFacVal =
        availableFaculties.contains(
          _courseFaculty == 'All' ? 'Faculty: All' : _courseFaculty,
        )
        ? (_courseFaculty == 'All' ? 'Faculty: All' : _courseFaculty)
        : 'Faculty: All';

    // Filter logic
    final filtered = allCourses.where((c) {
      final matchesQuery =
          c['code'].toString().toLowerCase().contains(
            _courseQuery.toLowerCase(),
          ) ||
          c['name'].toString().toLowerCase().contains(
            _courseQuery.toLowerCase(),
          );
      final matchesSem =
          currentSemVal == 'Semester: All' || c['semester'] == currentSemVal;
      final matchesFac =
          currentFacVal == 'Faculty: All' || c['faculty'] == currentFacVal;
      final matchesStatus =
          _courseStatus == 'All' || c['status'] == _courseStatus;
      return matchesQuery && matchesSem && matchesFac && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                // Inner title and Export Report
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Courses & Progress Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    HodExportDialog.buildExportButton(
                      context,
                      onPressed: () => HodExportDialog.show(
                        context,
                        title: 'Export Courses & Progress Data',
                        subtitle:
                            'Select export format for Courses & Progress records:',
                        moduleName: 'Courses',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filters Row (Horizontal Scroll on Narrow)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 800;

                    final filters = [
                      // Search field
                      SizedBox(
                        width: isNarrow ? double.infinity : 220,
                        height: 38,
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _courseQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search Courses...',
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isNarrow) const SizedBox(width: 8),
                      // Semester dropdown
                      Container(
                        width: isNarrow ? double.infinity : 160,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentSemVal,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                            ),
                            items: availableSemesters
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _courseSemester = val == 'Semester: All'
                                      ? 'All'
                                      : val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      if (!isNarrow) const SizedBox(width: 8),
                      // Faculty dropdown
                      Container(
                        width: isNarrow ? double.infinity : 160,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentFacVal,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                            ),
                            items: availableFaculties
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _courseFaculty = val == 'Faculty: All'
                                      ? 'All'
                                      : val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      if (!isNarrow) const SizedBox(width: 8),
                      // Status dropdown
                      Container(
                        width: isNarrow ? double.infinity : 160,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _courseStatus == 'All'
                                ? 'Status: All'
                                : _courseStatus,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                            ),
                            items: ['Status: All', 'Active', 'Completed']
                                .map(
                                  (st) => DropdownMenuItem(
                                    value: st,
                                    child: Text(st),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _courseStatus = val == 'Status: All'
                                      ? 'All'
                                      : val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        children: filters
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: f,
                              ),
                            )
                            .toList(),
                      );
                    } else {
                      return Row(children: filters);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Table
                LayoutBuilder(
                  builder: (context, tableConstraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: tableConstraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF8FAFC),
                          ),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Course Code & Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Type & Credits',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Semester',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Faculty Assigned',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Enrolled Students',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Syllabus Completion',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          rows: filtered.map((c) {
                            final progressColor = c['progress'] >= 0.80
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B);
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${c['code']}: ${c['name']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    c['type'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    c['semester'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: const Color(
                                          0xFFF1F5F9,
                                        ),
                                        child: Text(
                                          c['avatar'],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c['faculty'],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    c['students'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: c['progress'],
                                            minHeight: 6,
                                            valueColor: AlwaysStoppedAnimation(
                                              progressColor,
                                            ),
                                            backgroundColor: const Color(
                                              0xFFE2E8F0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(c['progress'] * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: progressColor,
                                        ),
                                      ),
                                    ],
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectAllocationTab(BuildContext context) {
    // Dynamic subject list from public.regulations database table
    final List<Map<String, dynamic>> allocationSubjects = _dbRegulationsList
        .map((r) {
          final code = (r['course_code'] ?? '').toString().trim();
          final name = (r['course_name'] ?? '').toString().trim();
          final typeStr = (r['course_type'] ?? 'Theory').toString().trim();
          final creditsStr = (r['credits'] ?? '3.0').toString().trim();
          final semVal = (r['semester'] ?? 'N/A').toString().trim();

          return {
            'code': code,
            'name': name,
            'type': '$typeStr • $creditsStr Credits',
            'semester': semVal,
          };
        })
        .toList();

    // Calculate dynamic KPI values based on regulations state
    final totalSubjects = allocationSubjects.length;
    int allocatedSubjects = 0;
    for (final s in allocationSubjects) {
      final code = s['code'].toString();
      final currentAssignment =
          _subjectFacultyAssignments[code] ?? 'Not Allocated (Clear)';
      if (currentAssignment != 'Not Allocated (Clear)') {
        allocatedSubjects++;
      }
    }
    final pendingAllocation = totalSubjects - allocatedSubjects;

    // KPI Cards Grid (4 cards)
    Widget kpis = LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = (availableWidth / 220).floor().clamp(1, 4);
        final double itemHeight = 112.0;
        final double spacing = 12.0;
        final double itemWidth =
            (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
        final double aspectRatio = itemWidth / itemHeight;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
          children: [
            _buildLegacyKpiCard(
              'Total Subjects',
              '$totalSubjects',
              'In Active Batch',
              Icons.menu_book,
              const Color(0xFF2563EB),
            ),
            _buildLegacyKpiCard(
              'Allocated Subjects',
              '$allocatedSubjects',
              '$allocatedSubjects / $totalSubjects Assigned',
              Icons.check_circle,
              const Color(0xFF10B981),
            ),
            _buildLegacyKpiCard(
              'Pending Allocation',
              '$pendingAllocation',
              'Requires Immediate HOD Action',
              Icons.warning_amber_rounded,
              const Color(0xFFF59E0B),
            ),
            _buildLegacyKpiCard(
              'Dept Workload',
              '59 Hrs',
              'Total assigned out of 102 max limit',
              Icons.loop_rounded,
              const Color(0xFF8B5CF6),
            ),
          ],
        );
      },
    );

    final filtered = allocationSubjects.where((s) {
      final matchesQuery =
          s['code'].toString().toLowerCase().contains(
            _allocationQuery.toLowerCase(),
          ) ||
          s['name'].toString().toLowerCase().contains(
            _allocationQuery.toLowerCase(),
          );
      final currentAssignment =
          _subjectFacultyAssignments[s['code']] ?? 'Not Allocated (Clear)';
      final isAllocated = currentAssignment != 'Not Allocated (Clear)';
      final matchesStatus =
          _allocationStatus == 'All' ||
          (_allocationStatus == 'Allocated' && isAllocated) ||
          (_allocationStatus == 'Pending' && !isAllocated);
      return matchesQuery && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      final semA = int.tryParse(a['semester']?.toString() ?? '') ?? 0;
      final semB = int.tryParse(b['semester']?.toString() ?? '') ?? 0;
      if (semA != semB) {
        return semA.compareTo(semB);
      }
      final codeA = (a['code'] ?? '').toString();
      final codeB = (b['code'] ?? '').toString();
      return codeA.compareTo(codeB);
    });

    // Prepare dynamic faculty dropdown options
    final List<String> dropdownFacultyOptions = ['Not Allocated (Clear)'];
    if (_dbFacultyList.isNotEmpty) {
      for (final f in _dbFacultyList) {
        final fName = f['name'] ?? 'Faculty';
        if (!dropdownFacultyOptions.contains('$fName (14 Hrs)')) {
          dropdownFacultyOptions.add('$fName (14 Hrs)');
        }
      }
    } else {
      dropdownFacultyOptions.addAll([
        'Dr. K. Ravichandran (14 Hrs)',
        'Prof. Muthukumaran (12/16 Hrs)',
        'Dr. S. Karthi (14/14 Hrs)',
        'Prof. Ramakrishnan P (16/16 Hrs)',
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kpis,
        const SizedBox(height: 18),
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
                // Filters Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 800;

                    final filters = [
                      // Batch Dropdown
                      Container(
                        width: isNarrow ? double.infinity : 220,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _allocationBatch,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Batch 2022 - 2026 (Year IV)',
                                child: Text('Batch 2022 - 2026 (Year IV)'),
                              ),
                              DropdownMenuItem(
                                value: 'Batch 2023 - 2027 (Year III)',
                                child: Text('Batch 2023 - 2027 (Year III)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _allocationBatch = val);
                              }
                            },
                          ),
                        ),
                      ),
                      if (!isNarrow) const SizedBox(width: 8),
                      // Search subjects
                      SizedBox(
                        width: isNarrow ? double.infinity : 280,
                        height: 38,
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _allocationQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search subjects by code or name...',
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isNarrow) const SizedBox(width: 8),
                      // Status dropdown
                      Container(
                        width: isNarrow ? double.infinity : 160,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _allocationStatus == 'All'
                                ? 'Status: All'
                                : _allocationStatus,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                            ),
                            items: ['Status: All', 'Allocated', 'Pending']
                                .map(
                                  (st) => DropdownMenuItem(
                                    value: st,
                                    child: Text(st),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _allocationStatus = val == 'Status: All'
                                      ? 'All'
                                      : val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        children: filters
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: f,
                              ),
                            )
                            .toList(),
                      );
                    } else {
                      return Row(children: filters);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Table
                LayoutBuilder(
                  builder: (context, tableConstraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: tableConstraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF8FAFC),
                          ),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Subject Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Subject Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Semester',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Type & Credits',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Assigned Faculty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          rows: filtered.map((s) {
                            final code = s['code'];
                            final currentAssignment =
                                _subjectFacultyAssignments[code] ??
                                'Not Allocated (Clear)';
                            final isAllocated =
                                currentAssignment != 'Not Allocated (Clear)';

                            final rowOptions = List<String>.from(
                              dropdownFacultyOptions,
                            );
                            if (currentAssignment != 'Not Allocated (Clear)' &&
                                !rowOptions.contains(currentAssignment)) {
                              rowOptions.add(currentAssignment);
                            }

                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        code,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    s['name'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    s['semester']?.toString() ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    s['type'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAllocated
                                          ? Colors.white
                                          : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isAllocated
                                            ? const Color(0xFFCBD5E1)
                                            : const Color(0xFFFECACA),
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: currentAssignment,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isAllocated
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFDC2626),
                                        ),
                                        items: rowOptions
                                            .map(
                                              (opt) => DropdownMenuItem(
                                                value: opt,
                                                child: Text(opt),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (newVal) {
                                          if (newVal != null &&
                                              newVal != currentAssignment) {
                                            _onFacultyAllocationChanged(
                                              context,
                                              code,
                                              s['name'].toString(),
                                              newVal,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAllocated
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isAllocated ? 'Allocated' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isAllocated
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFD97706),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyCoursesTab(BuildContext context) {
    // KPI Cards Grid (6 cards)
    Widget kpis = LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = (availableWidth / 160).floor().clamp(2, 6);
        final double itemHeight = 100.0;
        final double spacing = 10.0;
        final double itemWidth =
            (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
        final double aspectRatio = itemWidth / itemHeight;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
          children: [
            _buildLegacyKpiCard(
              'Theory Courses',
              '3',
              'Core Curriculum',
              Icons.menu_book,
              const Color(0xFF2563EB),
            ),
            _buildLegacyKpiCard(
              'Lab Courses',
              '1',
              'Hands-on Labs',
              Icons.science_outlined,
              const Color(0xFF10B981),
            ),
            _buildLegacyKpiCard(
              'Sections',
              '2',
              'Sec A & Sec B',
              Icons.grid_view_rounded,
              const Color(0xFF8B5CF6),
            ),
            _buildLegacyKpiCard(
              'Total Students',
              '120',
              'Across Classes',
              Icons.people_alt_rounded,
              const Color(0xFF3B82F6),
            ),
            _buildLegacyKpiCard(
              'Teaching Hours / ...',
              '18',
              'Weekly Distribution',
              Icons.access_time_rounded,
              const Color(0xFF2563EB),
            ),
            _buildLegacyKpiCard(
              'Pending Lessons',
              '4',
              'Requires Immediate Sync',
              Icons.assignment_late_outlined,
              const Color(0xFFF59E0B),
            ),
          ],
        );
      },
    );

    // Teaching courses matching image 3
    final List<Map<String, dynamic>> teachingCourses =
        _myTeachingCoursesList.isNotEmpty
        ? _myTeachingCoursesList
        : [
            {
              'code': '24${_hodDeptCode}T31',
              'name': 'Electronic Devices & Circuits',
              'subtext': 'Core Course',
              'credits': '4 Credits',
              'semesterSec': 'Sem III - Sec A',
              'students': '60 Students',
              'attendance': '96.5%',
              'attendanceText': 'Excellent',
              'syllabus': '80% (Unit 4/5)',
              'progress': 0.80,
              'diary': 'Updated Up to Date',
            },
            {
              'code': '24${_hodDeptCode}T32',
              'name': 'Signals & Systems',
              'subtext': 'Core Course',
              'credits': '4 Credits',
              'semesterSec': 'Sem III - Sec A',
              'students': '60 Students',
              'attendance': '92.0%',
              'attendanceText': 'Excellent',
              'syllabus': '85% (Unit 4/5)',
              'progress': 0.85,
              'diary': 'Updated Up to Date',
            },
            {
              'code': '24${_hodDeptCode}T51',
              'name': 'Microcontrollers & Applications',
              'subtext': 'Core Course',
              'credits': '4 Credits',
              'semesterSec': 'Sem V - Sec A',
              'students': '60 Students',
              'attendance': '95.0%',
              'attendanceText': 'Excellent',
              'syllabus': '90% (Unit 5/5)',
              'progress': 0.90,
              'diary': 'Updated Up to Date',
            },
          ];

    final filtered = teachingCourses.where((c) {
      final matchesQuery =
          c['code'].toString().toLowerCase().contains(
            _myCoursesQuery.toLowerCase(),
          ) ||
          c['name'].toString().toLowerCase().contains(
            _myCoursesQuery.toLowerCase(),
          );
      final matchesSem =
          _myCoursesSemester == 'All' ||
          c['semesterSec'].toString().contains(_myCoursesSemester);
      final matchesSec =
          _myCoursesSection == 'All' ||
          c['semesterSec'].toString().contains(_myCoursesSection);
      return matchesQuery && matchesSem && matchesSec;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kpis,
        const SizedBox(height: 18),
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
                const Text(
                  'My Teaching Courses & Progress Tracking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),

                // Filters Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 800;

                    final filters = [
                      // Search field
                      SizedBox(
                        width: isNarrow ? double.infinity : 200,
                        height: 38,
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _myCoursesQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search by Course Code...',
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isNarrow) const SizedBox(width: 8),
                      // Semester dropdown
                      Container(
                        width: isNarrow ? double.infinity : 130,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _myCoursesSemester == 'All'
                                ? 'Semester: All'
                                : _myCoursesSemester,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                            ),
                            items: ['Semester: All', 'Sem IV', 'Sem VIII']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _myCoursesSemester = val == 'Semester: All'
                                      ? 'All'
                                      : val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      if (!isNarrow) const SizedBox(width: 8),
                      // Section dropdown
                      Container(
                        width: isNarrow ? double.infinity : 130,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _myCoursesSection == 'All'
                                ? 'Section: All'
                                : _myCoursesSection,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                            ),
                            items: ['Section: All', 'Sec A', 'Sec B']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _myCoursesSection = val == 'Section: All'
                                      ? 'All'
                                      : val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      if (!isNarrow) const SizedBox(width: 8),
                      // Attendance dropdown
                      Container(
                        width: isNarrow ? double.infinity : 150,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _myCoursesAttendance == 'All'
                                ? 'Attendance: All'
                                : _myCoursesAttendance,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                            ),
                            items:
                                [
                                      'Attendance: All',
                                      'Excellent (>90%)',
                                      'Average (75%-90%)',
                                      'Critical (<75%)',
                                    ]
                                    .map(
                                      (a) => DropdownMenuItem(
                                        value: a,
                                        child: Text(a),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _myCoursesAttendance =
                                      val == 'Attendance: All' ? 'All' : val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      if (!isNarrow) const SizedBox(width: 8),
                      // Status dropdown
                      Container(
                        width: isNarrow ? double.infinity : 130,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _myCoursesStatus == 'All'
                                ? 'Status: All'
                                : _myCoursesStatus,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                            ),
                            items: ['Status: All', 'Active', 'Pending']
                                .map(
                                  (st) => DropdownMenuItem(
                                    value: st,
                                    child: Text(st),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _myCoursesStatus = val == 'Status: All'
                                      ? 'All'
                                      : val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      if (!isNarrow) const SizedBox(width: 8),
                      // Reset Button
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _myCoursesQuery = '';
                            _myCoursesSemester = 'All';
                            _myCoursesSection = 'All';
                            _myCoursesAttendance = 'All';
                            _myCoursesStatus = 'All';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          fixedSize: const Size.fromHeight(38),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        children: filters
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: f,
                              ),
                            )
                            .toList(),
                      );
                    } else {
                      return Row(children: filters);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Table
                LayoutBuilder(
                  builder: (context, tableConstraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: tableConstraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF8FAFC),
                          ),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Course Code & Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Credits',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Semester & Sec',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Students',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Attendance %',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Syllabus Completion',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Diary Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status / Action',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          rows: filtered.map((c) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${c['code']}: ${c['name']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        c['subtext'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    c['credits'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    c['semesterSec'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    c['students'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF10B981),
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${c['attendance']} ${c['attendanceText']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: c['progress'],
                                            minHeight: 6,
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                                  Color(0xFF3B82F6),
                                                ),
                                            backgroundColor: const Color(
                                              0xFFE2E8F0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c['syllabus'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF10B981),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        c['diary'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  TextButton(
                                    onPressed: () {
                                      final course = CourseItem(
                                        code: c['code'],
                                        name: c['name'],
                                        credits: int.parse(
                                          c['credits'].split(' ')[0],
                                        ),
                                        semester: c['semesterSec'].split(
                                          ' - ',
                                        )[0],
                                        facultyAssigned: 'Dr. M. Govindharaj',
                                      );
                                      _showCourseDetailsModal(context, course);
                                    },
                                    child: const Text(
                                      'Details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegacyKpiCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showStudentDetailsModal(BuildContext context, StudentItem s) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Student Profile: ${s.name}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Roll No: ${s.rollNo} • Register No: 731622IOT01'),
              Text('Class & Section: ${s.yearSection}'),
              Text('Official Email: ${s.email}'),
              Text('Contact Phone: ${s.phone}'),
              const SizedBox(height: 10),
              const Text(
                'Academic Record:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• Attendance Rate: 94.5% (Eligible for Semester Exams)',
              ),
              const Text('• Cumulative CGPA: 8.65 / 10.0'),
              const Text('• Fee Clearance: PAID (Receipt #2026-IOT-482)'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exporting report for ${s.name}...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
              ),
              child: const Text(
                'Export Student Record',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCourseDetailsModal(BuildContext context, CourseItem c) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Course Details: ${c.code}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Course Name: ${c.name}'),
              Text('Semester: ${c.semester} • Credits: ${c.credits}'),
              Text('Faculty Assigned: ${c.facultyAssigned}'),
              const SizedBox(height: 10),
              const Text(
                'Syllabus Completion: 80% (Units 1-4 Complete, Unit 5 Ongoing)',
              ),
              const Text('Lesson Plan Progress: On Track'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading syllabus for ${c.code}...'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
              ),
              child: const Text(
                'Download Syllabus PDF',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
