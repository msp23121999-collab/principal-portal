import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';
import '../services/lesson_service.dart';
import '../services/timetable_service.dart';
import '../services/local_storage_base.dart';
import '../services/course_allocation_service.dart';

class LessonPlanView extends StatefulWidget {
  const LessonPlanView({super.key});

  @override
  State<LessonPlanView> createState() => _LessonPlanViewState();
}

class _LessonPlanViewState extends State<LessonPlanView> {
  final repo = ErpRepository();
  String _selectedClassSec = '';
  String _selectedSubject = '';
  String _activeUnitFilter = 'All Units';
  String _activeStatusFilter = 'All Statuses';
  DateTime _selectedScheduleDate = DateTime.now();

  String get _facultyId =>
      repo.profile['employeeId']?.toString() ?? 'EMP_CSE_002';
  String get _dept =>
      repo.profile['department']?.toString() ??
      'Computer Science and Engineering';
  String get _academicYear => repo.selectedAcademicYear;

  @override
  void initState() {
    super.initState();
    _initFilterDefaults();
    _loadFromSupabase();
  }

  void _initFilterDefaults() {
    // Primary: CourseAllocationService
    final allocClasses = CourseAllocationService.getAllocatedClasses();
    if (allocClasses.isNotEmpty) {
      _selectedClassSec = allocClasses.first;
      final allocSubjects = CourseAllocationService.getAllocatedSubjects(
        selectedClass: _selectedClassSec,
      );
      if (allocSubjects.isNotEmpty) {
        _selectedSubject = allocSubjects.first;
      }
      return;
    }
    // Fallback: TimetableService
    final classes = TimetableService.getClassesForFaculty(_facultyId);
    if (classes.isNotEmpty) {
      _selectedClassSec = classes.first;
      final subjects = TimetableService.getSubjectsForClass(
        _facultyId,
        _selectedClassSec,
      );
      if (subjects.isNotEmpty) {
        _selectedSubject = subjects.first;
      }
    }
  }

  Future<void> _loadFromSupabase() async {
    final list = await LessonService.fetchFromSupabase(facultyId: _facultyId);
    if (mounted) {
      setState(() {
        repo.lessonPlans = list;
      });
    }
  }

  String get _monthlyStatus {
    final filtered = repo.lessonPlans
        .where(
          (lp) =>
              (_selectedSubject.isEmpty || lp['subject'] == _selectedSubject) &&
              (_selectedClassSec.isEmpty ||
                  lp['classSec'] == _selectedClassSec ||
                  lp['section'] == _selectedClassSec),
        )
        .toList();
    if (filtered.isEmpty) return 'Draft';
    final statuses = filtered
        .map((lp) => lp['monthlyStatus']?.toString() ?? 'Draft')
        .toSet();
    if (statuses.contains('Submitted to HOD') ||
        statuses.contains('Submitted for Review') ||
        statuses.contains('Submitted'))
      return 'Submitted to HOD';
    if (statuses.contains('Approved') &&
        !statuses.contains('Draft') &&
        !statuses.contains('Rejected'))
      return 'Approved';
    if (statuses.contains('Rejected')) return 'Rejected';
    return 'Draft';
  }

  bool get _isMonthlyLocked =>
      _monthlyStatus == 'Submitted to HOD' || _monthlyStatus == 'Approved';

  bool _isDateEditable(DateTime targetDate) {
    if (_isMonthlyLocked) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // Strictly ONLY today is active & editable
    return targetDay == today;
  }

  bool _isRecordEditable(Map<String, dynamic> record) {
    if (_isMonthlyLocked) return false;
    final dateStr = (record['plannedDate'] ?? record['completionDate'])
        ?.toString();
    if (dateStr == null || dateStr.isEmpty) return false;
    final target = DateTime.tryParse(dateStr);
    if (target == null) return false;
    return _isDateEditable(target);
  }

