// ignore_for_file: avoid_web_libraries_in_flutter, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/faculty_loading.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../erp_repository.dart';
import '../services/timetable_service.dart';
import '../services/assignment_service.dart';
import '../services/supabase_client.dart';
import '../services/course_allocation_service.dart';

class AssignmentUploadView extends StatefulWidget {
  const AssignmentUploadView({super.key});

  @override
  State<AssignmentUploadView> createState() => _AssignmentUploadViewState();
}

class _AssignmentUploadViewState extends State<AssignmentUploadView> {
  final repo = ErpRepository();
  bool _isLoading = false;

  // Filter States
  String _searchQuery = '';
  String _selectedYear = 'All Years';
  String _selectedClass = 'All Classes';
  String _selectedSubject = 'All Subjects';
  String _selectedStatus = 'All Status';
  String _selectedFileFormat = 'All Formats'; // Req 3: File format filter

  static const List<String> _formatOptions = [
    'All Formats',
    'PDF Document (.pdf)',
    'Word Document (.docx)',
    'Image (.jpg, .png)',
    'ZIP Archive (.zip)',
  ];

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadAssignmentsFromDatabase();
  }

  Future<void> _loadAssignmentsFromDatabase() async {
    if (!mounted || _isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      if (repo.assignments.isEmpty) _isLoading = true;
    });
    try {
      final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
      await AssignmentService.fetchFromSupabase(facultyId: facultyId);
      await repo.loadData();
    } catch (e) {
      debugPrint('Error loading assignments: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  // ── Derived Faculty Assigned Meta ──────────────────────────────────────────
  String? _extractYearFromClass(String cls) {
    final str = cls.toUpperCase();
    if (str.contains('IV') || str.contains('4TH') || str.contains('4 YEAR'))
      return 'IV Year';
    if (str.contains('III') || str.contains('3RD') || str.contains('3 YEAR'))
      return 'III Year';
    if (str.contains('II') || str.contains('2ND') || str.contains('2 YEAR'))
      return 'II Year';
    if (str.contains('I') || str.contains('1ST') || str.contains('1 YEAR'))
      return 'I Year';
    final match = RegExp(r'\(([^)]+)\)').firstMatch(cls);
    if (match != null) {
      final inner = match.group(1)!.trim();
      if (!inner.endsWith('Year')) return '$inner Year';
      return inner;
    }
    return null;
  }

  List<String> get _handlingYears {
    // Primary: CourseAllocationService
    final allocYears = CourseAllocationService.getAllocatedYears();
    if (allocYears.isNotEmpty) return ['All Years', ...allocYears];
    // Fallback: TimetableService
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    final classes = TimetableService.getClassesForFaculty(facultyId);
    final years = <String>{};
    for (final cls in classes) {
      final y = _extractYearFromClass(cls);
      if (y != null) years.add(y);
    }
    return ['All Years', ...years.toList()..sort()];
  }

  List<String> get _facultyClasses {
    // Primary: CourseAllocationService
    final allocClasses = CourseAllocationService.getAllocatedClasses(
      selectedYear: _selectedYear,
    );
    // Fallback: TimetableService
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    final ttClasses = TimetableService.getClassesForFaculty(facultyId);
    final all = <String>{...allocClasses, ...ttClasses};
    if (_selectedYear != 'All Years') {
      final filtered = all.where((c) {
        final y = _extractYearFromClass(c);
        return y == null || y == _selectedYear;
      }).toList();
      return ['All Classes', ...filtered];
    }
    return <String>['All Classes', ...all.toList()..sort()];
  }

  List<String> get _facultySubjects {
    // Primary: CourseAllocationService
    if (_selectedClass != 'All Classes') {
      final allocSubs = CourseAllocationService.getAllocatedSubjects(
        selectedClass: _selectedClass,
      );
      if (allocSubs.isNotEmpty) return ['All Subjects', ...allocSubs];
      // Fallback to TimetableService
      final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
      final subs = TimetableService.getSubjectsForClass(
        facultyId,
        _selectedClass,
      );
      if (subs.isNotEmpty) return ['All Subjects', ...subs];
    }
    final allSubs = CourseAllocationService.getAllocatedSubjects();
    if (allSubs.isNotEmpty) return ['All Subjects', ...allSubs];
    // Final fallback: timetable subjects
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    final subjects = <String>{};
    for (var day in repo.timetable) {
      for (var s in (day['schedule'] as List? ?? [])) {
        if (s['facultyId'] == facultyId && s['subject'] != null) {
          subjects.add(s['subject'].toString());
        }
      }
    }
    return ['All Subjects', ...subjects.toList()..sort()];
  }

  void _onYearSelected(String newYear) {
    setState(() {
      _selectedYear = newYear;
      final classes = _facultyClasses;
      _selectedClass = classes.length > 1 ? classes[1] : 'All Classes';
      _onClassSelected(_selectedClass);
    });
  }

  void _onClassSelected(String newClass) {
    setState(() {
      _selectedClass = newClass;
      if (newClass != 'All Classes') {
        final y = _extractYearFromClass(newClass);
        if (y != null) _selectedYear = y;
        final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
        final subs = TimetableService.getSubjectsForClass(facultyId, newClass);
        if (subs.isNotEmpty) {
          _selectedSubject = subs.first;
        } else {
          _selectedSubject = 'All Subjects';
        }
      } else {
        _selectedSubject = 'All Subjects';
      }
    });
  }

  // ── 3. Filtered Assignments (Filtered by File Format) ───────────────────────
  List<Map<String, dynamic>> get _filteredAssignments {
    List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      repo.assignments,
    );

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) {
        final title = (a['title'] ?? '').toString().toLowerCase();
        final desc = (a['description'] ?? '').toString().toLowerCase();
        final subj = (a['subject'] ?? '').toString().toLowerCase();
        final sec = (a['section'] ?? '').toString().toLowerCase();
        return title.contains(q) ||
            desc.contains(q) ||
            subj.contains(q) ||
            sec.contains(q);
      }).toList();
    }

    // Year filter
    if (_selectedYear != 'All Years') {
      list = list
          .where(
            (a) =>
                (a['year'] ?? '').toString().contains(_selectedYear) ||
                (a['classSec'] ?? '').toString().contains(_selectedYear),
          )
          .toList();
    }

    // Class filter
    if (_selectedClass != 'All Classes') {
      list = list
          .where(
            (a) => (a['classSec'] ?? a['section'] ?? '').toString().contains(
              _selectedClass,
            ),
          )
          .toList();
    }

    // Subject filter
    if (_selectedSubject != 'All Subjects') {
      list = list
          .where((a) => (a['subject'] ?? '') == _selectedSubject)
          .toList();
    }

    // Status filter
    if (_selectedStatus != 'All Status') {
      list = list.where((a) => (a['status'] ?? '') == _selectedStatus).toList();
    }

    // 3. File Format filter: Only allow assignments matching selected file format
    if (_selectedFileFormat != 'All Formats') {
      list = list.where((a) {
        final allowed =
            (a['allowedFileTypes'] ?? a['allowedFileFormats'] ?? 'All Formats')
                .toString();
        if (allowed == 'All Formats') return true;
        final formatClean = _selectedFileFormat.split(' ').first.toLowerCase();
        return allowed.toLowerCase().contains(formatClean);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final assignments = _filteredAssignments;
        final hasData = repo.assignments.isNotEmpty;

        if (_isLoading || (repo.isLoadingData && !hasData)) {
          return const FacultyLoadingWidget();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 16),
            _buildFilterControlBar(), // 6: Unlocked filters, 3: File types filter
            const SizedBox(height: 20),
            if (assignments.isEmpty)
              _buildEmptyState()
            else
              _buildAssignmentCardsGrid(assignments),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  // ── Page Header ───────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Row(
      children: [
        Text(
          'Assignment Management',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _isRefreshing ? null : _loadAssignmentsFromDatabase,
          icon: _isRefreshing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2563EB),
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
          label: Text(
            _isRefreshing ? 'Refreshing...' : 'Refresh',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF2563EB),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFBFDBFE)),
            backgroundColor: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _showCreateAssignmentModalEnhanced,
          icon: const Icon(Icons.add_task_rounded, size: 16),
          label: Text(
            'Create Assignment',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: FacultyLoadingWidget(),
    );
  }

  // ── 6: Unlocked Filter Control Bar & 3: File Format Filter ─────────────────
  Widget _buildFilterControlBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list_rounded,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '${_filteredAssignments.length} Assignments',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSearchInput(),
              // 6. Fully unlocked dropdown filters
              _buildDropdownFilter(
                'Year',
                _handlingYears,
                _selectedYear,
                (v) => _onYearSelected(v!),
              ),
              _buildDropdownFilter(
                'Class',
                _facultyClasses,
                _selectedClass,
                (v) => _onClassSelected(v!),
              ),
              _buildDropdownFilter(
                'Subject',
                _facultySubjects,
                _selectedSubject,
                (v) => setState(() => _selectedSubject = v!),
              ),
              _buildDropdownFilter(
                'Status',
                ['All Status', 'Published', 'Draft', 'Closed'],
                _selectedStatus,
                (v) => setState(() => _selectedStatus = v!),
              ),
              // 3. File Format Filter
              _buildDropdownFilter(
                'File Format',
                _formatOptions,
                _selectedFileFormat,
                (v) => setState(() => _selectedFileFormat = v!),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedYear = 'All Years';
                    _selectedClass = 'All Classes';
                    _selectedSubject = 'All Subjects';
                    _selectedStatus = 'All Status';
                    _selectedFileFormat = 'All Formats';
                  });
                },
                icon: const Icon(
                  Icons.restart_alt,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                label: Text(
                  'Reset',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF64748B),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return SizedBox(
      width: 190,
      height: 42,
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.inter(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search title...',
          hintStyle: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: Color(0xFF94A3B8),
          ),
          fillColor: const Color(0xFFF8FAFC),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  // 6. Removed filter lock (all dropdown filters are fully enabled)
  Widget _buildDropdownFilter(
    String label,
    List<String> items,
    String current,
    ValueChanged<String?>? onChanged,
  ) {
    final uniqueItems = items.toSet().toList();
    final String val = uniqueItems.contains(current)
        ? current
        : (uniqueItems.isNotEmpty ? uniqueItems.first : current);

    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      initialValue: val,
      onSelected: (selected) {
        if (onChanged != null) onChanged(selected);
      },
      itemBuilder: (context) {
        return uniqueItems.map((item) {
          final bool isSelected = item == val;
          return PopupMenuItem<String>(
            value: item,
            height: 38,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCardsGrid(List<Map<String, dynamic>> assignments) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1200
            ? 3
            : (constraints.maxWidth > 700 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisExtent: 185,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: assignments.length,
          itemBuilder: (ctx, idx) => _buildAssignmentCard(assignments[idx]),
        );
      },
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> asg) {
    final title = asg['title'] ?? 'Untitled Assignment';
    final subject = asg['subject'] ?? '';
    final code = asg['code'] ?? '24CST57';
    final classSec = asg['classSec'] ?? asg['section'] ?? 'CSE-A';
    final year = asg['year'] ?? 'II Year';
    final semester = asg['semester'] ?? 'Sem IV';
    final dueDate = asg['dueDate'] ?? '2026-08-10';
    final dueTime = asg['dueTime'] ?? '11:59 PM';
    final maxMarks = asg['maxMarks'] ?? asg['total_marks'] ?? 100;
    final submitted = (asg['submittedCount'] as num? ?? 0).toInt();
    final total = (asg['totalStudents'] as num? ?? 0).toInt();
    final status = asg['status'] ?? 'Published';
    final pct = total > 0
        ? ((submitted / total) * 100).clamp(0, 100).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$subject ($code)',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const Spacer(),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 12,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [
                            classSec,
                            year,
                            semester,
                          ].where((e) => e.toString().isNotEmpty).join(' • '),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Due: $dueDate${dueTime.isNotEmpty ? ', $dueTime' : ''} • ⭐ $maxMarks Marks',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Submissions',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          total > 0 ? '$submitted/$total ($pct%)' : '—',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total > 0 ? (submitted / total) : 0.0,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _openAssignmentDetailsModalEnhanced(asg),
                icon: const Icon(Icons.visibility_outlined, size: 12),
                label: Text(
                  'View',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              OutlinedButton(
                onPressed: () => _exportAssignmentExcel(asg),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16A34A),
                  side: const BorderSide(color: Color(0xFF86EFAC)),
                  padding: const EdgeInsets.all(6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Icon(Icons.table_view_outlined, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF64748B);
    if (status == 'Published') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
    } else if (status == 'Draft') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (status == 'Closed') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            'No Assignments Found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your class/subject filters or create a new assignment.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ── VIEW DETAILS MODAL: Material Preview + Marks Entry + Save Marks ────────
  void _openAssignmentDetailsModalEnhanced(Map<String, dynamic> asg) async {
    final asgId = (asg['assignmentId'] ?? asg['id'] ?? '').toString();
    final classSec = (asg['classSec'] ?? asg['section'] ?? 'CSE-A').toString();

    final marksData = await AssignmentService.fetchAssignmentMarksFromSupabase(
      assignmentId: asgId,
      classSec: classSec,
    );

    if (!mounted) return;

    final submittedList = List<Map<String, dynamic>>.from(
      marksData['submitted'] ?? [],
    );
    final notSubmittedList = List<Map<String, dynamic>>.from(
      marksData['notSubmitted'] ?? [],
    );

    showDialog(
      context: context,
      builder: (ctx) => _AssignmentDetailsModal(
        asg: asg,
        submittedList: submittedList,
        notSubmittedList: notSubmittedList,
      ),
    );
  }

  // Material preview + marks-entry logic now lives in [_AssignmentDetailsModal].

  void _exportAssignmentExcel(Map<String, dynamic> asg) async {
    final asgId = (asg['assignmentId'] ?? asg['id'] ?? '').toString();
    final classSec = (asg['classSec'] ?? asg['section'] ?? 'CSE-A').toString();
    final subject = (asg['subject'] ?? 'Database_Management_Systems')
        .toString();

    final marksData = await AssignmentService.fetchAssignmentMarksFromSupabase(
      assignmentId: asgId,
      classSec: classSec,
    );

    final submitted = List<Map<String, dynamic>>.from(
      marksData['submitted'] ?? [],
    );
    final notSubmitted = List<Map<String, dynamic>>.from(
      marksData['notSubmitted'] ?? [],
    );

    final xml = StringBuffer();
    xml.writeln('<?xml version="1.0"?>');
    xml.writeln('<?mso-application progid="Excel.Sheet"?>');
    xml.writeln(
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"',
    );
    xml.writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">');
    xml.writeln('<Styles>');
    xml.writeln(
      ' <Style ss:ID="header"><Font ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#2563EB" ss:Pattern="Solid"/></Style>',
    );
    xml.writeln(
      ' <Style ss:ID="headerRed"><Font ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#DC2626" ss:Pattern="Solid"/></Style>',
    );
    xml.writeln('</Styles>');

    xml.writeln('<Worksheet ss:Name="Submitted Students">');
    xml.writeln('<Table>');
    xml.writeln('<Row ss:StyleID="header">');
    xml.writeln(' <Cell><Data ss:Type="String">S.No.</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Register Number</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Name</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Department</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Year</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Class & Section</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Assignment Marks</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Status</Data></Cell>');
    xml.writeln('</Row>');

    for (int i = 0; i < submitted.length; i++) {
      final s = submitted[i];
      final regNo = s['regNo'] ?? s['reg_no'] ?? '';
      final name = s['name'] ?? '';
      final dept = s['department'] ?? 'CSE';
      final sYear = s['year'] ?? 'II Year';
      final sec = s['section'] ?? 'A';
      final marks = s['marks'] ?? '0';
      final status = s['status'] ?? 'Submitted';

      xml.writeln('<Row>');
      xml.writeln(' <Cell><Data ss:Type="Number">${i + 1}</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$regNo</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$name</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$dept</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$sYear</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$dept - $sec</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="Number">$marks</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$status</Data></Cell>');
      xml.writeln('</Row>');
    }
    xml.writeln('</Table></Worksheet>');

    xml.writeln('<Worksheet ss:Name="Not Submitted Students">');
    xml.writeln('<Table>');
    xml.writeln('<Row ss:StyleID="headerRed">');
    xml.writeln(' <Cell><Data ss:Type="String">S.No.</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Register Number</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Name</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Department</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Year</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Class & Section</Data></Cell>');
    xml.writeln(' <Cell><Data ss:Type="String">Status</Data></Cell>');
    xml.writeln('</Row>');

    for (int i = 0; i < notSubmitted.length; i++) {
      final ns = notSubmitted[i];
      final regNo = ns['regNo'] ?? ns['reg_no'] ?? '';
      final name = ns['name'] ?? '';
      final dept = ns['department'] ?? 'CSE';
      final sYear = ns['year'] ?? 'II Year';
      final sec = ns['section'] ?? 'A';

      xml.writeln('<Row>');
      xml.writeln(' <Cell><Data ss:Type="Number">${i + 1}</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$regNo</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$name</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$dept</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$sYear</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">$dept - $sec</Data></Cell>');
      xml.writeln(' <Cell><Data ss:Type="String">Not Submitted</Data></Cell>');
      xml.writeln('</Row>');
    }
    xml.writeln('</Table></Worksheet></Workbook>');

    final fileName =
        '${subject.replaceAll(' ', '_')}_${classSec.replaceAll(' ', '_')}.xls';
    repo.triggerFileDownload(
      fileName,
      xml.toString(),
      'application/vnd.ms-excel',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel exported: $fileName ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── 1. Create Assignment Modal (Matching Screenshot 1) ──────────────────────
  // 2: Working File Format Dropdown
  // 4: Form Input Special Symbol Validation
  void _showCreateAssignmentModalEnhanced() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final maxCtrl = TextEditingController(text: '100');
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 7));

    String selectedClass = 'CSE - A (II Year)';
    String selectedSubj = 'Principles of Compiler Design';
    String allowedTypes =
        'All Formats'; // 2. Working Allowed File Formats Dropdown

    // ── Class → Subject flow (from faculty_course_allocations) ────────────────
    // The Class & Section dropdown drives the selection. Choosing a class&section
    // auto-sets the subject to the one(s) the faculty handles for it. The subject
    // dropdown is locked unless the faculty handles more than one subject for the
    // same class&section. Falls back to the full lists only when no allocation
    // data is loaded.
    List<String> modalAllClasses() {
      final alloc = CourseAllocationService.getAllocatedClasses();
      if (alloc.isNotEmpty) return alloc;
      return _facultyClasses.where((c) => c != 'All Classes').toList();
    }

    List<String> modalSubjectsFor(String cls) {
      final byCls = CourseAllocationService.getAllocatedSubjects(
        selectedClass: cls,
      );
      if (byCls.isNotEmpty) return byCls;
      final all = CourseAllocationService.getAllocatedSubjects();
      if (all.isNotEmpty) return all;
      return _facultySubjects.where((s) => s != 'All Subjects').toList();
    }

    // Default: first class the faculty handles + its auto-derived subject.
    final modalClasses = modalAllClasses();
    if (modalClasses.isNotEmpty) {
      selectedClass = modalClasses.first;
      final subs = modalSubjectsFor(selectedClass);
      if (subs.isNotEmpty) selectedSubj = subs.first;
    }
    String? questionFileName;
    String? instructionFileName;
    String?
    questionFileDataUrl; // base64 data URL from the picked question paper file
    String? titleErrorText;
    String? descErrorText;
    String? maxMarksErrorText;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 620,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Text(
                            'Create Assignment',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Field 1: Assignment Title *
                      Text(
                        'Assignment Title *',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleCtrl,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. Lexical Analyzer Implementation',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          errorText: titleErrorText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          setModalState(() => titleErrorText = null);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Row 1: Target Subject * & Class / Section *
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Subject *',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _modalDropdown(
                                  modalSubjectsFor(selectedClass),
                                  selectedSubj,
                                  // Locked unless the faculty handles more than one
                                  // subject for the selected class & section.
                                  modalSubjectsFor(selectedClass).length <= 1
                                      ? null
                                      : (v) => setModalState(
                                          () => selectedSubj = v!,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Class & Section *',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _modalDropdown(
                                  modalAllClasses(),
                                  selectedClass,
                                  (v) => setModalState(() {
                                    selectedClass = v!;
                                    // Auto-set the subject to the first one the
                                    // faculty handles for the chosen class&section.
                                    final subs = modalSubjectsFor(
                                      selectedClass,
                                    );
                                    selectedSubj = subs.isNotEmpty
                                        ? subs.first
                                        : selectedSubj;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 2: Due Date * & Max Marks *
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Due Date (Supabase YYYY-MM-DD) *',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          selectedDueDate.isBefore(
                                            DateTime.now(),
                                          )
                                          ? DateTime.now()
                                          : selectedDueDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        selectedDueDate = picked;
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Color(0xFF2563EB),
                                  ),
                                  label: Text(
                                    selectedDueDate.toString().substring(0, 10),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      42,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    alignment: Alignment.centerLeft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Max Marks (Max 100) *',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: maxCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: GoogleFonts.inter(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: '100',
                                    errorText: maxMarksErrorText,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (v) {
                                    setModalState(
                                      () => maxMarksErrorText = null,
                                    );
                                    final val = int.tryParse(v);
                                    if (val != null && val > 100) {
                                      maxCtrl.text = '100';
                                      maxCtrl.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: maxCtrl.text.length,
                                            ),
                                          );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Allowed File Formats * Dropdown
                      Text(
                        'Allowed File Formats *',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _modalDropdown(
                        _formatOptions,
                        allowedTypes,
                        (v) => setModalState(() => allowedTypes = v!),
                      ),
                      const SizedBox(height: 14),

                      // Description / Objectives
                      Text(
                        'Description / Objectives',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          hintText:
                              'Brief summary of assignment goals and instructions',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          errorText: descErrorText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            setModalState(() => descErrorText = null),
                      ),
                      const SizedBox(height: 14),

                      // 5. Question Paper File Upload Area
                      Text(
                        'Question Paper File (Required)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          repo.triggerNativeUpload((name, size, dataUrl) {
                            setModalState(() {
                              questionFileName = name;
                              questionFileDataUrl = dataUrl;
                            });
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: questionFileName != null
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 24,
                                color: questionFileName != null
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                questionFileName ??
                                    'Drop Question Paper file here or click to browse',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: questionFileName != null
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5. Instruction / Reference File Upload Area (Optional)
                      Text(
                        'Instruction / Reference File (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          repo.triggerNativeUpload((name, size, dataUrl) {
                            setModalState(() {
                              instructionFileName = name;
                            });
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: instructionFileName != null
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.attachment,
                                size: 20,
                                color: instructionFileName != null
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                instructionFileName ??
                                    'Drop optional instruction file here or click to browse',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: instructionFileName != null
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Modal Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              final desc = descCtrl.text.trim();
                              final maxMarksVal =
                                  int.tryParse(maxCtrl.text) ?? 100;

                              // 4. Special symbol & text validation for inputs
                              if (title.isEmpty ||
                                  !RegExp(r'[a-zA-Z]').hasMatch(title)) {
                                setModalState(
                                  () => titleErrorText =
                                      'Title must contain valid letters (no special symbols only)',
                                );
                                return;
                              }

                              if (_hasSpecialSymbols(title)) {
                                setModalState(
                                  () => titleErrorText =
                                      'Special symbols are not allowed in title',
                                );
                                return;
                              }

                              if (desc.isNotEmpty && _hasSpecialSymbols(desc)) {
                                setModalState(
                                  () => descErrorText =
                                      'Special symbols are not allowed in description',
                                );
                                return;
                              }

                              final facultyId =
                                  repo.profile['employeeId'] ?? 'EMP_CSE_002';
                              final dateStr = selectedDueDate
                                  .toString()
                                  .substring(0, 10);
                              final fileName = questionFileName ?? '';
                              final code =
                                  CourseAllocationService.getCourseCodeForClassAndSubject(
                                    selectedClass,
                                    selectedSubj,
                                  ) ??
                                  CourseAllocationService.getCourseCodeForSubject(
                                    selectedSubj,
                                  ) ??
                                  '';

                              // Upload the picked question paper to Supabase Storage and
                              // persist the real public URL so the attachment is retrievable.
                              String? questionFileUrl;
                              final qDataUrl = questionFileDataUrl;
                              if (fileName.isNotEmpty &&
                                  qDataUrl != null &&
                                  qDataUrl.contains(',')) {
                                try {
                                  final bytes = base64Decode(
                                    qDataUrl.substring(
                                      qDataUrl.indexOf(',') + 1,
                                    ),
                                  );
                                  final safeName = fileName.replaceAll(
                                    RegExp(r'[^A-Za-z0-9._-]'),
                                    '_',
                                  );
                                  final storagePath =
                                      '$facultyId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
                                  final uploaded =
                                      await SupabaseClientHelper.uploadToStorage(
                                        'assignments',
                                        storagePath,
                                        bytes,
                                        mimeType:
                                            SupabaseClientHelper.mimeTypeFor(
                                              fileName,
                                            ),
                                      );
                                  if (uploaded.startsWith('http'))
                                    questionFileUrl = uploaded;
                                } catch (e) {
                                  debugPrint('Question file upload failed: $e');
                                }
                              }

                              final newAsg = {
                                'facultyId': facultyId,
                                'code': code,
                                'title': title,
                                'description': desc,
                                'subject': selectedSubj,
                                'section': selectedClass,
                                'classSec': selectedClass,
                                'dueDate': dateStr,
                                'maxMarks': maxMarksVal,
                                'allowedFileTypes': allowedTypes,
                                'academicYear': '2025-26',
                                'status': 'Published',
                                'questionFile': fileName,
                                'questionFileUrl': questionFileUrl ?? '',
                              };

                              await AssignmentService.save(newAsg);
                              Navigator.pop(ctx);
                              await _loadAssignmentsFromDatabase();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Assignment created and published to Supabase storage ✓',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Publish Assignment',
                              style: GoogleFonts.inter(
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _modalDropdown(
    List<String> items,
    String currentVal,
    ValueChanged<String?>? onChange,
  ) {
    final val = items.contains(currentVal)
        ? currentVal
        : (items.isNotEmpty ? items.first : null);
    return DropdownButtonFormField<String>(
      initialValue: val,
      items: items
          .map(
            (i) => DropdownMenuItem(
              value: i,
              child: Text(i, style: GoogleFonts.inter(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: onChange,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  bool _hasSpecialSymbols(String text) {
    const String symbols = '!@#\$%^&*()_+={}[]:;"\'<>,.?/\\|~`';
    for (int i = 0; i < text.length; i++) {
      if (symbols.contains(text[i])) return true;
    }
    return false;
  }
}

/// View-details modal for an assignment. Shows the assignment material preview,
/// a marks-entry table (one box per student, clamped to the assignment's max
/// marks) with a per-student download button for the submitted file, and a
/// "Save Marks" button at the bottom that persists to `faculty.assignment_marks`
/// via Supabase.
class _AssignmentDetailsModal extends StatefulWidget {
  final Map<String, dynamic> asg;
  final List<Map<String, dynamic>> submittedList;
  final List<Map<String, dynamic>> notSubmittedList;

  const _AssignmentDetailsModal({
    required this.asg,
    required this.submittedList,
    required this.notSubmittedList,
  });

  @override
  State<_AssignmentDetailsModal> createState() =>
      _AssignmentDetailsModalState();
}

class _AssignmentDetailsModalState extends State<_AssignmentDetailsModal> {
  final repo = ErpRepository();
  late final List<TextEditingController> _markControllers;
  final List<FocusNode> _focusNodes = [];
  late final List<String?>
  _fieldErrors; // per-row validation message, null = valid
  OverlayEntry? _bubbleEntry; // small HTML5-style popup above an invalid field
  bool _saving = false;

  String get _asgId =>
      (widget.asg['assignmentId'] ?? widget.asg['id'] ?? '').toString();
  int get _maxMarks => (widget.asg['maxMarks'] as num? ?? 100).toInt();

  @override
  void initState() {
    super.initState();
    _markControllers = widget.submittedList.map((st) {
      final hasRow = (st['hasRow'] ?? false) == true;
      final parsed = num.tryParse((st['marks'] ?? '').toString());
      String text = '';
      if (hasRow && parsed != null && parsed > 0) {
        text = parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
      }
      return TextEditingController(text: text);
    }).toList();
    _focusNodes.addAll(widget.submittedList.map((_) => FocusNode()));
    _fieldErrors = List<String?>.filled(widget.submittedList.length, null);
  }

  @override
  void dispose() {
    _hideFieldBubble();
    for (final c in _markControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Mark validation + HTML5-style popup ───────────────────────────────────
  /// Returns an error message for a raw mark string, or null when valid/empty.
  String? _validateMarks(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    final parsed = num.tryParse(v);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0 || parsed > _maxMarks) return 'Between 0 and $_maxMarks';
    return null;
  }

  void _hideFieldBubble() {
    _bubbleEntry?.remove();
    _bubbleEntry = null;
  }

  /// Shows a small red bubble (like an HTML5 validation popup) just above the
  /// offending mark field.
  void _showFieldBubble(int index, String message) {
    _hideFieldBubble();
    final focusCtx = index < _focusNodes.length
        ? _focusNodes[index].context
        : null;
    final box = focusCtx?.findRenderObject() as RenderBox?;
    if (!mounted || focusCtx == null || box == null || !box.hasSize) return;

    final pos = box.localToGlobal(Offset.zero);
    final left = pos.dx;
    final top = pos.dy - 44;
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: left < 0 ? 0 : left,
        top: top < 4 ? 4 : top,
        child: _buildErrorBubble(message),
      ),
    );
    Overlay.of(context).insert(entry);
    _bubbleEntry = entry;
  }

  Widget _buildErrorBubble(String message) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Transform.rotate(
              angle: 3.14159 / 4, // 45°, rotated square = bubble tail
              child: Container(
                width: 10,
                height: 10,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save Marks → Supabase ─────────────────────────────────────────────────
  Future<void> _saveMarks() async {
    final list = <Map<String, dynamic>>[];
    String? firstError;
    int? firstErrorIndex;

    for (var i = 0; i < widget.submittedList.length; i++) {
      final st = widget.submittedList[i];
      final raw = _markControllers[i].text.trim();
      final hasRow = (st['hasRow'] ?? false) == true;

      final fieldErr = _validateMarks(raw);
      _fieldErrors[i] = fieldErr;
      if (fieldErr != null) {
        firstError ??= '${st['name'] ?? st['regNo']}: $fieldErr';
        firstErrorIndex ??= i;
        continue;
      }

      if (raw.isEmpty && !hasRow) continue; // untouched, no existing row yet

      final parsed = num.tryParse(raw);
      final marks =
          parsed ??
          (hasRow ? (num.tryParse((st['marks'] ?? 0).toString()) ?? 0) : 0);
      list.add({
        'regNo': st['regNo'],
        'student_id': st['student_id'],
        'name': st['name'],
        'department': st['department'],
        'section': st['section'],
        'year': st['year'],
        'subject_code': widget.asg['code'] ?? '',
        'marks': marks,
        'status': raw.isNotEmpty ? 'Graded' : (st['status'] ?? 'Not Submitted'),
        'fileUrl': st['fileUrl'],
      });
    }

    if (firstError != null) {
      setState(() {}); // refresh the red backgrounds on every invalid field
      _focusNodes[firstErrorIndex!].requestFocus();
      _showFieldBubble(firstErrorIndex, firstError!);
      return;
    }
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No marks entered yet. Fill in marks and tap Save Marks.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await AssignmentService.saveStudentMarks(
        assignmentId: _asgId,
        marksList: list,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks saved to Supabase ✓'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error saving assignment marks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save marks: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final asg = widget.asg;
    final classSec = (asg['classSec'] ?? asg['section'] ?? 'CSE-A').toString();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 950,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asg['title'] ?? 'Assignment Details',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Subject: ${asg['subject']} • Class: $classSec',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const TabBar(
                tabs: [
                  Tab(text: 'Assignment Material & Preview'),
                  Tab(text: 'Marks Entry'),
                  Tab(text: 'Not Submitted'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMaterialPreviewTab(asg),
                    _buildMarksEntryTable(),
                    _buildNotSubmittedList(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Footer: max-marks hint + Save Marks button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Max Marks: $_maxMarks',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveMarks,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 16),
                    label: Text(
                      _saving ? 'Saving…' : 'Save Marks',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Assignment Material & Preview ──────────────────────────────────
  Widget _buildMaterialPreviewTab(Map<String, dynamic> asg) {
    final desc = asg['description'] ?? 'No description provided.';
    final qFile = (asg['questionFileUrl'] ?? asg['attachmentUrl'] ?? '')
        .toString();
    final qName = (asg['questionFile'] ?? '').toString();
    final hasFile = qFile.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description & Objectives:',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Allowed File Formats:',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              (asg['allowedFileTypes'] ?? 'All Formats').toString(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Question Paper Material File:',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: hasFile
                ? Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        color: Color(0xFFDC2626),
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              qName.isNotEmpty ? qName : qFile,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Question Paper Document • Supabase Storage',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _viewOrDownload(qFile, open: true, fileName: qName),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: Text(
                          'View Online',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _viewOrDownload(
                          qFile,
                          open: false,
                          fileName: qName,
                        ),
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 16,
                        ),
                        label: Text(
                          'Download',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF16A34A),
                          side: const BorderSide(color: Color(0xFF86EFAC)),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        color: Color(0xFF94A3B8),
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No question paper file was uploaded for this assignment.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Marks Entry Table (with per-student download) ──────────────────
  Widget _buildMarksEntryTable() {
    if (widget.submittedList.isEmpty) {
      return Center(
        child: Text(
          'No students to grade for this class yet.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: widget.submittedList.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (ctx, i) {
        final st = widget.submittedList[i];
        final regNo = st['regNo'] ?? st['reg_no'] ?? '';
        final name = st['name'] ?? '';
        final status = st['status'] ?? 'Not Submitted';
        final file = (st['fileUrl'] ?? '').toString();
        final hasFile = file.startsWith('http') || file.startsWith('data:');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name ($regNo)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    _statusChip(status),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (hasFile)
                IconButton(
                  tooltip: 'Download submission',
                  icon: const Icon(
                    Icons.download,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  onPressed: () => _viewOrDownload(file, open: false),
                ),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _markControllers[i],
                  focusNode: _focusNodes[i],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (v) {
                    final err = _validateMarks(v);
                    setState(() => _fieldErrors[i] = err);
                    if (err != null) {
                      _showFieldBubble(i, err);
                    } else {
                      _hideFieldBubble();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '0-$_maxMarks',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: (_fieldErrors[i] ?? '').isEmpty
                        ? const Color(0xFFF0F9FF) // light blue when valid
                        : const Color(0xFFFEE2E2), // light red when invalid
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: (_fieldErrors[i] ?? '').isEmpty
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    final isSubmitted = status != 'Not Submitted';
    final bg = isSubmitted ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final fg = isSubmitted ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        isSubmitted ? 'Submitted' : 'Not Submitted',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  // ── Tab 3: Not Submitted List ─────────────────────────────────────────────
  Widget _buildNotSubmittedList() {
    final list = widget.notSubmittedList;
    if (list.isEmpty) {
      return Center(
        child: Text(
          'All students have submitted, or none are marked Not Submitted yet.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (ctx, i) {
        final st = list[i];
        final regNo = st['regNo'] ?? st['reg_no'] ?? '';
        final name = st['name'] ?? '';
        return ListTile(
          dense: true,
          title: Text(
            '$name ($regNo)',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Pending Submission',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Not Submitted',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── View Online / Download helper ─────────────────────────────────────────
  void _viewOrDownload(
    String fileUrl, {
    required bool open,
    String fileName = '',
  }) {
    // Viewing always opens the real public URL in a new tab (native browser
    // handling → no re-encoding, no corruption).
    if (open && fileUrl.startsWith('http')) {
      html.window.open(fileUrl, '_blank');
      return;
    }
    // Download: pass the URL as `content` so triggerFileDownload streams the
    // actual stored bytes (previously the placeholder text was passed, which
    // produced a corrupted/fallback file).
    final safeName = fileName.trim().isNotEmpty
        ? fileName.trim()
        : (fileUrl.contains('/') ? fileUrl.split('/').last : 'assignment_file');
    repo.triggerFileDownload(safeName, fileUrl, 'application/pdf');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(open ? 'Downloading file…' : 'Downloaded ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
