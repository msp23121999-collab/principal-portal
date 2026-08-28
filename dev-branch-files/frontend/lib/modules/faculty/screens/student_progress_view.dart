// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../erp_repository.dart';
import '../services/timetable_service.dart';
import '../services/student_service.dart';

/// Student Progress View (Faculty Portal — Index 15)
///
/// Monitor academic progress of students belonging to logged-in faculty's
/// assigned classes & subjects.
class StudentProgressView extends StatefulWidget {
  const StudentProgressView({super.key});

  @override
  State<StudentProgressView> createState() => _StudentProgressViewState();
}

class _StudentProgressViewState extends State<StudentProgressView> {
  final repo = ErpRepository();

  // ── Faculty Scoped Allocation ────────────────────────────────────────────
  List<String> _facultySubjects = [];
  List<String> _facultyClassSections = [];

  // ── Filters ──────────────────────────────────────────────────────────────
  String _selectedSubject = 'All Subjects';
  String _selectedYear = 'All Years';
  String _selectedClassSec = 'All Classes';
  String _selectedStatusFilter = 'All Statuses';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initFacultyScope();
    StudentService.fetchFromSupabase().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initFacultyScope() {
    final facultyId = repo.profile['employeeId']?.toString() ?? 'FAC002';
    _facultySubjects = TimetableService.getSubjectsForFaculty(facultyId);

    final sections = <String>{};
    for (final day in TimetableService.getByFaculty(facultyId)) {
      for (final p in (day['schedule'] as List? ?? [])) {
        final cls = p['classSec']?.toString();
        if (cls != null && cls.isNotEmpty) sections.add(cls);
      }
    }
    _facultyClassSections = sections.toList()..sort();
  }

  // ── Helper: Map Subject to Assigned Classes/Sections ──────────────────────
  List<String> _getClassesForSubject(String subject) {
    final facultyId = repo.profile['facultyId']?.toString() ?? 'FAC73124';
    final sections = <String>{};
    for (final day in TimetableService.getByFaculty(facultyId)) {
      for (final p in (day['schedule'] as List? ?? [])) {
        final subj = p['subject']?.toString() ?? '';
        final cls = p['classSec']?.toString() ?? '';
        if ((subject == 'All Subjects' || subj == subject) && cls.isNotEmpty) {
          sections.add(cls);
        }
      }
    }
    return sections.isEmpty ? _facultyClassSections : sections.toList();
  }

  /// Filter class options by selected year
  List<String> get _availableClassOptions {
    final allForSubject = _selectedSubject == 'All Subjects'
        ? _facultyClassSections
        : _getClassesForSubject(_selectedSubject);

    if (_selectedYear == 'All Years') return allForSubject;

    final targetYearCode = StudentService.extractYear(_selectedYear);
    return allForSubject.where((c) {
      final y = StudentService.extractYear(c);
      return y.isEmpty || y == targetYearCode;
    }).toList();
  }

  /// Builds classSec string from student data using actual year_of_study
  String _buildClassSec(Map<String, dynamic> student) {
    final dept = (student['dept'] ?? student['department'] ?? '').toString();
    final sec = (student['sec'] ?? student['section'] ?? '').toString();
    final rawYear = (student['year_of_study'] ?? student['year'] ?? '')
        .toString();
    final year = rawYear.isNotEmpty
        ? rawYear
        : StudentService.calcYearFromSem(student['sem'] ?? student['semester']);
    final yearLabel = year.contains('Year') ? year : '$year Year';
    return '$dept - $sec ($yearLabel)';
  }

