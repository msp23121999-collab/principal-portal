import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../erp_repository.dart';
import '../services/timetable_service.dart';
import '../services/attendance_service.dart';
import '../services/local_storage_base.dart';
import '../services/course_allocation_service.dart';
import '../services/workload_service.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../widgets/faculty_loading.dart';

enum AttendanceWindowStatus {
  futureDate,
  todayBefore8am,
  todayOpen,
  todayAfter430pm,
  pastDate,
}

// ─────────────────────────────────────────────────────────────────────────────
class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});
  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final repo = ErpRepository();

  // ── Selection state ─────────────────────────────────────────────────────
  String _selectedYear = '';
  String? _selectedClass;
  String? _selectedSubject;
  String? _selectedPeriod;
  bool _loaded = true;
  DateTime _selectedDate = DateTime.now();
  bool _isEditing = false;
  bool _hodRequestSubmitted = false;
  List<Map<String, dynamic>> _courseAllocations = [];

  // ── Student list and search ─────────────────────────────────────────────
  List<Map<String, dynamic>> _localRecords = [];
  List<String> _assignedSubjects = [];
  final _searchCtrl = TextEditingController();

  // ── Live clock ──────────────────────────────────────────────────────────
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  // ── Canonical period times ───────────────────────────────────────────────
  static const Map<String, Map<String, String>> _periodTimes = {
    'P1': {'start': '09:00 AM', 'end': '09:50 AM'},
    'P2': {'start': '09:50 AM', 'end': '10:40 AM'},
    'P3': {'start': '10:55 AM', 'end': '11:40 AM'},
    'P4': {'start': '11:40 AM', 'end': '12:30 PM'},
    'P5': {'start': '01:30 PM', 'end': '02:20 PM'},
    'P6': {'start': '02:20 PM', 'end': '03:10 PM'},
    'P7': {'start': '03:10 PM', 'end': '04:00 PM'},
    'P8': {'start': '04:00 PM', 'end': '04:50 PM'},
  };

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _initDefaultFiltersAndLoad();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initDefaultFiltersAndLoad() async {
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    try {
      final allocs = await WorkloadService.fetchCourseAllocations(facultyId);
      if (allocs.isNotEmpty && mounted) {
        setState(() {
          _courseAllocations = allocs;
        });
      }
    } catch (_) {}

    final classes = _allocatedClassesList;

    if (classes.isNotEmpty) {
      _selectedClass = classes.first;
      _selectedYear =
          _extractYearFromClass(_selectedClass!) ??
          (_handlingYears.isNotEmpty ? _handlingYears.first : '');
    } else {
      _selectedYear = _handlingYears.isNotEmpty ? _handlingYears.first : '';
      _selectedClass = null;
    }

    if (_selectedClass != null) {
      _assignedSubjects = TimetableService.getSubjectsForClass(
        facultyId,
        _selectedClass!,
      );
      if (_assignedSubjects.isNotEmpty) {
        _selectedSubject = _assignedSubjects.first;
        _updateMatchingPeriods();
        _loadStudents();
      }
    }
  }

  List<String> get _allocatedClassesList {
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    final classesSet = <String>{};

    for (final alloc in _courseAllocations) {
      final dept = (alloc['department'] ?? '').toString().trim().toUpperCase();
      final sec = (alloc['section'] ?? '').toString().trim().toUpperCase();
      final rawYr = (alloc['year_of_study'] ?? '').toString().trim();
      final yr = _extractYearFromClass(rawYr) ?? rawYr;
      if (dept.isNotEmpty && sec.isNotEmpty) {
        classesSet.add(
          TimetableService.normalizeClassSec('$dept - $sec ($yr)'),
        );
      }
    }

    final ttClasses = TimetableService.getClassesForFaculty(facultyId);
    for (final c in ttClasses) {
      classesSet.add(TimetableService.normalizeClassSec(c));
    }

    final list = classesSet.toList()..sort();
    return list;
  }

  String _parseDept(String classSec) {
    if (classSec.isEmpty) return 'CSE';
    final parts = classSec.split('-');
    return parts[0].trim().toUpperCase();
  }

  String _parseSection(String classSec) {
    if (classSec.isEmpty) return 'A';
    final parts = classSec.split('-');
    if (parts.length >= 2) {
      final secPart = parts[1].trim().split(' ')[0].split('(')[0].trim();
      if (secPart.isNotEmpty) return secPart.toUpperCase();
    }
    return 'A';
  }

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
    final years = <String>{};
    for (final cls in _allocatedClassesList) {
      final y = _extractYearFromClass(cls);
      if (y != null) years.add(y);
    }
    final sorted = years.toList()..sort();
    return sorted;
  }

  List<String> get _classesByYear {
    final filtered = _allocatedClassesList.where((c) {
      final y = _extractYearFromClass(c);
      return y == _selectedYear;
    }).toList();
    return filtered;
  }

  void _onYearChanged(String? newYear) {
    if (newYear == null || newYear == _selectedYear) return;
    setState(() {
      _selectedYear = newYear;
      final classes = _classesByYear;
      if (classes.isNotEmpty) {
        _onClassSelected(classes.first);
      }
    });
  }

  String _weekdayName(int w) {
    const d = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return d[w.clamp(0, 7)];
  }

  AttendanceWindowStatus _getAttendanceWindowStatus() {
    final today = DateTime(_now.year, _now.month, _now.day);
    final selDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selDate.isAfter(today)) return AttendanceWindowStatus.futureDate;
    if (selDate.isBefore(today)) return AttendanceWindowStatus.pastDate;

    final m = _now.hour * 60 + _now.minute;
    const startM = 8 * 60; // 8:00 AM
    const lockM = 16 * 60 + 30; // 4:30 PM

    if (m < startM) return AttendanceWindowStatus.todayBefore8am;
    if (m > lockM) return AttendanceWindowStatus.todayAfter430pm;

    return AttendanceWindowStatus.todayOpen;
  }

  bool _isAttendanceLocked() {
    final status = _getAttendanceWindowStatus();
    return status != AttendanceWindowStatus.todayOpen;
  }

  Map<String, dynamic>? get _activeEntry {
    if (_selectedClass == null ||
        _selectedSubject == null ||
        _selectedPeriod == null)
      return null;
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    final dayName = _weekdayName(_selectedDate.weekday);
    final facultyTimetable = TimetableService.getByFaculty(facultyId);

    final dayData = facultyTimetable.firstWhere(
      (d) => d['day'] == dayName,
      orElse: () => <String, dynamic>{},
    );

    final schedule = (dayData['schedule'] as List? ?? []);
    final matches = schedule.where(
      (p) =>
          p['classSec'] == _selectedClass &&
          p['subject'] == _selectedSubject &&
          p['period'] == _selectedPeriod,
    );
    return matches.isNotEmpty
        ? Map<String, dynamic>.from(matches.first as Map)
        : null;
  }

  String _entryStartTime(Map<String, dynamic>? entry) {
    if (entry == null) return '';
    final periodKey = entry['period']?.toString() ?? '';
    return entry['start']?.toString() ??
        _periodTimes[periodKey]?['start'] ??
        '';
  }

  String _entryEndTime(Map<String, dynamic>? entry) {
    if (entry == null) return '';
    final periodKey = entry['period']?.toString() ?? '';
    return entry['end']?.toString() ?? _periodTimes[periodKey]?['end'] ?? '';
  }

  // ── Class selection → auto-select year, subject & load roster ─────────
  void _onClassSelected(String? val) {
    setState(() {
      _selectedClass = val;
      _selectedSubject = null;
      _selectedPeriod = null;
      _loaded = true;
      _localRecords = [];
      if (val == null) {
        _assignedSubjects = [];
        return;
      }

      final yearExtracted = _extractYearFromClass(val);
      if (yearExtracted != null && _handlingYears.contains(yearExtracted)) {
        _selectedYear = yearExtracted;
      }

      final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
      _assignedSubjects = TimetableService.getSubjectsForClass(facultyId, val);

      if (_assignedSubjects.isNotEmpty) {
        _selectedSubject = _assignedSubjects.first;
        _updateMatchingPeriods();
        _loadStudents();
      } else {
        _selectedSubject = null;
        _localRecords.clear();
      }
    });
  }

  void _onSubjectSelected(String? val) {
    setState(() {
      _selectedSubject = val;
      _selectedPeriod = null;
      _localRecords = [];
      if (val != null) {
        _updateMatchingPeriods();
        _loadStudents();
      }
    });
  }

  void _updateMatchingPeriods() {
    final matching = _getMatchingPeriods();
    if (matching.isEmpty) {
      _selectedPeriod = null;
    } else if (_selectedPeriod == null || !matching.contains(_selectedPeriod)) {
      _selectedPeriod = matching.first;
    }
  }

  Map<String, dynamic>? _getSavedSession() {
    if (_selectedClass == null ||
        _selectedSubject == null ||
        _selectedPeriod == null)
      return null;
    final dateStr = _selectedDate.toString().substring(0, 10);
    final periodStr = _selectedPeriod!.toUpperCase();

    final matching = repo.attendanceSessions.where((s) {
      final sDate = s['date']?.toString() ?? '';
      final sPeriod = s['period']?.toString().toUpperCase() ?? '';
      final sClass = s['classSec']?.toString() ?? '';
      final sSubj = s['subject']?.toString() ?? '';
      return sDate == dateStr &&
          sPeriod == periodStr &&
          (sClass == _selectedClass || sClass.contains(_selectedClass!)) &&
          (sSubj == _selectedSubject || sSubj.contains(_selectedSubject!));
    }).toList();
    return matching.isNotEmpty ? matching.first : null;
  }

  bool _isAttendanceSubmittedForSelectedPeriod() {
    final saved = _getSavedSession();
    if (saved != null && saved.isNotEmpty && saved['status'] != 'Draft') {
      return true;
    }
    if (_selectedPeriod == null || _localRecords.isEmpty) return false;
    final pCol = _selectedPeriod!.toLowerCase();
    int markedCount = 0;
    for (final s in _localRecords) {
      final val = s[pCol];
      if (val != null) {
        final valStr = val.toString().trim().toUpperCase();
        if (valStr.isNotEmpty && valStr != 'NULL') {
          markedCount++;
        }
      }
    }
    return markedCount > 0;
  }

  // ── Load students from CourseAllocationService + attendance_table overlay ──
  Future<void> _loadStudents() async {
    if (_selectedClass == null) {
      if (mounted) {
        setState(() {
          _localRecords = [];
          _loaded = true;
        });
      }
      return;
    }

    if (mounted) setState(() => _loaded = false);

    try {
      final dateStr = _selectedDate.toString().substring(0, 10);
      final periodCol = (_selectedPeriod ?? 'P1').toLowerCase();

      final students = await CourseAllocationService.fetchStudentsForClass(
        _selectedClass!,
      );

      List<Map<String, dynamic>> existingAttendance = [];
      try {
        existingAttendance =
            await AttendanceService.fetchStudentAttendanceTable(
              date: dateStr,
              classSec: _selectedClass!,
            );
      } catch (_) {}

      final attendanceLookup = <String, Map<String, dynamic>>{};
      for (final row in existingAttendance) {
        final regNo = (row['reg_no'] ?? '').toString();
        if (regNo.isNotEmpty) attendanceLookup[regNo] = row;
      }

      if (mounted) {
        setState(() {
          _localRecords = students.map((s) {
            final regNo = (s['reg'] ?? s['roll'] ?? '').toString();
            final attRow = attendanceLookup[regNo];

            final rawP = attRow?[periodCol];
            String pStatus = 'P';
            if (rawP == true || rawP == 'P' || rawP == 'true' || rawP == 'p') {
              pStatus = 'P';
            } else if (rawP == false ||
                rawP == 'A' ||
                rawP == 'false' ||
                rawP == 'a') {
              pStatus = 'A';
            } else if (rawP == 'OD' || rawP == 'od') {
              pStatus = 'OD';
            } else if (rawP == 'ML' || rawP == 'ml') {
              pStatus = 'ML';
            }

            return {
              'studentId': s['studentId'] ?? regNo,
              'roll': s['roll'] ?? regNo,
              'reg': regNo,
              'name': s['name'] ?? '',
              'dept': s['dept'] ?? '',
              'section': s['sec'] ?? s['section'] ?? '',
              'year': s['year'] ?? _selectedYear,
              'status': pStatus,
              'remarks': attRow?['remarks'] ?? '',
              'p1': attRow?['p1'],
              'p2': attRow?['p2'],
              'p3': attRow?['p3'],
              'p4': attRow?['p4'],
              'p5': attRow?['p5'],
              'p6': attRow?['p6'],
              'p7': attRow?['p7'],
              'p8': attRow?['p8'],
              'isMlLocked': false,
            };
          }).toList();
        });
        _fetchMlStatuses();
      }
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _fetchMlStatuses() async {
    final todayStr = _now.toString().substring(0, 10);
    for (var s in _localRecords) {
      final check = await repo.checkMedicalLeave(s['roll'], date: todayStr);
      if (mounted && check['hasMl'] == true) {
        setState(() {
          s['status'] = 'ML';
          s['isMlLocked'] = true;
        });
      }
    }
  }

  // ── Counts ───────────────────────────────────────────────────────────────
  int get _presentCount =>
      _localRecords.where((s) => s['status'] == 'P').length;
  int get _absentCount => _localRecords.where((s) => s['status'] == 'A').length;
  int get _odCount => _localRecords.where((s) => s['status'] == 'OD').length;
  int get _mlCount => _localRecords.where((s) => s['status'] == 'ML').length;

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _localRecords;
    return _localRecords
        .where(
          (s) =>
              (s['name'] ?? '').toString().toLowerCase().contains(q) ||
              (s['roll'] ?? '').toString().toLowerCase().contains(q) ||
              (s['reg'] ?? '').toString().toLowerCase().contains(q),
        )
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sw = mediaQuery.size.width;
    final isMobile = sw < 650;
    final wide = sw > 1050;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(isMobile),
            const SizedBox(height: 16),
            _sessionInfoBanner(isMobile),
            const SizedBox(height: 16),
            _selectCard(isMobile),
            const SizedBox(height: 16),
            _attendanceWorkflowPanel(),
            const SizedBox(height: 8),
            if (!_loaded)
              const FacultyLoadingWidget()
            else if (_localRecords.isEmpty)
              _emptyRosterCard()
            else
              wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _rosterCard(isMobile)),
                        const SizedBox(width: 20),
                        SizedBox(width: 320, child: _rightPanel()),
                      ],
                    )
                  : Column(
                      children: [
                        _rosterCard(isMobile),
                        const SizedBox(height: 16),
                        _rightPanel(),
                      ],
                    ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Page header with OD-included Attendance Ratio ──────────────────────────
  Widget _pageHeader(bool isMobile) {
    final total = _localRecords.length;
    final present = _presentCount;
    final absent = _absentCount;
    final od = _odCount;
    final ml = _mlCount;

    // Req 2 Fix: Calculate Attendance Ratio including OD (On Duty) as Present
    final effectivePresent = present + od;
    final pct = total > 0
        ? (effectivePresent / total * 100).toStringAsFixed(0)
        : '—';

    final headerCol = Text(
      'Take Attendance',
      style: GoogleFonts.inter(
        fontSize: isMobile ? 20 : 22,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      ),
    );

    final pills = total > 0
        ? Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _hdrPill(
                '$present Present',
                const Color(0xFF16A34A),
                const Color(0xFFDCFCE7),
              ),
              _hdrPill(
                '$absent Absent',
                const Color(0xFFDC2626),
                const Color(0xFFFEE2E2),
              ),
              _hdrPill(
                '$od OD',
                const Color(0xFF2563EB),
                const Color(0xFFDBEAFE),
              ),
              _hdrPill(
                '$ml ML',
                const Color(0xFF8B5CF6),
                const Color(0xFFF3E8FF),
              ),
              _hdrPill(
                '$pct% (P+OD)',
                const Color(0xFF0F172A),
                const Color(0xFFF1F5F9),
              ),
            ],
          )
        : const SizedBox();

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: headerCol),
              _badge(repo.selectedAcademicYear),
            ],
          ),
          if (total > 0) ...[const SizedBox(height: 10), pills],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        headerCol,
        const SizedBox(width: 20),
        if (total > 0) pills,
        const Spacer(),
        _badge(repo.selectedAcademicYear),
      ],
    );
  }

  Widget _hdrPill(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: fg.withValues(alpha: 0.25)),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: fg,
      ),
    ),
  );

  // ── Step selection card ───────────────────────────────────────────────────
  Widget _selectCard(bool isMobile) {
    final bool hasClass = _selectedClass != null;
    final bool hasSubject = _selectedSubject != null;
    final matchingPeriods = _getMatchingPeriods();
    final bool enableLoad =
        hasClass &&
        hasSubject &&
        matchingPeriods.isNotEmpty &&
        _selectedPeriod != null;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.how_to_reg_outlined,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Details',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final messenger = ScaffoldMessenger.of(context);
              final loadBtn = ElevatedButton.icon(
                onPressed: enableLoad
                    ? () async {
                        setState(() => _loaded = false);
                        await _loadStudents();
                        if (!mounted) return;
                        setState(() => _loaded = true);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Loaded ${_localRecords.length} students for $_selectedClass',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.filter_list_rounded, size: 16),
                label: Text(
                  'Load Students',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: enableLoad
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _labeledField(
                      label: 'Step 1 — Student Year',
                      child: _buildYearDropdown(),
                    ),
                    const SizedBox(height: 12),
                    _labeledField(
                      label: 'Step 2 — Class & Section',
                      child: _buildClassDropdown(),
                    ),
                    const SizedBox(height: 12),
                    _labeledField(
                      label: 'Step 3 — Subject',
                      child: _buildSubjectDropdown(hasClass),
                    ),
                    const SizedBox(height: 12),
                    _labeledField(
                      label: 'Step 4 — Date',
                      child: _buildDateSelector(),
                    ),
                    const SizedBox(height: 12),
                    _labeledField(
                      label: 'Step 5 — Period',
                      child: _buildPeriodDropdown(matchingPeriods),
                    ),
                    const SizedBox(height: 16),
                    loadBtn,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _labeledField(
                      label: 'Step 1 — Year',
                      child: _buildYearDropdown(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _labeledField(
                      label: 'Step 2 — Class & Section',
                      child: _buildClassDropdown(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _labeledField(
                      label: 'Step 3 — Subject',
                      child: _buildSubjectDropdown(hasClass),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _labeledField(
                      label: 'Step 4 — Date',
                      child: _buildDateSelector(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _labeledField(
                      label: 'Step 5 — Period',
                      child: _buildPeriodDropdown(matchingPeriods),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [const SizedBox(height: 20), loadBtn],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown() {
    final years = _handlingYears;
    return _dropdown(years, _selectedYear, _onYearChanged);
  }

  Widget _buildClassDropdown() {
    final classes = _classesByYear;
    return _dropdown(classes, _selectedClass, _onClassSelected);
  }

  Widget _buildSubjectDropdown(bool hasClass) {
    if (!hasClass) {
      return _disabledBox('Select class first');
    }
    if (_assignedSubjects.isEmpty) {
      return _errorBox('No subjects found in timetable');
    }
    final bool isSingleSubject = _assignedSubjects.length <= 1;
    return _dropdown(
      _assignedSubjects,
      _selectedSubject,
      isSingleSubject ? null : _onSubjectSelected,
    );
  }

  // ── Session info banner ───────────────────────────────────────────────────
  Widget _sessionInfoBanner(bool isMobile) {
    if (_selectedClass == null || _selectedSubject == null)
      return const SizedBox();
    final entry = _activeEntry;
    if (entry == null) return const SizedBox();

    final periodKey = entry['period']?.toString() ?? '';
    final startT = _entryStartTime(entry);
    final endT = _entryEndTime(entry);
    final room = entry['room']?.toString() ?? '';
    final todayName = _weekdayName(_selectedDate.weekday);

    final pills = [
      _infoPill(Icons.class_outlined, _selectedSubject!),
      _infoPill(Icons.people_alt_outlined, _selectedClass!),
      _infoPill(Icons.assignment_outlined, 'Period $periodKey'),
      _infoPill(Icons.location_on_outlined, room),
      _infoPill(Icons.access_time_outlined, '$startT – $endT'),
      _infoPill(Icons.calendar_today_outlined, todayName),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Timetable Auto-Detected:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: pills),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Timetable Auto-Detected:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(spacing: 8, runSpacing: 6, children: pills),
                ),
              ],
            ),
    );
  }

  Widget _infoPill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  // ── Date Selector ─────────────────────────────────────────────────────────
  Widget _buildDateSelector() {
    final dateStr =
        '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate.weekday == DateTime.sunday
              ? _selectedDate.add(const Duration(days: 1))
              : _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          selectableDayPredicate: (DateTime day) =>
              day.weekday != DateTime.sunday,
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _updateMatchingPeriods();
            _loadStudents();
          });
        }
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 14,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m.clamp(0, 12)];
  }

  // ── Req 1 Fix: Filter Periods based on actual timetable for selected day ──
  List<String> _getMatchingPeriods() {
    if (_selectedClass == null || _selectedSubject == null) return [];
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    final dayName = _weekdayName(_selectedDate.weekday);
    final facultyTimetable = TimetableService.getByFaculty(facultyId);

    final dayData = facultyTimetable.firstWhere(
      (d) =>
          (d['day']?.toString().toLowerCase() ?? '') == dayName.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );

    final schedule = (dayData['schedule'] as List? ?? []);
    final matching = schedule
        .where(
          (p) =>
              p['classSec'] == _selectedClass &&
              p['subject'] == _selectedSubject,
        )
        .map((p) => p['period']?.toString() ?? '')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();

    if (matching.isNotEmpty) {
      matching.sort();
      return matching;
    }

    // Req 1 Fix: Do NOT show all P1..P8 if the faculty has no periods on this day!
    return [];
  }

  Widget _buildPeriodDropdown(List<String> matchingPeriods) {
    if (_selectedClass == null || _selectedSubject == null) {
      return _disabledBox('Select class and subject first');
    }
    if (matchingPeriods.isEmpty) {
      return _errorBox('No period scheduled on this date');
    }
    return _dropdown(matchingPeriods, _selectedPeriod, (val) {
      setState(() {
        _selectedPeriod = val;
        _loadStudents();
      });
    });
  }

  // ── Workflow Alert Banner & Locked Time Message ───────────────────────────
  Widget _attendanceWorkflowPanel() {
    if (_selectedClass == null ||
        _selectedSubject == null ||
        _selectedPeriod == null)
      return const SizedBox();

    final saved = _getSavedSession();
    final isSubmitted = _isAttendanceSubmittedForSelectedPeriod();
    final bool hasSaved = (saved != null && saved.isNotEmpty) || isSubmitted;

    final List<Widget> children = [];

    final bool showTracker =
        _hodRequestSubmitted ||
        (hasSaved &&
            saved != null &&
            (saved['status'] == 'Pending HOD Approval' ||
                saved['status'] == 'Approved' ||
                saved['status'] == 'Rejected'));

    if (showTracker) {
      children.add(
        _buildWorkflowTracker(
          saved != null
              ? (saved['status'] ?? 'Pending HOD Approval')
              : 'Pending HOD Approval',
        ),
      );
    }

    if (saved != null && saved['status'] == 'Pending HOD Approval') {
      children.add(_simulatedHodPanel(saved));
    }

    if (saved != null) {
      final status = saved['status'] as String? ?? 'Submitted';
      if (status == 'Pending HOD Approval') {
        children.add(
          _alertBox(
            color: const Color(0xFFFFFBEB),
            border: const Color(0xFFFDE68A),
            icon: Icons.hourglass_empty,
            iconColor: const Color(0xFFD97706),
            message: 'Correction Request Submitted. Waiting for HOD approval.',
            extra: null,
          ),
        );
      } else if (status == 'Approved') {
        children.add(
          _alertBox(
            color: const Color(0xFFEFF6FF),
            border: const Color(0xFFBFDBFE),
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF2563EB),
            message:
                'Correction Request Approved\nApproved By: ${saved['hodName'] ?? 'HOD'}\nApproval Date: ${saved['approvalDate'] ?? ''}',
            extra: null,
          ),
        );
      } else if (status == 'Rejected') {
        children.add(
          _alertBox(
            color: const Color(0xFFFEF2F2),
            border: const Color(0xFFFCA5A5),
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFDC2626),
            message:
                'Correction Request Rejected\nHOD Remarks: ${saved['hodRemarks'] ?? 'No remarks provided'}',
            extra: null,
          ),
        );
      }
    } else {
      final windowStatus = _getAttendanceWindowStatus();
      switch (windowStatus) {
        case AttendanceWindowStatus.futureDate:
          children.add(
            _alertBox(
              color: const Color(0xFFEFF6FF),
              border: const Color(0xFFBFDBFE),
              icon: Icons.schedule_outlined,
              iconColor: const Color(0xFF2563EB),
              message:
                  'Attendance Entry Not Opened: Attendance can only be entered on the scheduled class date starting from 8:00 AM.',
              extra: null,
            ),
          );
          break;
        case AttendanceWindowStatus.todayBefore8am:
          children.add(
            _alertBox(
              color: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              icon: Icons.access_time_outlined,
              iconColor: const Color(0xFFD97706),
              message:
                  'Attendance Entry Not Opened Yet: Attendance for today\'s classes opens at 8:00 AM.',
              extra: null,
            ),
          );
          break;
        case AttendanceWindowStatus.todayAfter430pm:
          children.add(
            _alertBox(
              color: const Color(0xFFFEF2F2),
              border: const Color(0xFFFCA5A5),
              icon: Icons.lock_clock_outlined,
              iconColor: const Color(0xFFDC2626),
              message:
                  'Attendance Entry Locked: The daily deadline (4:30 PM) for marking attendance has passed. To make changes, please submit a correction request to your Department HOD.',
              extra: null,
            ),
          );
          break;
        case AttendanceWindowStatus.pastDate:
          children.add(
            _alertBox(
              color: const Color(0xFFFEF2F2),
              border: const Color(0xFFFCA5A5),
              icon: Icons.lock_clock_outlined,
              iconColor: const Color(0xFFDC2626),
              message:
                  'Attendance Entry Locked: The date for marking attendance has passed. To make changes for past dates, please submit a correction request to your Department HOD.',
              extra: null,
            ),
          );
          break;
        case AttendanceWindowStatus.todayOpen:
          children.add(
            _alertBox(
              color: const Color(0xFFF0FDF4),
              border: const Color(0xFFBBF7D0),
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF16A34A),
              message:
                  'Attendance Entry Open: You can mark attendance for your class until 4:30 PM today.',
              extra: null,
            ),
          );
          break;
      }
    }

    if (children.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children
          .map(
            (c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c),
          )
          .toList(),
    );
  }

  Widget _buildWorkflowTracker(String status) {
    int activeStep = 1;
    if (status == 'Pending HOD Approval') activeStep = 2;
    if (status == 'Approved' || status == 'Rejected') activeStep = 3;
    if (status == 'Updated') activeStep = 4;

    Widget stepWidget(int stepNum, String title, Color color, bool isLast) {
      final bool done = activeStep >= stepNum;
      final bool active = activeStep == stepNum;
      final Color bulletColor = done ? color : const Color(0xFFCBD5E1);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: bulletColor,
              shape: BoxShape.circle,
              border: active ? Border.all(color: Colors.white, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : Text(
                    '$stepNum',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
          ),
          if (!isLast) ...[
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 2,
              color: done ? color : const Color(0xFFE2E8F0),
            ),
            const SizedBox(width: 12),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            stepWidget(1, 'Submitted', const Color(0xFF16A34A), false),
            stepWidget(2, 'Pending HOD', const Color(0xFFD97706), false),
            stepWidget(3, 'Decision', const Color(0xFF2563EB), false),
            stepWidget(4, 'Updated', const Color(0xFF8B5CF6), true),
          ],
        ),
      ),
    );
  }

  Widget _simulatedHodPanel(Map<String, dynamic> session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                color: Color(0xFFEA580C),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'SIMULATED HOD CONTROL PANEL (Testing Workflow)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFC2410C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _handleHodDecision(session, true),
                icon: const Icon(Icons.check_circle, size: 14),
                label: Text(
                  'Approve Correction',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _handleHodDecision(session, false),
                icon: const Icon(Icons.cancel, size: 14),
                label: Text(
                  'Reject Correction',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleHodDecision(Map<String, dynamic> session, bool approve) {
    setState(() {
      session['status'] = approve ? 'Approved' : 'Rejected';
      session['hodName'] = 'Dr. K. G. Shanthi';
      session['approvalDate'] = DateTime.now().toString().substring(0, 10);
      repo.saveAttendanceSession(session);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? 'Request approved successfully.'
              : 'Request rejected successfully.',
        ),
        backgroundColor: approve ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _alertBox({
    required Color color,
    required Color border,
    required IconData icon,
    required Color iconColor,
    required String message,
    required Widget? extra,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (extra != null) ...[const SizedBox(height: 6), extra],
      ],
    ),
  );

  Widget _emptyRosterCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(40),
    decoration: _cardDecor(),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.people_outline, size: 52, color: Color(0xFF94A3B8)),
        const SizedBox(height: 16),
        Text(
          'No Students Loaded',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select Class & Section and Subject, then tap "Load Students".',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    ),
  );

  // ── Roster card (Req 3: Expanded Roll No space & uniform styling, Req 4: Mobile Responsive) ──
  Widget _rosterCard(bool isMobile) {
    final filtered = _filtered;
    final isLocked = _isAttendanceLocked();

    final saved = _getSavedSession();
    final isSubmitted = _isAttendanceSubmittedForSelectedPeriod();
    final matchingPeriods = _getMatchingPeriods();
    final bool hasPeriod = matchingPeriods.isNotEmpty || _activeEntry != null;

    final bool canModify = hasPeriod && !isLocked && !isSubmitted;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          if (isMobile) ...[
            Text(
              'Student Attendance — ${_selectedClass ?? 'Class'} | ${_selectedSubject ?? 'Subject'}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: canModify
                        ? () => setState(() {
                            for (var s in _localRecords) {
                              if (s['isMlLocked'] != true) s['status'] = 'P';
                            }
                          })
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'All Present',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: canModify
                        ? () => setState(() {
                            for (var s in _localRecords) {
                              if (s['isMlLocked'] != true) s['status'] = 'A';
                            }
                          })
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'All Absent',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Student Attendance — ${_selectedClass ?? 'Class'} | ${_selectedSubject ?? 'Subject'}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: canModify
                      ? () => setState(() {
                          for (var s in _localRecords) {
                            if (s['isMlLocked'] != true) s['status'] = 'P';
                          }
                        })
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFF16A34A)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'All Present',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: canModify
                      ? () => setState(() {
                          for (var s in _localRecords) {
                            if (s['isMlLocked'] != true) s['status'] = 'A';
                          }
                        })
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'All Absent',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          // Search bar
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search student by name, roll, or reg no...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Req 3 & 4: Mobile Card List or Desktop Table Layout
          if (isMobile) ...[
            // Mobile Card List for students
            ...filtered.asMap().entries.map(
              (e) => _mobileStudentCard(e.key, e.value, canModify),
            ),
          ] else ...[
            // Desktop Table with expanded Roll No space (130px) & uniform font styling
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                constraints: const BoxConstraints(minWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text('Roll No.', style: _hStyle()),
                          ), // Req 3: Expanded to 130px
                          SizedBox(
                            width: 125,
                            child: Text('Reg No.', style: _hStyle()),
                          ), // Req 3: Expanded to 125px
                          const SizedBox(
                            width: 180,
                            child: Text(
                              'Student Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 230,
                            child: Text(
                              'Attendance Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 130,
                            child: Text(
                              'Remarks',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...filtered.asMap().entries.map(
                      (e) => _studentRow(e.key, e.value, canModify),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Footer actions
          Row(
            children: [
              Text(
                '${filtered.length} of ${_localRecords.length} students',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              if (isLocked || (isSubmitted && !_isEditing))
                Row(
                  children: [
                    _statusBadge(
                      saved != null
                          ? (saved['status'] ?? 'Submitted')
                          : 'Submitted',
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _openCorrectionRequestDialog,
                      icon: const Icon(Icons.edit_note_outlined, size: 14),
                      label: Text(
                        'Request Correction',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                ElevatedButton.icon(
                  onPressed: canModify ? _saveAttendance : null,
                  icon: Icon(
                    _isEditing ? Icons.check : Icons.save_outlined,
                    size: 16,
                  ),
                  label: Text(
                    _isEditing ? 'Save Updated' : 'Save Attendance',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canModify
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    elevation: 0,
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
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _hStyle() => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF64748B),
  );

  // ── Desktop Student Row (Req 3: Expanded Roll No & Uniform Typography) ─────
  Widget _studentRow(int idx, Map<String, dynamic> s, bool canModify) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Roll No - Expanded to 130px to prevent multi-line breaks e.g. 2024CEUCS035
          SizedBox(
            width: 130,
            child: Text(
              s['roll'] as String? ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // Reg No - Uniform 125px font style
          SizedBox(
            width: 125,
            child: Text(
              s['reg'] as String? ?? '',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // Student Name - Uniform 13px font style
          SizedBox(
            width: 180,
            child: Text(
              s['name'] as String? ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // Attendance Buttons (P, A, OD, ML)
          SizedBox(
            width: 230,
            child: Row(
              children: [
                _statusBtn(
                  idx,
                  'P',
                  const Color(0xFF16A34A),
                  const Color(0xFFDCFCE7),
                  canModify,
                ),
                _statusBtn(
                  idx,
                  'A',
                  const Color(0xFFDC2626),
                  const Color(0xFFFEE2E2),
                  canModify,
                ),
                _statusBtn(
                  idx,
                  'OD',
                  const Color(0xFF2563EB),
                  const Color(0xFFDBEAFE),
                  canModify,
                ),
                _statusBtn(
                  idx,
                  'ML',
                  const Color(0xFF8B5CF6),
                  const Color(0xFFF3E8FF),
                  canModify,
                ),
              ],
            ),
          ),
          // Remarks Textbox
          SizedBox(
            width: 130,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: canModify
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                enabled: canModify,
                style: GoogleFonts.inter(fontSize: 11),
                controller:
                    TextEditingController(text: s['remarks'] as String? ?? '')
                      ..selection = TextSelection.collapsed(
                        offset: (s['remarks'] as String? ?? '').length,
                      ),
                onChanged: (val) => s['remarks'] = val,
                decoration: InputDecoration(
                  hintText: 'Remarks...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile Responsive Student Card (Req 4) ────────────────────────────────
  Widget _mobileStudentCard(int idx, Map<String, dynamic> s, bool canModify) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  s['name'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Roll: ${s['roll']}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Reg No: ${s['reg']}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statusBtnMobile(
                  idx,
                  'P',
                  const Color(0xFF16A34A),
                  const Color(0xFFDCFCE7),
                  canModify,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _statusBtnMobile(
                  idx,
                  'A',
                  const Color(0xFFDC2626),
                  const Color(0xFFFEE2E2),
                  canModify,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _statusBtnMobile(
                  idx,
                  'OD',
                  const Color(0xFF2563EB),
                  const Color(0xFFDBEAFE),
                  canModify,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _statusBtnMobile(
                  idx,
                  'ML',
                  const Color(0xFF8B5CF6),
                  const Color(0xFFF3E8FF),
                  canModify,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              enabled: canModify,
              style: GoogleFonts.inter(fontSize: 11),
              controller:
                  TextEditingController(text: s['remarks'] as String? ?? '')
                    ..selection = TextSelection.collapsed(
                      offset: (s['remarks'] as String? ?? '').length,
                    ),
              onChanged: (val) => s['remarks'] = val,
              decoration: InputDecoration(
                hintText: 'Add remarks...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBtnMobile(
    int idx,
    String status,
    Color fg,
    Color bg,
    bool enabled,
  ) {
    final isSelected = _localRecords[idx]['status'] == status;
    final isLocked = _localRecords[idx]['isMlLocked'] == true;
    final bool canTap = enabled && !isLocked;
    return InkWell(
      onTap: canTap
          ? () => setState(() => _localRecords[idx]['status'] = status)
          : null,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.white,
          border: Border.all(
            color: isSelected ? fg : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          status,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? fg : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color fg = const Color(0xFF475569);
    Color bg = const Color(0xFFF1F5F9);
    String label = status;
    if (status == 'P') {
      fg = const Color(0xFF16A34A);
      bg = const Color(0xFFDCFCE7);
      label = 'Present';
    } else if (status == 'A') {
      fg = const Color(0xFFDC2626);
      bg = const Color(0xFFFEE2E2);
      label = 'Absent';
    } else if (status == 'OD') {
      fg = const Color(0xFF2563EB);
      bg = const Color(0xFFDBEAFE);
      label = 'On Duty';
    } else if (status == 'ML') {
      fg = const Color(0xFF8B5CF6);
      bg = const Color(0xFFF3E8FF);
      label = 'Med. Leave';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusBtn(int idx, String status, Color fg, Color bg, bool enabled) {
    final isSelected = _localRecords[idx]['status'] == status;
    final isLocked = _localRecords[idx]['isMlLocked'] == true;
    final bool canTap = enabled && !isLocked;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: canTap
            ? () => setState(() => _localRecords[idx]['status'] = status)
            : null,
        child: Container(
          width: 46,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? bg : Colors.white,
            border: Border.all(
              color: isSelected ? fg : const Color(0xFFCBD5E1),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? fg : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  // ── Right panel: Attendance Summary with OD in Ratio Calculation (Req 2) ──
  Widget _rightPanel() {
    final total = _localRecords.length;
    final present = _presentCount;
    final absent = _absentCount;
    final od = _odCount;
    final ml = _mlCount;

    // Req 2 Fix: Calculate Attendance Ratio including OD (On Duty)
    final effectivePresent = present + od;
    final pct = total > 0
        ? (effectivePresent / total * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Attendance Summary',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _sumRow(
            Icons.people_outline,
            const Color(0xFF475569),
            const Color(0xFFF1F5F9),
            'Total Students',
            total,
          ),
          const SizedBox(height: 10),
          _sumRow(
            Icons.check_circle_outlined,
            const Color(0xFF16A34A),
            const Color(0xFFDCFCE7),
            'Present (P)',
            present,
          ),
          const SizedBox(height: 10),
          _sumRow(
            Icons.cancel_outlined,
            const Color(0xFFDC2626),
            const Color(0xFFFEE2E2),
            'Absent (A)',
            absent,
          ),
          const SizedBox(height: 10),
          _sumRow(
            Icons.calendar_today_outlined,
            const Color(0xFF2563EB),
            const Color(0xFFDBEAFE),
            'On Duty (OD)',
            od,
          ),
          const SizedBox(height: 10),
          _sumRow(
            Icons.medical_services_outlined,
            const Color(0xFF8B5CF6),
            const Color(0xFFF3E8FF),
            'Med. Leave (ML)',
            ml,
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Ratio',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '(P: $present + OD: $od)',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$pct%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF60A5FA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumRow(IconData icon, Color fg, Color bg, String label, int count) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ],
        ),
      );

  void _openCorrectionRequestDialog() {
    final periodStr = _selectedPeriod ?? 'P1';
    final dateStr = _selectedDate.toString().substring(0, 10);

    final saved = _getSavedSession();
    String? selectedCategory = 'On Duty';
    final remarksCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Attendance Correction Request',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason Category:',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      alignment: AlignmentDirectional.bottomStart,
                      menuMaxHeight: 280,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF334155),
                      ),
                      isExpanded: true,
                      items:
                          [
                                'On Duty',
                                'Medical Leave',
                                'Data Entry Error',
                                'Approved Leave',
                                'Student Submitted Proof',
                                'Other',
                              ]
                              .map(
                                (val) => DropdownMenuItem(
                                  value: val,
                                  child: Text(
                                    val,
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCategory = val;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Faculty Remarks (Mandatory):',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: remarksCtrl,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 12),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Remarks are required';
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Provide detailed reason for correction...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final facultyId = repo.profile['employeeId'] ?? 'FAC002';
                  final facultyName = repo.profile['name'] ?? 'Dr. S. Malliga';
                  final cls = _selectedClass ?? '';
                  final dept = _parseDept(cls);
                  final sec = _parseSection(cls);

                  final request = {
                    'facultyId': facultyId,
                    'facultyName': facultyName,
                    'classSec': _selectedClass,
                    'department': dept,
                    'section': sec,
                    'yearOfStudy': _selectedYear,
                    'subject': _selectedSubject,
                    'period': periodStr,
                    'date': dateStr,
                    'reasonCategory': selectedCategory,
                    'facultyRemarks': remarksCtrl.text.trim(),
                    'requestedTime': DateTime.now().toString().substring(0, 19),
                    'status': 'Pending HOD Approval',
                    'prevRecords': saved != null
                        ? List<Map<String, dynamic>>.from(
                            saved['records'] ?? [],
                          )
                        : [],
                  };

                  final requestsList = LocalStorageBase.readList(
                    'attendanceCorrectionRequests',
                  );
                  requestsList.add(request);
                  LocalStorageBase.writeList(
                    'attendanceCorrectionRequests',
                    requestsList,
                  );

                  await AttendanceService.submitHodCorrectionRequest(
                    facultyEmployeeId: facultyId,
                    facultyName: facultyName,
                    department: dept,
                    yearOfStudy: _selectedYear,
                    section: sec,
                    subjectCode: _selectedSubject ?? '',
                    subjectName: _selectedSubject ?? '',
                    periodCode: periodStr,
                    attendanceDate: dateStr,
                    reasonCategory: selectedCategory ?? 'On Duty',
                    facultyRemarks: remarksCtrl.text.trim(),
                    requestedRecords: _localRecords,
                    attendanceSessionId: saved != null
                        ? saved['id']?.toString()
                        : null,
                  );

                  if (saved != null) {
                    setState(() {
                      _hodRequestSubmitted = true;
                      saved['status'] = 'Pending HOD Approval';
                      saved['correctionCategory'] = selectedCategory;
                      saved['correctionRemarks'] = remarksCtrl.text.trim();
                      repo.saveAttendanceSession(saved);
                    });
                  } else {
                    setState(() {
                      _hodRequestSubmitted = true;
                    });
                  }

                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Correction Request Submitted. Waiting for HOD approval.',
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              child: Text(
                'Send Request to HOD',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save attendance ───────────────────────────────────────────────────────
  Future<void> _saveAttendance() async {
    final dateStr = _selectedDate.toString().substring(0, 10);
    final todayDay = _weekdayName(_selectedDate.weekday);
    final periodStr = _selectedPeriod ?? 'P1';
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    final entry = _activeEntry;
    final startT = _entryStartTime(entry);
    final endT = _entryEndTime(entry);
    final room = entry?['room']?.toString() ?? '';

    await AttendanceService.updateStudentPeriodAttendance(
      date: dateStr,
      classSec: _selectedClass!,
      periodKey: periodStr,
      studentRecords: _localRecords,
    );

    final List<Map<String, dynamic>> recordsToSave = _localRecords
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
    final nowTime = DateTime.now();
    final h = nowTime.hour > 12
        ? nowTime.hour - 12
        : (nowTime.hour == 0 ? 12 : nowTime.hour);
    final m = nowTime.minute.toString().padLeft(2, '0');
    final ampm = nowTime.hour >= 12 ? 'PM' : 'AM';
    final submittedAtStr = '$h:$m $ampm';

    String sec = 'A';
    if (_selectedClass?.contains(' - B ') == true) sec = 'B';

    final session = {
      'attendanceId': 'ATT${DateTime.now().millisecondsSinceEpoch}',
      'date': dateStr,
      'day': todayDay,
      'facultyId': facultyId,
      'classSec': _selectedClass,
      'section': sec,
      'subject': _selectedSubject,
      'period': periodStr,
      'startTime': startT,
      'endTime': endT,
      'room': room,
      'present': _presentCount,
      'absent': _absentCount,
      'od': _odCount,
      'ml': _mlCount,
      'status': 'Submitted',
      'submittedAt': submittedAtStr,
      'records': recordsToSave,
    };

    await repo.saveAttendanceSession(session);

    await _loadStudents();

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Attendance Saved ✓',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance saved to database successfully.',
                style: GoogleFonts.inter(),
              ),
              const SizedBox(height: 12),
              _summaryLine('Class', _selectedClass ?? '—'),
              _summaryLine('Subject', _selectedSubject ?? '—'),
              _summaryLine('Period', periodStr),
              _summaryLine('Date', dateStr),
              _summaryLine('Present', '$_presentCount'),
              _summaryLine('Absent', '$_absentCount'),
              _summaryLine('On Duty', '$_odCount'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'OK',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _summaryLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    ),
  );

  // ── Shared helper widgets ─────────────────────────────────────────────────
  Widget _labeledField({required String label, required Widget child}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      );

  Widget _dropdown(
    List<String> items,
    String? val,
    ValueChanged<String?>? onChange,
  ) {
    final uniqueItems = items.toSet().toList();
    final bool disabled = onChange == null || uniqueItems.isEmpty;
    final String? effectiveValue = (val != null && uniqueItems.contains(val))
        ? val
        : (uniqueItems.isNotEmpty ? uniqueItems.first : null);

    final displayLabel = effectiveValue ?? 'Select...';

    if (disabled) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      initialValue: effectiveValue,
      onSelected: onChange,
      itemBuilder: (context) {
        return uniqueItems.map((item) {
          final bool isSelected = item == effectiveValue;
          return PopupMenuItem<String>(
            value: item,
            height: 38,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
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
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
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

  Widget _disabledBox(String msg) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Text(
      msg,
      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
    ),
  );

  Widget _errorBox(String msg) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFFCA5A5)),
    ),
    child: Text(
      msg,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFFDC2626),
        fontWeight: FontWeight.bold,
      ),
    ),
  );

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
      'AY $text',
      style: GoogleFonts.inter(
        color: const Color(0xFF2563EB),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}
