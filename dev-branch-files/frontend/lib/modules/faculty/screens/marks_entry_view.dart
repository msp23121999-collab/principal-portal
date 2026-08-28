// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';
import '../services/timetable_service.dart';
import '../services/marks_entry_service.dart';
import '../services/course_allocation_service.dart';

/// Marks Entry View (Faculty Portal)
/// Standard Question Pattern for CIA I & CIA II:
/// S.No, Register Number, Student Name & Status, Part A (10), Part B (40), Total (50), Grade, Status, Remarks
class MarksEntryView extends StatefulWidget {
  const MarksEntryView({super.key});

  @override
  State<MarksEntryView> createState() => _MarksEntryViewState();
}

class _MarksEntryViewState extends State<MarksEntryView> {
  final repo = ErpRepository();
  String _exam = 'CIA - I';
  String _class = '';
  String _subject = '';

  List<Map<String, dynamic>> _localMarks = [];
  bool _isEditing = false;
  bool _isLoading = false;

  // Question Breakdown & Configuration State (Part A, Part B, Part C)
  // No hardcoded default pattern is shown — the saved pattern is fetched from
  // `faculty.assessment_question_sets` for the selected CIA / class / subject.
  // If none exists the roster prompts the faculty to set one first.
  bool _showQuestionBreakdown = false;
  bool _hasQuestionPattern = false;

  Map<String, dynamic> _questionConfig = {
    'partA': {'title': 'Part A', 'questions': <Map<String, dynamic>>[]},
    'partB': {'title': 'Part B', 'questions': <Map<String, dynamic>>[]},
    'partC': {'title': 'Part C', 'questions': <Map<String, dynamic>>[]},
  };

  /// Extracts the section (e.g. "A") from a class string like "CSE - A (III Year)".
  String _sectionFromClass() {
    final cls = _class.trim();
    if (cls.isEmpty) return 'A';
    final parts = cls.split('-');
    if (parts.length >= 2) {
      final rest = parts[1].trim();
      final sec = rest.split('(')[0].trim().split(' ')[0];
      return sec.isNotEmpty ? sec : 'A';
    }
    return 'A';
  }

  Map<String, dynamic> _emptyQuestionConfig() {
    return {
      'partA': {'title': 'Part A', 'questions': <Map<String, dynamic>>[]},
      'partB': {'title': 'Part B', 'questions': <Map<String, dynamic>>[]},
      'partC': {'title': 'Part C', 'questions': <Map<String, dynamic>>[]},
    };
  }

  /// Converts a saved `assessment_question_sets.parts_config_json` list into the
  /// in-memory `_questionConfig` shape keyed by partA / partB / partC.
  Map<String, dynamic> _questionConfigFromParts(List<dynamic> parts) {
    final cfg = {
      'partA': {'title': 'Part A', 'questions': <Map<String, dynamic>>[]},
      'partB': {'title': 'Part B', 'questions': <Map<String, dynamic>>[]},
      'partC': {'title': 'Part C', 'questions': <Map<String, dynamic>>[]},
    };
    for (final raw in parts) {
      final p = Map<String, dynamic>.from(raw as Map);
      final title = (p['part'] ?? '').toString().toUpperCase();
      final qs = (p['questions'] as List? ?? [])
          .map((q) => Map<String, dynamic>.from(q as Map))
          .toList();
      if (title.contains('PART A') || title == 'A') {
        cfg['partA'] = {'title': 'Part A', 'questions': qs};
      } else if (title.contains('PART B') || title == 'B') {
        cfg['partB'] = {'title': 'Part B', 'questions': qs};
      } else if (title.contains('PART C') || title == 'C') {
        cfg['partC'] = {'title': 'Part C', 'questions': qs};
      }
    }
    return cfg;
  }

  bool _hasPatternInConfig(Map<String, dynamic> cfg) {
    final a = (cfg['partA']['questions'] as List? ?? []).length;
    final b = (cfg['partB']['questions'] as List? ?? []).length;
    final c = ((cfg['partC']?['questions']) as List? ?? []).length;
    return (a + b + c) > 0;
  }

  /// Builds the full marks document stored as JSON in `faculty.marks.marks_json`.
  Map<String, dynamic> _buildMarksJson(Map<String, dynamic> m) {
    final overallMax = (m['overallMax'] as num? ?? 50.0).toDouble();
    return {
      'assessment': _exam,
      'class_sec': _class,
      'subject': _subject,
      'partA': (m['partA'] as num? ?? 0.0).toDouble(),
      'partB': (m['partB'] as num? ?? 0.0).toDouble(),
      'partC': (m['partC'] as num? ?? 0.0).toDouble(),
      'total': (m['total'] as num? ?? 0.0).toDouble(),
      'maxMarks': overallMax,
      'percentage': (m['percentage'] as num? ?? 0.0).toDouble(),
      'grade': (m['grade'] ?? '-').toString(),
      'status': (m['status'] ?? 'Draft').toString(),
      'attendance': (m['attendanceStatus'] ?? 'Present').toString(),
      'remarks': (m['remarks'] ?? '').toString(),
      'questions': Map<String, dynamic>.from(m['qMarks'] as Map? ?? {}),
    };
  }

  // Focus matrix for keyboard navigation
  List<List<FocusNode>> _focusMatrix = [];

  @override
  void initState() {
    super.initState();
    _initSelection();
    _loadLocalRoster();
  }

  @override
  void dispose() {
    _disposeFocusMatrix();
    super.dispose();
  }

  void _initSelection() {
    final classes = CourseAllocationService.getAllocatedClasses();
    if (classes.isNotEmpty) {
      _class = classes.first;
      final subjects = CourseAllocationService.getAllocatedSubjects(
        selectedClass: _class,
      );
      if (subjects.isNotEmpty) _subject = subjects.first;
    } else {
      final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
      final ttClasses = TimetableService.getClassesForFaculty(facultyId);
      if (ttClasses.isNotEmpty) {
        _class = ttClasses.first;
        final subjects = TimetableService.getSubjectsForClass(
          facultyId,
          _class,
        );
        if (subjects.isNotEmpty) _subject = subjects.first;
      } else {
        _class = '';
        _subject = '';
      }
    }
  }

  void _disposeFocusMatrix() {
    for (final row in _focusMatrix) {
      for (final node in row) {
        node.dispose();
      }
    }
    _focusMatrix.clear();
  }

  List<Map<String, dynamic>> _extractQuestionsList(dynamic rawObj) {
    if (rawObj is List) {
      return rawObj.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  void _initFocusMatrix(int studentCount) {
    _disposeFocusMatrix();
    if (studentCount <= 0) return;

    final rawA = _extractQuestionsList(_questionConfig['partA']?['questions']);
    final rawB = _extractQuestionsList(_questionConfig['partB']?['questions']);
    final rawC = _extractQuestionsList(_questionConfig['partC']?['questions']);

    final qALen = _getEnterableQuestions(rawA).length;
    final qBLen = _getEnterableQuestions(rawB).length;
    final qCLen = _getEnterableQuestions(rawC).length;
    final qCount = _showQuestionBreakdown ? (qALen + qBLen + qCLen) : 2;

    _focusMatrix = List.generate(
      studentCount,
      (i) => List.generate(qCount > 0 ? qCount : 2, (j) => FocusNode()),
    );
  }

  String _normalizeExam(String exam) {
    return exam.replaceAll(' - ', ' ').trim();
  }

  void _loadRosterData() {
    _loadLocalRoster();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded roster for $_class - $_exam'),
        behavior: SnackBarBehavior.floating,
        width: 300,
      ),
    );
  }

