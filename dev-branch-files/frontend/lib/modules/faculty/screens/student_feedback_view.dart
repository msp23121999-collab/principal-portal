// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../erp_repository.dart';
import '../widgets/faculty_loading.dart';
import '../services/timetable_service.dart';
import '../services/student_service.dart';
import '../services/feedback_service.dart';
import '../services/course_allocation_service.dart';

/// Student Feedback View (Faculty Portal — Index 17)
///
/// Read-only anonymized student feedback evaluation system for logged-in Faculty.
class StudentFeedbackView extends StatefulWidget {
  const StudentFeedbackView({super.key});

  @override
  State<StudentFeedbackView> createState() => _StudentFeedbackViewState();
}

class _StudentFeedbackViewState extends State<StudentFeedbackView> {
  final repo = ErpRepository();

  List<String> _facultySubjects = [];
  List<String> _facultyClassSections = [];

  // ── Filters (Order: Year -> Class & Sec -> Subject -> Rating) ───────────
  String _selectedYear = 'All Years';
  String _selectedClassSec = 'All Classes';
  String _selectedSubject = 'All Subjects';
  String _ratingFilter = 'All Ratings';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  List<Map<String, dynamic>> _allFeedbacks = [];

  @override
  void initState() {
    super.initState();
    _initFacultyScope();
    _loadFeedbacks();
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

  Future<void> _loadFeedbacks({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    final facultyId = repo.profile['employeeId']?.toString() ?? 'FAC002';
    await CourseAllocationService.fetchAllocations(facultyId: facultyId);
    final feedbacks = await FeedbackService.fetchFacultyFeedback(facultyId);

    _facultySubjects = CourseAllocationService.getAllocatedSubjects();
    _facultyClassSections = CourseAllocationService.getAllocatedClasses();

    final subjs = <String>{..._facultySubjects};
    final classes = <String>{..._facultyClassSections};
    for (final f in feedbacks) {
      final s = f['subject']?.toString();
      final c = f['classSec']?.toString();
      if (s != null && s.isNotEmpty) subjs.add(s);
      if (c != null && c.isNotEmpty) classes.add(c);
    }
    _facultySubjects = subjs.toList()..sort();
    _facultyClassSections = classes.toList()..sort();

    if (mounted) {
      setState(() {
        _allFeedbacks = feedbacks;
        _isLoading = false;
      });
    }
  }

  /// Filter available class sections based on selected year
  List<String> get _availableClassOptions {
    if (_selectedYear == 'All Years') return _facultyClassSections;

    final targetYearCode = StudentService.extractYear(_selectedYear);
    return _facultyClassSections.where((c) {
      final y = StudentService.extractYear(c);
      return y.isEmpty || y == targetYearCode;
    }).toList();
  }

  /// Filter available subjects based on selected class
  List<String> get _availableSubjectOptions {
    if (_selectedClassSec == 'All Classes') return _facultySubjects;

    final facultyId = repo.profile['facultyId']?.toString() ?? 'FAC73124';
    final matchingSubjs = <String>{};
    for (final day in TimetableService.getByFaculty(facultyId)) {
      for (final p in (day['schedule'] as List? ?? [])) {
        final cls = p['classSec']?.toString() ?? '';
        final subj = p['subject']?.toString() ?? '';
        if (cls.contains(_selectedClassSec) && subj.isNotEmpty) {
          matchingSubjs.add(subj);
        }
      }
    }
    return matchingSubjs.isEmpty ? _facultySubjects : matchingSubjs.toList();
  }

  List<Map<String, dynamic>> get _filteredFeedbacks {
    final q = _searchQuery.toLowerCase();

    return _allFeedbacks.where((f) {
      final subject = (f['subject'] ?? '').toString();
      final classSec = (f['classSec'] ?? '').toString();
      final comment = (f['comment'] ?? '').toString().toLowerCase();
      final yearRaw = (f['year'] ?? StudentService.extractYear(classSec))
          .toString();

      final selectedYearCode = StudentService.extractYear(_selectedYear);
      final matchesYear =
          _selectedYear == 'All Years' ||
          selectedYearCode.isEmpty ||
          yearRaw.toUpperCase() == selectedYearCode.toUpperCase();

      final matchesClass =
          _selectedClassSec == 'All Classes' ||
          classSec.contains(_selectedClassSec);

      final matchesSubject =
          _selectedSubject == 'All Subjects' ||
          subject.contains(_selectedSubject);

      final rating = (f['rating'] as num? ?? 5).toInt();
      final matchesRating =
          _ratingFilter == 'All Ratings' ||
          (_ratingFilter == '5 Stars' && rating == 5) ||
          (_ratingFilter == '4 Stars' && rating == 4) ||
          (_ratingFilter == '3 Stars' && rating == 3) ||
          (_ratingFilter == '1-2 Stars' && rating <= 2);

      final matchesSearch =
          q.isEmpty || comment.contains(q) || subject.toLowerCase().contains(q);

      return matchesYear &&
          matchesClass &&
          matchesSubject &&
          matchesRating &&
          matchesSearch;
    }).toList();
  }

  // ── Analytics ────────────────────────────────────────────────────────────

  double get _avgOverall {
    final list = _filteredFeedbacks;
    if (list.isEmpty) return 0.0;
    final sum = list.fold<num>(
      0,
      (prev, e) => prev + (e['rating'] as num? ?? 0),
    );
    return sum / list.length;
  }

  double get _avgFeedbackPercentage {
    final list = _filteredFeedbacks;
    if (list.isEmpty) return 0.0;
    final sum = list.fold<num>(0, (prev, e) {
      final fbPct = e['feedbackPercentage'] as num?;
      final rating = e['rating'] as num? ?? 0;
      final val = fbPct ?? (rating * 20);
      return prev + val;
    });
    return sum / list.length;
  }

  int get _positiveCount {
    return _filteredFeedbacks
        .where((f) => (f['rating'] as num? ?? 0).toInt() >= 4)
        .length;
  }

  double get _positiveRate {
    final list = _filteredFeedbacks;
    if (list.isEmpty) return 0.0;
    return (_positiveCount / list.length * 100);
  }

  double get _avgKnowledge {
    final list = _filteredFeedbacks;
    if (list.isEmpty) return 0.0;
    final sum = list.fold<num>(
      0,
      (prev, e) => prev + (e['knowledge'] as num? ?? 0),
    );
    return sum / list.length;
  }

  double get _avgMethodology {
    final list = _filteredFeedbacks;
    if (list.isEmpty) return 0.0;
    final sum = list.fold<num>(
      0,
      (prev, e) => prev + (e['methodology'] as num? ?? 0),
    );
    return sum / list.length;
  }

  double get _avgPunctuality {
    final list = _filteredFeedbacks;
    if (list.isEmpty) return 0.0;
    final sum = list.fold<num>(
      0,
      (prev, e) => prev + (e['punctuality'] as num? ?? 0),
    );
    return sum / list.length;
  }

  double get _avgAvailability {
    final list = _filteredFeedbacks;
    if (list.isEmpty) return 0.0;
    final sum = list.fold<num>(
      0,
      (prev, e) => prev + (e['availability'] as num? ?? 0),
    );
    return sum / list.length;
  }

  int _countStar(int star) {
    return _filteredFeedbacks
        .where((f) => (f['rating'] as num? ?? 0).toInt() == star)
        .length;
  }

  // ── Export Anonymized Report to CSV/Excel ─────────────────────────────────
  void _downloadReportCsv(List<Map<String, dynamic>> feedbacks) {
    final buffer = StringBuffer();
    // Add UTF-8 BOM for Microsoft Excel compatibility
    buffer.write('\uFEFF');

    // Header with uniform column spacing
    buffer.writeln(
      '"Response ID  ","Subject                                       ","Class / Section           ","Overall Rating","Knowledge Score","Methodology Score","Punctuality Score","Availability Score","Comments                                                                                        ","Date        "',
    );

    for (final f in feedbacks) {
      final id = (f['id'] ?? '').toString().padRight(14);
      final subj = (f['subject'] ?? '')
          .toString()
          .replaceAll(',', ' ')
          .padRight(46);
      final classSec = (f['classSec'] ?? '')
          .toString()
          .replaceAll(',', ' ')
          .padRight(26);
      final rating = (f['rating'] as num? ?? 0).toInt();
      final knowledge = (f['knowledge'] as num? ?? 0).toInt();
      final methodology = (f['methodology'] as num? ?? 0).toInt();
      final punctuality = (f['punctuality'] as num? ?? 0).toInt();
      final availability = (f['availability'] as num? ?? 0).toInt();
      final comment = (f['comment'] ?? '')
          .toString()
          .replaceAll(',', ' ')
          .replaceAll('\n', ' ')
          .padRight(96);
      final date = (f['date'] ?? '').toString().padRight(12);

      final rStr = '$rating / 5'.padRight(14);
      final kStr = '$knowledge / 5'.padRight(15);
      final mStr = '$methodology / 5'.padRight(17);
      final pStr = '$punctuality / 5'.padRight(17);
      final aStr = '$availability / 5'.padRight(18);

      buffer.writeln(
        '"$id","$subj","$classSec","$rStr","$kStr","$mStr","$pStr","$aStr","$comment","$date"',
      );
    }

    final fileName =
        'Student_Feedback_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
    repo.triggerFileDownload(fileName, buffer.toString(), 'text/csv');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Downloaded anonymized feedback report for ${feedbacks.length} submissions!',
        ),
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
    final feedbacks = _filteredFeedbacks;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (_isLoading || (repo.isLoadingData && _allFeedbacks.isEmpty)) {
          return const FacultyLoadingWidget();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(feedbacks),
            const SizedBox(height: 20),
            _statCards(),
            const SizedBox(height: 20),
            _scoreSummaryCard(),
            const SizedBox(height: 20),
            _feedbackListCard(feedbacks),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _pageHeader(List<Map<String, dynamic>> feedbacks) {
    return Row(
      children: [
        Text(
          'Student Feedback',
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
          onPressed: () => _downloadReportCsv(feedbacks),
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

  // ── Top Analytical Cards Grid ──────────────────────────────────────────────
  Widget _statCards() {
    final cards = [
      {
        'label': 'Average Rating',
        'value': '${_avgOverall.toStringAsFixed(1)} / 5.0',
        'icon': Icons.star_outline,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFFFBEB),
      },
      {
        'label': 'Total Responses',
        'value': '${_filteredFeedbacks.length}',
        'icon': Icons.rate_review_outlined,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'label': 'Feedback Percentage',
        'value': '${_avgFeedbackPercentage.toStringAsFixed(1)}%',
        'icon': Icons.pie_chart_outline,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFECFDF5),
      },
      {
        'label': 'Positive Feedback Rate',
        'value': '${_positiveRate.toStringAsFixed(0)}%',
        'icon': Icons.thumb_up_alt_outlined,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
      },
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final perRow = constraints.maxWidth < 600
            ? 2
            : (constraints.maxWidth < 1100 ? 2 : 4);
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            c['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 10,
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

  // ── Score Summary & Rating Distribution Breakdown Card ──────────────────────
  Widget _scoreSummaryCard() {
    final overall = _avgOverall;
    final knowledge = _avgKnowledge;
    final methodology = _avgMethodology;
    final punctuality = _avgPunctuality;
    final availability = _avgAvailability;
    final totalFeedbacks = _filteredFeedbacks.length;

    final ratingBox = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            overall > 0 ? overall.toStringAsFixed(1) : '0.0',
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2563EB),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (idx) => Icon(
                idx < overall.round() ? Icons.star : Icons.star_border,
                size: 16,
                color: const Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Overall Average',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          Text(
            '$totalFeedbacks Submissions',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );

    final distributionSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Distribution',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        _distributionRow('5 Stars', _countStar(5), totalFeedbacks),
        const SizedBox(height: 6),
        _distributionRow('4 Stars', _countStar(4), totalFeedbacks),
        const SizedBox(height: 6),
        _distributionRow('3 Stars', _countStar(3), totalFeedbacks),
        const SizedBox(height: 6),
        _distributionRow('2 Stars', _countStar(2), totalFeedbacks),
        const SizedBox(height: 6),
        _distributionRow('1 Star', _countStar(1), totalFeedbacks),
      ],
    );

    final breakdownSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question Parameter Breakdown',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        _categoryBar('Subject Knowledge', knowledge),
        const SizedBox(height: 8),
        _categoryBar('Teaching Methodology', methodology),
        const SizedBox(height: 8),
        _categoryBar('Punctuality & Discipline', punctuality),
        const SizedBox(height: 8),
        _categoryBar('Availability & Support', availability),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Container(
          decoration: _cardDecor(),
          padding: const EdgeInsets.all(20),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: ratingBox),
                    const SizedBox(height: 20),
                    distributionSection,
                    const SizedBox(height: 20),
                    breakdownSection,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ratingBox,
                    const SizedBox(width: 24),
                    Expanded(child: distributionSection),
                    const SizedBox(width: 24),
                    Expanded(child: breakdownSection),
                  ],
                ),
        );
      },
    );
  }

