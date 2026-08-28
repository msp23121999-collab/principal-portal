import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/supabase_service.dart';

class ReportsScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final String initialWorkflow;
  const ReportsScreen({super.key, this.onNavigate, this.initialWorkflow = 'Course Exit Survey'});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Top-right workflow selection: 'Course Exit Survey' or 'Course Feedback'
  late String _activeWorkflow;

  // Semesters list
  List<String> _semesters = [];

  // Subjects mapped by Semester
  Map<String, List<Map<String, String>>> _subjectsBySemester = {};

  // State variables for Course Exit Survey
  String _exitSurveySem = 'Semester ';
  String? _exitSurveySelectedSubject;
  // Selected reviews: { subjectCode: { CO1: 'HIGH', ... } }
  Map<String, Map<String, String>> _surveyReviews = {};
  // Tracks submitted survey subject codes: { subjectCode: true }
  Map<String, bool> _submittedSurveys = {};

  // State variables for Course Feedback
  String _feedbackSem = 'Semester ';
  // Ratings: { subjectCode: 'Excellent'/'Very Good'... }
  Map<String, String> _feedbackRatings = {};
  // 5-Metric Ratings for faculty.student_feedback_results
  Map<String, int> _metricKnowledge = {};
  Map<String, int> _metricMethodology = {};
  Map<String, int> _metricPunctuality = {};
  Map<String, int> _metricAvailability = {};
  Map<String, int> _metricOverall = {};
  // Comments: { subjectCode: 'Comments text' }
  Map<String, String> _feedbackComments = {};
  // Tracks submitted feedback for semesters/subjects
  Map<String, bool> _submittedFeedback = {};
  Map<String, bool> _submittedFeedbackSubjects = {};

  // Holds currently selected subject code for single-subject feedback evaluation
  // Holds currently selected subject code for single-subject feedback evaluation
  String? _selectedSubjectCodeForFeedback;

  int _getSemesterInt(String semLabel) {
    if (semLabel.contains('VIII')) return 8;
    if (semLabel.contains('VII')) return 7;
    if (semLabel.contains('VI')) return 6;
    if (semLabel.contains('IV')) return 4;
    if (semLabel.contains('III')) return 3;
    if (semLabel.contains('II')) return 2;
    if (semLabel.contains('I') && !semLabel.contains('V')) return 1;
    if (semLabel.contains('V')) return 5;
    if (semLabel.contains('EVEN')) return 6;
    return 5;
  }

  bool _initialized = false;

  @override
  void didUpdateWidget(covariant ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWorkflow != widget.initialWorkflow) {
      setState(() {
        _activeWorkflow = widget.initialWorkflow;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeDynamicSubjects();
      _initialized = true;
    }
  }

  void _initializeDynamicSubjects() {
    final appState = AppStateProvider.of(context);
    final dbMarks = appState.marksList;
    final dbTimetables = appState.timetables;

    final Map<String, List<Map<String, String>>> dynamicMap = {};
    final Set<String> addedCodes = {};

    final semVal = appState.studentProfileData?['semester'] ?? 5;
    final int semInt = semVal is int ? semVal : int.tryParse(semVal.toString()) ?? 5;
    final semRoman = (semInt >= 1 && semInt <= 8)
        ? ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'][semInt - 1]
        : 'V';
    final currentSemesterLabel = 'Semester $semRoman';

    final List<Map<String, String>> currentSubjects = [];
    
    for (var row in dbMarks) {
      final code = row['subject_code']?.toString() ?? '';
      var name = row['subject']?.toString() ?? '';
      if (code.isEmpty || addedCodes.contains(code)) continue;
      addedCodes.add(code);
      if (name.contains('(') && name.contains(')')) {
        name = name.substring(0, name.indexOf('(')).trim();
      }
      currentSubjects.add({'code': code, 'name': name});
    }

    for (var t in dbTimetables) {
      for (int p = 1; p <= 7; p++) {
        final code = t['period_$p']?.toString() ?? '';
        final name = t['subject_name']?.toString() ?? '';
        if (code.isNotEmpty && !addedCodes.contains(code)) {
          addedCodes.add(code);
          currentSubjects.add({'code': code, 'name': name.isEmpty ? code : name});
        }
      }
    }

    // All 8 Semesters only
    final allSemLabels = [
      'Semester I',
      'Semester II',
      'Semester III',
      'Semester IV',
      'Semester V',
      'Semester VI',
      'Semester VII',
      'Semester VIII',
    ];

    // Populate active semester subjects for current active semester
    dynamicMap[currentSemesterLabel] = currentSubjects;

    // For semesters without subjects registered in DB, keep empty list (don't show dummy/copied subjects)
    for (var sem in allSemLabels) {
      if (!dynamicMap.containsKey(sem)) {
        dynamicMap[sem] = [];
      }
    }

    _subjectsBySemester.clear();
    _subjectsBySemester.addAll(dynamicMap);
    _semesters.clear();
    _semesters.addAll(allSemLabels);
    
    if (!_semesters.contains(_exitSurveySem)) {
      _exitSurveySem = 'Semester V';
    }
    if (!_semesters.contains(_feedbackSem)) {
      _feedbackSem = 'Semester V';
    }
    // Do NOT auto-select a subject — user must click a subject card to see the form
  }

  @override
  void initState() {
    super.initState();
    _activeWorkflow = widget.initialWorkflow;
    _initializeSurveyState();
  }

  void _initializeSurveyState() {
    for (var sem in _subjectsBySemester.keys) {
      final subjects = _subjectsBySemester[sem] ?? [];
      for (var sub in subjects) {
        final code = sub['code']!;
        if (!_surveyReviews.containsKey(code)) {
          _surveyReviews[code] = {
            'CO1': 'HIGH',
            'CO2': 'HIGH',
            'CO3': 'HIGH',
            'CO4': 'HIGH',
            'CO5': 'HIGH',
          };
        }
      }
    }
  }

  // Renders a beautiful searchable semester selection dialog
  void _showSemesterSearchDialog({required bool isExitSurvey}) {
    showDialog(
      context: context,
      builder: (context) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredSems = _semesters
                .where((s) => s.toLowerCase().contains(filter.toLowerCase()))
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isExitSurvey
                    ? 'Exit Survey Semester Selector'
                    : 'Course Feedback Semester Selector',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search semester (e.g. V)',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          filter = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (filteredSems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text('No semesters match search filters.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredSems.length,
                          separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final sem = filteredSems[index];
                            final isCurrent = isExitSurvey ? (_exitSurveySem == sem) : (_feedbackSem == sem);

                            return ListTile(
                              title: Text(
                                sem,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF334155),
                                ),
                              ),
                              trailing: isCurrent ? const Icon(Icons.check, size: 16, color: Color(0xFF2563EB)) : null,
                              onTap: () {
                                setState(() {
                                  if (isExitSurvey) {
                                    _exitSurveySem = sem;
                                    // Reset selected subject so user must pick one
                                    _exitSurveySelectedSubject = null;
                                  } else {
                                    _feedbackSem = sem;
                                    _selectedSubjectCodeForFeedback = null;
                                  }
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_activeWorkflow == 'Course Exit Survey')
              _buildExitSurveyWorkflow(isDesktop)
            else
              _buildFeedbackWorkflow(isDesktop),
          ],
        ),
      ),
    );
  }



  Widget _buildWorkflowDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _activeWorkflow,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _activeWorkflow = val;
              });
            }
          },
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
          items: const [
            DropdownMenuItem(value: 'Course Exit Survey', child: Text('Course Exit Survey')),
            DropdownMenuItem(value: 'Course Feedback', child: Text('Course Feedback')),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COURSE EXIT SURVEY WORKFLOW
  // ---------------------------------------------------------------------------
  Widget _buildExitSurveyWorkflow(bool isDesktop) {
    final subjects = _subjectsBySemester[_exitSurveySem] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Semester selection bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showSemesterSearchDialog(isExitSurvey: true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'To search year & semester',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (subjects.isEmpty)
          _buildNoSubjectsPlaceholder()
        else ...[
          // Horizontal/wrap subjects selection grid
          const Text(
            'Select a Subject to survey:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final cardWidth = isDesktop ? 220.0 : (constraints.maxWidth > 0 ? constraints.maxWidth : 300.0);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: subjects.map((sub) {
                final code = sub['code']!;
                final name = sub['name']!;
                final isSel = _exitSurveySelectedSubject == code;

                return InkWell(
                  onTap: () => setState(() => _exitSurveySelectedSubject = code),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    width: cardWidth,
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                      border: Border.all(color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: isSel ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFFBFDBFE) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? const Color(0xFF1E40AF) : const Color(0xFF475569)),
                              ),
                            ),
                            if (isSel) const Icon(Icons.check_circle, size: 16, color: Color(0xFF2563EB)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text('Faculty: Assigned Handlers', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 24),

          // Detailed outcomes survey table
          if (_exitSurveySelectedSubject != null) ...[
            Text(
              'Course Outcomes & Review Matrix (${_exitSurveySelectedSubject})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 700),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2), // Unit/Outcome
                        1: FlexColumnWidth(2.5), // Lesson Name
                        2: FlexColumnWidth(4.5), // Topic (What you learned)
                        3: FlexColumnWidth(2.0), // Select Review
                      },
                      border: const TableBorder(
                        horizontalInside: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                      ),
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                          children: [
                            _buildTableCell('Unit/Outcome', isHeader: true),
                            _buildTableCell('Lesson Name', isHeader: true),
                            _buildTableCell('Topic (What you learned)', isHeader: true),
                            _buildTableCell('Select Review', isHeader: true),
                          ],
                        ),
                        ...List.generate(5, (index) {
                          final co = 'CO${index + 1}';
                          final lessonName = _getLessonNameForCO(index + 1);
                          final topicLearned = _getTopicLearnedForCO(index + 1);

                          return TableRow(
                            children: [
                              _buildTableCellWidget(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Text(
                                    co,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                  ),
                                ),
                              ),
                              _buildTableCell(lessonName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              _buildTableCell(topicLearned, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4)),
                              _buildTableCellWidget(
                                _buildReviewDropdown(_exitSurveySelectedSubject!, co),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit survey action
            if (!(_submittedSurveys[_exitSurveySelectedSubject!] ?? false))
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final appState = AppStateProvider.of(context);
                    final answers = _surveyReviews[_exitSurveySelectedSubject!] ?? {};
                    final payload = {
                      'subject': _exitSurveySelectedSubject,
                      'answers': answers,
                    };
                    SupabaseService.instance.submitExitSurveyLog(appState.dbStudentUuid ?? appState.studentId, jsonEncode(payload));

                    setState(() {
                      _submittedSurveys[_exitSurveySelectedSubject!] = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Course Exit Survey for $_exitSurveySelectedSubject submitted successfully to faculty!'),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                  label: const Text('Submit Survey Outcomes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    '✓ Survey submitted for this subject',
                    style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildReviewDropdown(String subjectCode, String co) {
    final currentVal = _surveyReviews[subjectCode]?[co] ?? 'HIGH';
    final isSubmitted = _submittedSurveys[subjectCode] ?? false;

    if (isSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: currentVal == 'HIGH'
              ? const Color(0xFFF0FDF4)
              : currentVal == 'MEDIUM'
                  ? const Color(0xFFFFFBEB)
                  : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: currentVal == 'HIGH'
                ? const Color(0xFFBBF7D0)
                : currentVal == 'MEDIUM'
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFFCA5A5),
          ),
        ),
        child: Text(
          currentVal,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: currentVal == 'HIGH'
                ? const Color(0xFF15803D)
                : currentVal == 'MEDIUM'
                    ? const Color(0xFFB45309)
                    : const Color(0xFFB91C1C),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 32,
      decoration: BoxDecoration(
        color: currentVal == 'HIGH'
            ? const Color(0xFFF0FDF4)
            : currentVal == 'MEDIUM'
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: currentVal == 'HIGH'
              ? const Color(0xFFBBF7D0)
              : currentVal == 'MEDIUM'
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFFFCA5A5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                if (!_surveyReviews.containsKey(subjectCode)) {
                  _surveyReviews[subjectCode] = {};
                }
                _surveyReviews[subjectCode]![co] = val;
              });
            }
          },
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: currentVal == 'HIGH'
                ? const Color(0xFF15803D)
                : currentVal == 'MEDIUM'
                    ? const Color(0xFFB45309)
                    : const Color(0xFFB91C1C),
          ),
          items: const [
            DropdownMenuItem(value: 'HIGH', child: Text('HIGH')),
            DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM')),
            DropdownMenuItem(value: 'LOW', child: Text('LOW')),
          ],
        ),
      ),
    );
  }

  String _getLessonNameForCO(int coNum) {
    try {
      final appState = AppStateProvider.of(context);
      final plans = appState.lessonPlans.where((p) => p['course_code'] == _exitSurveySelectedSubject && p['unit_number'] == coNum).toList();
      if (plans.isNotEmpty && plans.first['topic_title'] != null) {
        return plans.first['topic_title'] as String;
      }
    } catch (_) {}
    switch (coNum) {
      case 1:
        return '';
      case 2:
        return '';
      case 3:
        return '';
      case 4:
        return '';
      case 5:
        return '';
      default:
        return '';
    }
  }

  String _getTopicLearnedForCO(int coNum) {
    try {
      final appState = AppStateProvider.of(context);
      final plans = appState.lessonPlans.where((p) => p['course_code'] == _exitSurveySelectedSubject && p['unit_number'] == coNum).toList();
      if (plans.isNotEmpty && plans.first['topic_title'] != null) {
        return 'Lessons regarding ${plans.first['topic_title']}';
      }
    } catch (_) {}
    switch (coNum) {
      case 1:
        return '';
      case 2:
        return '';
      case 3:
        return '';
      case 4:
        return '';
      case 5:
        return '';
      default:
        return '';
    }
  }

  Widget _buildStarRatingBar({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required bool isSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              final starNum = index + 1;
              final isFilled = starNum <= value;
              return InkWell(
                onTap: isSubmitted ? null : () => onChanged(starNum),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Icon(
                    isFilled ? Icons.star : Icons.star_border,
                    color: isFilled ? const Color(0xFFEAB308) : const Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COURSE FEEDBACK WORKFLOW
  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // COURSE FEEDBACK WORKFLOW
  // ---------------------------------------------------------------------------
  Widget _buildFeedbackWorkflow(bool isDesktop) {
    final subjects = _subjectsBySemester[_feedbackSem] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Semester selection bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    _showSemesterSearchDialog(isExitSurvey: false);
                    setState(() {
                      _selectedSubjectCodeForFeedback = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Selected Semester: $_feedbackSem (Click to change)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (subjects.isEmpty)
          _buildNoSubjectsPlaceholder()
        else if (_selectedSubjectCodeForFeedback == null)
          // STEP 1: Show Subjects List Cards View
          _buildSubjectCardsGrid(subjects, isDesktop)
        else
          // STEP 2: Show Single Subject Feedback Form View
          _buildSingleSubjectFeedbackForm(_selectedSubjectCodeForFeedback!, subjects, isDesktop),
      ],
    );
  }

  Widget _buildSubjectCardsGrid(List<Map<String, String>> subjects, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Subjects for $_feedbackSem (Select a subject to give feedback)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                '${subjects.length} Subjects',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: subjects.asMap().entries.map((entry) {
            final idx = entry.key;
            final sub = entry.value;
            final code = sub['code']!;
            final name = sub['name']!;
            final facultyName = sub['faculty'] ?? 'Dr. P. Kalaiyarasan';
            final facultyId = sub['faculty_id'] ?? 'EMP_CSE_${(idx + 1).toString().padLeft(3, '0')}';
            final isSubmitted = _submittedFeedbackSubjects[code] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSubmitted ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                  width: isSubmitted ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedSubjectCodeForFeedback = code;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSubmitted ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSubmitted ? const Color(0xFF86EFAC) : const Color(0xFFC7D2FE),
                          ),
                        ),
                        child: Text(
                          code,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSubmitted ? const Color(0xFF15803D) : const Color(0xFF4338CA),
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
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Faculty: $facultyName ($facultyId)',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isSubmitted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text(
                                'Submitted',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedSubjectCodeForFeedback = code;
                            });
                          },
                          icon: const Icon(Icons.edit_note, size: 16, color: Colors.white),
                          label: const Text('Give Feedback', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSingleSubjectFeedbackForm(String subjectCode, List<Map<String, String>> subjects, bool isDesktop) {
    final sub = subjects.firstWhere((element) => element['code'] == subjectCode, orElse: () => {'code': subjectCode, 'name': 'Selected Subject'});
    final code = sub['code']!;
    final name = sub['name']!;
    final facultyName = sub['faculty'] ?? 'Dr. P. Kalaiyarasan';
    final facultyId = sub['faculty_id'] ?? 'EMP_CSE_002';
    final isSubmitted = _submittedFeedbackSubjects[code] ?? false;

    final know = _metricKnowledge[code] ?? 5;
    final meth = _metricMethodology[code] ?? 5;
    final punc = _metricPunctuality[code] ?? 5;
    final avail = _metricAvailability[code] ?? 5;
    final over = _metricOverall[code] ?? 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back Button Header
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSubjectCodeForFeedback = null;
                });
              },
              icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF2563EB)),
              label: const Text('← Back to Subjects List', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Single Subject Feedback Form Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course & Faculty Info Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Target Faculty: $facultyName ($facultyId)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              // Detailed 5 Metrics Evaluation
              const Text(
                'Detailed Metrics Evaluation (1 to 5 Stars):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),

              _buildStarRatingBar(
                label: '• Subject Knowledge & Preparation',
                value: know,
                isSubmitted: isSubmitted,
                onChanged: (v) => setState(() => _metricKnowledge[code] = v),
              ),
              _buildStarRatingBar(
                label: '• Teaching Methodology & Clarity',
                value: meth,
                isSubmitted: isSubmitted,
                onChanged: (v) => setState(() => _metricMethodology[code] = v),
              ),
              _buildStarRatingBar(
                label: '• Punctuality & Class Discipline',
                value: punc,
                isSubmitted: isSubmitted,
                onChanged: (v) => setState(() => _metricPunctuality[code] = v),
              ),
              _buildStarRatingBar(
                label: '• Availability & Doubt Clearing',
                value: avail,
                isSubmitted: isSubmitted,
                onChanged: (v) => setState(() => _metricAvailability[code] = v),
              ),
              _buildStarRatingBar(
                label: '• Overall Course Rating',
                value: over,
                isSubmitted: isSubmitted,
                onChanged: (v) => setState(() => _metricOverall[code] = v),
              ),


            ],
          ),
        ),
        const SizedBox(height: 16),

        // Anonymity Guarantee Notice
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: const [
              Icon(Icons.lock_outline, size: 18, color: Color(0xFF16A34A)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🔒 ANONYMITY NOTICE: Your feedback is 100% anonymous. Identity is strictly protected.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Submit Button
        if (!isSubmitted)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final comment = _feedbackComments[code] ?? '';
                if (comment.trim().isNotEmpty) {
                  final onlyNumbers = RegExp(r'^\d+$').hasMatch(comment.trim());
                  if (onlyNumbers) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Feedback comment for $code cannot contain only numbers!'),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                    return;
                  }
                }

                final appState = AppStateProvider.of(context);
                final dept = appState.getProfileField('department', defaultValue: 'CSE');
                final yr = appState.getProfileField('year', defaultValue: 'III');
                final sec = appState.studentProfileData?['section']?.toString() ?? 'A';
                final classSecLabel = '$dept - $sec ($yr Year)';

                final success = await SupabaseService.instance.submitStudentFeedbackResult(
                  facultyEmployeeId: facultyId,
                  courseCode: code,
                  subject: name,
                  department: dept,
                  section: sec,
                  classSec: classSecLabel,
                  academicYear: appState.selectedAcademicYear,
                  semester: _getSemesterInt(_feedbackSem),
                  period: 'Odd Semester ${appState.selectedAcademicYear}',
                  rating: _metricOverall[code] ?? 5,
                  knowledge: _metricKnowledge[code] ?? 5,
                  methodology: _metricMethodology[code] ?? 5,
                  punctuality: _metricPunctuality[code] ?? 5,
                  availability: _metricAvailability[code] ?? 5,
                  comment: comment.isNotEmpty ? comment : 'Interactive teaching style and clear explanation of concepts.',
                  studentAlias: 'Anonymous Student #${DateTime.now().second % 30 + 1}',
                );

                if (success) {
                  setState(() {
                    _submittedFeedbackSubjects[code] = true;
                    _selectedSubjectCodeForFeedback = null;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Feedback for $code submitted 100% anonymously to Supabase!'),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to submit feedback. Please try again.'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              label: const Text('SUBMIT FEEDBACK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )
        else
          Center(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _selectedSubjectCodeForFeedback = null),
              icon: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 16),
              label: const Text('Feedback Submitted • Return to Subjects', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF86EFAC))),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingRadioRow(String subjectCode, bool isDesktop) {
    final options = ['Excellent', 'Very Good', 'Good', 'Poor', 'Very Poor'];
    final currentRating = _feedbackRatings[subjectCode];
    final isSubmitted = _submittedFeedback[_feedbackSem] ?? false;

    if (isSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: Text(
          currentRating ?? 'No rating selected',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
        ),
      );
    }

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: options.map((opt) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: opt,
                groupValue: currentRating,
                activeColor: const Color(0xFF4F46E5),
                onChanged: (newVal) {
                  setState(() {
                    _feedbackRatings[subjectCode] = newVal!;
                  });
                },
              ),
              Text(
                opt,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ],
          );
        }).toList(),
      );
    } else {
      // Mobile wrap layout
      return Wrap(
        spacing: 12,
        runSpacing: 4,
        children: options.map((opt) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: opt,
                groupValue: currentRating,
                activeColor: const Color(0xFF4F46E5),
                onChanged: (newVal) {
                  setState(() {
                    _feedbackRatings[subjectCode] = newVal!;
                  });
                },
              ),
              Text(
                opt,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ],
          );
        }).toList(),
      );
    }
  }



  Widget _buildNoSubjectsPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text('No academic records available for this semester selection.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: style ?? TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildTableCellWidget(Widget child) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}