  Future<void> _loadLocalRoster() async {
    setState(() => _isLoading = true);
    _isEditing = false;
    try {
      final filteredStudents =
          await CourseAllocationService.fetchStudentsForClass(_class);
      final normExam = _normalizeExam(_exam);

      final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
      final courseCode =
          CourseAllocationService.getCourseCodeForClassAndSubject(
            _class,
            _subject,
          ) ??
          '';
      final dbMarks = await MarksEntryService.fetchStudentMarks(
        facultyId: facultyId,
        courseCode: courseCode,
        assessment: _exam,
      );

      final questionSet = courseCode.isNotEmpty
          ? await MarksEntryService.fetchQuestionSet(
              assessmentName: _exam,
              courseCode: courseCode,
              section: _sectionFromClass(),
            )
          : null;
      final Map<String, dynamic> questionConfig;
      final bool hasPattern;
      if (questionSet != null) {
        questionConfig = _questionConfigFromParts(
          questionSet['parts'] as List? ?? [],
        );
        hasPattern = _hasPatternInConfig(questionConfig);
      } else {
        questionConfig = _emptyQuestionConfig();
        hasPattern = false;
      }

      setState(() {
        _questionConfig = questionConfig;
        _hasQuestionPattern = hasPattern;
        _showQuestionBreakdown = hasPattern;
        _localMarks = filteredStudents.map((s) {
          final stuId = (s['studentId'] ?? s['student_id'] ?? s['id'] ?? '')
              .toString();
          final roll = (s['roll'] ?? s['studentId'] ?? '').toString();
          final name = (s['name'] ?? s['full_name'] ?? '').toString();
          final reg = (s['reg'] ?? s['register_no'] ?? roll).toString();

          final matchingRows = dbMarks.where((m) {
            final matchesStu =
                (m['register_no'] ?? m['studentRoll'] ?? '').toString() ==
                    reg ||
                (m['student_roll'] ?? m['studentRoll'] ?? '').toString() ==
                    roll;
            final matchesExam =
                _normalizeExam(m['assessment'] ?? '') == normExam;
            return matchesStu && matchesExam;
          }).toList();

          final match =
              matchingRows.where((m) {
                final q =
                    m['question_marks'] ??
                    m['question_marks_json'] ??
                    m['marks_json'];
                if (q is Map) return q.isNotEmpty;
                if (q is String) return q.trim().isNotEmpty && q.trim() != '{}';
                return false;
              }).firstOrNull ??
              matchingRows.firstOrNull ??
              repo.marks
                  .where(
                    (m) =>
                        m['studentRoll'] == roll &&
                        m['subject'] == _subject &&
                        _normalizeExam(m['assessment'] ?? '') == normExam,
                  )
                  .firstOrNull ??
              <String, dynamic>{};

          if (match.isNotEmpty) {
            final res = Map<String, dynamic>.from(match);
            res['studentId'] = stuId.isNotEmpty
                ? stuId
                : (res['student_id'] ?? '').toString();
            res['studentRoll'] = roll;
            res['studentName'] = name;
            res['studentReg'] = reg;
            res['isDirty'] = false;

            Map<String, dynamic> dbQMarks = {};
            final qRaw =
                res['question_marks'] ??
                res['question_marks_json'] ??
                res['marks_json'];
            if (qRaw is Map) {
              dbQMarks = Map<String, dynamic>.from(qRaw);
              if (dbQMarks.containsKey('questions') &&
                  dbQMarks['questions'] is Map) {
                dbQMarks = Map<String, dynamic>.from(
                  dbQMarks['questions'] as Map,
                );
              }
            } else if (qRaw is String && qRaw.trim().isNotEmpty) {
              try {
                final decoded = jsonDecode(qRaw);
                if (decoded is Map) {
                  dbQMarks = Map<String, dynamic>.from(decoded);
                  if (dbQMarks.containsKey('questions') &&
                      dbQMarks['questions'] is Map) {
                    dbQMarks = Map<String, dynamic>.from(
                      dbQMarks['questions'] as Map,
                    );
                  }
                }
              } catch (_) {}
            }
            res['qMarks'] = dbQMarks;
            res['partA'] = (res['part_a'] as num? ?? 0.0).toDouble();
            res['partB'] = (res['part_b'] as num? ?? 0.0).toDouble();
            res['partC'] = (res['part_c'] as num? ?? 0.0).toDouble();
            res['total'] = (res['total'] as num? ?? 0.0).toDouble();
            res['attendanceStatus'] =
                (res['is_absent'] == true || res['status'] == 'Absent')
                ? 'Absent'
                : (res['attendanceStatus'] ?? 'Present').toString();
            res['remarks'] = (res['remarks'] ?? '').toString();
            return res;
          } else {
            return {
              'studentId': stuId,
              'studentRoll': roll,
              'studentName': name,
              'studentReg': reg,
              'subject': _subject,
              'assessment': _exam,
              'qMarks': <String, dynamic>{},
              'partA': 0.0,
              'partB': 0.0,
              'partC': 0.0,
              'total': 0.0,
              'percentage': 0.0,
              'grade': 'F',
              'status': 'Fail',
              'attendanceStatus': 'Present',
              'remarks': '',
              'isDirty': false,
            };
          }
        }).toList();

        _initFocusMatrix(_localMarks.length);

        for (int i = 0; i < _localMarks.length; i++) {
          _recalculate(i);
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getEnterableQuestions(
    List<Map<String, dynamic>> rawList,
  ) {
    final Set<String> parentBasesWithSubs = {};
    for (final q in rawList) {
      final name = (q['name'] ?? '').toString().trim();
      final bool isSub =
          (q['isSubDiv'] == true) ||
          RegExp(r'\([a-zA-Z]\)$|[a-zA-Z]$').hasMatch(name);
      if (isSub) {
        final match = RegExp(r'^(Q?\d+)').firstMatch(name);
        if (match != null) {
          parentBasesWithSubs.add(match.group(1)!);
        }
      }
    }

    return rawList.where((q) {
      final name = (q['name'] ?? '').toString().trim();
      final bool isSub =
          (q['isSubDiv'] == true) ||
          RegExp(r'\([a-zA-Z]\)$|[a-zA-Z]$').hasMatch(name);
      if (!isSub && parentBasesWithSubs.contains(name)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _recalculate(int idx) {
    final m = _localMarks[idx];
    final attStatus = (m['attendanceStatus'] ?? 'Present').toString();

    if (attStatus == 'Absent') {
      m['partA'] = 0.0;
      m['partB'] = 0.0;
      m['partC'] = 0.0;
      m['total'] = 0.0;
      m['percentage'] = 0.0;
      m['grade'] = 'F';
      m['status'] = 'Absent';
      return;
    } else if (attStatus == 'OD' || attStatus == 'On Duty') {
      m['partA'] = 0.0;
      m['partB'] = 0.0;
      m['partC'] = 0.0;
      m['total'] = 0.0;
      m['percentage'] = 0.0;
      m['grade'] = 'OD';
      m['status'] = 'OD';
      return;
    }

    final qAList = _getEnterableQuestions(
      _extractQuestionsList(_questionConfig['partA']?['questions']),
    );
    final qBList = _getEnterableQuestions(
      _extractQuestionsList(_questionConfig['partB']?['questions']),
    );
    final qCList = _getEnterableQuestions(
      _extractQuestionsList(_questionConfig['partC']?['questions']),
    );

    final bool hasQuestions =
        (qAList.isNotEmpty || qBList.isNotEmpty || qCList.isNotEmpty);

    if (_showQuestionBreakdown || hasQuestions) {
      final Map<String, dynamic> qMarks = Map<String, dynamic>.from(
        m['qMarks'] as Map? ?? {},
      );

      double pA = 0.0;
      for (final q in qAList) {
        final qName = (q['name'] ?? '').toString();
        final keyA = 'A_$qName';
        final val =
            qMarks[keyA] ?? (qMarks.containsKey(keyA) ? 0.0 : qMarks[qName]);
        pA += (val as num? ?? 0.0).toDouble();
      }

      double pB = 0.0;
      for (final q in qBList) {
        final qName = (q['name'] ?? '').toString();
        final keyB = 'B_$qName';
        final val =
            qMarks[keyB] ?? (qMarks.containsKey(keyB) ? 0.0 : qMarks[qName]);
        pB += (val as num? ?? 0.0).toDouble();
      }

      double pC = 0.0;
      for (final q in qCList) {
        final qName = (q['name'] ?? '').toString();
        final keyC = 'C_$qName';
        final val =
            qMarks[keyC] ?? (qMarks.containsKey(keyC) ? 0.0 : qMarks[qName]);
        pC += (val as num? ?? 0.0).toDouble();
      }

      m['partA'] = pA;
      m['partB'] = pB;
      m['partC'] = pC;
      m['qMarks'] = qMarks;
    }

    final double partA = ((m['partA'] as num? ?? 0.0)).toDouble();
    final double partB = ((m['partB'] as num? ?? 0.0)).toDouble();
    final double partC = ((m['partC'] as num? ?? 0.0)).toDouble();

    m['partA'] = partA;
    m['partB'] = partB;
    m['partC'] = partC;

    double maxA = qAList.fold(
      0.0,
      (sum, q) => sum + ((q['max'] as num? ?? 0.0).toDouble()),
    );
    double maxB = qBList.fold(
      0.0,
      (sum, q) => sum + ((q['max'] as num? ?? 0.0).toDouble()),
    );
    double maxC = qCList.fold(
      0.0,
      (sum, q) => sum + ((q['max'] as num? ?? 0.0).toDouble()),
    );

    double totalMax = (maxA + maxB + maxC);
    if (totalMax == 0) totalMax = 50.0;

    final total = partA + partB + partC;
    m['total'] = total;
    m['overallMax'] = totalMax;

    final pct = (total / totalMax) * 100.0;
    m['percentage'] = pct;

    if (pct >= 90) {
      m['grade'] = 'O';
    } else if (pct >= 80) {
      m['grade'] = 'A+';
    } else if (pct >= 70) {
      m['grade'] = 'A';
    } else if (pct >= 60) {
      m['grade'] = 'B+';
    } else if (pct >= 50) {
      m['grade'] = 'B';
    } else {
      m['grade'] = 'F';
    }

    m['status'] = pct >= 50.0 ? 'Pass' : 'Fail';
  }

  void _showSetQuestionsDialog() {
    // Deep clone current question config
    final List<Map<String, dynamic>> partAQs = List<Map<String, dynamic>>.from(
      (_questionConfig['partA']['questions'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    final List<Map<String, dynamic>> partBQs = List<Map<String, dynamic>>.from(
      (_questionConfig['partB']['questions'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    final List<Map<String, dynamic>> partCQs = List<Map<String, dynamic>>.from(
      ((_questionConfig['partC']?['questions']) as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );

    final List<Map<String, dynamic>> customParts =
        List<Map<String, dynamic>>.from(
          ((_questionConfig['customParts'] as List?) ?? []).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );

    bool showBreakdownTemp = _showQuestionBreakdown;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            double totalA = partAQs.fold(
              0.0,
              (s, q) => s + ((q['max'] as num? ?? 0.0).toDouble()),
            );
            double totalB = partBQs.fold(
              0.0,
              (s, q) => s + ((q['max'] as num? ?? 0.0).toDouble()),
            );
            double totalC = partCQs.fold(
              0.0,
              (s, q) => s + ((q['max'] as num? ?? 0.0).toDouble()),
            );
            double overallTotal = totalA + totalB + totalC;

            int getNextMainNum(List<Map<String, dynamic>> list) {
              int maxNum = 0;
              final regExp = RegExp(r'^Q?(\d+)');
              for (final q in list) {
                final bool isSub =
                    (q['isSubDiv'] == true) ||
                    RegExp(
                      r'\([a-zA-Z]\)$|[a-zA-Z]$',
                    ).hasMatch((q['name'] ?? '').toString().trim());
                if (!isSub) {
                  final name = (q['name'] ?? '').toString().trim();
                  final match = regExp.firstMatch(name);
                  if (match != null) {
                    final parsed = int.tryParse(match.group(1) ?? '0') ?? 0;
                    if (parsed > maxNum) maxNum = parsed;
                  }
                }
              }
              return maxNum + 1;
            }

            Widget buildQuestionSection(
              String title,
              Color color,
              List<Map<String, dynamic>> qList,
              String prefix,
            ) {
              final double defaultMax = prefix == 'A'
                  ? 2.0
                  : (prefix == 'B' ? 13.0 : 15.0);
              final double inheritedMax = qList.isNotEmpty
                  ? ((qList.first['max'] as num? ?? defaultMax).toDouble())
                  : defaultMax;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${qList.length} Questions | Subtotal: ${qList.fold(0.0, (s, q) => s + ((q['max'] as num? ?? 0.0).toDouble())).toStringAsFixed(0)} Marks',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            setDlgState(() {
                              final int nextNum = getNextMainNum(qList);
                              qList.add({
                                'name': 'Q$nextNum',
                                'max': inheritedMax,
                                'co': 'CO1',
                                'isSubDiv': false,
                              });
                            });
                          },
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(
                            '+ Add Question',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (qList.isEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'No questions configured in $title yet. Click "+ Add Question" above to add.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      const SizedBox(height: 10),
                    if (qList.isNotEmpty)
                      ...qList.asMap().entries.map((entry) {
                        final qIdx = entry.key;
                        final q = entry.value;
                        final qNameStr = (q['name'] ?? '').toString();
                        final bool isSubDiv =
                            (q['isSubDiv'] == true) ||
                            RegExp(
                              r'\([a-zA-Z]\)$|[a-zA-Z]$',
                            ).hasMatch(qNameStr.trim());

                        return Container(
                          margin: EdgeInsets.only(
                            left: isSubDiv ? 28.0 : 0.0,
                            bottom: 6.0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSubDiv
                                ? color.withValues(alpha: 0.03)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSubDiv
                                  ? color.withValues(alpha: 0.35)
                                  : const Color(0xFFE2E8F0),
                              width: isSubDiv ? 1.2 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSubDiv) ...[
                                Icon(
                                  Icons.subdirectory_arrow_right,
                                  size: 16,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                              ],
                              SizedBox(
                                width: isSubDiv ? 146 : 166,
                                child: TextFormField(
                                  initialValue: qNameStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: isSubDiv
                                        ? 'Sub-Div Q. Name'
                                        : 'Q. Name',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    q['name'] = val.trim();
                                    if (RegExp(
                                      r'\([a-zA-Z]\)$|[a-zA-Z]$',
                                    ).hasMatch(val.trim())) {
                                      q['isSubDiv'] = true;
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: TextFormField(
                                  initialValue: (q['max'] ?? '').toString(),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Max Marks',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final parsed =
                                        double.tryParse(val.trim()) ?? 0.0;
                                    setDlgState(() => q['max'] = parsed);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: TextFormField(
                                  initialValue: (q['co'] ?? 'CO1').toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF334155),
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Target CO',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (val) => q['co'] = val.trim(),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.account_tree_outlined,
                                  size: 20,
                                  color: Color(0xFF2563EB),
                                ),
                                tooltip: 'Add sub-division (e.g. Q1(a), Q1(b))',
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setDlgState(() {
                                    final String currentName =
                                        (q['name'] ?? 'Q1').toString().trim();
                                    final double currentMax =
                                        (q['max'] as num? ?? 16.0).toDouble();
                                    final double splitMax = (currentMax / 2.0);

                                    final baseMatch = RegExp(
                                      r'^(Q?\d+)',
                                    ).firstMatch(currentName);
                                    final String baseStr = baseMatch != null
                                        ? baseMatch.group(1)!
                                        : currentName;

                                    q['isSubDiv'] = false;
                                    q['name'] = baseStr;

                                    int existingSubsCount = 0;
                                    int insertIndex = qIdx + 1;

                                    for (
                                      int i = qIdx + 1;
                                      i < qList.length;
                                      i++
                                    ) {
                                      final item = qList[i];
                                      final name = (item['name'] ?? '')
                                          .toString()
                                          .trim();
                                      final bool isSub =
                                          (item['isSubDiv'] == true) ||
                                          RegExp(
                                            r'\([a-zA-Z]\)$|[a-zA-Z]$',
                                          ).hasMatch(name);
                                      if (isSub && name.startsWith(baseStr)) {
                                        existingSubsCount++;
                                        insertIndex = i + 1;
                                      } else {
                                        break;
                                      }
                                    }

                                    if (existingSubsCount == 0) {
                                      qList.insertAll(qIdx + 1, [
                                        {
                                          'name': '$baseStr(a)',
                                          'max': splitMax,
                                          'co': q['co'] ?? 'CO1',
                                          'isSubDiv': true,
                                        },
                                        {
                                          'name': '$baseStr(b)',
                                          'max': splitMax,
                                          'co': q['co'] ?? 'CO2',
                                          'isSubDiv': true,
                                        },
                                      ]);
                                    } else {
                                      final nextChar = String.fromCharCode(
                                        97 + existingSubsCount,
                                      );
                                      qList.insert(insertIndex, {
                                        'name': '$baseStr($nextChar)',
                                        'max': splitMax,
                                        'co': q['co'] ?? 'CO1',
                                        'isSubDiv': true,
                                      });
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setDlgState(() => qList.removeAt(qIdx));
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.quiz_outlined,
                          color: Color(0xFF7C3AED),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set Exam Question Pattern (Part A, Part B, Part C)',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '$_exam | $_class | $_subject',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Exam Total: ${overallTotal.toStringAsFixed(0)} Marks',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'Show Q-Breakdown Columns',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Switch(
                              value: showBreakdownTemp,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (v) =>
                                  setDlgState(() => showBreakdownTemp = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 650,
                height: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildQuestionSection(
                        'PART A (2 Marks Each)',
                        const Color(0xFF2563EB),
                        partAQs,
                        'A',
                      ),
                      buildQuestionSection(
                        'PART B (13/14 Marks Each)',
                        const Color(0xFF7C3AED),
                        partBQs,
                        'B',
                      ),
                      buildQuestionSection(
                        'PART C (15 Marks Case Study)',
                        const Color(0xFF059669),
                        partCQs,
                        'C',
                      ),
                      ...customParts.map((p) {
                        final title = (p['title'] ?? 'PART D').toString();
                        final pQs = (p['questions'] as List? ?? [])
                            .cast<Map<String, dynamic>>();
                        return buildQuestionSection(
                          title,
                          Color(p['color'] as int? ?? 0xFFD97706),
                          pQs,
                          (p['prefix'] ?? 'D').toString(),
                        );
                      }),
                      const SizedBox(height: 8),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setDlgState(() {
                              final char = String.fromCharCode(
                                68 + customParts.length,
                              );
                              customParts.add({
                                'id': 'part$char',
                                'title': 'PART $char (Custom Part)',
                                'prefix': char,
                                'color': 0xFFD97706,
                                'questions': <Map<String, dynamic>>[
                                  {
                                    'name': 'Q1',
                                    'max': 10.0,
                                    'co': 'CO1',
                                    'isSubDiv': false,
                                  },
                                ],
                              });
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: Text(
                            '+ Add New Part (e.g. PART D)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () {
                    setDlgState(() {
                      partAQs.clear();
                      partBQs.clear();
                      partCQs.clear();
                      customParts.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                  child: Text(
                    'Reset to Default',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final bool hasPattern = _hasPatternInConfig({
                      'partA': {'title': 'Part A', 'questions': partAQs},
                      'partB': {'title': 'Part B', 'questions': partBQs},
                      'partC': {'title': 'Part C', 'questions': partCQs},
                      'customParts': customParts,
                    });

                    setState(() {
                      _hasQuestionPattern = hasPattern;
                      _showQuestionBreakdown = hasPattern;
                      _questionConfig = {
                        'partA': {'title': 'Part A', 'questions': partAQs},
                        'partB': {'title': 'Part B', 'questions': partBQs},
                        'partC': {'title': 'Part C', 'questions': partCQs},
                        'customParts': customParts,
                      };
                      _initFocusMatrix(_localMarks.length);
                      for (int i = 0; i < _localMarks.length; i++) {
                        _recalculate(i);
                      }
                    });

                    final courseCode =
                        CourseAllocationService.getCourseCodeForClassAndSubject(
                          _class,
                          _subject,
                        ) ??
                        '24CST57';
                    await MarksEntryService.saveQuestionSet(
                      assessmentName: _exam,
                      courseCode: courseCode,
                      department: 'CSE',
                      section: _sectionFromClass(),
                      academicYear: repo.selectedAcademicYear,
                      partsConfig: [
                        {'part': 'Part A', 'questions': partAQs, 'max': totalA},
                        {'part': 'Part B', 'questions': partBQs, 'max': totalB},
                        {'part': 'Part C', 'questions': partCQs, 'max': totalC},
                        ...customParts.map(
                          (p) => {
                            'part': p['title'] ?? 'Part D',
                            'questions': p['questions'] ?? [],
                            'max': 0.0,
                          },
                        ),
                      ],
                      totalMaxMarks: overallTotal,
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Question pattern (Part A, Part B, Part C) saved successfully ✓',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    'Save Pattern',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double get _avgMarks {
    if (_localMarks.isEmpty) return 0;
    final totalSum = _localMarks
        .map((m) => (m['total'] as num? ?? 0.0).toDouble())
        .reduce((a, b) => a + b);
    return totalSum / _localMarks.length;
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
      await CourseAllocationService.fetchAllocations(facultyId: facultyId);
      await _loadLocalRoster();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks roster refreshed successfully.'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Page Header ────────────────────────────────────────────────────────────
  Widget _pageHeader() {
    return Text(
      'Marks Entry',
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) repo.setGlobalPrintContent(_buildMarksHtml());
        });

        if (_isLoading && _localMarks.isEmpty) {
          return const FacultyLoadingWidget();
        }

        return Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _pageHeader(),
                  const SizedBox(height: 20),
                  _heroCard(),
                  const SizedBox(height: 16),
                  _statsRow(),
                  const SizedBox(height: 20),
                  if (_localMarks.isEmpty)
                    _emptyRosterCard()
                  else if (!_hasQuestionPattern)
                    _noPatternCard()
                  else
                    _fullRosterSection(sw),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            if (_isLoading)
              const Positioned.fill(child: FacultyLoadingWidget()),
          ],
        );
      },
    );
  }

  // ── Current Assessment Hero Card ──────────────────────────────────────────
  Widget _heroCard() {
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';

    final allocClasses = CourseAllocationService.getAllocatedClasses();
    final ttClasses = TimetableService.getClassesForFaculty(facultyId);
    final List<String> allClasses = <String>{
      ...allocClasses,
      ...ttClasses,
    }.toList()..sort();

    final allocSubjects = CourseAllocationService.getAllocatedSubjects(
      selectedClass: _class,
    );
    final ttSubjects = TimetableService.getSubjectsForClass(facultyId, _class);
    final allSubjects = <String>{...allocSubjects, ...ttSubjects}.toList()
      ..sort();
    if (allSubjects.isNotEmpty && !allSubjects.contains(_subject)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _subject = allSubjects.first);
      });
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _heroDropdown(
            'Examination',
            ['CIA - I', 'CIA - II'],
            _exam,
            (v) => setState(() {
              _exam = v!;
              _loadLocalRoster();
            }),
          ),
          _heroDropdown(
            'Class & Section',
            allClasses.isEmpty ? [_class] : allClasses,
            _class,
            (v) => setState(() {
              _class = v!;
              _loadLocalRoster();
            }),
          ),
          _heroDropdown(
            'Subject',
            allSubjects.isEmpty ? [_subject] : allSubjects,
            allSubjects.contains(_subject)
                ? _subject
                : (allSubjects.isNotEmpty ? allSubjects.first : _subject),
            (v) => setState(() {
              _subject = v!;
              _loadLocalRoster();
            }),
          ),
          ElevatedButton.icon(
            onPressed: _loadRosterData,
            icon: const Icon(Icons.search, size: 16),
            label: Text(
              'Load Students',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
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
          ElevatedButton.icon(
            onPressed: _showSetQuestionsDialog,
            icon: const Icon(Icons.quiz_outlined, size: 16),
            label: Text(
              'Set Question Pattern',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _refreshData,
            icon: _isLoading
                ? LoadingAnimationWidget.hexagonDots(
                    color: const Color(0xFF2563EB),
                    size: 18,
                  )
                : const Icon(Icons.refresh_outlined, size: 16),
            label: Text(
              _isLoading ? '...' : 'Refresh',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              final cls = CourseAllocationService.getAllocatedClasses();
              final firstClass = cls.isNotEmpty ? cls.first : _class;
              final subs = CourseAllocationService.getAllocatedSubjects(
                selectedClass: firstClass,
              );
              setState(() {
                _exam = 'CIA - I';
                _class = firstClass;
                _subject = subs.isNotEmpty ? subs.first : _subject;
                _loadLocalRoster();
              });
            },
            icon: const Icon(Icons.history_outlined, size: 16),
            label: Text(
              'Reset Filters',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    final uniqueItems = items.toSet().toList();
    final String effectiveValue = uniqueItems.contains(value)
        ? value
        : (uniqueItems.isNotEmpty ? uniqueItems.first : value);
    final displayLabel = effectiveValue.isNotEmpty ? effectiveValue : label;

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
      initialValue: effectiveValue,
      onSelected: onChanged,
      itemBuilder: (context) {
        return uniqueItems.map((item) {
          final bool isSelected = item == effectiveValue;
          return PopupMenuItem<String>(
            value: item,
            height: 38,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 13,
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
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

  // ── Stats Pills Row ───────────────────────────────────────────────────────
  Widget _statsRow() {
    final total = _localMarks.length;
    final entered = _localMarks
        .where((m) => (m['total'] as num? ?? 0) > 0)
        .length;
    final pending = total - entered;
    final enteredPct = total > 0 ? (entered / total * 100).round() : 0;
    final pendingPct = total > 0 ? (pending / total * 100).round() : 0;
    final highest = _localMarks.isEmpty
        ? 0.0
        : _localMarks
              .map((m) => (m['total'] as num? ?? 0.0).toDouble())
              .reduce((a, b) => a > b ? a : b);
    final lowest = _localMarks.isEmpty
        ? 0.0
        : _localMarks.where((m) => (m['total'] as num? ?? 0) > 0).fold(999.0, (
            prev,
            m,
          ) {
            final v = (m['total'] as num? ?? 0).toDouble();
            return v < prev ? v : prev;
          });

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _statPill(
            Icons.people_outline,
            const Color(0xFF6366F1),
            const Color(0xFFEEF2FF),
            'Total Students',
            '$total',
            '',
          ),
          _statPill(
            Icons.check_circle_outline,
            const Color(0xFF16A34A),
            const Color(0xFFF0FDF4),
            'Entered',
            '$entered',
            '$enteredPct%',
          ),
          _statPill(
            Icons.access_time_outlined,
            const Color(0xFFF97316),
            const Color(0xFFFFF7ED),
            'Pending',
            '$pending',
            '$pendingPct%',
          ),
          _statPill(
            Icons.bar_chart_outlined,
            const Color(0xFF2563EB),
            const Color(0xFFEFF6FF),
            'Average Marks',
            _avgMarks.toStringAsFixed(1),
            '/ 50',
          ),
          _statPill(
            Icons.star_outline,
            const Color(0xFF8B5CF6),
            const Color(0xFFF5F3FF),
            'Highest Marks',
            highest.toStringAsFixed(0),
            '/ 50',
          ),
          _statPill(
            Icons.trending_down_outlined,
            const Color(0xFFEF4444),
            const Color(0xFFFEF2F2),
            'Lowest Marks',
            lowest == 999.0 ? '—' : '${lowest.toStringAsFixed(0)} / 50',
            '',
          ),
        ];

        final w = constraints.maxWidth;
        if (w >= 1150) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: cards[i]),
              ],
            ],
          );
        } else if (w >= 680) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[2]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: cards[3]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[4]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[5]),
                ],
              ),
            ],
          );
        } else if (w >= 450) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[3]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: cards[4]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[5]),
                ],
              ),
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                SizedBox(width: 170, child: cards[i]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statPill(
    IconData icon,
    Color fg,
    Color bg,
    String label,
    String value,
    String sub,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(width: 2),
                      Text(
                        ' $sub',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRosterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: _cardDecor(),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            'No students loaded for $_class',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when no question pattern is saved for the selected CIA / class /
  /// subject. Prompts the faculty to set one before entering marks.
  Widget _noPatternCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: _cardDecor(),
      child: Column(
        children: [
          const Icon(Icons.quiz_outlined, size: 48, color: Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          Text(
            'No question pattern set for $_exam | $_class | $_subject',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set a question pattern (Part A, Part B, Part C) before entering marks.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showSetQuestionsDialog,
            icon: const Icon(Icons.quiz_outlined, size: 16),
            label: Text(
              'Set Question Pattern',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullRosterSection(double sw) {
    final key = '${_exam}_${_class}_$_subject';
    final sheetStatus = repo.markSheetStatuses[key] ?? 'Draft';

    final total = _localMarks.length;
    final entered = _localMarks
        .where((m) => (m['total'] as num? ?? 0) > 0)
        .length;
    final pct = total > 0 ? (entered / total * 100).round() : 0;

    final qAList = _getEnterableQuestions(
      (_questionConfig['partA']['questions'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
    final qBList = _getEnterableQuestions(
      (_questionConfig['partB']['questions'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
    final qCList = _getEnterableQuestions(
      ((_questionConfig['partC']?['questions']) as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
    double minCalcWidth = _showQuestionBreakdown
        ? (45.0 +
              125.0 +
              190.0 +
              (qAList.isNotEmpty ? (qAList.length * 65.0) + 85.0 : 0.0) +
              (qBList.isNotEmpty ? (qBList.length * 70.0) + 85.0 : 0.0) +
              (qCList.isNotEmpty ? (qCList.length * 70.0) + 85.0 : 0.0) +
              90.0 +
              55.0 +
              80.0 +
              130.0 +
              24.0)
        : (45.0 +
              130.0 +
              220.0 +
              110.0 +
              110.0 +
              100.0 +
              60.0 +
              85.0 +
              140.0 +
              24.0);
    if (minCalcWidth < sw - 48) minCalcWidth = sw - 48;

    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final double tableWidth = math.max(
          cardConstraints.maxWidth - 40.0,
          minCalcWidth,
        );

        return Container(
          width: double.infinity,
          decoration: _cardDecor(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Progress & Action Toolbar ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final double maxA = qAList.fold(
                      0.0,
                      (sum, q) => sum + ((q['max'] as num? ?? 0.0).toDouble()),
                    );
                    final double maxB = qBList.fold(
                      0.0,
                      (sum, q) => sum + ((q['max'] as num? ?? 0.0).toDouble()),
                    );
                    final double maxC = qCList.fold(
                      0.0,
                      (sum, q) => sum + ((q['max'] as num? ?? 0.0).toDouble()),
                    );
                    final double overallMaxMarks = (maxA + maxB + maxC) > 0
                        ? (maxA + maxB + maxC)
                        : 50.0;

                    final titleRow = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Marks Entry Roster',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Max: ${overallMaxMarks.toStringAsFixed(0)} Marks',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                    final actionBtns = Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _importExcelCSV,
                          icon: const Icon(Icons.download_outlined, size: 14),
                          label: Text(
                            'Import Excel / CSV',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0284C7),
                            side: const BorderSide(color: Color(0xFFBAE6FD)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'excel') _exportExcel();
                            if (val == 'csv') _exportCSV();
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'excel',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.table_view,
                                    size: 16,
                                    color: Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Export Excel (.xls)',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'csv',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.text_snippet_outlined,
                                    size: 16,
                                    color: Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Export CSV (.csv)',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFBBF7D0),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.upload_outlined,
                                  size: 14,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Export Marks',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: Color(0xFF16A34A),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleRow,
                          const SizedBox(height: 10),
                          actionBtns,
                        ],
                      );
                    }
                    return Row(
                      children: [titleRow, const Spacer(), actionBtns],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: total > 0 ? entered / total : 0,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$pct%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$entered / $total Students Entered',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Standard Table Layout ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        // Header Row
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 45,
                                child: Text(
                                  'S.No',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 125,
                                child: Text(
                                  'Register Number',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: _showQuestionBreakdown ? 190 : 220,
                                child: Text(
                                  'Student Name & Status',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (_showQuestionBreakdown) ...[
                                if (qAList.isNotEmpty) ...[
                                  ...qAList.map((q) {
                                    final name = (q['name'] ?? '').toString();
                                    final maxVal = (q['max'] ?? 2).toString();
                                    return SizedBox(
                                      width: 65,
                                      child: Text(
                                        '$name ($maxVal)',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF93C5FD),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }),
                                  SizedBox(
                                    width: 85,
                                    child: Text(
                                      'Part A',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF60A5FA),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                                if (qBList.isNotEmpty) ...[
                                  ...qBList.map((q) {
                                    final name = (q['name'] ?? '').toString();
                                    final maxVal = (q['max'] ?? 13).toString();
                                    return SizedBox(
                                      width: 70,
                                      child: Text(
                                        '$name ($maxVal)',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFC084FC),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }),
                                  SizedBox(
                                    width: 85,
                                    child: Text(
                                      'Part B',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFC084FC),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                                if (qCList.isNotEmpty) ...[
                                  ...qCList.map((q) {
                                    final name = (q['name'] ?? '').toString();
                                    final maxVal = (q['max'] ?? 15).toString();
                                    return SizedBox(
                                      width: 70,
                                      child: Text(
                                        '$name ($maxVal)',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF6EE7B7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }),
                                  SizedBox(
                                    width: 85,
                                    child: Text(
                                      'Part C',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF34D399),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ] else ...[
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    'Part A',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF60A5FA),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    'Part B',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFC084FC),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                              SizedBox(
                                width: 90,
                                child: Text(
                                  'Total',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF34D399),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 55,
                                child: Text(
                                  'Grade',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  'Status',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 130,
                                child: Text(
                                  'Remarks',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Data Rows
                        Column(
                          children: _localMarks
                              .asMap()
                              .entries
                              .map((e) => _standardMarksRow(e.key, e.value))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Footer Actions & Status Bar ────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: sheetStatus == 'Submitted for Verification'
                              ? const Color(0xFFFFF7ED)
                              : sheetStatus == 'Saved' ||
                                    sheetStatus == 'Approved'
                              ? const Color(0xFFECFDF5)
                              : sheetStatus == 'Rejected'
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: sheetStatus == 'Submitted for Verification'
                                ? const Color(0xFFFED7AA)
                                : sheetStatus == 'Saved' ||
                                      sheetStatus == 'Approved'
                                ? const Color(0xFFA7F3D0)
                                : sheetStatus == 'Rejected'
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          'Status: $sheetStatus',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sheetStatus == 'Submitted for Verification'
                                ? const Color(0xFFC2410C)
                                : sheetStatus == 'Saved' ||
                                      sheetStatus == 'Approved'
                                ? const Color(0xFF065F46)
                                : sheetStatus == 'Rejected'
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed:
                            (sheetStatus == 'Submitted for Verification' ||
                                sheetStatus == 'Approved')
                            ? null
                            : () => setState(() => _isEditing = !_isEditing),
                        icon: Icon(
                          _isEditing
                              ? Icons.check_circle_outline
                              : Icons.edit_outlined,
                          size: 14,
                        ),
                        label: Text(
                          _isEditing ? 'Editing Enabled' : 'Edit Marks',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isEditing
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF2563EB),
                          side: BorderSide(
                            color: _isEditing
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFBFDBFE),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed:
                            (sheetStatus == 'Submitted for Verification' ||
                                sheetStatus == 'Approved')
                            ? null
                            : () async {
                                final dirtyMarks = _localMarks
                                    .where((m) => m['isDirty'] == true)
                                    .toList();
                                if (dirtyMarks.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No changed marks to save.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(milliseconds: 1500),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isLoading = true);
                                try {
                                  repo.saveMarkSheetDraft(
                                    _exam,
                                    _class,
                                    _subject,
                                    _localMarks,
                                  );
                                  repo.markSheetStatuses['${_exam}_${_class}_$_subject'] =
                                      'Saved';
                                  final facultyId =
                                      repo.profile['employeeId'] ??
                                      'EMP_CSE_002';
                                  final courseCode =
                                      CourseAllocationService.getCourseCodeForClassAndSubject(
                                        _class,
                                        _subject,
                                      ) ??
                                      '24CST57';
                                  for (final m in dirtyMarks) {
                                    final ok =
                                        await MarksEntryService.saveStudentMark(
                                          facultyEmployeeId: facultyId,
                                          studentId:
                                              (m['studentId'] ??
                                                      m['student_id'] ??
                                                      m['studentRoll'] ??
                                                      '')
                                                  .toString(),
                                          registerNo:
                                              (m['studentReg'] ??
                                                      m['studentRoll'] ??
                                                      '')
                                                  .toString(),
                                          studentRoll: (m['studentRoll'] ?? '')
                                              .toString(),
                                          studentName: (m['studentName'] ?? '')
                                              .toString(),
                                          subjectCode: courseCode,
                                          subjectName: _subject,
                                          assessment: _exam,
                                          academicYear:
                                              repo.selectedAcademicYear,
                                          partA: (m['partA'] as num? ?? 0.0)
                                              .toDouble(),
                                          partB: (m['partB'] as num? ?? 0.0)
                                              .toDouble(),
                                          partC: (m['partC'] as num? ?? 0.0)
                                              .toDouble(),
                                          totalMarks:
                                              (m['total'] as num? ?? 0.0)
                                                  .toDouble(),
                                          maxMarks:
                                              (m['overallMax'] as num? ?? 50.0)
                                                  .toDouble(),
                                          classSec: _class,
                                          year: (m['year'] ?? '').toString(),
                                          department: (m['dept'] ?? 'CSE')
                                              .toString(),
                                          section: (m['section'] ?? 'A')
                                              .toString(),
                                          percentage:
                                              (m['percentage'] as num? ?? 0.0)
                                                  .toDouble(),
                                          grade: (m['grade'] ?? '-').toString(),
                                          remarks: (m['remarks'] ?? '')
                                              .toString(),
                                          questionMarks:
                                              Map<String, dynamic>.from(
                                                m['qMarks'] as Map? ?? {},
                                              ),
                                          marksJson: _buildMarksJson(m),
                                          isAbsent:
                                              m['attendanceStatus'] == 'Absent',
                                          status: (m['status'] ?? 'Draft')
                                              .toString(),
                                        );
                                    if (ok) {
                                      m['isDirty'] = false;
                                    }
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Updated student marks saved successfully ✓',
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted)
                                    setState(() => _isLoading = false);
                                }
                              },
                        icon: const Icon(Icons.save_outlined, size: 15),
                        label: Text(
                          'Save Marks',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed:
                            (sheetStatus == 'Submitted for Verification' ||
                                sheetStatus == 'Approved')
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                  _isEditing = false;
                                });
                                try {
                                  repo.submitMarkSheet(
                                    _exam,
                                    _class,
                                    _subject,
                                    _localMarks,
                                  );
                                  repo.markSheetStatuses['${_exam}_${_class}_$_subject'] =
                                      'Submitted for Verification';
                                  final facultyId =
                                      repo.profile['employeeId'] ??
                                      'EMP_CSE_002';
                                  final courseCode =
                                      CourseAllocationService.getCourseCodeForClassAndSubject(
                                        _class,
                                        _subject,
                                      ) ??
                                      '24CST57';
                                  for (final m in _localMarks) {
                                    await MarksEntryService.saveStudentMark(
                                      facultyEmployeeId: facultyId,
                                      studentId:
                                          (m['studentId'] ??
                                                  m['student_id'] ??
                                                  m['studentRoll'] ??
                                                  '')
                                              .toString(),
                                      registerNo:
                                          (m['studentReg'] ??
                                                  m['studentRoll'] ??
                                                  '')
                                              .toString(),
                                      studentRoll: (m['studentRoll'] ?? '')
                                          .toString(),
                                      studentName: (m['studentName'] ?? '')
                                          .toString(),
                                      subjectCode: courseCode,
                                      subjectName: _subject,
                                      assessment: _exam,
                                      academicYear: repo.selectedAcademicYear,
                                      partA: (m['partA'] as num? ?? 0.0)
                                          .toDouble(),
                                      partB: (m['partB'] as num? ?? 0.0)
                                          .toDouble(),
                                      partC: (m['partC'] as num? ?? 0.0)
                                          .toDouble(),
                                      totalMarks: (m['total'] as num? ?? 0.0)
                                          .toDouble(),
                                      maxMarks: 50.0,
                                      classSec: _class,
                                      year: (m['year'] ?? '').toString(),
                                      department: (m['dept'] ?? 'CSE')
                                          .toString(),
                                      section: (m['section'] ?? 'A').toString(),
                                      percentage:
                                          (m['percentage'] as num? ?? 0.0)
                                              .toDouble(),
                                      grade: (m['grade'] ?? '-').toString(),
                                      remarks: (m['remarks'] ?? '').toString(),
                                      questionMarks: Map<String, dynamic>.from(
                                        m['qMarks'] as Map? ?? {},
                                      ),
                                      marksJson: _buildMarksJson(m),
                                      isAbsent:
                                          m['attendanceStatus'] == 'Absent',
                                      status: 'Submitted for Verification',
                                    );
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Marks submitted for verification successfully.',
                                        ),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted)
                                    setState(() => _isLoading = false);
                                }
                              },
                        icon: const Icon(Icons.send_outlined, size: 15),
                        label: Text(
                          'Submit for Verification',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _focusNextMarkCell(int rowIdx, int cellIdx) {
    final nextCellIdx = cellIdx + 1;
    FocusNode? targetNode;

    if (_focusMatrix.length > rowIdx &&
        _focusMatrix[rowIdx].length > nextCellIdx) {
      targetNode = _focusMatrix[rowIdx][nextCellIdx];
    } else if (_focusMatrix.length > rowIdx + 1 &&
        _focusMatrix[rowIdx + 1].isNotEmpty) {
      targetNode = _focusMatrix[rowIdx + 1][0];
    }

    if (targetNode != null) {
      targetNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          targetNode?.requestFocus();
        }
      });
    }
  }

  // ── Standard Marks Row Component ──────────────────────────────────────────
  Widget _standardMarksRow(int idx, Map<String, dynamic> m) {
    final key = '${_exam}_${_class}_$_subject';
    final sheetStatus = repo.markSheetStatuses[key] ?? 'Draft';
    final isEditable =
        _isEditing &&
        (sheetStatus != 'Submitted for Verification' &&
            sheetStatus != 'Approved');

    final attStatus = (m['attendanceStatus'] ?? 'Present').toString();
    final name = (m['studentName'] as String? ?? '').trim();
    final reg = (m['studentReg'] ?? m['studentRoll'] ?? '').toString();
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final grade = (m['grade'] ?? 'F').toString();
    final total = (m['total'] as num? ?? 0.0).toDouble();
    final overallM = (m['overallMax'] as num? ?? 50.0).toDouble();
    final partA = (m['partA'] as num? ?? 0.0).toDouble();
    final partB = (m['partB'] as num? ?? 0.0).toDouble();
    final partC = (m['partC'] as num? ?? 0.0).toDouble();
    final isEven = idx % 2 == 0;

    final avatarColors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFEA580C),
      const Color(0xFFDB2777),
    ];
    final avatarColor = avatarColors[idx % avatarColors.length];

    final qAList = _getEnterableQuestions(
      (_questionConfig['partA']['questions'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
    final qBList = _getEnterableQuestions(
      (_questionConfig['partB']['questions'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
    final qCList = _getEnterableQuestions(
      ((_questionConfig['partC']?['questions']) as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
    final Map<String, dynamic> qMarks = Map<String, dynamic>.from(
      m['qMarks'] as Map? ?? {},
    );

    int focusIdx = 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // S.No
          SizedBox(
            width: 45,
            child: Text(
              '${idx + 1}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Register Number
          SizedBox(
            width: 125,
            child: Text(
              reg,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Student Name & Attendance Toggle
          SizedBox(
            width: _showQuestionBreakdown ? 190 : 220,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: avatarColor,
                  child: Text(
                    initials.isEmpty ? 'S' : initials,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name.isEmpty ? 'Student ${idx + 1}' : name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: ['Present', 'Absent', 'OD'].map((s) {
                          final isSel = attStatus == s;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: InkWell(
                              onTap: isEditable
                                  ? () => setState(() {
                                      m['attendanceStatus'] = s;
                                      m['isDirty'] = true;
                                      _recalculate(idx);
                                    })
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(
                                          0xFF2563EB,
                                        ).withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSel
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  s,
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    color: isSel
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey[600],
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_showQuestionBreakdown) ...[
            if (qAList.isNotEmpty) ...[
              // Part A Question Cells
              ...qAList.map((q) {
                final qName = (q['name'] ?? '').toString();
                final keyA = 'A_$qName';
                final double maxVal = (q['max'] as num? ?? 2.0).toDouble();
                final double qVal =
                    (qMarks[keyA] as num? ??
                            (qMarks.containsKey(keyA)
                                ? 0.0
                                : (qMarks[qName] as num? ?? 0.0)))
                        .toDouble();
                final currentFIdx = focusIdx++;
                final fn =
                    (_focusMatrix.length > idx &&
                        _focusMatrix[idx].length > currentFIdx)
                    ? _focusMatrix[idx][currentFIdx]
                    : null;

                return SizedBox(
                  width: 65,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: attStatus == 'Present'
                        ? (isEditable
                              ? TextFormField(
                                  key: ValueKey('${m['studentRoll']}_$keyA'),
                                  focusNode: fn,
                                  textInputAction: TextInputAction.next,
                                  onEditingComplete: () =>
                                      _focusNextMarkCell(idx, currentFIdx),
                                  onFieldSubmitted: (_) =>
                                      _focusNextMarkCell(idx, currentFIdx),
                                  initialValue: qVal == 0.0
                                      ? ''
                                      : (qVal % 1 == 0
                                            ? qVal.toInt().toString()
                                            : qVal.toString()),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: '0',
                                    hintStyle: GoogleFonts.inter(
                                      color: const Color(0xFFCBD5E1),
                                      fontSize: 11,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 2,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2563EB),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onChanged: (valStr) {
                                    final parsed =
                                        double.tryParse(valStr.trim()) ?? 0.0;
                                    final double clamped = parsed.clamp(
                                      0.0,
                                      maxVal,
                                    );
                                    if (parsed > maxVal) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '$qName mark (${parsed.toStringAsFixed(0)}) auto-capped to max (${maxVal.toStringAsFixed(0)})',
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                    setState(() {
                                      qMarks[keyA] = clamped;
                                      m['qMarks'] = qMarks;
                                      m['isDirty'] = true;
                                      _recalculate(idx);
                                    });
                                  },
                                )
                              : Text(
                                  qVal.toStringAsFixed(0),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ))
                        : Text(
                            '—',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                  ),
                );
              }),

              // Part A Subtotal Badge
              SizedBox(
                width: 85,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    attStatus == 'Present' ? partA.toStringAsFixed(0) : '—',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],

            if (qBList.isNotEmpty) ...[
              // Part B Question Cells
              ...qBList.map((q) {
                final qName = (q['name'] ?? '').toString();
                final keyB = 'B_$qName';
                final double maxVal = (q['max'] as num? ?? 13.0).toDouble();
                final double qVal =
                    (qMarks[keyB] as num? ??
                            (qMarks.containsKey(keyB)
                                ? 0.0
                                : (qMarks[qName] as num? ?? 0.0)))
                        .toDouble();
                final currentFIdx = focusIdx++;
                final fn =
                    (_focusMatrix.length > idx &&
                        _focusMatrix[idx].length > currentFIdx)
                    ? _focusMatrix[idx][currentFIdx]
                    : null;

                return SizedBox(
                  width: 70,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: attStatus == 'Present'
                        ? (isEditable
                              ? TextFormField(
                                  key: ValueKey('${m['studentRoll']}_$keyB'),
                                  focusNode: fn,
                                  textInputAction: TextInputAction.next,
                                  onEditingComplete: () =>
                                      _focusNextMarkCell(idx, currentFIdx),
                                  onFieldSubmitted: (_) =>
                                      _focusNextMarkCell(idx, currentFIdx),
                                  initialValue: qVal == 0.0
                                      ? ''
                                      : (qVal % 1 == 0
                                            ? qVal.toInt().toString()
                                            : qVal.toString()),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: '0',
                                    hintStyle: GoogleFonts.inter(
                                      color: const Color(0xFFCBD5E1),
                                      fontSize: 11,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 2,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF7C3AED),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onChanged: (valStr) {
                                    final parsed =
                                        double.tryParse(valStr.trim()) ?? 0.0;
                                    final double clamped = parsed.clamp(
                                      0.0,
                                      maxVal,
                                    );
                                    if (parsed > maxVal) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '$qName mark (${parsed.toStringAsFixed(0)}) auto-capped to max (${maxVal.toStringAsFixed(0)})',
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                    setState(() {
                                      qMarks[keyB] = clamped;
                                      m['qMarks'] = qMarks;
                                      m['isDirty'] = true;
                                      _recalculate(idx);
                                    });
                                  },
                                )
                              : Text(
                                  qVal.toStringAsFixed(0),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ))
                        : Text(
                            '—',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                  ),
                );
              }),

              // Part B Subtotal Badge
              SizedBox(
                width: 85,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Text(
                    attStatus == 'Present' ? partB.toStringAsFixed(0) : '—',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ),
            ],

            // Part C Question Cells
            ...qCList.map((q) {
              final qName = (q['name'] ?? '').toString();
              final keyC = 'C_$qName';
              final double maxVal = (q['max'] as num? ?? 15.0).toDouble();
              final double qVal =
                  (qMarks[keyC] as num? ??
                          (qMarks.containsKey(keyC)
                              ? 0.0
                              : (qMarks[qName] as num? ?? 0.0)))
                      .toDouble();
              final currentFIdx = focusIdx++;
              final fn =
                  (_focusMatrix.length > idx &&
                      _focusMatrix[idx].length > currentFIdx)
                  ? _focusMatrix[idx][currentFIdx]
                  : null;

              return SizedBox(
                width: 70,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: attStatus == 'Present'
                      ? (isEditable
                            ? TextFormField(
                                key: ValueKey('${m['studentRoll']}_$keyC'),
                                focusNode: fn,
                                textInputAction: TextInputAction.next,
                                onEditingComplete: () =>
                                    _focusNextMarkCell(idx, currentFIdx),
                                onFieldSubmitted: (_) =>
                                    _focusNextMarkCell(idx, currentFIdx),
                                initialValue: qVal == 0.0
                                    ? ''
                                    : (qVal % 1 == 0
                                          ? qVal.toInt().toString()
                                          : qVal.toString()),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: '0',
                                  hintStyle: GoogleFonts.inter(
                                    color: const Color(0xFFCBD5E1),
                                    fontSize: 11,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 2,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0xFF059669),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onChanged: (valStr) {
                                  final parsed =
                                      double.tryParse(valStr.trim()) ?? 0.0;
                                  final double clamped = parsed.clamp(
                                    0.0,
                                    maxVal,
                                  );
                                  if (parsed > maxVal) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$qName mark (${parsed.toStringAsFixed(0)}) auto-capped to max (${maxVal.toStringAsFixed(0)})',
                                        ),
                                        backgroundColor: Colors.orange,
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  setState(() {
                                    qMarks[keyC] = clamped;
                                    m['qMarks'] = qMarks;
                                    m['isDirty'] = true;
                                    _recalculate(idx);
                                  });
                                },
                              )
                            : Text(
                                qVal.toStringAsFixed(0),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ))
                      : Text(
                          '—',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                ),
              );
            }),

            // Part C Subtotal Badge
            if (qCList.isNotEmpty)
              SizedBox(
                width: 85,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    attStatus == 'Present' ? partC.toStringAsFixed(0) : '—',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              ),
          ] else ...[
            // Part A Standard Field
            SizedBox(
              width: 110,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: attStatus == 'Present'
                    ? (isEditable
                          ? TextFormField(
                              key: ValueKey('${m['studentRoll']}_partA'),
                              focusNode:
                                  (_focusMatrix.length > idx &&
                                      _focusMatrix[idx].isNotEmpty)
                                  ? _focusMatrix[idx][0]
                                  : null,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () =>
                                  _focusNextMarkCell(idx, 0),
                              onFieldSubmitted: (_) =>
                                  _focusNextMarkCell(idx, 0),
                              initialValue: partA == 0.0
                                  ? ''
                                  : (partA % 1 == 0
                                        ? partA.toInt().toString()
                                        : partA.toString()),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: '0',
                                hintStyle: GoogleFonts.inter(
                                  color: const Color(0xFFCBD5E1),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 4,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onChanged: (valStr) {
                                final parsed =
                                    double.tryParse(valStr.trim()) ?? 0.0;
                                setState(() {
                                  m['partA'] = parsed;
                                  m['isDirty'] = true;
                                  _recalculate(idx);
                                });
                              },
                            )
                          : Text(
                              partA.toStringAsFixed(0),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ))
                    : Text(
                        '—',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
              ),
            ),
            // Part B Standard Field
            SizedBox(
              width: 110,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: attStatus == 'Present'
                    ? (isEditable
                          ? TextFormField(
                              key: ValueKey('${m['studentRoll']}_partB'),
                              focusNode:
                                  (_focusMatrix.length > idx &&
                                      _focusMatrix[idx].length > 1)
                                  ? _focusMatrix[idx][1]
                                  : null,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () =>
                                  _focusNextMarkCell(idx, 1),
                              onFieldSubmitted: (_) =>
                                  _focusNextMarkCell(idx, 1),
                              initialValue: partB == 0.0
                                  ? ''
                                  : (partB % 1 == 0
                                        ? partB.toInt().toString()
                                        : partB.toString()),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: '0',
                                hintStyle: GoogleFonts.inter(
                                  color: const Color(0xFFCBD5E1),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 4,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onChanged: (valStr) {
                                final parsed =
                                    double.tryParse(valStr.trim()) ?? 0.0;
                                setState(() {
                                  m['partB'] = parsed;
                                  m['isDirty'] = true;
                                  _recalculate(idx);
                                });
                              },
                            )
                          : Text(
                              partB.toStringAsFixed(0),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ))
                    : Text(
                        '—',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
              ),
            ),
          ],

          // Total
          SizedBox(
            width: 90,
            child: Text(
              attStatus == 'Present'
                  ? '${total.toStringAsFixed(0)} / ${overallM.toStringAsFixed(0)}'
                  : '—',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF047857),
              ),
            ),
          ),
          // Grade
          SizedBox(
            width: 55,
            child: Text(
              grade,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: (grade == 'O' || grade == 'A+' || grade == 'A')
                    ? const Color(0xFF15803D)
                    : (grade == 'F'
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFB45309)),
              ),
            ),
          ),
          // Status Badge
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: m['status'] == 'Pass'
                    ? const Color(0xFFDCFCE7)
                    : m['status'] == 'Absent'
                    ? const Color(0xFFFFEDD5)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                (m['status'] ?? 'Draft').toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: m['status'] == 'Pass'
                      ? const Color(0xFF15803D)
                      : m['status'] == 'Absent'
                      ? const Color(0xFFC2410C)
                      : const Color(0xFFB91C1C),
                ),
              ),
            ),
          ),
          // Remarks
          SizedBox(
            width: 130,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: isEditable
                  ? TextFormField(
                      key: ValueKey('${m['studentRoll']}_remarks'),
                      initialValue: (m['remarks'] ?? '').toString(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF334155),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Remarks...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFFCBD5E1),
                          fontSize: 11,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onChanged: (v) {
                        m['remarks'] = v;
                        m['isDirty'] = true;
                      },
                    )
                  : Text(
                      (m['remarks'] ?? '—').toString().isEmpty
                          ? '—'
                          : (m['remarks'] ?? '—').toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Excel & CSV Import ─────────────────────────────────────────────────────
  void _importExcelCSV() {
    repo.triggerNativeUpload((name, size, dataUrl) {
      try {
        String content = '';
        final commaIdx = dataUrl.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = dataUrl.substring(commaIdx + 1);
          try {
            content = utf8.decode(base64.decode(base64Str));
          } catch (_) {
            content = Uri.decodeComponent(base64Str);
          }
        } else {
          content = dataUrl;
        }

        final lines = content
            .split(RegExp(r'\r?\n'))
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        if (lines.isEmpty) return;

        final firstLine = lines.first;
        final String delimiter = firstLine.contains('\t')
            ? '\t'
            : (firstLine.contains(';') ? ';' : ',');

        List<String> parseLine(String line) {
          return line
              .split(delimiter)
              .map((c) => c.trim().replaceAll('"', '').replaceAll("'", ''))
              .toList();
        }

        final headers = parseLine(firstLine);

        // Gather all active question names
        final qAList = (_questionConfig['partA']['questions'] as List? ?? []);
        final qBList = (_questionConfig['partB']['questions'] as List? ?? []);
        final qCList = (_questionConfig['partC']?['questions'] as List? ?? []);
        final allQList = [...qAList, ...qBList, ...qCList];

        Map<String, int> qColMap = {};
        int colReg = -1;
        int colPartA = -1;
        int colPartB = -1;
        int colPartC = -1;
        int colRemarks = -1;

        String cleanToken(String s) =>
            s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

        for (int i = 0; i < headers.length; i++) {
          final hClean = cleanToken(headers[i]);
          if (hClean.contains('REG') ||
              hClean.contains('REGISTER') ||
              hClean.contains('ROLL')) {
            colReg = i;
          } else if (hClean.contains('PARTA') || hClean == 'A') {
            colPartA = i;
          } else if (hClean.contains('PARTB') || hClean == 'B') {
            colPartB = i;
          } else if (hClean.contains('PARTC') || hClean == 'C') {
            colPartC = i;
          } else if (hClean.contains('REMARK')) {
            colRemarks = i;
          }

          // Check for question column match
          for (final q in allQList) {
            final qName = (q['name'] ?? '').toString();
            if (qName.isNotEmpty && cleanToken(qName) == hClean) {
              qColMap[qName] = i;
            }
          }
        }

        int importedCount = 0;
        for (int i = 1; i < lines.length; i++) {
          final cols = parseLine(lines[i]);
          if (cols.length < 2) continue;

          final col0 = cols[0];
          final col1 = cols.length > 1 ? cols[1] : '';
          final col2 = cols.length > 2 ? cols[2] : '';

          final studentIdx = _localMarks.indexWhere((m) {
            final r = (m['studentRoll'] ?? '').toString().trim();
            final reg = (m['studentReg'] ?? '').toString().trim();
            return (r.isNotEmpty && (r == col0 || r == col1 || r == col2)) ||
                (reg.isNotEmpty && (reg == col0 || reg == col1 || reg == col2));
          });

          final targetIdx = studentIdx != -1
              ? studentIdx
              : ((i - 1) < _localMarks.length ? (i - 1) : -1);

          if (targetIdx != -1 && targetIdx < _localMarks.length) {
            final m = _localMarks[targetIdx];
            final qMarks = Map<String, dynamic>.from(m['qMarks'] as Map? ?? {});

            // Parse question column scores
            qColMap.forEach((qName, colIdx) {
              if (colIdx < cols.length) {
                final parsed = double.tryParse(cols[colIdx]) ?? 0.0;
                qMarks[qName] = parsed;
              }
            });
            m['qMarks'] = qMarks;

            if (colPartA != -1 && colPartA < cols.length) {
              m['partA'] = double.tryParse(cols[colPartA]) ?? m['partA'];
            }
            if (colPartB != -1 && colPartB < cols.length) {
              m['partB'] = double.tryParse(cols[colPartB]) ?? m['partB'];
            }
            if (colPartC != -1 && colPartC < cols.length) {
              m['partC'] = double.tryParse(cols[colPartC]) ?? m['partC'];
            }
            if (colRemarks != -1 && colRemarks < cols.length) {
              m['remarks'] = cols[colRemarks];
            }
            _recalculate(targetIdx);
            importedCount++;
          }
        }

        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported marks for $importedCount students from "$name" ✓',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
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

  // ── CSV Export ─────────────────────────────────────────────────────────────
  void _exportCSV() {
    final csvBuffer = StringBuffer();
    csvBuffer.write('\uFEFF'); // UTF-8 BOM

    final qAList = (_questionConfig['partA']['questions'] as List? ?? []);
    final qBList = (_questionConfig['partB']['questions'] as List? ?? []);
    final qCList = (_questionConfig['partC']?['questions'] as List? ?? []);

    final List<String> headerCols = ['S.No', 'Register Number', 'Student Name'];

    if (_showQuestionBreakdown) {
      for (final q in qAList) {
        headerCols.add('${q['name']} (${q['max']})');
      }
      headerCols.add('Part A Subtotal');

      for (final q in qBList) {
        headerCols.add('${q['name']} (${q['max']})');
      }
      headerCols.add('Part B Subtotal');

      for (final q in qCList) {
        headerCols.add('${q['name']} (${q['max']})');
      }
      if (qCList.isNotEmpty) headerCols.add('Part C Subtotal');
    } else {
      headerCols.add('Part A');
      headerCols.add('Part B');
    }

    headerCols.addAll(['Total Marks', 'Grade', 'Status', 'Remarks']);
    csvBuffer.writeln(headerCols.map((c) => '"$c"').join(','));

    for (int i = 0; i < _localMarks.length; i++) {
      final m = _localMarks[i];
      final reg = (m['studentReg'] ?? m['studentRoll'] ?? '').toString();
      final name = (m['studentName'] ?? '').toString();
      final qMarks = Map<String, dynamic>.from(m['qMarks'] as Map? ?? {});

      final List<String> rowCols = ['${i + 1}', reg, name];

      if (_showQuestionBreakdown) {
        for (final q in qAList) {
          final qName = (q['name'] ?? '').toString();
          final keyA = 'A_$qName';
          final val =
              qMarks[keyA] ??
              (qMarks.containsKey(keyA) ? 0.0 : (qMarks[qName] as num? ?? 0.0));
          rowCols.add('${(val as num? ?? 0.0).toDouble()}');
        }
        rowCols.add('${(m['partA'] as num? ?? 0.0).toDouble()}');

        for (final q in qBList) {
          final qName = (q['name'] ?? '').toString();
          final keyB = 'B_$qName';
          final val =
              qMarks[keyB] ??
              (qMarks.containsKey(keyB) ? 0.0 : (qMarks[qName] as num? ?? 0.0));
          rowCols.add('${(val as num? ?? 0.0).toDouble()}');
        }
        rowCols.add('${(m['partB'] as num? ?? 0.0).toDouble()}');

        for (final q in qCList) {
          final qName = (q['name'] ?? '').toString();
          final keyC = 'C_$qName';
          final val =
              qMarks[keyC] ??
              (qMarks.containsKey(keyC) ? 0.0 : (qMarks[qName] as num? ?? 0.0));
          rowCols.add('${(val as num? ?? 0.0).toDouble()}');
        }
        if (qCList.isNotEmpty)
          rowCols.add('${(m['partC'] as num? ?? 0.0).toDouble()}');
      } else {
        rowCols.add('${(m['partA'] as num? ?? 0.0).toDouble()}');
        rowCols.add('${(m['partB'] as num? ?? 0.0).toDouble()}');
      }

      final total = (m['total'] as num? ?? 0.0).toDouble();
      final overallM = (m['overallMax'] as num? ?? 50.0).toDouble();
      rowCols.add('$total / $overallM');
      rowCols.add((m['grade'] ?? '-').toString());
      rowCols.add((m['status'] ?? 'Draft').toString());
      rowCols.add((m['remarks'] ?? '').toString());

      csvBuffer.writeln(rowCols.map((c) => '"$c"').join(','));
    }

    repo.triggerFileDownload(
      'marks_${_exam.replaceAll(" ", "_")}_${_class.replaceAll(" ", "_")}.csv',
      csvBuffer.toString(),
      'text/csv',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV exported successfully ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Excel Export (.xls Spreadsheet) ───────────────────────────────────────
  void _exportExcel() {
    final qAList = _getEnterableQuestions(
      (_questionConfig['partA']['questions'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
    final qBList = _getEnterableQuestions(
      (_questionConfig['partB']['questions'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
    final qCList = _getEnterableQuestions(
      ((_questionConfig['partC']?['questions']) as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );

    final List<String> headerCols = ['S.No', 'Register Number', 'Student Name'];
    if (_showQuestionBreakdown) {
      for (final q in qAList) {
        headerCols.add('${q['name']} (${q['max']})');
      }
      headerCols.add('Part A Subtotal');

      for (final q in qBList) {
        headerCols.add('${q['name']} (${q['max']})');
      }
      headerCols.add('Part B Subtotal');

      for (final q in qCList) {
        headerCols.add('${q['name']} (${q['max']})');
      }
      if (qCList.isNotEmpty) headerCols.add('Part C Subtotal');
    } else {
      headerCols.add('Part A');
      headerCols.add('Part B');
    }
    headerCols.addAll(['Total Marks', 'Grade', 'Status', 'Remarks']);

    final xml = StringBuffer();
    xml.writeln('<?xml version="1.0"?>');
    xml.writeln('<?mso-application progid="Excel.Sheet"?>');
    xml.writeln(
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"',
    );
    xml.writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">');
    xml.writeln('<Styles>');
    xml.writeln(
      ' <Style ss:ID="header"><Font ss:Bold="1" ss:Color="#FFFFFF"/>'
      '<Interior ss:Color="#1E3A8A" ss:Pattern="Solid"/><Alignment ss:Horizontal="Center"/></Style>',
    );
    xml.writeln(
      ' <Style ss:ID="title"><Font ss:Bold="1" ss:Size="14" ss:Color="#1E3A8A"/></Style>',
    );
    xml.writeln(
      ' <Style ss:ID="center"><Alignment ss:Horizontal="Center"/></Style>',
    );
    xml.writeln('</Styles>');
    xml.writeln('<Worksheet ss:Name="Marks Sheet">');
    xml.writeln('<Table>');

    for (int i = 0; i < headerCols.length; i++) {
      xml.writeln(' <Column ss:Width="110" ss:StyleID="center"/>');
    }

    xml.writeln('<Row>');
    xml.writeln(
      ' <Cell ss:MergeAcross="${headerCols.length - 1}" ss:StyleID="title"><Data ss:Type="String">Marks Sheet - $_exam | Class: $_class | Subject: $_subject</Data></Cell>',
    );
    xml.writeln('</Row>');
    xml.writeln('<Row/>'); // Spacer

    xml.writeln('<Row ss:StyleID="header">');
    for (final col in headerCols) {
      xml.writeln(' <Cell><Data ss:Type="String">$col</Data></Cell>');
    }
    xml.writeln('</Row>');

    for (int i = 0; i < _localMarks.length; i++) {
      final m = _localMarks[i];
      final reg = (m['studentReg'] ?? m['studentRoll'] ?? '').toString();
      final name = (m['studentName'] ?? '').toString();
      final qMarks = Map<String, dynamic>.from(m['qMarks'] as Map? ?? {});

      final List<dynamic> rowVals = [i + 1, reg, name];

      if (_showQuestionBreakdown) {
        for (final q in qAList) {
          final qName = (q['name'] ?? '').toString();
          final keyA = 'A_$qName';
          final val =
              qMarks[keyA] ??
              (qMarks.containsKey(keyA) ? 0.0 : (qMarks[qName] as num? ?? 0.0));
          rowVals.add((val as num? ?? 0.0).toDouble());
        }
        rowVals.add((m['partA'] as num? ?? 0.0).toDouble());

        for (final q in qBList) {
          final qName = (q['name'] ?? '').toString();
          final keyB = 'B_$qName';
          final val =
              qMarks[keyB] ??
              (qMarks.containsKey(keyB) ? 0.0 : (qMarks[qName] as num? ?? 0.0));
          rowVals.add((val as num? ?? 0.0).toDouble());
        }
        rowVals.add((m['partB'] as num? ?? 0.0).toDouble());

        for (final q in qCList) {
          final qName = (q['name'] ?? '').toString();
          final keyC = 'C_$qName';
          final val =
              qMarks[keyC] ??
              (qMarks.containsKey(keyC) ? 0.0 : (qMarks[qName] as num? ?? 0.0));
          rowVals.add((val as num? ?? 0.0).toDouble());
        }
        if (qCList.isNotEmpty)
          rowVals.add((m['partC'] as num? ?? 0.0).toDouble());
      } else {
        rowVals.add((m['partA'] as num? ?? 0.0).toDouble());
        rowVals.add((m['partB'] as num? ?? 0.0).toDouble());
      }

      final total = (m['total'] as num? ?? 0.0).toDouble();
      final overallM = (m['overallMax'] as num? ?? 50.0).toDouble();
      rowVals.add('$total / $overallM');
      rowVals.add((m['grade'] ?? '-').toString());
      rowVals.add((m['status'] ?? 'Draft').toString());
      rowVals.add((m['remarks'] ?? '').toString());

      xml.writeln('<Row>');
      for (final val in rowVals) {
        if (val is num) {
          xml.writeln(' <Cell><Data ss:Type="Number">$val</Data></Cell>');
        } else {
          xml.writeln(' <Cell><Data ss:Type="String">$val</Data></Cell>');
        }
      }
      xml.writeln('</Row>');
    }

    xml.writeln('</Table></Worksheet></Workbook>');

    repo.triggerFileDownload(
      'marks_${_exam.replaceAll(" ", "_")}_${_class.replaceAll(" ", "_")}.xls',
      xml.toString(),
      'application/vnd.ms-excel',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel (.xls) downloaded ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── HTML Print / PDF Generation Template ──────────────────────────────────
  String _buildMarksHtml() {
    final normExam = _normalizeExam(_exam);
    final html = StringBuffer();
    html.writeln('''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Marks Sheet – $normExam</title>
<style>
  @page { size: landscape; margin: 8mm; }
  body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; padding: 20px; color: #0f172a; background: #fff; margin: 0; }
  .header { text-align:center; margin-bottom:12px; border-bottom: 2px solid #1e3a8a; padding-bottom: 8px; }
  .header h1 { margin:0; font-size:22px; color:#1e3a8a; font-weight:bold; }
  .header h3 { margin:4px 0 0; font-size:13px; color:#475569; font-weight:600; }
  .info { display:flex; justify-content:space-between; border:1px solid #cbd5e1;
          background:#f8fafc; border-radius:6px; padding:10px 16px; margin:12px 0; font-size:12px; }
  .info span { font-weight:bold; color:#1e293b; }
  table { width:100%; border-collapse:collapse; font-size:11px; margin-top:10px; }
  th { background:#0f172a; color:#fff; padding:8px; text-align:center; font-size:11px; text-transform:uppercase; border:1px solid #0f172a; }
  td { border:1px solid #cbd5e1; padding:8px; text-align:center; vertical-align:middle; }
</style>
</head>
<body>
<div class="header">
  <h1>K.S.R. COLLEGE OF ENGINEERING</h1>
  <h3>Academic Marks Sheet – $normExam</h3>
  <h3>Class: $_class | Subject: $_subject</h3>
</div>
<div class="info">
  <div>Faculty: <span>${repo.profile['name'] ?? 'Faculty'}</span></div>
  <div>Academic Year: <span>${repo.selectedAcademicYear}</span></div>
  <div>Generated: <span>${DateTime.now().toString().substring(0, 16)}</span></div>
</div>
<table>
<thead>
<tr>
  <th style="width:50px;">S.No</th>
  <th style="width:130px;">Register Number</th>
  <th style="text-align:left;">Student Name & Status</th>
  <th>Part A (10)</th>
  <th>Part B (40)</th>
  <th>Total (50)</th>
  <th>Grade</th>
  <th>Status</th>
  <th>Remarks</th>
</tr>
</thead>
<tbody>''');

    for (int i = 0; i < _localMarks.length; i++) {
      final m = _localMarks[i];
      final isPass = m['status'] == 'Pass';
      html.writeln('''<tr>
  <td>${i + 1}</td>
  <td style="font-family:monospace; font-weight:bold;">${m['studentReg'] ?? m['studentRoll']}</td>
  <td style="text-align:left; font-weight:bold;">${m['studentName']}</td>
  <td>${m['partA']}</td>
  <td>${m['partB']}</td>
  <td style="font-weight:bold; color:#1e3a8a;">${m['total']}</td>
  <td style="font-weight:bold;">${m['grade']}</td>
  <td><span style="padding:2px 8px; border-radius:4px; font-size:10px; font-weight:bold; background:${isPass ? '#f0fdf4' : '#fef2f2'}; color:${isPass ? '#16a34a' : '#dc2626'}">${m['status']}</span></td>
  <td>${m['remarks']}</td>
</tr>''');
    }

    html.writeln('</tbody></table></body></html>');
    return html.toString();
  }
}