  // ── Student List Computation (Scoped to Faculty & Active Subject) ────────
  List<Map<String, dynamic>> get _facultyScopedStudents {
    final targetClassSecs = _selectedSubject == 'All Subjects'
        ? _facultyClassSections
        : _getClassesForSubject(_selectedSubject);

    return repo.students.where((s) {
      final dept = (s['dept'] ?? s['department'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final sec = (s['sec'] ?? s['section'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final studentYear = StudentService.extractYear(
        (s['year_of_study'] ??
                s['year'] ??
                StudentService.calcYearFromSem(s['sem'] ?? s['semester']))
            .toString(),
      );

      bool belongsToClass = false;
      for (final classSec in targetClassSecs) {
        final cDept = classSec.split('-')[0].trim().toUpperCase();
        final rest = classSec.contains('-')
            ? classSec.split('-')[1].trim()
            : '';
        final cSec = rest.split(' ')[0].split('(')[0].trim().toUpperCase();
        final cYear = StudentService.extractYear(classSec);

        final matchDept =
            dept == cDept ||
            (cDept == 'CSE' && dept.contains('COMPUTER')) ||
            (cDept == 'IT' && dept.contains('INFORMATION'));
        final matchSec = sec == cSec;
        final matchYear =
            cYear.isEmpty || studentYear.isEmpty || studentYear == cYear;

        if (matchDept && matchSec && matchYear) {
          belongsToClass = true;
          break;
        }
      }
      return belongsToClass;
    }).toList();
  }

  // ── Subject-Aware Indicator Computations per Student ──────────────────────

  /// 1. Attendance percentage from student.students column / student object (NO FALLBACK)
  double _getAttendancePct(Map<String, dynamic> student, String subject) {
    final rawAtt =
        student['attendance_percentage'] ??
        student['attendance_pct'] ??
        student['attendancePct'];
    if (rawAtt != null) {
      final val = double.tryParse(rawAtt.toString());
      if (val != null && val > 0) return val;
    }

    final roll = (student['roll'] ?? '').toString().trim();
    final reg = (student['reg'] ?? student['register_no'] ?? '')
        .toString()
        .trim();
    final sessions = repo.attendanceSessions.where((s) {
      final matchesSubject =
          (subject == 'All Subjects') || s['subject'] == subject;
      return matchesSubject;
    }).toList();

    if (sessions.isNotEmpty) {
      int present = 0;
      int total = 0;
      for (final s in sessions) {
        final records = s['records'] as List? ?? [];
        final r = records
            .where((rec) => rec['roll'] == roll || rec['reg'] == reg)
            .toList();
        if (r.isNotEmpty) {
          total++;
          final st = r.first['status'] as String? ?? '';
          if (st == 'P' || st == 'OD' || st == 'ML') present++;
        }
      }
      if (total > 0) return (present / total * 100);
    }

    return 0.0;
  }

  List<Map<String, dynamic>> _getStudentMarks(
    String roll,
    String reg, [
    String? subject,
  ]) {
    final uRoll = roll.toUpperCase();
    final uReg = reg.toUpperCase();
    return repo.marks.where((m) {
      final sRoll = (m['studentRoll'] ?? m['student_roll'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final sReg = (m['register_no'] ?? m['reg_no'] ?? m['reg'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final matchesRoll =
          (uRoll.isNotEmpty && sRoll == uRoll) ||
          (uReg.isNotEmpty && sReg == uReg);
      final subj =
          (m['subject'] ?? m['subject_name'] ?? m['subject_code'] ?? '')
              .toString();
      final matchesSubject =
          (subject == null || subject == 'All Subjects') ||
          subj == subject ||
          subj.contains(subject);
      return matchesRoll && matchesSubject;
    }).toList();
  }

  /// 2. Average Marks Percentage calculating CIA I and CIA II from faculty.marks (NO FALLBACK)
  double _getMarksAvgPct(Map<String, dynamic> student, String subject) {
    final roll = (student['roll'] ?? '').toString().trim();
    final reg = (student['reg'] ?? student['register_no'] ?? '')
        .toString()
        .trim();
    final allMarks = _getStudentMarks(roll, reg, subject);

    final ciaMarks = allMarks.where((m) {
      final ass = (m['assessment'] ?? '').toString().toUpperCase();
      return ass.contains('CIA');
    }).toList();

    if (ciaMarks.isEmpty) return 0.0;

    double sumPct = 0.0;
    for (final m in ciaMarks) {
      final pct = double.tryParse(m['percentage']?.toString() ?? '');
      if (pct != null && pct > 0) {
        sumPct += pct;
      } else {
        final t = double.tryParse(m['total']?.toString() ?? '') ?? 0.0;
        final mx =
            double.tryParse(
              m['maxMarks']?.toString() ?? m['max_marks']?.toString() ?? '100',
            ) ??
            100.0;
        sumPct += mx > 0 ? (t / mx * 100) : 0.0;
      }
    }
    return sumPct / ciaMarks.length;
  }

  /// 3. Assignments loaded from faculty.assignment_marks & repo.assignments (NO FALLBACK)
  int _getAssignmentStats(Map<String, dynamic> student, String subject) {
    final reg =
        (student['reg'] ?? student['register_no'] ?? student['roll'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
    final roll = (student['roll'] ?? '').toString().trim().toUpperCase();

    final relevantAssignments = repo.assignments.where((a) {
      final subj = (a['subject'] ?? a['subject_name'] ?? '').toString();
      return subject == 'All Subjects' ||
          subj == subject ||
          subj.contains(subject);
    }).toList();

    if (relevantAssignments.isEmpty) return 0;

    int submitted = 0;
    for (final a in relevantAssignments) {
      final subs = a['submissions'] as List? ?? [];
      final hasSubmission = subs.any((s) {
        final r =
            (s['roll'] ??
                    s['studentRoll'] ??
                    s['reg_no'] ??
                    s['regNo'] ??
                    s['studentId'] ??
                    '')
                .toString()
                .trim()
                .toUpperCase();
        return (roll.isNotEmpty && r == roll) || (reg.isNotEmpty && r == reg);
      });

      if (hasSubmission) {
        submitted++;
      }
    }
    return ((submitted / relevantAssignments.length) * 100).toInt();
  }

  /// Progress Status: 'Needs Attention' if Attendance < 75% or Marks < 50% or Assignments < 50%
  String _getProgressStatus(double attPct, double marksPct, int assignmentPct) {
    if (attPct < 75.0 || marksPct < 50.0 || assignmentPct < 50) {
      return 'Needs Attention';
    }
    return 'On Track';
  }

  List<Map<String, dynamic>> get _filteredStudentList {
    final q = _searchQuery.toLowerCase();
    return _facultyScopedStudents.where((student) {
      final name = (student['name'] as String? ?? '').toLowerCase();
      final roll = (student['roll'] as String? ?? '').toLowerCase();
      final reg =
          (student['reg'] as String? ?? student['register_no'] as String? ?? '')
              .toLowerCase();
      final classSec = _buildClassSec(student);
      final studentYear = StudentService.extractYear(
        (student['year_of_study'] ??
                student['year'] ??
                StudentService.calcYearFromSem(
                  student['sem'] ?? student['semester'],
                ))
            .toString(),
      );

      final matchesSearch =
          q.isEmpty || name.contains(q) || roll.contains(q) || reg.contains(q);

      final selectedYearCode = StudentService.extractYear(_selectedYear);
      final matchesYear =
          _selectedYear == 'All Years' ||
          selectedYearCode.isEmpty ||
          studentYear == selectedYearCode;

      final matchesClass =
          _selectedClassSec == 'All Classes' ||
          classSec.contains(_selectedClassSec);

      final attPct = _getAttendancePct(student, _selectedSubject);
      final marksPct = _getMarksAvgPct(student, _selectedSubject);
      final assignPct = _getAssignmentStats(student, _selectedSubject);
      final status = _getProgressStatus(attPct, marksPct, assignPct);

      final matchesStatus =
          _selectedStatusFilter == 'All Statuses' ||
          status == _selectedStatusFilter;

      return matchesSearch && matchesYear && matchesClass && matchesStatus;
    }).toList();
  }

  // ── Metrics ──────────────────────────────────────────────────────────────

  int get _totalScopedStudents => _filteredStudentList.length;

  int get _needsAttentionCount {
    int count = 0;
    for (final student in _filteredStudentList) {
      final att = _getAttendancePct(student, _selectedSubject);
      final marks = _getMarksAvgPct(student, _selectedSubject);
      final assign = _getAssignmentStats(student, _selectedSubject);

      if (_getProgressStatus(att, marks, assign) == 'Needs Attention') {
        count++;
      }
    }
    return count;
  }

  int get _onTrackCount => _totalScopedStudents - _needsAttentionCount;

  int get _assignedClassesCount {
    if (_selectedSubject != 'All Subjects') {
      return _getClassesForSubject(_selectedSubject).length;
    }
    return _facultyClassSections.length;
  }

  // ── Export Report to CSV/Excel ───────────────────────────────────────────
  void _downloadReportCsv(List<Map<String, dynamic>> students) {
    final buffer = StringBuffer();
    // Add UTF-8 BOM for Microsoft Excel compatibility
    buffer.write('\uFEFF');

    // Header with uniform column spacing
    buffer.writeln(
      '"Roll / Reg No.      ","Student Name                    ","Class / Section           ","Attendance %","Marks Avg % ","Assignments %","Progress Status     "',
    );

    for (final student in students) {
      final roll =
          (student['roll'] ?? student['reg'] ?? student['register_no'] ?? '')
              .toString()
              .padRight(20);
      final name = (student['name'] ?? '')
          .toString()
          .replaceAll(',', ' ')
          .padRight(32);
      final classSec = _buildClassSec(
        student,
      ).replaceAll(',', ' ').padRight(26);

      final attPct = _getAttendancePct(student, _selectedSubject);
      final marksPct = _getMarksAvgPct(student, _selectedSubject);
      final assignPct = _getAssignmentStats(student, _selectedSubject);
      final status = _getProgressStatus(
        attPct,
        marksPct,
        assignPct,
      ).padRight(20);

      final attStr = '${attPct.toStringAsFixed(1)}%'.padRight(12);
      final marksStr = '${marksPct.toStringAsFixed(1)}%'.padRight(12);
      final assignStr = '$assignPct%'.padRight(13);

      buffer.writeln(
        '"$roll","$name","$classSec","$attStr","$marksStr","$assignStr","$status"',
      );
    }

    final fileName =
        'Student_Progress_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
    repo.triggerFileDownload(fileName, buffer.toString(), 'text/csv');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloaded report for ${students.length} students!'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final students = _filteredStudentList;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(students),
            const SizedBox(height: 20),
            _statCards(),
            const SizedBox(height: 20),
            _studentProgressTableCard(students),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _pageHeader(List<Map<String, dynamic>> students) {
    return Row(
      children: [
        Text(
          'Student Progress',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        _badge('Academic Year ${repo.selectedAcademicYear}'),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _downloadReportCsv(students),
          icon: const Icon(Icons.download, size: 15),
          label: Text(
            'Download Report',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCards() {
    final cards = [
      {
        'label': 'Total Assigned Students',
        'value': '$_totalScopedStudents',
        'icon': Icons.people_outline,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'label': 'On Track',
        'value': '$_onTrackCount',
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFECFDF5),
      },
      {
        'label': 'Needs Attention',
        'value': '$_needsAttentionCount',
        'icon': Icons.warning_amber_outlined,
        'color': const Color(0xFFDC2626),
        'bg': const Color(0xFFFEF2F2),
      },
      {
        'label': 'Assigned Classes',
        'value': '$_assignedClassesCount',
        'icon': Icons.class_outlined,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
      },
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final perRow = constraints.maxWidth < 650 ? 2 : 4;
        final w = (constraints.maxWidth - (perRow - 1) * 16) / perRow;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((c) {
            return SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c['bg'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        c['icon'] as IconData,
                        color: c['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c['value'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            c['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _studentProgressTableCard(List<Map<String, dynamic>> students) {
    return Container(
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Student Progress Roster',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                _countBadge('${students.length}'),

                // 1. Year Filter
                _dropdownWidget(
                  ['All Years', 'II Year', 'III Year', 'IV Year'],
                  _selectedYear,
                  (v) => setState(() {
                    _selectedYear = v!;
                    if (_selectedClassSec != 'All Classes') {
                      final cYear = StudentService.extractYear(
                        _selectedClassSec,
                      );
                      final selYearCode = StudentService.extractYear(
                        _selectedYear,
                      );
                      if (selYearCode.isNotEmpty && cYear != selYearCode) {
                        _selectedClassSec = 'All Classes';
                      }
                    }
                  }),
                ),

                // 2. Class/Section Filter (Synchronized with Year)
                _dropdownWidget(
                  ['All Classes', ..._availableClassOptions],
                  _availableClassOptions.contains(_selectedClassSec)
                      ? _selectedClassSec
                      : 'All Classes',
                  (v) => setState(() {
                    _selectedClassSec = v!;
                    if (_selectedClassSec != 'All Classes') {
                      final yrCode = StudentService.extractYear(
                        _selectedClassSec,
                      );
                      if (yrCode == 'II') _selectedYear = 'II Year';
                      if (yrCode == 'III') _selectedYear = 'III Year';
                      if (yrCode == 'IV') _selectedYear = 'IV Year';
                    }
                  }),
                ),

                // 3. Subject Filter
                _dropdownWidget(
                  ['All Subjects', ..._facultySubjects],
                  _selectedSubject,
                  (v) => setState(() {
                    _selectedSubject = v!;
                    if (!_availableClassOptions.contains(_selectedClassSec)) {
                      _selectedClassSec = 'All Classes';
                    }
                  }),
                ),

                // 4. Progress Status Filter
                _dropdownWidget(
                  ['All Statuses', 'Needs Attention', 'On Track'],
                  _selectedStatusFilter,
                  (v) => setState(() => _selectedStatusFilter = v!),
                ),

                // 5. Search Box
                SizedBox(
                  height: 38,
                  width: 190,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search student / roll...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),

                // 6. Refresh Button
                IconButton(
                  tooltip: 'Refresh Data',
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  onPressed: () async {
                    await StudentService.fetchFromSupabase();
                    await repo.loadData();
                    if (!mounted) return;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Student progress data refreshed!'),
                        backgroundColor: Color(0xFF2563EB),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                // 7. Reset Filters Button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedYear = 'All Years';
                      _selectedClassSec = 'All Classes';
                      _selectedSubject = 'All Subjects';
                      _selectedStatusFilter = 'All Statuses';
                      _searchCtrl.clear();
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.restart_alt, size: 15),
                  label: Text(
                    'Reset Filters',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          students.isEmpty
              ? _emptyState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final tableWidth = math.max(constraints.maxWidth, 1050.0);

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            _tableHeader(),
                            ...students.asMap().entries.map(
                              (e) => _tableRow(e.value, e.key.isOdd),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 25, child: _th('Roll / Reg No.')),
          Expanded(flex: 35, child: _th('Student Name')),
          Expanded(flex: 25, child: _th('Class / Section')),
          Expanded(flex: 20, child: _th('Attendance %')),
          Expanded(flex: 20, child: _th('Marks Avg %')),
          Expanded(flex: 20, child: _th('Assignments')),
          Expanded(flex: 30, child: _th('Progress Status')),
          Expanded(flex: 15, child: _th('Action')),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> student, bool alt) {
    final roll = (student['roll'] ?? student['register_no'] ?? '').toString();
    final name = (student['name'] ?? '').toString();
    final classSec = _buildClassSec(student);

    final attPct = _getAttendancePct(student, _selectedSubject);
    final marksPct = _getMarksAvgPct(student, _selectedSubject);
    final assignPct = _getAssignmentStats(student, _selectedSubject);
    final status = _getProgressStatus(attPct, marksPct, assignPct);
    final isNeedsAttention = status == 'Needs Attention';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: alt ? const Color(0xFFFAFAFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Roll No
          Expanded(
            flex: 25,
            child: Text(
              roll,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
          // Student Name
          Expanded(
            flex: 35,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Class / Section
          Expanded(
            flex: 25,
            child: Text(
              classSec,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          // Attendance Indicator
          Expanded(
            flex: 20,
            child: Row(
              children: [
                Icon(
                  attPct < 75.0
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  size: 14,
                  color: attPct < 75.0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF059669),
                ),
                const SizedBox(width: 4),
                Text(
                  '${attPct.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: attPct < 75.0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          // Marks Indicator
          Expanded(
            flex: 20,
            child: Text(
              '${marksPct.toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: marksPct < 50.0
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF334155),
              ),
            ),
          ),
          // Assignment Indicator
          Expanded(
            flex: 20,
            child: Text(
              '$assignPct% done',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          // Progress Status Badge
          Expanded(flex: 30, child: _statusBadge(status, isNeedsAttention)),
          // View Action Button
          Expanded(
            flex: 15,
            child: IconButton(
              icon: const Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              tooltip: 'View Academic Progress',
              onPressed: () => _showStudentProgressDialog(
                student,
                attPct,
                marksPct,
                assignPct,
                status,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Student Progress Detail Dialog ────────────────────────────────────────

  void _showStudentProgressDialog(
    Map<String, dynamic> student,
    double attPct,
    double marksPct,
    int assignPct,
    String progressStatus,
  ) {
    final roll = (student['roll'] ?? '').toString();
    final reg = (student['reg'] ?? student['register_no'] ?? '').toString();
    final name = (student['name'] ?? '').toString();
    final classSec = _buildClassSec(student);
    final marksList = _getStudentMarks(roll, reg, _selectedSubject);
    final subject = _selectedSubject == 'All Subjects'
        ? (_facultySubjects.isNotEmpty ? _facultySubjects.first : '')
        : _selectedSubject;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Roll: $roll | Reg: $reg | $classSec',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(
                      progressStatus,
                      progressStatus == 'Needs Attention',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),

                // Subject Scope Badge
                _badge('Subject Progress Overview: $subject'),
                const SizedBox(height: 16),

                // Indicator Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: _metricBox(
                        'Attendance',
                        '${attPct.toStringAsFixed(1)}%',
                        attPct < 75.0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                        attPct < 75.0 ? 'Below 75% Limit' : 'Good Standing',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricBox(
                        'Marks Average',
                        '${marksPct.toStringAsFixed(1)}%',
                        marksPct < 50.0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF2563EB),
                        'Across Internal Assessments',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricBox(
                        'Assignments',
                        '$assignPct%',
                        const Color(0xFF7C3AED),
                        'Submitted on time',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Marks Breakdown
                Text(
                  'Assessment Performance Breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                marksList.isEmpty
                    ? Text(
                        'No assessment marks recorded yet for this student.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Column(
                        children: marksList.map((m) {
                          final score = m['total']?.toString() ?? 'N/A';
                          final maxM =
                              m['maxMarks']?.toString() ??
                              m['max_marks']?.toString() ??
                              '100';
                          final grade = m['grade']?.toString() ?? '-';
                          final asmt = m['assessment']?.toString() ?? 'Exam';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    asmt,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                Text(
                                  '$score / $maxM',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Grade $grade',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 20),

                // Faculty Note Footer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: progressStatus == 'Needs Attention'
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: progressStatus == 'Needs Attention'
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        progressStatus == 'Needs Attention'
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        size: 18,
                        color: progressStatus == 'Needs Attention'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          progressStatus == 'Needs Attention'
                              ? 'Academic Attention Required: Student has low attendance or assessment scores. Consider scheduling counseling.'
                              : 'Student is performing well and meeting all academic progress criteria.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: progressStatus == 'Needs Attention'
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF065F46),
                          ),
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
    );
  }

  Widget _metricBox(String label, String val, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED UI HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xFF2563EB),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );

  Widget _countBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2563EB),
      ),
    ),
  );

  Widget _th(String t) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF475569),
    ),
  );

  Widget _statusBadge(String status, bool isNeedsAttention) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNeedsAttention
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNeedsAttention
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              size: 12,
              color: isNeedsAttention
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF166534),
            ),
            const SizedBox(width: 4),
            Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isNeedsAttention
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF166534),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.people_outline,
              size: 52,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              'No student records found',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No students match your filter or class allocation.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownWidget(
    List<String> items,
    String val,
    ValueChanged<String?> onChange,
  ) {
    final uniqueItems = items.toSet().toList();
    final validVal = uniqueItems.contains(val)
        ? val
        : (uniqueItems.isNotEmpty ? uniqueItems.first : val);

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
      initialValue: validVal,
      onSelected: onChange,
      itemBuilder: (context) {
        return uniqueItems.map((item) {
          final bool isSelected = item == validVal;
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
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              validVal,
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

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
