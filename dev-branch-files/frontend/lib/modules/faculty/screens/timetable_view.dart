import 'dart:async';
import 'dart:math' as math;
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../erp_repository.dart';
import '../services/timetable_service.dart';

class TimetableView extends StatefulWidget {
  const TimetableView({super.key});

  @override
  State<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<TimetableView> {
  final repo = ErpRepository();
  late Timer _timer;
  DateTime _now = DateTime.now();

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  String _searchQuery = '';
  bool _isRefreshing = false;

  // Mobile Responsiveness state
  String _selectedMobileDay = 'Monday';
  bool _isMobileCardsView = true;

  // ── Engineering College timetable column order ──────────────────────────────
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  // 8 teaching periods only — no break/lunch columns
  final List<Map<String, dynamic>> _cols = [
    {'label': 'Period 1', 'key': 'P1'},
    {'label': 'Period 2', 'key': 'P2'},
    {'label': 'Period 3', 'key': 'P3'},
    {'label': 'Period 4', 'key': 'P4'},
    {'label': 'Period 5', 'key': 'P5'},
    {'label': 'Period 6', 'key': 'P6'},
    {'label': 'Period 7', 'key': 'P7'},
    {'label': 'Period 8', 'key': 'P8'},
  ];

  // Canonical period times
  final Map<String, Map<String, String>> _periodTimes = {
    'P1': {'start': '09:00 AM', 'end': '09:50 AM'},
    'P2': {'start': '09:50 AM', 'end': '10:40 AM'},
    'P3': {'start': '10:55 AM', 'end': '11:40 AM'},
    'P4': {'start': '11:40 AM', 'end': '12:30 PM'},
    'P5': {'start': '01:30 PM', 'end': '02:20 PM'},
    'P6': {'start': '02:20 PM', 'end': '03:10 PM'},
    'P7': {'start': '03:10 PM', 'end': '04:00 PM'},
    'P8': {'start': '04:00 PM', 'end': '04:50 PM'},
  };

  // Low-brightness blue-themed color palettes for subject differentiation
  final List<Map<String, Color>> _blueThemePalettes = const [
    {
      'bg': Color(0xFFEFF6FF),
      'border': Color(0xFF93C5FD),
      'title': Color(0xFF1E3A8A),
      'subtitle': Color(0xFF1D4ED8),
      'room': Color(0xFF2563EB),
    },
    {
      'bg': Color(0xFFF0F9FF),
      'border': Color(0xFF7DD3FC),
      'title': Color(0xFF0C4A6E),
      'subtitle': Color(0xFF0284C7),
      'room': Color(0xFF0369A1),
    },
    {
      'bg': Color(0xFFEEF2FF),
      'border': Color(0xFFA5B4FC),
      'title': Color(0xFF312E81),
      'subtitle': Color(0xFF4338CA),
      'room': Color(0xFF4F46E5),
    },
    {
      'bg': Color(0xFFECFEFF),
      'border': Color(0xFF67E8F9),
      'title': Color(0xFF164E63),
      'subtitle': Color(0xFF0891B2),
      'room': Color(0xFF0E7490),
    },
    {
      'bg': Color(0xFFF8FAFC),
      'border': Color(0xFF94A3B8),
      'title': Color(0xFF0F172A),
      'subtitle': Color(0xFF334155),
      'room': Color(0xFF475569),
    },
    {
      'bg': Color(0xFFF5F3FF),
      'border': Color(0xFFC4B5FD),
      'title': Color(0xFF4C1D95),
      'subtitle': Color(0xFF6D28D9),
      'room': Color(0xFF7C3AED),
    },
  ];

  Map<String, Color> _getSubjectColorPalette(String subject) {
    if (subject.isEmpty) return _blueThemePalettes[0];
    final hash = subject.codeUnits.fold(0, (prev, elem) => prev + elem);
    return _blueThemePalettes[hash % _blueThemePalettes.length];
  }

  @override
  void initState() {
    super.initState();
    final today = _weekdayName(DateTime.now().weekday);
    if (_days.contains(today)) {
      _selectedMobileDay = today;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String? _getCurrentPeriodKey() {
    final m = _now.hour * 60 + _now.minute;
    if (m >= 9 * 60 && m < 9 * 60 + 50) return 'P1';
    if (m >= 9 * 60 + 50 && m < 10 * 60 + 40) return 'P2';
    if (m >= 10 * 60 + 55 && m < 11 * 60 + 40) return 'P3';
    if (m >= 11 * 60 + 40 && m < 12 * 60 + 30) return 'P4';
    if (m >= 13 * 60 + 30 && m < 14 * 60 + 20) return 'P5';
    if (m >= 14 * 60 + 20 && m < 15 * 60 + 10) return 'P6';
    if (m >= 15 * 60 + 10 && m < 16 * 60) return 'P7';
    if (m >= 16 * 60 && m < 16 * 60 + 50) return 'P8';
    return null;
  }

  String _fmtClock(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _weekdayName(int w) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[w.clamp(0, 7)];
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

  // ── Timetable data lookup ──────────────────────────────────────────────────
  Map<String, dynamic>? _getCell(
    String day,
    String periodKey,
    String facultyId,
  ) {
    final dayData =
        repo.timetable
            .where(
              (t) =>
                  (t['day']?.toString().toLowerCase() ?? '') ==
                  day.toLowerCase(),
            )
            .firstOrNull ??
        <String, dynamic>{};
    if (dayData.isEmpty || dayData['schedule'] == null) return null;

    final schedule = (dayData['schedule'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final raw =
        schedule
            .where(
              (s) =>
                  (s['period']?.toString().toUpperCase() ?? '') ==
                  periodKey.toUpperCase(),
            )
            .firstOrNull ??
        <String, dynamic>{};
    if (raw.isEmpty) return null;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final subj = (raw['subject'] ?? '').toString().toLowerCase();
      final cls = (raw['classSec'] ?? '').toString().toLowerCase();
      final rm = (raw['room'] ?? '').toString().toLowerCase();
      if (!subj.contains(q) && !cls.contains(q) && !rm.contains(q)) return null;
    }

    // Enrich with canonical times
    final cell = Map<String, dynamic>.from(raw);
    final pt = _periodTimes[periodKey];
    if (pt != null) {
      cell['start'] ??= pt['start'];
      cell['end'] ??= pt['end'];
    }
    return cell;
  }

  // ── Refresh handler — fetches live from timetable.class_timetables ────────
  Future<void> _refreshTimetable() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
      final data = await TimetableService.fetchFromSupabase(
        facultyId: facultyId,
      );
      repo.timetable = data;
      repo.notify();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Timetable refreshed from database ✓'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to refresh timetable: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // ── Build with MediaQuery ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth < 650;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
        final facultyName = repo.profile['name'] ?? 'Dr. S. Malliga';

        bool hasTimetable =
            repo.timetable.isNotEmpty &&
            repo.timetable.any(
              (d) => (d['schedule'] as List? ?? []).isNotEmpty,
            );

        return Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerSection(facultyName, screenWidth),
                SizedBox(height: isMobile ? 14 : 20),
                _realtimePanel(facultyId, screenWidth),
                SizedBox(height: isMobile ? 14 : 20),
                _filtersAndSearchPanel(screenWidth),
                SizedBox(height: isMobile ? 14 : 20),
                if (!hasTimetable)
                  _emptyState()
                else if (isMobile && _isMobileCardsView)
                  _mobileDayCardsView(facultyId, screenWidth)
                else
                  _timetableGrid(facultyId, screenWidth),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header with action buttons & MediaQuery responsiveness ───────────────
  Widget _headerSection(String facultyName, double screenWidth) {
    final isMobile = screenWidth < 650;
    final isSmallMobile = screenWidth < 420;

    final actions = [
      _actionBtn(Icons.print_outlined, 'Print', _printTimetable),
      const SizedBox(width: 8),
      _actionBtn(Icons.table_view_outlined, 'Excel', _exportExcel),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: _isRefreshing ? null : _refreshTimetable,
        icon: _isRefreshing
            ? LoadingAnimationWidget.hexagonDots(color: Colors.white, size: 18)
            : const Icon(Icons.refresh, size: 16),
        label: Text(
          _isRefreshing ? '...' : 'Refresh',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Timetable',
                style: GoogleFonts.inter(
                  fontSize: isSmallMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              // Mobile View Mode Toggle
              InkWell(
                onTap: () =>
                    setState(() => _isMobileCardsView = !_isMobileCardsView),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isMobileCardsView
                            ? Icons.grid_on_rounded
                            : Icons.view_day_rounded,
                        size: 16,
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isMobileCardsView ? 'Grid View' : 'Cards View',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: actions),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Timetable',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: const Color(0xFF475569)),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF475569),
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getCourseType(Map<String, dynamic> cell) {
    final explicitType = (cell['type'] ?? '').toString().trim();
    if (explicitType.isNotEmpty && explicitType != 'Lecture') {
      return explicitType;
    }
    final subj = (cell['subject'] ?? '').toString().toLowerCase();
    final code = (cell['code'] ?? '').toString().toLowerCase();
    if (subj.contains('lab') ||
        subj.contains('practical') ||
        code.contains('lab')) {
      return 'Lab';
    }
    if (subj.contains('project') || subj.contains('seminar')) {
      return 'Practical';
    }
    if (subj.contains('elective')) {
      return 'Elective';
    }
    return 'Theory';
  }

  // ── Real-time status panel with MediaQuery responsiveness ─────────────────
  Widget _realtimePanel(String facultyId, double screenWidth) {
    final isMobile = screenWidth < 650;
    final isSmallMobile = screenWidth < 400;

    final periodKey = _getCurrentPeriodKey();
    final dayName = _weekdayName(_now.weekday);
    final activeCell = periodKey != null
        ? _getCell(dayName, periodKey, facultyId)
        : null;
    final pt = periodKey != null ? _periodTimes[periodKey] : null;

    String currentClassText = 'Free Period / No Active Class';
    if (activeCell != null) {
      final codeStr = (activeCell['code'] ?? '').toString();
      final codePart = codeStr.isNotEmpty ? ' ($codeStr)' : '';
      final roomStr = (activeCell['room'] ?? '').toString();
      final roomPart = roomStr.isNotEmpty ? ' | Room: $roomStr' : '';
      final typeStr = _getCourseType(activeCell);
      currentClassText =
          '${activeCell['subject']}$codePart — ${activeCell['classSec']} [$typeStr]$roomPart';
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Row 1: Live clock & date
          if (isSmallMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_filled,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmtClock(_now),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$dayName, ${_now.day} ${_monthName(_now.month)} ${_now.year}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_filled,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmtClock(_now),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$dayName, ${_now.day} ${_monthName(_now.month)} ${_now.year}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),

          // Highlighted Current Period Banner Card (Reduced Size & Compact Layout)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: periodKey != null
                    ? [const Color(0xFF1E4ED8), const Color(0xFF2563EB)]
                    : [const Color(0xFF334155), const Color(0xFF475569)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: periodKey != null
                      ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Compact Period Indicator Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CURRENT PERIOD',
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        periodKey ?? 'NO PERIOD',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (pt != null)
                        Text(
                          '${pt['start']} - ${pt['end']}',
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 14),
                // Class details inside current period
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NOW TEACHING',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentClassText,
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Panel with MediaQuery ──────────────────────────────────────────
  Widget _filtersAndSearchPanel(double screenWidth) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: screenWidth < 480
                    ? 'Search subject, room, class...'
                    : 'Search timetable by Subject, Room, or Class...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
              onPressed: () => setState(() => _searchQuery = ''),
            ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          Text(
            'No timetable assigned to this faculty.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isRefreshing ? null : _refreshTimetable,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(
              'Refresh from Database',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile Responsive Day-by-Day Cards View ──────────────────────────────
  Widget _mobileDayCardsView(String facultyId, double screenWidth) {
    final currentPeriodKey = _getCurrentPeriodKey();
    final todayName = _weekdayName(_now.weekday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day selector pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _days.map((day) {
              final isSelected = day == _selectedMobileDay;
              final isToday = day == todayName;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day.substring(0, 3).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ],
                  ),
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: isToday
                      ? const Color(0xFFEFF6FF)
                      : Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : (isToday
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  onSelected: (_) => setState(() => _selectedMobileDay = day),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // List of periods for selected mobile day
        ..._cols.map((col) {
          final periodKey = (col['key'] ?? '').toString();
          final cell = _getCell(_selectedMobileDay, periodKey, facultyId);
          final pt = _periodTimes[periodKey];
          final isCurrentActive =
              _selectedMobileDay == todayName && periodKey == currentPeriodKey;

          if (cell == null) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentActive
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentActive
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrentActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          col['label'],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrentActive
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                        ),
                        if (pt != null)
                          Text(
                            pt['start'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: isCurrentActive
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'FREE PERIOD',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final palette = _getSubjectColorPalette(cell['subject'] ?? '');

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showCellDetails(cell, _selectedMobileDay),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCurrentActive
                        ? const Color(0xFFDBEAFE)
                        : palette['bg'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentActive
                          ? const Color(0xFF2563EB)
                          : palette['border']!,
                      width: isCurrentActive ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time & Period Column
                      Container(
                        width: 72,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentActive
                              ? const Color(0xFF2563EB)
                              : palette['border']!.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              col['label'],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCurrentActive
                                    ? Colors.white
                                    : palette['title'],
                              ),
                            ),
                            if (pt != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${pt['start']}',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  color: isCurrentActive
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : palette['subtitle'],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${pt['end']}',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  color: isCurrentActive
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : palette['subtitle'],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Details Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    cell['subject'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: palette['title'],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: palette['border']!,
                                    ),
                                  ),
                                  child: Text(
                                    cell['type'] ?? 'Lecture',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: palette['room'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cell['classSec'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: palette['subtitle'],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.code_rounded,
                                  size: 12,
                                  color: palette['room'],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cell['code'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: palette['room'],
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: palette['room'],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  cell['room'] ?? 'N/A',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: palette['room'],
                                  ),
                                ),
                              ],
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
        }),
      ],
    );
  }

  // ── Main Timetable Grid (Engineering College Format) ─────────────────────
  Widget _timetableGrid(String facultyId, double screenWidth) {
    final currentPeriodKey = _getCurrentPeriodKey();
    final currentDay = _weekdayName(_now.weekday);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isMobile = availableWidth < 650;
        final dayWidth = isMobile ? 45.0 : 48.0;

        // Calculate column width to perfectly fit available screen width without horizontal scroll on desktop
        final calculatedColWidth =
            (availableWidth - dayWidth - 2) / _cols.length;
        final colWidth = isMobile
            ? math.max(115.0, calculatedColWidth)
            : math.max(92.0, calculatedColWidth);

        final Map<int, TableColumnWidth> colWidths = {
          0: FixedColumnWidth(dayWidth),
        };
        for (int i = 1; i <= _cols.length; i++) {
          colWidths[i] = FixedColumnWidth(colWidth);
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: isMobile,
            trackVisibility: isMobile,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: Table(
                columnWidths: colWidths,
                border: TableBorder.all(
                  color: const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
                children: [
                  // ── Header Row with current period highlight ────────────────
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFF0F172A)),
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Text(
                            'DAY',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      ..._cols.map((col) {
                        final pt = _periodTimes[col['key']];
                        final isCurrentCol = col['key'] == currentPeriodKey;
                        return TableCell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentCol
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF0F172A),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrentCol)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'NOW',
                                      style: GoogleFonts.inter(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                Text(
                                  col['label'],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: isCurrentCol ? 10 : 9,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentCol
                                        ? Colors.white
                                        : const Color(0xFF60A5FA),
                                  ),
                                ),
                                if (pt != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${pt['start']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 7.5,
                                      color: isCurrentCol
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Text(
                                    '${pt['end']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 7.5,
                                      color: isCurrentCol
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  // ── Day Rows ────────────────────────────────────────────────
                  ..._days.map((day) {
                    final isToday = day == currentDay;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isToday ? const Color(0xFFF0F9FF) : Colors.white,
                      ),
                      children: [
                        TableCell(
                          child: Container(
                            height: 70,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            color: isToday
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFF8FAFC),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  day.substring(0, 3).toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isToday
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                                if (isToday)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'Today',
                                      style: GoogleFonts.inter(
                                        fontSize: 7,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        ..._cols.map((col) {
                          final periodKey = (col['key'] ?? '').toString();
                          final cell = _getCell(day, periodKey, facultyId);
                          final isActive =
                              isToday && periodKey == currentPeriodKey;
                          return TableCell(
                            child: _buildCell(cell, isActive, day),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(Map<String, dynamic>? cell, bool isActive, String day) {
    if (cell == null) {
      return Container(
        height: 70,
        color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFFAFAFA),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'FREE PERIOD',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 2),
              Text(
                'Current Slot',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final palette = _getSubjectColorPalette(cell['subject'] ?? '');
    final courseType = _getCourseType(cell);

    return InkWell(
      onTap: () => _showCellDetails(cell, day),
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFDBEAFE) : palette['bg'],
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : palette['border']!,
            width: isActive ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Subject Title
            Text(
              cell['subject'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                color: palette['title'],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class & Section Name
                Text(
                  cell['classSec'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 9.0,
                    color: palette['subtitle'],
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 1),
                // Course Code + Course Type Badge
                Row(
                  children: [
                    Icon(Icons.code_rounded, size: 8.5, color: palette['room']),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        cell['code'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          color: palette['room'],
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: courseType == 'Lab'
                            ? const Color(0xFFFCE7F3)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: courseType == 'Lab'
                              ? const Color(0xFFF472B6)
                              : const Color(0xFF93C5FD),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        courseType.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 7.0,
                          fontWeight: FontWeight.w800,
                          color: courseType == 'Lab'
                              ? const Color(0xFFBE185D)
                              : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Cell Detail Dialog ────────────────────────────────────────────────────
  void _showCellDetails(Map<String, dynamic> cell, String day) {
    final facultyName = repo.profile['name'] ?? 'Dr. S. Malliga';
    final dept =
        repo.profile['department'] ?? 'Computer Science and Engineering';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cell['type'] == 'Lab'
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      cell['type'] == 'Lab'
                          ? Icons.science_outlined
                          : Icons.menu_book_outlined,
                      color: cell['type'] == 'Lab'
                          ? const Color(0xFF059669)
                          : const Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cell['subject'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${cell['code'] ?? ''} • $day • ${cell['period'] ?? ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),
              _detailRow(Icons.school_outlined, 'Department', dept),
              _detailRow(
                Icons.people_alt_outlined,
                'Class',
                cell['classSec'] ?? 'N/A',
              ),
              _detailRow(Icons.person_outline, 'Faculty', facultyName),
              _detailRow(
                Icons.access_time_outlined,
                'Time Slot',
                '${cell['start'] ?? ''} – ${cell['end'] ?? ''}',
              ),
              _detailRow(
                Icons.assignment_outlined,
                'Period',
                cell['period'] ?? 'N/A',
              ),
              _detailRow(
                Icons.category_outlined,
                'Type',
                cell['type'] ?? 'Lecture',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      repo.selectedMenuIndex = 5;
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Lesson Progress',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      repo.selectedMenuIndex = 3;
                    },
                    icon: const Icon(Icons.how_to_reg, size: 14),
                    label: Text(
                      'Take Attendance',
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Print Timetable (Adjusted for 1 Single Page A4 Landscape Fit) ─────────
  void _printTimetable() {
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    final facultyName = repo.profile['name'] ?? 'Dr. S. Malliga';
    final dept =
        repo.profile['department'] ?? 'Computer Science and Engineering';

    final htmlBuf = StringBuffer();
    htmlBuf.writeln('''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Faculty Timetable – $facultyName</title>
<style>
  @page {
    size: A4 landscape;
    margin: 6mm 10mm;
  }
  * { box-sizing: border-box; }
  html, body {
    margin: 0;
    padding: 0;
    font-family: 'Segoe UI', Arial, sans-serif;
    color: #0f172a;
    background: #ffffff;
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }
  body {
    padding: 10px 14px;
  }
  .header {
    text-align: center;
    margin-bottom: 10px;
    border-bottom: 2.5px solid #2563eb;
    padding-bottom: 6px;
  }
  .header h1 {
    margin: 0;
    font-size: 20px;
    font-weight: 800;
    color: #1e3a8a;
    letter-spacing: 0.5px;
  }
  .header h2 {
    margin: 2px 0 0;
    font-size: 13.5px;
    font-weight: 600;
    color: #475569;
  }
  .header h3 {
    margin: 2px 0 0;
    font-size: 12.5px;
    font-weight: 700;
    color: #2563eb;
  }
  .info-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: #f8fafc;
    border: 1px solid #cbd5e1;
    border-radius: 6px;
    padding: 6px 14px;
    margin-bottom: 10px;
    font-size: 11.5px;
  }
  .info-bar span {
    font-weight: 700;
    color: #0f172a;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    table-layout: fixed;
    font-size: 10px;
    page-break-inside: avoid !important;
    break-inside: avoid !important;
  }
  th {
    background: #0f172a;
    color: #ffffff;
    padding: 6px 3px;
    text-align: center;
    font-size: 10px;
    font-weight: 700;
    border: 1px solid #334155;
  }
  th small {
    display: block;
    font-weight: normal;
    font-size: 8.5px;
    color: #94a3b8;
    margin-top: 1px;
  }
  td {
    border: 1px solid #cbd5e1;
    padding: 4px 3px;
    vertical-align: middle;
    height: 52px;
    text-align: center;
    word-wrap: break-word;
  }
  td.day {
    background: #f1f5f9;
    font-weight: 800;
    color: #1e293b;
    font-size: 11px;
    width: 55px;
  }
  .subj {
    font-weight: 800;
    font-size: 10.5px;
    color: #0f172a;
    display: block;
    margin-bottom: 2px;
    line-height: 1.15;
  }
  .cls {
    font-weight: 700;
    font-size: 9.5px;
    color: #2563eb;
    display: block;
    margin-bottom: 1px;
  }
  .code {
    font-weight: 700;
    font-size: 9px;
    color: #1e3a8a;
  }
  .free {
    color: #cbd5e1;
    font-size: 12px;
  }
  @media print {
    body { padding: 0 !important; }
    .no-print { display: none !important; }
    @page { size: A4 landscape; margin: 6mm 8mm; }
  }
</style>
</head>
<body>
<div class="header">
  <h1>K.S.R. COLLEGE OF ENGINEERING</h1>
  <h2>Department of $dept</h2>
  <h3>Faculty Timetable Matrix</h3>
</div>
<div class="info-bar">
  <div>Faculty: <span>$facultyName</span> ($facultyId)</div>
  <div>Academic Year: <span>2025-26 (Even Semester)</span></div>
  <div>Generated: <span>${DateTime.now().toString().substring(0, 16)}</span></div>
</div>
<table>
<tr>
  <th style="width:55px">DAY</th>''');

    for (final col in _cols) {
      final pt = _periodTimes[col['key']];
      htmlBuf.writeln(
        '<th>${col['label']}'
        '<small>'
        '${pt?['start'] ?? ''} – ${pt?['end'] ?? ''}'
        '</small></th>',
      );
    }
    htmlBuf.writeln('</tr>');

    for (final day in _days) {
      htmlBuf.writeln('<tr>');
      htmlBuf.writeln(
        '<td class="day">${day.substring(0, 3).toUpperCase()}</td>',
      );
      for (final col in _cols) {
        final cell = _getCell(day, col['key']!, facultyId);
        if (cell != null) {
          htmlBuf.writeln(
            '<td>'
            '<span class="subj">${cell['subject']}</span>'
            '<span class="cls">${cell['classSec']}</span>'
            '<span class="code">${cell['code']}</span>'
            '</td>',
          );
        } else {
          htmlBuf.writeln('<td><span class="free">-</span></td>');
        }
      }
      htmlBuf.writeln('</tr>');
    }

    htmlBuf.writeln('''</table>
<script>window.onload=function(){setTimeout(function(){window.print();},300);}</script>
</body></html>''');

    // Trigger instant browser print dialog cleanly
    repo.triggerPrintHtmlDocument(htmlBuf.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Timetable opened for printing ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // ── Export Excel (Spacious Cell Formatting & Multi-line Cells) ─────────────
  void _exportExcel() {
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    final facultyName = repo.profile['name'] ?? 'Dr. S. Malliga';
    final dept =
        repo.profile['department'] ?? 'Computer Science and Engineering';

    final xml = StringBuffer();
    xml.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    xml.writeln('<?mso-application progid="Excel.Sheet"?>');
    xml.writeln(
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"',
    );
    xml.writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"');
    xml.writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"');
    xml.writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"');
    xml.writeln(' xmlns:html="http://www.w3.org/TR/REC-html40">');
    xml.writeln(
      ' <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">',
    );
    xml.writeln('  <Author>CAMS Engineering</Author>');
    xml.writeln('  <Title>Faculty Timetable Matrix</Title>');
    xml.writeln('  <Created>${DateTime.now().toIso8601String()}</Created>');
    xml.writeln(' </DocumentProperties>');
    xml.writeln(
      ' <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">',
    );
    xml.writeln('  <WindowHeight>12000</WindowHeight>');
    xml.writeln('  <WindowWidth>22000</WindowWidth>');
    xml.writeln('  <ProtectStructure>False</ProtectStructure>');
    xml.writeln('  <ProtectWindows>False</ProtectWindows>');
    xml.writeln(' </ExcelWorkbook>');
    xml.writeln(' <Styles>');
    xml.writeln('  <Style ss:ID="Default" ss:Name="Normal">');
    xml.writeln('   <Alignment ss:Vertical="Bottom"/>');
    xml.writeln('   <Borders/>');
    xml.writeln(
      '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>',
    );
    xml.writeln('   <Interior/>');
    xml.writeln('   <NumberFormat/>');
    xml.writeln('   <Protection/>');
    xml.writeln('  </Style>');
    xml.writeln('  <Style ss:ID="titleHeader">');
    xml.writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>');
    xml.writeln(
      '   <Font ss:FontName="Calibri" ss:Size="14" ss:Color="#FFFFFF" ss:Bold="1"/>',
    );
    xml.writeln('   <Interior ss:Color="#0F172A" ss:Pattern="Solid"/>');
    xml.writeln('  </Style>');
    xml.writeln('  <Style ss:ID="infoBar">');
    xml.writeln('   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>');
    xml.writeln(
      '   <Font ss:FontName="Calibri" ss:Size="10" ss:Color="#334155" ss:Bold="1"/>',
    );
    xml.writeln('   <Interior ss:Color="#F8FAFC" ss:Pattern="Solid"/>');
    xml.writeln('  </Style>');
    xml.writeln('  <Style ss:ID="colHeader">');
    xml.writeln(
      '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>',
    );
    xml.writeln(
      '   <Font ss:FontName="Calibri" ss:Size="10" ss:Color="#FFFFFF" ss:Bold="1"/>',
    );
    xml.writeln('   <Interior ss:Color="#1E293B" ss:Pattern="Solid"/>');
    xml.writeln('   <Borders>');
    xml.writeln(
      '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#475569"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#475569"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#475569"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#475569"/>',
    );
    xml.writeln('   </Borders>');
    xml.writeln('  </Style>');
    xml.writeln('  <Style ss:ID="dayCell">');
    xml.writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>');
    xml.writeln(
      '   <Font ss:FontName="Calibri" ss:Size="11" ss:Color="#0F172A" ss:Bold="1"/>',
    );
    xml.writeln('   <Interior ss:Color="#F1F5F9" ss:Pattern="Solid"/>');
    xml.writeln('   <Borders>');
    xml.writeln(
      '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#CBD5E1"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#CBD5E1"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#CBD5E1"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#CBD5E1"/>',
    );
    xml.writeln('   </Borders>');
    xml.writeln('  </Style>');
    xml.writeln('  <Style ss:ID="dataCell">');
    xml.writeln(
      '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>',
    );
    xml.writeln(
      '   <Font ss:FontName="Calibri" ss:Size="10" ss:Color="#0F172A"/>',
    );
    xml.writeln('   <Interior ss:Color="#EFF6FF" ss:Pattern="Solid"/>');
    xml.writeln('   <Borders>');
    xml.writeln(
      '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#93C5FD"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#93C5FD"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#93C5FD"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#93C5FD"/>',
    );
    xml.writeln('   </Borders>');
    xml.writeln('  </Style>');
    xml.writeln('  <Style ss:ID="freeCell">');
    xml.writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>');
    xml.writeln(
      '   <Font ss:FontName="Calibri" ss:Size="10" ss:Color="#94A3B8"/>',
    );
    xml.writeln('   <Interior ss:Color="#FAFAFA" ss:Pattern="Solid"/>');
    xml.writeln('   <Borders>');
    xml.writeln(
      '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>',
    );
    xml.writeln(
      '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>',
    );
    xml.writeln('   </Borders>');
    xml.writeln('  </Style>');
    xml.writeln(' </Styles>');
    xml.writeln(' <Worksheet ss:Name="Timetable">');
    xml.writeln('  <Table>');

    // Explicit generous column widths (giving ample space for each cell)
    xml.writeln('   <Column ss:Width="90"/>'); // DAY Column Width
    for (int i = 0; i < _cols.length; i++) {
      xml.writeln('   <Column ss:Width="160"/>'); // 160pt width per period cell
    }

    // Title Row
    xml.writeln('   <Row ss:Height="36">');
    xml.writeln(
      '    <Cell ss:MergeAcross="${_cols.length}" ss:StyleID="titleHeader">'
      '<Data ss:Type="String">FACULTY TIMETABLE MATRIX - $facultyName ($facultyId)</Data></Cell>',
    );
    xml.writeln('   </Row>');

    // Info Sub-Header
    xml.writeln('   <Row ss:Height="24">');
    xml.writeln(
      '    <Cell ss:MergeAcross="${_cols.length}" ss:StyleID="infoBar">'
      '<Data ss:Type="String"> Department: $dept   |   Academic Year: 2025-26 (Even Semester)   |   Generated: ${DateTime.now().toString().substring(0, 16)}</Data></Cell>',
    );
    xml.writeln('   </Row>');

    // Column Headers (Periods)
    xml.writeln('   <Row ss:Height="32">');
    xml.writeln(
      '    <Cell ss:StyleID="colHeader"><Data ss:Type="String">DAY</Data></Cell>',
    );
    for (final col in _cols) {
      final pt = _periodTimes[col['key']];
      final timeStr = pt != null ? '&#10;(${pt['start']} - ${pt['end']})' : '';
      xml.writeln(
        '    <Cell ss:StyleID="colHeader"><Data ss:Type="String">${_xmlEscape(col['label'] as String)}$timeStr</Data></Cell>',
      );
    }
    xml.writeln('   </Row>');

    // Day Rows with spacious cells (Row height 60pt)
    for (final day in _days) {
      xml.writeln('   <Row ss:Height="60">');
      xml.writeln(
        '    <Cell ss:StyleID="dayCell"><Data ss:Type="String">$day</Data></Cell>',
      );
      for (final col in _cols) {
        final cell = _getCell(day, col['key']!, facultyId);
        if (cell != null) {
          final subj = _xmlEscape((cell['subject'] ?? '').toString());
          final cls = _xmlEscape((cell['classSec'] ?? '').toString());
          final code = _xmlEscape((cell['code'] ?? '').toString());
          final val = '$subj&#10;$cls&#10;$code';
          xml.writeln(
            '    <Cell ss:StyleID="dataCell"><Data ss:Type="String">$val</Data></Cell>',
          );
        } else {
          xml.writeln(
            '    <Cell ss:StyleID="freeCell"><Data ss:Type="String">-</Data></Cell>',
          );
        }
      }
      xml.writeln('   </Row>');
    }

    xml.writeln('  </Table>');
    xml.writeln(' </Worksheet>');
    xml.writeln('</Workbook>');

    repo.triggerFileDownload(
      'timetable_${facultyName.replaceAll(' ', '_')}.xls',
      xml.toString(),
      'application/vnd.ms-excel',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Spacious Timetable Excel (.xls) downloaded ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
