// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';
import '../services/timetable_service.dart';
import '../services/student_service.dart';
import '../services/marks_service.dart';
import '../services/feedback_service.dart';
import '../services/course_allocation_service.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final repo = ErpRepository();
  String _selectedReportType = 'Performance'; // 'Performance' or 'Feedback'

  // Faculty Scoped Allocation Lists (Only handling items)
  List<String> _facultySubjects = [];
  List<String> _facultyClassSections = [];

  // Horizontal Filters (No Department Filter, No Month Filter)
  String _selectedYear = 'All Years';
  String _selectedClass = 'All Classes';
  String _selectedSubject = 'All Subjects';
  String _selectedStatusFilter =
      'All Statuses'; // 'All Statuses', 'On Track', 'Needs Attention'
  String _selectedRatingFilter =
      'All Ratings'; // 'All Ratings', '5 Stars', '4 Stars', '3 Stars', '1-2 Stars'

  List<Map<String, dynamic>> _rawFeedbackData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initFacultyScope();
    _loadAllReportsData();
  }

  void _initFacultyScope() {
    final facultyId = repo.profile['employeeId']?.toString() ?? 'EMP_CSE_002';
    final allocClasses = CourseAllocationService.getAllocatedClasses();
    final allocSubjects = CourseAllocationService.getAllocatedSubjects();

    _facultySubjects = allocSubjects.isNotEmpty
        ? allocSubjects
        : TimetableService.getSubjectsForFaculty(facultyId);

    final sections = <String>{...allocClasses};
    for (final day in TimetableService.getByFaculty(facultyId)) {
      for (final p in (day['schedule'] as List? ?? [])) {
        final cls = p['classSec']?.toString();
        if (cls != null && cls.isNotEmpty) sections.add(cls);
      }
    }
    _facultyClassSections = sections.toList()..sort();
  }

  Future<void> _loadAllReportsData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final facultyId = repo.profile['employeeId']?.toString() ?? 'EMP_CSE_002';

      // Load Allocations, Students, Marks, Attendance, and Feedback
      await CourseAllocationService.fetchAllocations(facultyId: facultyId);
      await StudentService.fetchFromSupabase();
      MarksService.seedIfEmpty();
      await MarksService.fetchFromSupabase(facultyId: facultyId);

      final feedback = await FeedbackService.fetchFacultyFeedback(facultyId);

      _initFacultyScope();

      if (mounted) {
        setState(() {
          _rawFeedbackData = feedback;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Scoped Filter Options (STRICTLY Faculty Handling Scope) ───────────────
  List<String> get _availableYearOptions => [
    'All Years',
    'II Year',
    'III Year',
    'IV Year',
  ];

  List<String> get _availableClassOptions {
    final allocClasses = CourseAllocationService.getAllocatedClasses();
    final classesToUse = allocClasses.isNotEmpty
        ? allocClasses
        : _facultyClassSections;
    List<String> list;
    if (_selectedYear == 'All Years') {
      list = classesToUse;
    } else {
      final targetYearCode = StudentService.extractYear(_selectedYear);
      list = classesToUse.where((c) {
        final y = StudentService.extractYear(c);
        return y.isEmpty || y == targetYearCode;
      }).toList();
    }
    return ['All Classes', ...list].toSet().toList();
  }

  List<String> get _availableSubjectOptions {
    final subjs = CourseAllocationService.getAllocatedSubjects(
      selectedClass: _selectedClass != 'All Classes' ? _selectedClass : '',
    );
    final list = subjs.isNotEmpty ? subjs : _facultySubjects;
    return ['All Subjects', ...list].toSet().toList();
  }

  List<String> _getClassesForSubject(String subject) {
    final facultyId =
        repo.profile['employeeId']?.toString() ??
        repo.profile['facultyId']?.toString() ??
        'EMP_CSE_002';
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

  // ── Student Progress Roster Logic (Guarantees NO Duplicate Rows) ───────────
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

  // ── Attendance Calculation from student.attendance_table ─────────
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
      return (subject == 'All Subjects') || s['subject'] == subject;
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

  // ── Marks Calculation from faculty.marks (NO HARDCODED FALLBACKS) ────────
  double _getMarksAvgPct(Map<String, dynamic> student, String subject) {
    final roll = (student['roll'] ?? '').toString().trim().toUpperCase();
    final reg = (student['reg'] ?? student['register_no'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

    final allMarks = repo.marks.where((m) {
      final sRoll = (m['studentRoll'] ?? m['student_roll'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final sReg = (m['register_no'] ?? m['reg_no'] ?? m['reg'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final matchesRoll =
          (roll.isNotEmpty && sRoll == roll) || (reg.isNotEmpty && sReg == reg);
      final subj = (m['subject'] ?? m['subject_name'] ?? '').toString();
      final matchesSubject =
          (subject == 'All Subjects') ||
          subj == subject ||
          subj.contains(subject);
      return matchesRoll && matchesSubject;
    }).toList();

    if (allMarks.isEmpty) return 0.0;

    double sumPct = 0.0;
    int count = 0;
    for (final m in allMarks) {
      final pct = double.tryParse(m['percentage']?.toString() ?? '');
      if (pct != null) {
        sumPct += pct;
        count++;
      } else {
        final partA = double.tryParse(m['part_a']?.toString() ?? '0') ?? 0.0;
        final partB = double.tryParse(m['part_b']?.toString() ?? '0') ?? 0.0;
        final total = (partA + partB > 0)
            ? (partA + partB)
            : (double.tryParse(
                    m['total']?.toString() ?? m['marks']?.toString() ?? '0',
                  ) ??
                  0.0);
        final maxM =
            double.tryParse(
              m['maxMarks']?.toString() ?? m['max_marks']?.toString() ?? '50',
            ) ??
            50.0;
        if (maxM > 0) {
          sumPct += (total / maxM * 100);
          count++;
        }
      }
    }
    return count > 0 ? (sumPct / count) : 0.0;
  }

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
      if (hasSubmission) submitted++;
    }
    return ((submitted / relevantAssignments.length) * 100).toInt();
  }

  String _buildClassSec(Map<String, dynamic> student) {
    final dept = (student['dept'] ?? student['department'] ?? '').toString();
    final sec = (student['sec'] ?? student['section'] ?? '').toString();
    final rawYear =
        (student['year_of_study'] ??
                student['year'] ??
                StudentService.calcYearFromSem(
                  student['sem'] ?? student['semester'],
                ))
            .toString();
    final yearLabel = rawYear.contains('Year') ? rawYear : '$rawYear Year';
    return '$dept - $sec ($yearLabel)';
  }

  /// Fetches the actual subject for a student from database (marks / timetable / allocations)
  String _getStudentSubject(Map<String, dynamic> student) {
    if (_selectedSubject != 'All Subjects') return _selectedSubject;

    final roll = (student['roll'] ?? '').toString().trim().toUpperCase();
    final reg = (student['reg'] ?? student['register_no'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    final classSec = _buildClassSec(student);
    final allowedSubjects = _facultySubjects;

    // 1. Check repo.marks for student's recorded subjects THAT THIS FACULTY TEACHES
    final studentMarks = repo.marks.where((m) {
      final sRoll = (m['studentRoll'] ?? m['student_roll'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final sReg = (m['register_no'] ?? m['reg_no'] ?? m['reg'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final matchesRoll =
          (roll.isNotEmpty && sRoll == roll) || (reg.isNotEmpty && sReg == reg);
      final subj = (m['subject'] ?? m['subject_name'] ?? '').toString();
      final isHandledByFaculty = allowedSubjects.any(
        (fs) => subj == fs || subj.contains(fs),
      );
      return matchesRoll && isHandledByFaculty;
    }).toList();

    if (studentMarks.isNotEmpty) {
      final subjects = studentMarks
          .map((m) => (m['subject'] ?? m['subject_name'] ?? '').toString())
          .where((s) => allowedSubjects.any((fs) => s == fs || s.contains(fs)))
          .toSet();
      if (subjects.isNotEmpty) {
        return subjects.join(', ');
      }
    }

    // 2. Check Timetable for class section's assigned subject for this faculty
    final facultyId =
        repo.profile['employeeId']?.toString() ??
        repo.profile['facultyId']?.toString() ??
        'EMP_CSE_002';
    for (final day in TimetableService.getByFaculty(facultyId)) {
      for (final p in (day['schedule'] as List? ?? [])) {
        final c = (p['classSec'] ?? '').toString();
        final s = (p['subject'] ?? '').toString();
        if ((c.contains(classSec) || classSec.contains(c)) &&
            s.isNotEmpty &&
            allowedSubjects.contains(s)) {
          return s;
        }
      }
    }

    return allowedSubjects.isNotEmpty ? allowedSubjects.first : 'All Subjects';
  }

  /// Checks if a student is enrolled in or has records for the target subject filter
  bool _studentBelongsToSubject(
    Map<String, dynamic> student,
    String targetSubject,
  ) {
    if (targetSubject == 'All Subjects') return true;

    final roll = (student['roll'] ?? '').toString().trim().toUpperCase();
    final reg = (student['reg'] ?? student['register_no'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    final classSec = _buildClassSec(student);

    // 1. Check if student has marks for this subject
    final hasMarks = repo.marks.any((m) {
      final sRoll = (m['studentRoll'] ?? m['student_roll'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final sReg = (m['register_no'] ?? m['reg_no'] ?? m['reg'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final matchesRoll =
          (roll.isNotEmpty && sRoll == roll) || (reg.isNotEmpty && sReg == reg);
      final subj = (m['subject'] ?? m['subject_name'] ?? '').toString();
      return matchesRoll &&
          (subj == targetSubject || subj.contains(targetSubject));
    });
    if (hasMarks) return true;

    // 2. Check timetable assignments for classSec
    final facultyId = repo.profile['employeeId']?.toString() ?? 'FAC002';
    for (final day in TimetableService.getByFaculty(facultyId)) {
      for (final p in (day['schedule'] as List? ?? [])) {
        final c = (p['classSec'] ?? '').toString();
        final s = (p['subject'] ?? '').toString();
        if (s == targetSubject &&
            (c.contains(classSec) || classSec.contains(c))) {
          return true;
        }
      }
    }

    return false;
  }

  // ── Filtered Handling Performance Roster (1 Row per Student) ─────────────
  List<Map<String, dynamic>> get _filteredPerformance {
    return _facultyScopedStudents
        .where((student) {
          final classSec = _buildClassSec(student);
          final studentYear = StudentService.extractYear(
            (student['year_of_study'] ??
                    student['year'] ??
                    StudentService.calcYearFromSem(
                      student['sem'] ?? student['semester'],
                    ))
                .toString(),
          );

          final selectedYearCode = StudentService.extractYear(_selectedYear);
          final matchesYear =
              _selectedYear == 'All Years' ||
              selectedYearCode.isEmpty ||
              studentYear == selectedYearCode;
          final matchesClass =
              _selectedClass == 'All Classes' ||
              classSec.contains(_selectedClass);
          final matchesSubject = _studentBelongsToSubject(
            student,
            _selectedSubject,
          );

          final attPct = _getAttendancePct(student, _selectedSubject);
          final marksPct = _getMarksAvgPct(student, _selectedSubject);
          final assignPct = _getAssignmentStats(student, _selectedSubject);
          final status = (attPct >= 75.0 && marksPct >= 50.0 && assignPct >= 50)
              ? 'On Track'
              : 'Needs Attention';

          final matchesStatus =
              _selectedStatusFilter == 'All Statuses' ||
              status == _selectedStatusFilter;

          return matchesYear && matchesClass && matchesSubject && matchesStatus;
        })
        .map((s) {
          final roll = (s['roll'] ?? s['reg'] ?? '').toString();
          final name = (s['name'] ?? '').toString();
          final classSec = _buildClassSec(s);
          final studentSubject = _getStudentSubject(s);
          final attPct = _getAttendancePct(s, _selectedSubject);
          final marksPct = _getMarksAvgPct(s, _selectedSubject);
          final assignPct = _getAssignmentStats(s, _selectedSubject);
          final status = (attPct >= 75.0 && marksPct >= 50.0 && assignPct >= 50)
              ? 'On Track'
              : 'Needs Attention';

          return {
            'roll': roll,
            'name': name,
            'subject': studentSubject,
            'classSec': classSec,
            'marksPct': marksPct,
            'attPct': attPct,
            'status': status,
          };
        })
        .toList();
  }

  // ── Filtered Feedback Roster ──────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredFeedback {
    return _rawFeedbackData.where((f) {
      final sub = (f['subject'] ?? '').toString().toLowerCase();
      final code = (f['courseCode'] ?? '').toString().toLowerCase();
      final cls = (f['classSec'] ?? '').toString();
      final rating = (f['rating'] as num? ?? 5).toInt();

      final matchesYear =
          _selectedYear == 'All Years' || cls.contains(_selectedYear);
      final matchesClass =
          _selectedClass == 'All Classes' || cls.contains(_selectedClass);

      final selSubNorm = _selectedSubject.replaceAll(' ', '').toLowerCase();
      final subNorm = sub.replaceAll(' ', '');
      final codeNorm = code.replaceAll(' ', '');

      final matchesSubject =
          _selectedSubject == 'All Subjects' ||
          subNorm.contains(selSubNorm) ||
          selSubNorm.contains(subNorm) ||
          (codeNorm.isNotEmpty &&
              (codeNorm.contains(selSubNorm) || selSubNorm.contains(codeNorm)));

      final matchesRating =
          _selectedRatingFilter == 'All Ratings' ||
          (_selectedRatingFilter == '5 Stars' && rating == 5) ||
          (_selectedRatingFilter == '4 Stars' && rating == 4) ||
          (_selectedRatingFilter == '3 Stars' && rating == 3) ||
          (_selectedRatingFilter == '1-2 Stars' && rating <= 2);

      return matchesYear && matchesClass && matchesSubject && matchesRating;
    }).toList();
  }

  // ── Excel Export (Clean CSV file download with generous cell padding) ────────
  void _exportExcel() {
    final StringBuffer csv = StringBuffer();
    csv.write('\uFEFF'); // UTF-8 BOM for MS Excel auto-encoding

    String filename = 'Report.csv';

    if (_selectedReportType == 'Performance') {
      filename =
          'Performance_Report_${_selectedClass.replaceAll(' ', '_')}_${_selectedSubject.replaceAll(' ', '_')}.csv';

      // Clean Table Header directly without metadata blocks
      csv.writeln(
        '${"Roll No".padRight(18)},'
        '${"Student Name".padRight(32)},'
        '${"Subject".padRight(40)},'
        '${"Class / Section".padRight(25)},'
        '${"Average Marks %".padRight(20)},'
        '${"Attendance %".padRight(18)},'
        '${"Progress Status".padRight(20)}',
      );

      final data = _filteredPerformance;
      for (final r in data) {
        final roll = (r['roll'] ?? '').toString().padRight(18);
        final name = (r['name'] ?? '').toString().padRight(32);
        final sub = (r['subject'] ?? '').toString().padRight(40);
        final cls = (r['classSec'] ?? '').toString().padRight(25);
        final marksPct = '${(r['marksPct'] as num).toStringAsFixed(1)}%'
            .padRight(20);
        final attPct = '${(r['attPct'] as num).toStringAsFixed(1)}%'.padRight(
          18,
        );
        final status = (r['status'] ?? 'On Track').toString().padRight(20);

        csv.writeln(
          '"$roll","$name","$sub","$cls","$marksPct","$attPct","$status"',
        );
      }
    } else {
      filename =
          'Feedback_Report_${_selectedClass.replaceAll(' ', '_')}_${_selectedSubject.replaceAll(' ', '_')}.csv';

      // Clean Table Header directly without metadata blocks
      csv.writeln(
        '${"Response ID".padRight(20)},'
        '${"Subject Name".padRight(40)},'
        '${"Class & Section".padRight(25)},'
        '${"Rating (Out of 5)".padRight(20)},'
        '${"Knowledge".padRight(15)},'
        '${"Methodology".padRight(15)},'
        '${"Punctuality".padRight(15)},'
        '${"Availability".padRight(15)},'
        '${"Feedback Comment".padRight(50)},'
        '${"Date".padRight(18)}',
      );

      final data = _filteredFeedback;
      for (final r in data) {
        final id = (r['id'] ?? '').toString().padRight(20);
        final sub = (r['subject'] ?? '')
            .toString()
            .replaceAll(',', ' ')
            .padRight(40);
        final classSec = (r['classSec'] ?? '')
            .toString()
            .replaceAll(',', ' ')
            .padRight(25);
        final rating = '${r['rating'] ?? 5} / 5'.padRight(20);
        final k = '${r['knowledge'] ?? 5} / 5'.padRight(15);
        final m = '${r['methodology'] ?? 5} / 5'.padRight(15);
        final p = '${r['punctuality'] ?? 5} / 5'.padRight(15);
        final a = '${r['availability'] ?? 5} / 5'.padRight(15);
        final comment = (r['comment'] ?? '')
            .toString()
            .replaceAll(',', ' ')
            .replaceAll('\n', ' ')
            .padRight(50);
        final date = (r['date'] ?? '').toString().padRight(18);

        csv.writeln(
          '"$id","$sub","$classSec","$rating","$k","$m","$p","$a","$comment","$date"',
        );
      }
    }

    final bytes = html.Blob([csv.toString()], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(bytes);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel Report downloaded successfully! ($filename) ✓'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if ((_isLoading || repo.isLoadingData) && repo.students.isEmpty) {
          return const FacultyLoadingWidget();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _reportConfigCard(),
            const SizedBox(height: 20),
            _reportPreviewCard(),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  // ── Header: Title on Left, Year Badge & Export Excel on Right ──────────────
  Widget _pageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final rightControls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _badge('Academic Year ${repo.selectedAcademicYear}'),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _exportExcel,
              icon: const Icon(Icons.download_outlined, size: 15),
              label: Text(
                'Export Excel',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              rightControls,
            ],
          );
        }

        return Row(
          children: [
            Text(
              'Reports',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            rightControls,
          ],
        );
      },
    );
  }

  // ── Filter Parameters Bar (NO Department Filter, NO Month Filter) ─────────
  Widget _reportConfigCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Report Type Selector Chips
          Text(
            'Select Report Type',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 768;
              final items = [
                _typeChip(
                  'Performance Report',
                  'View assessment & exam stats',
                  'Performance',
                  Icons.trending_up_outlined,
                ),
                _typeChip(
                  'Student Feedback Report',
                  'View student feedback & ratings',
                  'Feedback',
                  Icons.star_border_outlined,
                ),
              ];
              if (isNarrow) {
                return Column(
                  children: items
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: w,
                        ),
                      )
                      .toList(),
                );
              }
              return Row(
                children: items
                    .map(
                      (w) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: w,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 16),

          // 2. Horizontal Filter Bar (Year -> Class & Sec -> Subject -> Status/Rating)
          Text(
            'Filter Parameters',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 1. Handling Year Filter
              SizedBox(
                width: 130,
                child: _dropdown(
                  _availableYearOptions,
                  _selectedYear,
                  (v) => setState(() {
                    _selectedYear = v!;
                    _selectedClass = 'All Classes';
                  }),
                ),
              ),

              // 2. Handling Class & Section Filter
              SizedBox(
                width: 170,
                child: _dropdown(
                  _availableClassOptions,
                  _availableClassOptions.contains(_selectedClass)
                      ? _selectedClass
                      : 'All Classes',
                  (v) => setState(() => _selectedClass = v!),
                ),
              ),

              // 3. Handling Subject Filter
              SizedBox(
                width: 190,
                child: _dropdown(
                  _availableSubjectOptions,
                  _availableSubjectOptions.contains(_selectedSubject)
                      ? _selectedSubject
                      : 'All Subjects',
                  (v) => setState(() => _selectedSubject = v!),
                ),
              ),

              // 4. Status / Rating Filter
              if (_selectedReportType == 'Performance')
                SizedBox(
                  width: 145,
                  child: _dropdown(
                    ['All Statuses', 'On Track', 'Needs Attention'],
                    _selectedStatusFilter,
                    (v) => setState(() => _selectedStatusFilter = v!),
                  ),
                )
              else
                SizedBox(
                  width: 135,
                  child: _dropdown(
                    [
                      'All Ratings',
                      '5 Stars',
                      '4 Stars',
                      '3 Stars',
                      '1-2 Stars',
                    ],
                    _selectedRatingFilter,
                    (v) => setState(() => _selectedRatingFilter = v!),
                  ),
                ),

              // 5. Reset Filters Button
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedYear = 'All Years';
                    _selectedClass = 'All Classes';
                    _selectedSubject = 'All Subjects';
                    _selectedStatusFilter = 'All Statuses';
                    _selectedRatingFilter = 'All Ratings';
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
                    horizontal: 14,
                    vertical: 10,
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
    );
  }

  Widget _typeChip(String title, String desc, String type, IconData icon) {
    final isSel = _selectedReportType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedReportType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSel ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSel ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSel ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              size: 18,
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 16,
              color: isSel ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSel
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Report Preview Card ───────────────────────────────────────────────────
  Widget _reportPreviewCard() {
    if (_selectedReportType == 'Feedback') {
      return _buildFeedbackReportPreview();
    }
    return _buildPerformanceReportPreview();
  }

  Widget _buildFeedbackReportPreview() {
    final data = _filteredFeedback;

    double avgRating = 0.0;
    if (data.isNotEmpty) {
      final sum = data.fold<num>(
        0,
        (prev, e) => prev + (e['rating'] as num? ?? 0),
      );
      avgRating = sum / data.length;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_border_outlined,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview: Student Feedback Report',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              _badge('${data.length} Submissions'),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(36),
              child: FacultyLoadingWidget(),
            )
          else if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.rate_review_outlined,
                      size: 40,
                      color: Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No feedback records available for selected criteria.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                _metricBox(
                  'OVERALL RATING',
                  '${avgRating.toStringAsFixed(1)} / 5.0',
                  'Average across responses',
                  const Color(0xFFEEF2FF),
                  const Color(0xFF4F46E5),
                  Icons.star_outlined,
                ),
                const SizedBox(width: 12),
                _metricBox(
                  'TOTAL RESPONSES',
                  '${data.length}',
                  'Submitted completions',
                  const Color(0xFFE6F4EA),
                  const Color(0xFF137333),
                  Icons.people_alt_outlined,
                ),
                const SizedBox(width: 12),
                _metricBox(
                  'FEEDBACK %',
                  '${(avgRating * 20).toStringAsFixed(1)}%',
                  'Satisfaction index',
                  const Color(0xFFE8F0FE),
                  const Color(0xFF1A73E8),
                  Icons.assignment_turned_in_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Feedback Responses Roster',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Response ID',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Subject Name',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Class & Sec',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Rating',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Knowledge',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Methodology',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Comments',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ...data.map((r) {
              final rating = r['rating'] ?? 5;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r['id']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${r['subject']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r['classSec']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$rating / 5',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r['knowledge'] ?? 5} / 5',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r['methodology'] ?? 5} / 5',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        '${r['comment'] ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceReportPreview() {
    final data = _filteredPerformance;

    double avgMarks = 0.0;
    double avgAtt = 0.0;
    int onTrack = 0;

    if (data.isNotEmpty) {
      double totalM = 0;
      double totalA = 0;
      for (final r in data) {
        final m = (r['marksPct'] as num).toDouble();
        final a = (r['attPct'] as num).toDouble();
        totalM += m;
        totalA += a;
        if (r['status'] == 'On Track') onTrack++;
      }
      avgMarks = totalM / data.length;
      avgAtt = totalA / data.length;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF10B981),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview: Student Progress - $_selectedClass',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              _badge('${data.length} Handling Students'),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(36),
              child: FacultyLoadingWidget(),
            )
          else if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No performance data available for the selected filters.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                _metricBox(
                  'CLASS AVG MARKS',
                  '${avgMarks.toStringAsFixed(1)}%',
                  'Average percentage score',
                  const Color(0xFFEEF2FF),
                  const Color(0xFF4F46E5),
                  Icons.assessment,
                ),
                const SizedBox(width: 12),
                _metricBox(
                  'CLASS AVG ATTENDANCE',
                  '${avgAtt.toStringAsFixed(1)}%',
                  'Average attendance percentage',
                  const Color(0xFFE6F4EA),
                  const Color(0xFF137333),
                  Icons.event_available,
                ),
                const SizedBox(width: 12),
                _metricBox(
                  'ON TRACK STUDENTS',
                  '$onTrack / ${data.length}',
                  'Satisfactory progress rate',
                  const Color(0xFFE8F0FE),
                  const Color(0xFF1A73E8),
                  Icons.trending_up_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Handling Students Progress Roster',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Roll No',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Student Name',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Subject',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Class / Sec',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Avg Marks %',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Attendance %',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Progress Status',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ...data.map((r) {
              final roll = r['roll'] ?? '';
              final name = r['name'] ?? '';
              final sub = r['subject'] ?? '';
              final cls = r['classSec'] ?? '';
              final marksPct = (r['marksPct'] as num).toDouble();
              final attPct = (r['attPct'] as num).toDouble();
              final status = r['status'] ?? 'On Track';
              final isOnTrack = status == 'On Track';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        roll,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        sub,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        cls,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${marksPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: marksPct >= 50
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${attPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: attPct >= 75
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOnTrack
                                ? const Color(0xFFE6F4EA)
                                : const Color(0xFFFCE8E6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOnTrack
                                  ? const Color(0xFF137333)
                                  : const Color(0xFFC5221F),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Performance Analytics & Graphs
            _buildPerformanceCharts(data),
          ],
        ],
      ),
    );
  }

  // ── Performance Visualization Charts (Dynamic from _filteredPerformance) ────
  Widget _buildPerformanceCharts(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox();

    final onTrackCount = data.where((r) => r['status'] == 'On Track').length;
    final needsAttentionCount = data.length - onTrackCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Row(
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              color: Color(0xFF2563EB),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Performance Analytics & Visualizations',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            if (isWide) {
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _marksBarChart(data)),
                      const SizedBox(width: 16),
                      Expanded(child: _attendanceBarChart(data)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _marksVsAttendanceComparisonChart(data),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _statusDistributionChart(
                          onTrackCount,
                          needsAttentionCount,
                          data.length,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Column(
              children: [
                _marksBarChart(data),
                const SizedBox(height: 16),
                _attendanceBarChart(data),
                const SizedBox(height: 16),
                _marksVsAttendanceComparisonChart(data),
                const SizedBox(height: 16),
                _statusDistributionChart(
                  onTrackCount,
                  needsAttentionCount,
                  data.length,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _marksBarChart(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Average Marks % by Student',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  final name = item['name'] as String;
                  final roll = item['roll'] as String;
                  final pct = (item['marksPct'] as num).toDouble().clamp(
                    0.0,
                    100.0,
                  );
                  final barHeight = (pct / 100.0) * 130.0;

                  return Tooltip(
                    message:
                        'Student: $name ($roll)\nAverage Marks: ${pct.toStringAsFixed(1)}%',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 24,
                            height: math.max(barHeight, 4.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 38,
                            child: Text(
                              roll.isNotEmpty ? roll : name,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceBarChart(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Average Attendance % by Student',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  final name = item['name'] as String;
                  final roll = item['roll'] as String;
                  final pct = (item['attPct'] as num).toDouble().clamp(
                    0.0,
                    100.0,
                  );
                  final barHeight = (pct / 100.0) * 130.0;

                  return Tooltip(
                    message:
                        'Student: $name ($roll)\nAttendance: ${pct.toStringAsFixed(1)}%',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 24,
                            height: math.max(barHeight, 4.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 38,
                            child: Text(
                              roll.isNotEmpty ? roll : name,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marksVsAttendanceComparisonChart(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              Text(
                'Marks % vs Attendance % Comparison',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Marks %',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Attendance %',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  final name = item['name'] as String;
                  final roll = item['roll'] as String;
                  final mPct = (item['marksPct'] as num).toDouble().clamp(
                    0.0,
                    100.0,
                  );
                  final aPct = (item['attPct'] as num).toDouble().clamp(
                    0.0,
                    100.0,
                  );
                  final mHeight = (mPct / 100.0) * 130.0;
                  final aHeight = (aPct / 100.0) * 130.0;

                  return Tooltip(
                    message:
                        'Student: $name ($roll)\nMarks: ${mPct.toStringAsFixed(1)}%\nAttendance: ${aPct.toStringAsFixed(1)}%',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 14,
                                height: math.max(mHeight, 4.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Container(
                                width: 14,
                                height: math.max(aHeight, 4.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 36,
                            child: Text(
                              roll.isNotEmpty ? roll : name,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDistributionChart(int onTrack, int needsAttention, int total) {
    final onTrackPct = total > 0
        ? (onTrack / total * 100).toStringAsFixed(1)
        : '0.0';
    final needsAttPct = total > 0
        ? (needsAttention / total * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Progress Status Distribution',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  if (onTrack > 0)
                    Expanded(
                      flex: onTrack,
                      child: Container(
                        color: const Color(0xFF10B981),
                        alignment: Alignment.center,
                        child: Text(
                          '$onTrack',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (needsAttention > 0)
                    Expanded(
                      flex: needsAttention,
                      child: Container(
                        color: const Color(0xFFEF4444),
                        alignment: Alignment.center,
                        child: Text(
                          '$needsAttention',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'On Track',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                '$onTrack ($onTrackPct%)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Needs Attention',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                '$needsAttention ($needsAttPct%)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Handling Students:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  '$total',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared UI Helpers ──────────────────────────────────────────────────────

  Widget _metricBox(
    String label,
    String value,
    String desc,
    Color bg,
    Color fg,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            Text(
              desc,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: fg.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    List<String> items,
    String val,
    ValueChanged<String?> onChange,
  ) {
    final uniqueItems = items.toSet().toList();
    final validVal = uniqueItems.contains(val)
        ? val
        : (uniqueItems.isNotEmpty ? uniqueItems.first : val);

    return PopupMenuButton<String>(
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
            height: 36,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
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
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                validVal,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

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
}