  Widget _distributionRow(String label, int count, int total) {
    final pct = total > 0 ? (count / total) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFD97706),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryBar(String label, double rating) {
    final pct = rating / 5.0;
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${rating.toStringAsFixed(1)} / 5',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ── Main Feedback List Card ────────────────────────────────────────────────
  Widget _feedbackListCard(List<Map<String, dynamic>> feedbacks) {
    return Container(
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Toolbar (Order: Year -> Class & Sec -> Subject -> Rating)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Student Feedback Responses',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                _badge('${feedbacks.length}'),

                // 1. Year Filter
                SizedBox(
                  width: 125,
                  child: _dropdownWidget(
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
                ),

                // 2. Class & Section Filter (Synchronized with Year)
                SizedBox(
                  width: 145,
                  child: _dropdownWidget(
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
                ),

                // 3. Subject Filter (Filtered by Class)
                SizedBox(
                  width: 165,
                  child: _dropdownWidget(
                    ['All Subjects', ..._availableSubjectOptions],
                    _availableSubjectOptions.contains(_selectedSubject)
                        ? _selectedSubject
                        : 'All Subjects',
                    (v) => setState(() => _selectedSubject = v!),
                  ),
                ),

                // 4. Rating Filter
                SizedBox(
                  width: 130,
                  child: _dropdownWidget(
                    [
                      'All Ratings',
                      '5 Stars',
                      '4 Stars',
                      '3 Stars',
                      '1-2 Stars',
                    ],
                    _ratingFilter,
                    (v) => setState(() => _ratingFilter = v!),
                  ),
                ),

                // 5. Search Box
                SizedBox(
                  height: 36,
                  width: 170,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search comments...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
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
                  tooltip: 'Refresh Feedback',
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  onPressed: () async {
                    await _loadFeedbacks();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback data refreshed from Supabase!'),
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
                      _ratingFilter = 'All Ratings';
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

          feedbacks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No student feedback responses found',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No feedback entries match your filter criteria.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: feedbacks.length,
                  separatorBuilder: (ctx, idx) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, idx) => _feedbackTile(feedbacks[idx]),
                ),
        ],
      ),
    );
  }

  // ── Anonymized Feedback Submission Tile ────────────────────────────────────
  Widget _feedbackTile(Map<String, dynamic> f) {
    final rating = (f['rating'] as num? ?? 5).toInt();
    final alias = (f['studentAlias'] ?? 'Anonymous Student').toString();
    final subject = (f['subject'] ?? '').toString();
    final classSec = (f['classSec'] ?? '').toString();
    final comment = (f['comment'] ?? '').toString();
    final date = (f['date'] ?? '').toString();

    final knowledge = (f['knowledge'] as num? ?? 5).toInt();
    final methodology = (f['methodology'] as num? ?? 5).toInt();
    final punctuality = (f['punctuality'] as num? ?? 5).toInt();
    final availability = (f['availability'] as num? ?? 5).toInt();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEFF6FF),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      alias,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        classSec,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subject,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 8),

                // Question Parameter Scores Grid
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _paramChip('Knowledge', '$knowledge/5'),
                    _paramChip('Methodology', '$methodology/5'),
                    _paramChip('Punctuality', '$punctuality/5'),
                    _paramChip('Availability', '$availability/5'),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: List.generate(
                    5,
                    (idx) => Icon(
                      idx < rating ? Icons.star : Icons.star_border,
                      size: 15,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paramChip(String label, String score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $score',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF475569),
        ),
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