  @override
  Widget build(BuildContext context) {
    // Primary: CourseAllocationService, with TimetableService fallback
    final allocClasses = CourseAllocationService.getAllocatedClasses();
    final ttClasses = TimetableService.getClassesForFaculty(_facultyId);
    final classes = <String>{...allocClasses, ...ttClasses}.toList()..sort();
    final allClasses = classes.isEmpty
        ? (_selectedClassSec.isNotEmpty ? [_selectedClassSec] : <String>[])
        : classes;
    if (allClasses.isNotEmpty &&
        (_selectedClassSec.isEmpty ||
            !allClasses.contains(_selectedClassSec))) {
      _selectedClassSec = allClasses.first;
    }

    final allocSubjects = CourseAllocationService.getAllocatedSubjects(
      selectedClass: _selectedClassSec,
    );
    final ttSubjects = TimetableService.getSubjectsForClass(
      _facultyId,
      _selectedClassSec,
    );
    final subjects = <String>{...allocSubjects, ...ttSubjects}.toList()..sort();
    final allSubjects = subjects.isEmpty
        ? (_selectedSubject.isNotEmpty ? [_selectedSubject] : <String>[])
        : subjects;
    if (allSubjects.isNotEmpty &&
        (_selectedSubject.isEmpty || !allSubjects.contains(_selectedSubject))) {
      _selectedSubject = allSubjects.first;
    }

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (repo.isLoadingData && repo.lessonPlans.isEmpty) {
          return const FacultyLoadingWidget();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _todayTeachingScheduleSection(),
            const SizedBox(height: 20),
            _previousLessonPlanRecordsSection(),
            const SizedBox(height: 20),
            _filterAndActionRow(allClasses, allSubjects),
            const SizedBox(height: 20),
            _statsRow(),
            const SizedBox(height: 20),
            _syllabusCoverageCard(),
            const SizedBox(height: 20),
            if (_monthlyStatus == 'Rejected') ...[
              _rejectionRemarksCard(),
              const SizedBox(height: 12),
            ],
            _topicsList(),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  // ── Page Header (3. Add topic removed from header) ─────────────────────────
  Widget _pageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final yearBadge = _badge('Academic Year $_academicYear');

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lesson Progress Plan',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              yearBadge,
            ],
          );
        }

        return Row(
          children: [
            Text(
              'Lesson Progress Plan',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            yearBadge,
          ],
        );
      },
    );
  }

  String _formatShortDate(DateTime d) {
    const months = [
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  // ── Timetable-Connected Teaching Schedule Section ────────────────────────
  // ── Timetable-Connected Today's Teaching Schedule Section ──────────────────
  Widget _todayTeachingScheduleSection() {
    final now = DateTime.now();
    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final weekdayName = weekdayNames[now.weekday - 1];
    final todayIso =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final facultyTimetable = TimetableService.getByFaculty(_facultyId);
    final dayEntry = facultyTimetable.firstWhere(
      (item) =>
          (item['day'] ?? '').toString().toLowerCase() ==
          weekdayName.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );
    final scheduleList = (dayEntry['schedule'] as List? ?? [])
        .map((p) => Map<String, dynamic>.from(p as Map))
        .where((p) => (p['subject'] ?? '').toString().trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: Color(0xFF2563EB), size: 22),
              const SizedBox(width: 8),
              Text(
                "Today — ${_formatShortDate(now)} • $weekdayName",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Text(
                  'Active Today',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (scheduleList.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'No classes scheduled in your timetable for today ($weekdayName, ${_formatShortDate(now)}).',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: scheduleList.map((periodItem) {
                final periodCode = periodItem['period']?.toString() ?? 'P1';
                final time = periodItem['time']?.toString() ?? '';
                final subject = periodItem['subject']?.toString() ?? '';
                final code = periodItem['code']?.toString() ?? '';
                final classSec = periodItem['classSec']?.toString() ?? '';
                final room = periodItem['room']?.toString() ?? '';

                // Match existing today's lesson plan entry
                final existingRecord = repo.lessonPlans.firstWhere((lp) {
                  final lpPeriod = lp['period']?.toString() ?? '';
                  final lpSubj = lp['subject']?.toString() ?? '';
                  final lpClass =
                      (lp['classSec'] ?? lp['section'])?.toString() ?? '';
                  final lpPlanDate = lp['plannedDate']?.toString() ?? '';
                  final lpCompDate = lp['completionDate']?.toString() ?? '';

                  bool dateMatch =
                      lpPlanDate == todayIso || lpCompDate == todayIso;
                  bool periodMatch =
                      lpPeriod.isNotEmpty &&
                      lpPeriod.toUpperCase() == periodCode.toUpperCase();
                  bool subjMatch =
                      lpSubj.toLowerCase() == subject.toLowerCase();
                  bool classMatch =
                      lpClass.toLowerCase() == classSec.toLowerCase();

                  return (dateMatch && periodMatch) ||
                      (dateMatch && subjMatch && classMatch);
                }, orElse: () => <String, dynamic>{});

                final hasEntry = existingRecord.isNotEmpty;
                final status =
                    existingRecord['status']?.toString() ?? 'Pending';
                final topicTitle = existingRecord['topic']?.toString() ?? '';
                final unitTitle = existingRecord['unitTitle']?.toString() ?? '';
                final unitStr = existingRecord['unit']?.toString() ?? '';

                return Container(
                  width: 340,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasEntry ? Colors.white : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasEntry
                          ? (status == 'Completed'
                                ? const Color(0xFF10B981)
                                : const Color(0xFF2563EB))
                          : const Color(0xFFCBD5E1),
                      width: hasEntry ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Text(
                              '$periodCode ${time.isNotEmpty ? "($time)" : ""}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (hasEntry) _statusChip(status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subject,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (code.isNotEmpty)
                        Text(
                          code,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            classSec,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          if (room.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.meeting_room_outlined,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              room,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      if (hasEntry) ...[
                        Text(
                          unitStr.isNotEmpty
                              ? '$unitStr: $topicTitle'
                              : topicTitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (unitTitle.isNotEmpty)
                          Text(
                            unitTitle,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: _isMonthlyLocked
                                ? null
                                : () => _showTopicModal(
                                    existingRecord,
                                    presetSubject: subject,
                                    presetClassSec: classSec,
                                    presetPeriod: periodCode,
                                    presetDate: todayIso,
                                  ),
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: Text(
                              'Update Topic',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Topic: Not Added',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _isMonthlyLocked
                                ? null
                                : () => _showTopicModal(
                                    null,
                                    presetSubject: subject,
                                    presetClassSec: classSec,
                                    presetPeriod: periodCode,
                                    presetDate: todayIso,
                                  ),
                            icon: const Icon(Icons.add, size: 14),
                            label: Text(
                              'Add Topic',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Previous Lesson Plan Records (Historical / Locked Section) ──────────────
  Widget _previousLessonPlanRecordsSection() {
    final now = DateTime.now();
    final todayIso =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final pastPlans = repo.lessonPlans.where((lp) {
      final pDate = lp['plannedDate']?.toString() ?? '';
      final cDate = lp['completionDate']?.toString() ?? '';
      final dateStr = pDate.isNotEmpty ? pDate : cDate;
      if (dateStr.isEmpty) return false;
      final topic = (lp['topic']?.toString() ?? '').trim();
      if (topic.isEmpty || topic.toLowerCase() == 'not added') return false;
      return dateStr.compareTo(todayIso) < 0;
    }).toList();

    if (pastPlans.isEmpty) return const SizedBox.shrink();

    final Map<String, List<Map<String, dynamic>>> groupedByDate = {};
    for (final lp in pastPlans) {
      final pDate = lp['plannedDate']?.toString() ?? '';
      final cDate = lp['completionDate']?.toString() ?? '';
      final dateStr = pDate.isNotEmpty ? pDate : cDate;
      groupedByDate.putIfAbsent(dateStr, () => []).add(lp);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF64748B), size: 20),
              const SizedBox(width: 8),
              Text(
                "PREVIOUS LESSON PLAN RECORDS",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Locked / Read-Only',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...sortedDates.map((dateStr) {
            final items = groupedByDate[dateStr] ?? [];
            final dateObj = DateTime.tryParse(dateStr);
            final dayName = dateObj != null
                ? weekdayNames[dateObj.weekday - 1]
                : '';
            final formattedDate = dateObj != null
                ? _formatShortDate(dateObj)
                : dateStr;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$formattedDate — $dayName',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: items.map((lp) {
                      final period = lp['period']?.toString() ?? 'P1';
                      final subject = lp['subject']?.toString() ?? '';
                      final topic = lp['topic']?.toString() ?? '';
                      final status = lp['status']?.toString() ?? 'Completed';
                      final classSec =
                          (lp['classSec'] ?? lp['section'])?.toString() ?? '';

                      return Container(
                        width: 300,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  period,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    subject,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _statusChip(status),
                              ],
                            ),
                            if (classSec.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                classSec,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Topic: $topic',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF334155),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showTopicModal(lp, isReadOnly: true),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 12,
                                ),
                                label: Text(
                                  'View Record (Locked)',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF64748B),
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 9. Filter and Action Row (Moved above unit coverage) ───────────────────
  Widget _filterAndActionRow(
    List<String> allClasses,
    List<String> allSubjects,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 2. Class & Section Filter
          _filterLabelDropdown(
            'Class & Section',
            allClasses,
            _selectedClassSec,
            (v) => setState(() {
              _selectedClassSec = v!;
              final subs = TimetableService.getSubjectsForClass(
                _facultyId,
                _selectedClassSec,
              );
              if (subs.isNotEmpty) _selectedSubject = subs.first;
            }),
          ),
          // 2. Subject Filter
          _filterLabelDropdown(
            'Subject',
            allSubjects,
            _selectedSubject,
            (v) => setState(() => _selectedSubject = v!),
          ),
          // Unit Filter
          _filterLabelDropdown(
            'Unit',
            ['All Units', 'Unit 1', 'Unit 2', 'Unit 3', 'Unit 4', 'Unit 5'],
            _activeUnitFilter,
            (v) => setState(() => _activeUnitFilter = v!),
          ),
          // Status Filter
          _filterLabelDropdown(
            'Status',
            ['All Statuses', 'Pending', 'In Progress', 'Completed'],
            _activeStatusFilter,
            (v) => setState(() => _activeStatusFilter = v!),
          ),
          const SizedBox(width: 4),
          // 5. Download Report as Excel Button
          OutlinedButton.icon(
            onPressed: _exportExcelReport,
            icon: const Icon(
              Icons.download_outlined,
              size: 16,
              color: Color(0xFF16A34A),
            ),
            label: Text(
              'Download Report (Excel)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF16A34A),
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF0FDF4),
              side: const BorderSide(color: Color(0xFFBBF7D0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Submit to HOD Button
          ElevatedButton.icon(
            onPressed: _isMonthlyLocked ? null : _submitMonthlyProgress,
            icon: const Icon(Icons.send_rounded, size: 14),
            label: Text(
              'Submit Monthly Progress to HOD',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMonthlyLocked
                  ? Colors.grey
                  : const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterLabelDropdown(
    String label,
    List<String> items,
    String currentVal,
    ValueChanged<String?> onChange,
  ) {
    final uniqueItems = items.toSet().toList();
    final val = uniqueItems.contains(currentVal)
        ? currentVal
        : (uniqueItems.isNotEmpty ? uniqueItems.first : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        PopupMenuButton<String>(
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
          onSelected: onChange,
          itemBuilder: (context) {
            return uniqueItems.map((item) {
              final bool isSelected = item == val;
              return PopupMenuItem<String>(
                value: item,
                height: 38,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
                    fontSize: 14,
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────
  Widget _statsRow() {
    final plans = repo.lessonPlans
        .where(
          (lp) =>
              (_selectedSubject.isEmpty || lp['subject'] == _selectedSubject),
        )
        .toList();

    final total = plans.length;
    final complet = plans.where((p) => p['status'] == 'Completed').length;
    final inProg = plans.where((p) => p['status'] == 'In Progress').length;
    final pending = plans
        .where((p) => p['status'] == 'Pending' || p['status'] == 'Scheduled')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 650) {
          return Row(
            children: [
              Expanded(
                child: _statPill(
                  Icons.auto_stories_outlined,
                  const Color(0xFF2563EB),
                  const Color(0xFFEFF6FF),
                  'Total Topics',
                  '$total',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statPill(
                  Icons.check_circle_outline,
                  const Color(0xFF16A34A),
                  const Color(0xFFF0FDF4),
                  'Completed',
                  '$complet',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statPill(
                  Icons.pending_actions_outlined,
                  const Color(0xFF7C3AED),
                  const Color(0xFFF5F3FF),
                  'In Progress',
                  '$inProg',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statPill(
                  Icons.hourglass_empty_outlined,
                  const Color(0xFFD97706),
                  const Color(0xFFFFFBEB),
                  'Pending',
                  '$pending',
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 180,
                child: _statPill(
                  Icons.auto_stories_outlined,
                  const Color(0xFF2563EB),
                  const Color(0xFFEFF6FF),
                  'Total Topics',
                  '$total',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: _statPill(
                  Icons.check_circle_outline,
                  const Color(0xFF16A34A),
                  const Color(0xFFF0FDF4),
                  'Completed',
                  '$complet',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: _statPill(
                  Icons.pending_actions_outlined,
                  const Color(0xFF7C3AED),
                  const Color(0xFFF5F3FF),
                  'In Progress',
                  '$inProg',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: _statPill(
                  Icons.hourglass_empty_outlined,
                  const Color(0xFFD97706),
                  const Color(0xFFFFFBEB),
                  'Pending',
                  '$pending',
                ),
              ),
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
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Syllabus Coverage by Units ─────────────────────────────────────────────
  Widget _syllabusCoverageCard() {
    final units = ['Unit 1', 'Unit 2', 'Unit 3', 'Unit 4', 'Unit 5'];

    final Map<String, double> unitProgress = {};
    final Map<String, int> unitCompleted = {};
    final Map<String, int> unitTotal = {};

    final currentPlans = repo.lessonPlans
        .where(
          (lp) =>
              (_selectedSubject.isEmpty || lp['subject'] == _selectedSubject),
        )
        .toList();

    for (final u in units) {
      final unitPlans = currentPlans
          .where(
            (lp) =>
                (lp['unit']?.toString() ?? '').toLowerCase().contains(
                  u.toLowerCase(),
                ) ||
                (lp['unitNumber']?.toString() == u.replaceAll('Unit ', '')),
          )
          .toList();
      final done = unitPlans.where((lp) => lp['status'] == 'Completed').length;
      final tot = unitPlans.length;

      unitTotal[u] = tot;
      unitCompleted[u] = done;
      unitProgress[u] = tot > 0 ? done / tot : 0.0;
    }

    final totalCount = currentPlans.length;
    final totalCompleted = currentPlans
        .where((lp) => lp['status'] == 'Completed')
        .length;
    final overallPct = totalCount > 0
        ? (totalCompleted / totalCount * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Syllabus Coverage by Unit',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              _badge('Overall Coverage: $overallPct%'),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: units.map((u) {
                final prog = unitProgress[u] ?? 0.0;
                final pct = (prog * 100).round();
                final done = unitCompleted[u] ?? 0;
                final tot = unitTotal[u] ?? 0;
                final statusText = pct == 100
                    ? 'Completed'
                    : (pct > 0 ? 'In Progress' : 'Pending');
                final Color col = pct == 100
                    ? const Color(0xFF059669)
                    : (pct > 0
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8));
                final Color bg = pct == 100
                    ? const Color(0xFFECFDF5)
                    : (pct > 0
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC));

                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: col.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 54,
                              height: 54,
                              child: CircularProgressIndicator(
                                value: prog,
                                strokeWidth: 5,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(col),
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: col,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        u,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: col,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$done / $tot Topics',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Topics List View ───────────────────────────────────────────────────────
  Widget _topicsList() {
    var topics = repo.lessonPlans.where((lp) {
      final matchSubj =
          _selectedSubject.isEmpty || lp['subject'] == _selectedSubject;
      final matchClass =
          _selectedClassSec.isEmpty ||
          lp['classSec'] == _selectedClassSec ||
          lp['section'] == _selectedClassSec ||
          lp['department'] == _selectedClassSec;
      final topic = (lp['topic']?.toString() ?? '').trim();
      final hasTopic = topic.isNotEmpty && topic.toLowerCase() != 'not added';
      return matchSubj && matchClass && hasTopic;
    }).toList();

    if (_activeUnitFilter != 'All Units') {
      topics = topics
          .where(
            (t) => (t['unit']?.toString() ?? '').toLowerCase().contains(
              _activeUnitFilter.toLowerCase(),
            ),
          )
          .toList();
    }
    if (_activeStatusFilter != 'All Statuses') {
      topics = topics.where((t) => t['status'] == _activeStatusFilter).toList();
    }

    if (topics.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: _cardDecor(),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              Text(
                'No lesson plan topics found for the selected filter.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a date in Teaching Schedule above to log or plan topics.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lesson Plan Schedule Topics',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              _badge('${topics.length} Topics Listed'),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1000,
              child: Column(
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
                        Expanded(flex: 2, child: _th('Unit')),
                        Expanded(flex: 4, child: _th('Topic Title')),
                        Expanded(flex: 2, child: _th('Planned Date')),
                        Expanded(flex: 2, child: _th('Actual Date')),
                        Expanded(flex: 2, child: _th('Teaching Aid')),
                        Expanded(flex: 2, child: _th('Status')),
                        Expanded(flex: 2, child: _th('Actions')),
                      ],
                    ),
                  ),
                  ...topics.map((t) => _topicRow(t)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicRow(Map<String, dynamic> t) {
    final status = t['status']?.toString() ?? 'Pending';
    final unitStr = t['unit']?.toString() ?? 'Unit 1';
    final topicStr = t['topic']?.toString() ?? '';
    final plannedDate = t['plannedDate']?.toString() ?? '—';
    final actualDate = t['completionDate']?.toString() ?? '—';
    final aid = t['teachingAid']?.toString() ?? 'Blackboard';
    final isEditable = _isRecordEditable(t);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              unitStr,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topicStr,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (t['unitTitle'] != null &&
                    t['unitTitle'].toString().isNotEmpty)
                  Text(
                    t['unitTitle'].toString(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              plannedDate,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              actualDate,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: actualDate != '—'
                    ? const Color(0xFF059669)
                    : const Color(0xFF94A3B8),
                fontWeight: actualDate != '—'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              aid,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          Expanded(flex: 2, child: _statusChip(status)),
          Expanded(
            flex: 2,
            child: Row(
              children: isEditable
                  ? [
                      _circleAction(
                        Icons.edit_outlined,
                        const Color(0xFF475569),
                        const Color(0xFFF1F5F9),
                        onTap: () => _showTopicModal(t),
                      ),
                      const SizedBox(width: 6),
                      _circleAction(
                        Icons.delete_outline,
                        const Color(0xFFDC2626),
                        const Color(0xFFFEF2F2),
                        onTap: () => _deleteTopic(t),
                      ),
                    ]
                  : [
                      Tooltip(
                        message: 'Locked — Outside 24h Window',
                        child: _circleAction(
                          Icons.visibility_outlined,
                          const Color(0xFF64748B),
                          const Color(0xFFF1F5F9),
                          onTap: () => _showTopicModal(t, isReadOnly: true),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Unrestricted Topic Modal (No Syllabus Constraint) ─────────────────
  void _showTopicModal(
    Map<String, dynamic>? editing, {
    String? presetSubject,
    String? presetClassSec,
    String? presetPeriod,
    String? presetDate,
    bool isReadOnly = false,
  }) {
    final isEdit = editing != null;

    final effectiveSubject =
        presetSubject ??
        (isEdit
            ? (editing['subject']?.toString() ?? _selectedSubject)
            : _selectedSubject);
    final effectiveClassSec =
        presetClassSec ??
        (isEdit
            ? ((editing['classSec'] ?? editing['section'])?.toString() ??
                  _selectedClassSec)
            : _selectedClassSec);
    final effectivePeriod =
        presetPeriod ?? (isEdit ? (editing['period']?.toString() ?? '') : '');
    final initialDate =
        presetDate ??
        (isEdit
            ? (editing['plannedDate']?.toString() ??
                  DateTime.now().toString().substring(0, 10))
            : DateTime.now().toString().substring(0, 10));

    final unitCtrl = TextEditingController(
      text: isEdit ? (editing['unitNumber']?.toString() ?? '1') : '1',
    );
    final unitTitleCtrl = TextEditingController(
      text: isEdit ? (editing['unitTitle']?.toString() ?? '') : '',
    );
    final topicCtrl = TextEditingController(
      text: isEdit ? (editing['topic']?.toString() ?? '') : '',
    );
    final plannedDateCtrl = TextEditingController(text: initialDate);
    final actualDateCtrl = TextEditingController(
      text: isEdit ? (editing['completionDate']?.toString() ?? '') : '',
    );
    final aidCtrl = TextEditingController(
      text: isEdit
          ? (editing['teachingAid']?.toString() ?? 'Blackboard')
          : 'Blackboard',
    );
    final targetHoursCtrl = TextEditingController(
      text: isEdit ? (editing['targetHours']?.toString() ?? '1') : '1',
    );
    final remarksCtrl = TextEditingController(
      text: isEdit ? (editing['remarks']?.toString() ?? '') : '',
    );
    String status = isEdit
        ? (editing['status']?.toString() ?? 'Pending')
        : 'Pending';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Container(
              width: 750,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isReadOnly
                              ? Icons.lock_outline
                              : Icons.add_task_outlined,
                          color: isReadOnly
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF2563EB),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isReadOnly
                              ? 'View Lesson Topic (Read-Only)'
                              : (isEdit
                                    ? 'Edit Lesson Topic'
                                    : 'Add Lesson Topic'),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    if (isReadOnly) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Historical Record Locked — Outside 24-Hour Correction Window',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Read-only Timetable Subject Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Subject (Read-Only from Timetable): $effectiveSubject   •   Class: $effectiveClassSec ${effectivePeriod.isNotEmpty ? "   •   Period: $effectivePeriod" : ""}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _dlgField(
                            'Unit Number (e.g. 1, 2)',
                            unitCtrl,
                            readOnly: isReadOnly,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _dlgField(
                            'Unit Title (e.g. Relational Model)',
                            unitTitleCtrl,
                            readOnly: isReadOnly,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _dlgField(
                      'Topic Name / Title *',
                      topicCtrl,
                      readOnly: isReadOnly,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _dlgField(
                            'Teaching Aid / Methodology',
                            aidCtrl,
                            readOnly: isReadOnly,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dlgField(
                            'Target Hours',
                            targetHoursCtrl,
                            readOnly: isReadOnly,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: isReadOnly
                              ? _dlgField(
                                  'Status',
                                  TextEditingController(text: status),
                                  readOnly: true,
                                )
                              : _dlgDropdown(
                                  'Status',
                                  ['Pending', 'In Progress', 'Completed'],
                                  status,
                                  (v) => setModal(() => status = v!),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _dlgField(
                      'Remarks / Delay Reason',
                      remarksCtrl,
                      maxLines: 2,
                      readOnly: isReadOnly,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            isReadOnly ? 'Close' : 'Cancel',
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        ),
                        if (!isReadOnly) ...[
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (topicCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a Topic Name'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final unitInt =
                                  int.tryParse(unitCtrl.text.trim()) ?? 1;
                              final dateVal = presetDate ?? initialDate;
                              final map = <String, dynamic>{
                                'id': isEdit
                                    ? editing['id']
                                    : LocalStorageBase.generateId('LP'),
                                'lessonPlanId': isEdit
                                    ? editing['lessonPlanId']
                                    : LocalStorageBase.generateId('LP'),
                                'facultyId': _facultyId,
                                'code': effectiveSubject,
                                'subject': effectiveSubject,
                                'unit': 'Unit $unitInt',
                                'unitNumber': unitInt,
                                'unitTitle': unitTitleCtrl.text.trim(),
                                'topic': topicCtrl.text.trim(),
                                'plannedDate': dateVal,
                                'completionDate': status == 'Completed'
                                    ? dateVal
                                    : '',
                                'status': status,
                                'teachingAid': aidCtrl.text.trim(),
                                'targetHours':
                                    int.tryParse(targetHoursCtrl.text.trim()) ??
                                    1,
                                'remarks': remarksCtrl.text.trim(),
                                'department': _dept,
                                'section': effectiveClassSec,
                                'classSec': effectiveClassSec,
                                'period': effectivePeriod,
                                'academicYear': _academicYear,
                              };

                              await LessonService.save(map);
                              await _loadFromSupabase();
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEdit
                                          ? 'Topic updated successfully ✓'
                                          : 'Topic added successfully ✓',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              isEdit ? 'Save Changes' : 'Add Topic',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteTopic(Map<String, dynamic> t) {
    final id = t['id']?.toString() ?? t['lessonPlanId']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Topic',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this topic?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await LessonService.delete(id);
              await _loadFromSupabase();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Topic deleted ✓'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 8. Submit Monthly Progress to HOD schema ──────────────────────────────
  void _submitMonthlyProgress() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.send_rounded, color: Color(0xFF059669)),
            const SizedBox(width: 8),
            Text(
              'Submit Progress to HOD',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Submit Lesson Progress for $_selectedSubject ($_selectedClassSec) to HOD?\n\nThis will record progress in the HOD schema.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final plans = repo.lessonPlans
                  .where(
                    (lp) =>
                        (_selectedSubject.isEmpty ||
                        lp['subject'] == _selectedSubject),
                  )
                  .toList();

              final total = plans.length;
              final completed = plans
                  .where((lp) => lp['status'] == 'Completed')
                  .length;
              final pct = total > 0 ? (completed / total * 100) : 0.0;

              await LessonService.submitMonthlyProgressToHod(
                facultyId: _facultyId,
                department: _dept,
                section: _selectedClassSec,
                subject: _selectedSubject,
                courseCode: _selectedSubject,
                month: 'July 2026',
                academicYear: _academicYear,
                totalTopics: total,
                completedTopics: completed,
                completionPct: pct,
              );

              await _loadFromSupabase();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Monthly Lesson Progress submitted to HOD! ✓',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
            ),
            child: Text(
              'Confirm & Submit',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Excel Export Functionality ─────────────────────────────────────────
  void _exportExcelReport() {
    final topics = repo.lessonPlans.where((lp) {
      final matchSubj =
          _selectedSubject.isEmpty || lp['subject'] == _selectedSubject;
      final matchClass =
          _selectedClassSec.isEmpty ||
          lp['classSec'] == _selectedClassSec ||
          lp['section'] == _selectedClassSec ||
          lp['department'] == _selectedClassSec;
      return matchSubj && matchClass;
    }).toList();

    final csv = StringBuffer();
    csv.writeln(
      'Unit Number,Unit Title,Topic Name,Class & Section,Subject Name,Planned Date,Actual Date,Teaching Aid,Target Hours,Status,Remarks',
    );

    for (final t in topics) {
      final uNum = (t['unit'] ?? 'Unit 1').toString();
      final uTitle = (t['unitTitle'] ?? '').toString().replaceAll('"', '""');
      final topicName = (t['topic'] ?? '').toString().replaceAll('"', '""');
      final cSec = _selectedClassSec;
      final subj = _selectedSubject;
      final planned = (t['plannedDate'] ?? '—').toString();
      final actual = (t['completionDate'] ?? '—').toString();
      final aid = (t['teachingAid'] ?? 'Blackboard').toString();
      final hours = (t['targetHours'] ?? 1).toString();
      final st = (t['status'] ?? 'Pending').toString();
      final rem = (t['remarks'] ?? '').toString().replaceAll('"', '""');

      csv.writeln(
        '"$uNum","$uTitle","$topicName","$cSec","$subj","$planned","$actual","$aid","$hours","$st","$rem"',
      );
    }

    repo.triggerFileDownload(
      'Lesson_Plan_Report_${_selectedClassSec.replaceAll(' ', '_')}_${_selectedSubject.replaceAll(' ', '_')}.csv',
      csv.toString(),
      'text/csv',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting Lesson Plan Excel Report... ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _rejectionRemarksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson Plan Rejected by HOD',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Remarks: Re-check planned dates and complete pending units.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF7F1D1D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dlgDropdown(
    String label,
    List<String> items,
    String currentVal,
    ValueChanged<String?> onChange,
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
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 11),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _dlgField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      readOnly: readOnly,
      style: GoogleFonts.inter(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 11),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _dlgDateField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
    required StateSetter setModal,
    bool allowPast = false,
    bool readOnly = false,
  }) {
    return GestureDetector(
      onTap: readOnly
          ? null
          : () async {
              DateTime? initial;
              if (controller.text.isNotEmpty) {
                initial = DateTime.tryParse(controller.text);
              }
              final picked = await _LessonDatePickerDialog.show(
                context: context,
                initialDate: initial,
                disablePastDates: !allowPast,
              );
              if (picked != null) {
                setModal(() {
                  controller.text =
                      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                });
              }
            },
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          readOnly: true,
          style: GoogleFonts.inter(fontSize: 12),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.inter(fontSize: 11),
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: readOnly
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF2563EB),
            ),
            hintText: 'Tap to select',
            hintStyle: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    if (status == 'Completed' || status == 'Approved') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
    } else if (status == 'In Progress' ||
        status == 'Submitted' ||
        status == 'Submitted to HOD') {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF2563EB);
    } else if (status == 'Pending') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
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

  Widget _th(String t) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF64748B),
    ),
  );

  Widget _circleAction(
    IconData icon,
    Color fg,
    Color bg, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: fg),
      ),
    );
  }
}

// ── Lesson Date Picker Dialog ─────────────────────────────────────────────────

class _LessonDatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final bool disablePastDates;

  const _LessonDatePickerDialog({
    this.initialDate,
    this.disablePastDates = false,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    DateTime? initialDate,
    bool disablePastDates = false,
  }) {
    return showGeneralDialog<DateTime?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, a1, a2, child) {
        final curve = CurveTween(curve: Curves.easeOutBack).animate(a1);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: a1,
            child: _LessonDatePickerDialog(
              initialDate: initialDate,
              disablePastDates: disablePastDates,
            ),
          ),
        );
      },
    );
  }

  @override
  State<_LessonDatePickerDialog> createState() =>
      _LessonDatePickerDialogState();
}

class _LessonDatePickerDialogState extends State<_LessonDatePickerDialog> {
  late DateTime _focusedMonth;
  DateTime? _selected;
  final _today = DateTime.now();

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _focusedMonth = DateTime(
      (widget.initialDate ?? _today).year,
      (widget.initialDate ?? _today).month,
    );
  }

  bool _isPast(DateTime d) {
    final todayMid = DateTime(_today.year, _today.month, _today.day);
    return d.isBefore(todayMid);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, _today);

  void _selectQuick(String action) {
    setState(() {
      final todayMid = DateTime(_today.year, _today.month, _today.day);
      switch (action) {
        case 'Today':
          _selected = todayMid;
          _focusedMonth = DateTime(todayMid.year, todayMid.month);
          break;
        case 'Tomorrow':
          _selected = todayMid.add(const Duration(days: 1));
          _focusedMonth = DateTime(_selected!.year, _selected!.month);
          break;
        case 'Next Monday':
          int diff = DateTime.monday - todayMid.weekday;
          if (diff <= 0) diff += 7;
          _selected = todayMid.add(Duration(days: diff));
          _focusedMonth = DateTime(_selected!.year, _selected!.month);
          break;
        case 'Next Week':
          _selected = todayMid.add(const Duration(days: 7));
          _focusedMonth = DateTime(_selected!.year, _selected!.month);
          break;
        case 'Clear':
          _selected = null;
          break;
      }
    });
  }

  List<Widget> _buildDayGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final startOffset = firstDay.weekday % 7; // Sun=0
    final cells = <Widget>[];

    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final isSel = _selected != null && _isSameDay(date, _selected!);
      final isT = _isToday(date);
      final disabled = widget.disablePastDates && _isPast(date);
      final isSun = date.weekday == DateTime.sunday;
      final isSat = date.weekday == DateTime.saturday;

      cells.add(
        GestureDetector(
          onTap: disabled ? null : () => setState(() => _selected = date),
          child: Container(
            alignment: Alignment.center,
            decoration: isSel
                ? BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  )
                : isT
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2563EB),
                      width: 1.5,
                    ),
                  )
                : null,
            child: Text(
              '$d',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: disabled
                    ? const Color(0xFFCBD5E1)
                    : isSel
                    ? Colors.white
                    : isSun
                    ? const Color(0xFFEF4444)
                    : isSat
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      );
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Month / Year Navigation ──────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () => setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      );
                    }),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton<int>(
                          value: _focusedMonth.month,
                          underline: const SizedBox(),
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text(
                                _months[i],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          onChanged: (v) => setState(() {
                            _focusedMonth = DateTime(_focusedMonth.year, v!);
                          }),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _focusedMonth.year,
                          underline: const SizedBox(),
                          items: List.generate(10, (i) {
                            final yr = _today.year - 1 + i;
                            return DropdownMenuItem(
                              value: yr,
                              child: Text(
                                '$yr',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            );
                          }),
                          onChanged: (v) => setState(() {
                            _focusedMonth = DateTime(v!, _focusedMonth.month);
                          }),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () => setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Weekday Headers ───────────────────────────────────────────
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: _weekdays
                    .map(
                      (d) => Center(
                        child: Text(
                          d,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: d == 'Sun'
                                ? const Color(0xFFEF4444)
                                : d == 'Sat'
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              // ── Day Grid ─────────────────────────────────────────────────
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: _buildDayGrid(),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // ── Quick Action Buttons ──────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children:
                    ['Today', 'Tomorrow', 'Next Monday', 'Next Week', 'Clear']
                        .map(
                          (a) => OutlinedButton(
                            onPressed: () => _selectQuick(a),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              foregroundColor: const Color(0xFF475569),
                              textStyle: GoogleFonts.inter(fontSize: 12),
                            ),
                            child: Text(a),
                          ),
                        )
                        .toList(),
              ),

              const SizedBox(height: 16),

              // ── Cancel / Apply ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
}
