import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../utils/file_downloader.dart';
import '../services/supabase_client_helper.dart';
import '../services/admin_supabase_service.dart';

class AcademicCalendarScreen extends ConsumerStatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  ConsumerState<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends ConsumerState<AcademicCalendarScreen>
    with TickerProviderStateMixin {

  // ── Toolbar filter state ──────────────────────────────────────────────────
  String _selectedYear   = '2026 – 2027';
  String _selectedSem    = 'All Semesters';
  String _selectedDept   = 'All Departments';
  String _selectedProg   = 'All Programmes';
  String _searchQuery    = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Calendar view ─────────────────────────────────────────────────────────
  _CalView _activeView = _CalView.monthly;
  DateTime _currentMonth = DateTime(2026, 8);

  // ── Semester Progress (Week 1–16) ─────────────────────────────────────────
  int get _currentWeek {
    final start = DateTime(2026, 8, 3);
    final now   = DateTime.now();
    if (now.isBefore(start)) return 0;
    final diff = now.difference(start).inDays;
    return (diff ~/ 7 + 1).clamp(0, 16);
  }

  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  // ── Supabase data ─────────────────────────────────────────────────────────
  List<_CalEvent> _events = [];
  bool _isLoading = true;

  // ── Hardcoded fallback ────────────────────────────────────────────────────
  static const List<_CalEvent> _fallbackEvents = [
    _CalEvent('Semester Commencement',     '2026-08-03', '2026-08-03', _EvType.semester,    'ALL',     'ALL',    'Full Day'),
    _CalEvent('Course Registration',       '2026-08-03', '2026-08-07', _EvType.academic,    'ALL',     'ALL',    'Full Day'),
    _CalEvent('Orientation Day',           '2026-08-04', '2026-08-04', _EvType.event,       'ALL',     'ALL',    '09:00–13:00'),
    _CalEvent('Independence Day',          '2026-08-15', '2026-08-15', _EvType.holiday,     'ALL',     'ALL',    'Full Day'),
    _CalEvent('CIA – 1 (All Departments)', '2026-08-24', '2026-08-29', _EvType.cia,         'ALL',     'ALL',    '09:30–12:00'),
    _CalEvent('HOD Sync Meeting',          '2026-09-01', '2026-09-01', _EvType.meeting,     'ALL',     'ALL',    '14:00–17:00'),
    _CalEvent('National Seminar – AI/ML',  '2026-09-12', '2026-09-13', _EvType.workshop,    'CSE',     'Sem 5',  'Full Day'),
    _CalEvent('CIA – 2 (All Departments)', '2026-09-21', '2026-09-26', _EvType.cia,         'ALL',     'ALL',    '09:30–12:00'),
    _CalEvent('Gandhi Jayanthi',           '2026-10-02', '2026-10-02', _EvType.holiday,     'ALL',     'ALL',    'Full Day'),
    _CalEvent('Sports Day',                '2026-10-05', '2026-10-06', _EvType.sports,      'ALL',     'ALL',    'Full Day'),
    _CalEvent('Alumni Meet 2026',          '2026-10-18', '2026-10-18', _EvType.event,       'ALL',     'ALL',    '09:00–18:00'),
    _CalEvent('CIA – 3 (Model Exam)',      '2026-10-26', '2026-11-01', _EvType.cia,         'ALL',     'ALL',    '09:30–12:00'),
    _CalEvent('Attendance Lock',           '2026-11-05', '2026-11-05', _EvType.admin,       'ALL',     'ALL',    'End of Day'),
    _CalEvent('Practical Examinations',    '2026-11-08', '2026-11-14', _EvType.practicalExam,'ALL',   'ALL',    'Full Day'),
    _CalEvent('Hall Ticket Release',       '2026-11-15', '2026-11-15', _EvType.admin,       'ALL',     'ALL',    'Full Day'),
    _CalEvent('University Theory Exams',   '2026-11-18', '2026-12-06', _EvType.universityExam,'ALL',  'ALL',    '10:00–13:00'),
    _CalEvent('Results Publication',       '2026-12-20', '2026-12-20', _EvType.admin,       'ALL',     'ALL',    'Full Day'),
    _CalEvent('Semester End',              '2026-12-20', '2026-12-20', _EvType.semester,    'ALL',     'ALL',    'Full Day'),
    _CalEvent('Christmas Holiday',         '2026-12-25', '2026-12-25', _EvType.holiday,     'ALL',     'ALL',    'Full Day'),
  ];

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final allEvents = <_CalEvent>[];

      // 1. Try public academic_calendar_events table
      final calData = await SupabaseClientHelper.select('academic_calendar_events', schema: 'public');
      if (calData.isNotEmpty) {
        allEvents.addAll(calData.map((row) => _CalEvent(
          row['title'] ?? '',
          row['event_date'] ?? '',
          row['event_date'] ?? '',
          _parseEvType(row['event_type']),
          row['scope'] ?? 'ALL',
          'ALL',
          'Full Day',
        )));
      }

      // 2. Fetch circulars from principal schema as calendar items
      final circulars = await AdminSupabaseService.fetchCirculars();
      for (final c in circulars) {
        final date = c['published_at']?.toString().substring(0, 10) ?? c['created_at']?.toString().substring(0, 10) ?? '';
        if (date.isNotEmpty) {
          allEvents.add(_CalEvent(c['title'] ?? 'Circular', date, date, _EvType.admin, 'ALL', 'ALL', 'Full Day'));
        }
      }

      // 3. Fetch meetings from principal schema
      final meetings = await AdminSupabaseService.fetchMeetings();
      for (final m in meetings) {
        final date = m['meeting_date']?.toString().substring(0, 10) ?? m['created_at']?.toString().substring(0, 10) ?? '';
        if (date.isNotEmpty) {
          allEvents.add(_CalEvent(m['title'] ?? m['agenda'] ?? 'Meeting', date, date, _EvType.meeting, 'ALL', 'ALL', 'Full Day'));
        }
      }

      if (allEvents.isEmpty) {
        _events = List.from(_fallbackEvents);
      } else {
        _events = allEvents;
      }
    } catch (_) {
      _events = List.from(_fallbackEvents);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  _EvType _parseEvType(String? category) {
    switch (category?.toString().toLowerCase().trim() ?? '') {
      case 'semester start':
      case 'semester end':
      case 'semester':
        return _EvType.semester;
      case 'mid exam':
      case 'cia':
      case 'cia assessment':
        return _EvType.cia;
      case 'university exam':
      case 'theory exam':
        return _EvType.universityExam;
      case 'practical exam':
        return _EvType.practicalExam;
      case 'holiday':
        return _EvType.holiday;
      case 'workshop':
      case 'seminar':
      case 'workshop/seminar':
        return _EvType.workshop;
      case 'event':
      case 'institutional event':
        return _EvType.event;
      case 'sports':
      case 'sports/nss/ncc':
        return _EvType.sports;
      case 'meeting':
        return _EvType.meeting;
      case 'admin':
      case 'deadline':
      case 'admin/deadline':
        return _EvType.admin;
      default:
        return _EvType.academic;
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadEvents();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Static filter lists ──────────────────────────────────────────────────
  static const _depts = ['All Departments', 'CSE', 'IT', 'ECE', 'AI&DS', 'MECH', 'CIVIL'];
  static const _progs = ['All Programmes', 'B.E. CSE', 'B.Tech IT', 'B.E. ECE', 'B.E. AI&DS'];
  static const _sems  = ['All Semesters', 'Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5', 'Sem 6', 'Sem 7', 'Sem 8'];

  List<_CalEvent> get _filteredEvents => _events.where((e) {
    final matchSearch = _searchQuery.isEmpty ||
        e.title.toLowerCase().contains(_searchQuery.toLowerCase());
    final matchDept = _selectedDept == 'All Departments' || e.dept == 'ALL' || e.dept == _selectedDept;
    final matchSem  = _selectedSem  == 'All Semesters'   || e.sem  == 'ALL' || e.sem  == _selectedSem;
    return matchSearch && matchDept && matchSem;
  }).toList();

  // ── Statistics derived from events ───────────────────────────────────────
  int get _totalEvents      => _filteredEvents.length;
  int get _holidayCount     => _filteredEvents.where((e) => e.type == _EvType.holiday).length;
  int get _examCount        => _filteredEvents.where((e) => e.type == _EvType.universityExam || e.type == _EvType.practicalExam).length;
  int get _ciaCount         => _filteredEvents.where((e) => e.type == _EvType.cia).length;
  int get _workshopCount    => _filteredEvents.where((e) => e.type == _EvType.workshop || e.type == _EvType.event).length;
  int get _upcomingCount    => _filteredEvents.where(_isUpcoming).length;
  int get _completedCount   => _filteredEvents.where(_isCompleted).length;
  static const int _workingDays = 185;

  bool _isUpcoming(  _CalEvent e) => DateTime.tryParse(e.startDate)?.isAfter(DateTime.now())  ?? false;
  bool _isCompleted( _CalEvent e) => DateTime.tryParse(e.endDate)?.isBefore(DateTime.now())   ?? false;
  String _evStatus(  _CalEvent e) {
    final s = DateTime.tryParse(e.startDate);
    final en = DateTime.tryParse(e.endDate);
    final now = DateTime.now();
    if (s == null || en == null) return 'Scheduled';
    if (en.isBefore(now)) return 'Completed';
    if (s.isAfter(now))   return 'Upcoming';
    return 'Running';
  }

  // ────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderBar(),
                      AppSpacing.gapMd,
                      _buildStatCards(),
                      AppSpacing.gapLg,
                      _buildSemesterProgressTracker(),
                      AppSpacing.gapLg,
                      _buildCIASchedulePanel(),
                      AppSpacing.gapLg,
                      _buildCalendarSection(),
                      AppSpacing.gapLg,
                      _buildUpcomingDeadlines(),
                      AppSpacing.gapLg,
                    ],
                  ),
                ),
              ),
      ),
    );

  // ═══════════════════════════════════════════════════════════════════════
  //  HEADER BAR
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHeaderBar() => AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title + Actions Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Academic Calendar', style: AppTypography.h2),
                            Text('KSR College of Engineering – Official Institutional Calendar',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionIconBtn(icon: Icons.refresh_rounded,        tooltip: 'Refresh',    onTap: _loadEvents),
                  _ActionIconBtn(icon: Icons.share_rounded,          tooltip: 'Share',      onTap: () => _showSnack('Sharing calendar link...')),
                  _ActionIconBtn(icon: Icons.print_rounded,          tooltip: 'Print',      onTap: () => _showSnack('Opening print dialog...')),
                  _ActionIconBtn(
                    icon: Icons.download_rounded,
                    tooltip: 'Export PDF',
                    onTap: () {
                      final todayStr = DateTime.now().toIso8601String().split('T')[0];
                      final buffer = StringBuffer();
                      buffer.writeln('KSRCE Institutional Academic Calendar Events');
                      buffer.writeln('Academic Year: $_selectedYear | Export Date: $todayStr');
                      buffer.writeln();
                      final activeEvents = _events.isEmpty ? _fallbackEvents : _events;
                      for (final e in activeEvents) {
                        buffer.writeln('- [${e.type.label}] ${e.title} (${e.startDate} to ${e.endDate}) [${e.dept}]');
                      }
                      FileDownloader.downloadPdf(
                        filename: 'academic_calendar_$todayStr.pdf',
                        title: 'KSRCE Academic Calendar $_selectedYear',
                        content: buffer.toString(),
                      );
                      _showSnack('Academic calendar PDF downloaded!');
                    },
                  ),
                  AppButton(label: 'Add Event', icon: Icons.add_rounded, onPressed: () => _showAddEventSheet(context)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Filter Row
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _FilterDropdown(label: 'Academic Year', value: _selectedYear,
                  items: ['2026 – 2027', '2025 – 2026', '2024 – 2025'],
                  onChanged: (v) => setState(() => _selectedYear = v!)),
              _FilterDropdown(label: 'Semester', value: _selectedSem,
                  items: _sems, onChanged: (v) => setState(() => _selectedSem = v!)),
              _FilterDropdown(label: 'Department', value: _selectedDept,
                  items: _depts, onChanged: (v) => setState(() => _selectedDept = v!)),
              _FilterDropdown(label: 'Programme', value: _selectedProg,
                  items: _progs, onChanged: (v) => setState(() => _selectedProg = v!)),
              // Search
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _searchCtrl,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search events…',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                                child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted))
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

  // ═══════════════════════════════════════════════════════════════════════
  //  STAT CARDS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStatCards() {
    final cards = [
      _StatDef('Total Events',     '$_totalEvents',    Icons.event_note_rounded,          AppColors.primary),
      const _StatDef('Working Days',     '$_workingDays',    Icons.work_outline_rounded,         AppColors.darkBlue),
      _StatDef('Holidays',         '$_holidayCount',   Icons.beach_access_rounded,         AppColors.error),
      _StatDef('Examinations',     '$_examCount',      Icons.assignment_outlined,          const Color(0xFF6A1B9A)),
      _StatDef('CIA Assessments',  '$_ciaCount',       Icons.quiz_outlined,               AppColors.warning),
      _StatDef('Workshops/Events', '$_workshopCount',  Icons.celebration_outlined,        const Color(0xFF00897B)),
      _StatDef('Upcoming',         '$_upcomingCount',  Icons.upcoming_rounded,            AppColors.info),
      _StatDef('Completed',        '$_completedCount', Icons.check_circle_outline_rounded, AppColors.success),
    ];

    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 1100 ? 4 : (c.maxWidth > 700 ? 3 : (c.maxWidth > 450 ? 2 : 1));
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 70,
        ),
        itemBuilder: (_, i) => _buildStatCard(cards[i]),
      );
    });
  }

  Widget _buildStatCard(_StatDef d) => AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: d.color.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(d.icon, color: d.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(d.value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: d.color)),
                Text(d.label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );

  // ═══════════════════════════════════════════════════════════════════════
  //  SEMESTER PROGRESS TRACKER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSemesterProgressTracker() {
    final week = _currentWeek.clamp(0, 16);
    final pct  = (week / 16 * 100).toStringAsFixed(0);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.timeline_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('Semester Progress Tracker — Odd Semester 2026–27', style: AppTypography.labelLarge),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Week $week of 16 • $pct% Complete',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Week number labels
          LayoutBuilder(builder: (_, c) {
            final cellW = c.maxWidth / 16;
            final showLabels = cellW > 24;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Milestone labels above bar (desktop only)
                if (showLabels)
                  SizedBox(
                    height: 20,
                    child: Row(
                      children: List.generate(16, (i) {
                        final labels = {3: 'CIA-1', 7: 'CIA-2', 11: 'CIA-3', 13: 'Prac', 15: 'Theory'};
                        return Expanded(
                          child: labels.containsKey(i)
                              ? Text(labels[i]!, textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold))
                              : const SizedBox(),
                        );
                      }),
                    ),
                  ),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 20,
                    child: Row(
                      children: List.generate(16, (i) {
                        final filled = i < week;
                        final isMilestone = [3, 7, 11, 13, 15].contains(i);
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: filled
                                  ? (isMilestone ? AppColors.gold : AppColors.primary)
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Week numbers
                if (showLabels)
                  Row(
                    children: List.generate(16, (i) => Expanded(
                      child: Text('W${i + 1}', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9,
                              color: i < week ? AppColors.primary : AppColors.textMuted)),
                    )),
                  ),
              ],
            );
          }),

          const SizedBox(height: 14),
          // Legend
          const Wrap(spacing: 16, runSpacing: 8, children: [
            _Legend(AppColors.primary, 'Completed Weeks'),
            _Legend(AppColors.gold,    'Milestone Weeks (CIA/Exam)'),
            _Legend(AppColors.border,  'Remaining'),
          ]),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CIA SCHEDULE PANEL
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCIASchedulePanel() {
    final cias = [
      _CIADef('CIA – 1', 'Week 4',  '24 Aug – 29 Aug 2026', 'Internal Assessment I',       AppColors.primary, Icons.looks_one_rounded,   _evStatus(_events.length > 4 ? _events[4] : const _CalEvent('','','',_EvType.academic,'','',''))),
      _CIADef('CIA – 2', 'Week 8',  '21 Sep – 26 Sep 2026', 'Internal Assessment II',      AppColors.info,    Icons.looks_two_rounded,   _evStatus(_events.length > 7 ? _events[7] : const _CalEvent('','','',_EvType.academic,'','',''))),
      _CIADef('CIA – 3', 'Week 12', '26 Oct – 1 Nov 2026',  'Model Exam / End Assessment', AppColors.warning, Icons.looks_3_rounded,    _evStatus(_events.length > 11 ? _events[11] : const _CalEvent('','','',_EvType.academic,'','',''))),
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.quiz_rounded, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text('CIA Assessment Schedule', style: AppTypography.labelLarge),
          ]),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (_, c) {
            final isWide = c.maxWidth > 600;
            if (isWide) {
              return Row(
                children: cias.map((d) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildCIACard(d),
                ))).toList(),
              );
            }
            return Column(children: cias.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCIACard(d),
            )).toList());
          }),
        ],
      ),
    );
  }

  Widget _buildCIACard(_CIADef d) {
    final isCompleted = d.status == 'Completed';
    final isRunning   = d.status == 'Running';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: d.color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: d.color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(d.icon, color: d.color, size: 28),
            _StatusBadge(d.status),
          ]),
          const SizedBox(height: 10),
          Text(d.name, style: AppTypography.labelLarge.copyWith(color: d.color, fontSize: 15)),
          Text(d.subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Flexible(child: Text(d.dates,
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(d.week, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          ]),
          if (isCompleted || isRunning) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: isCompleted ? 1.0 : 0.5,
              backgroundColor: d.color.withAlpha(38),
              color: d.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CALENDAR SECTION (View Toggle + Calendar Body)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCalendarSection() => AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // View Toggle
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_view_month_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('Calendar View', style: AppTypography.labelLarge),
              ]),
              _ViewToggleBar(current: _activeView, onChanged: (v) {
                _fadeCtrl.reverse().then((_) {
                  setState(() => _activeView = v);
                  _fadeCtrl.forward();
                });
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Color legend
          Wrap(spacing: 14, runSpacing: 6, children: _EvType.values.map((t) =>
            _Legend(t.color, t.label)).toList()),
          const Divider(height: 24),

          // Active view body
          FadeTransition(
            opacity: _fadeAnim,
            child: switch (_activeView) {
              _CalView.monthly  => _buildMonthlyView(),
              _CalView.agenda   => _buildAgendaView(),
              _CalView.timeline => _buildTimelineView(),
              _CalView.weekly   => _buildWeeklyView(),
              _CalView.semester => _buildSemesterTimeline(),
            },
          ),
        ],
      ),
    );

  // ── Monthly Calendar ───────────────────────────────────────────────────
  Widget _buildMonthlyView() {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month).weekday; // Mon=1

    return Column(
      children: [
        // Month nav
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                onPressed: () => setState(() => _currentMonth = DateTime(year, month - 1)),
              ),
              Text(_monthName(month), style: AppTypography.h3),
              Text('  $year', style: AppTypography.h3.copyWith(color: AppColors.textMuted)),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                onPressed: () => setState(() => _currentMonth = DateTime(year, month + 1)),
              ),
            ]),
            TextButton.icon(
              onPressed: () => setState(() => _currentMonth = DateTime.now()),
              icon: const Icon(Icons.today_rounded, size: 16),
              label: const Text('Today'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Day headers
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) =>
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: d == 'Sun' || d == 'Sat' ? AppColors.background : Colors.transparent,
              ),
              child: Text(d, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
            ))
          ).toList(),
        ),
        const Divider(height: 1),

        // Calendar grid
        LayoutBuilder(builder: (_, c) {
          final cellW = c.maxWidth / 7;
          final cellH = cellW < 55 ? 52.0 : (cellW < 90 ? 68.0 : 84.0);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: cellW / cellH,
            ),
            itemBuilder: (_, idx) {
              final day = idx - (firstWeekday - 2);
              if (day < 1 || day > daysInMonth) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withAlpha(128),
                    border: Border.all(color: AppColors.border.withAlpha(77)),
                  ),
                );
              }
              final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final dayEvents = _filteredEvents.where((e) => e.startDate == dateStr || e.endDate == dateStr).toList();
              final isToday = dateStr == _todayStr();
              final isWeekend = idx % 7 >= 5;

              return GestureDetector(
                onTap: dayEvents.isNotEmpty ? () => _showEventListDialog(context, dateStr, dayEvents) : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary.withAlpha(20)
                        : isWeekend
                            ? AppColors.background
                            : Colors.white,
                    border: Border.all(
                      color: isToday ? AppColors.primary : AppColors.border.withAlpha(77),
                      width: isToday ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: isToday
                            ? const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)
                            : null,
                        child: Text('$day',
                            style: TextStyle(
                              fontSize: cellW < 55 ? 10 : 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday
                                  ? Colors.white
                                  : isWeekend ? AppColors.error : AppColors.textPrimary,
                            )),
                      ),
                      if (dayEvents.isNotEmpty) ...[
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          height: 5,
                          decoration: BoxDecoration(
                            color: dayEvents.first.type.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        if (dayEvents.length > 1 && cellW > 60)
                          Text('+${dayEvents.length}',
                              style: TextStyle(fontSize: 8, color: dayEvents.first.type.color, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  // ── Weekly View ────────────────────────────────────────────────────────
  Widget _buildWeeklyView() {
    // Show current week (Mon–Sun)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: Column(
          children: [
            // Day headers
            Row(
              children: List.generate(7, (i) {
                final d = days[i];
                final isToday = _todayStr() == _dateStr(d);
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(dayNames[i],
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                color: isToday ? Colors.white : AppColors.textMuted)),
                        Text('${d.day}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                color: isToday ? Colors.white : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            // Events row
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(7, (i) {
                  final dateStr = _dateStr(days[i]);
                  final dayEvents = _filteredEvents.where((e) => e.startDate == dateStr || e.endDate == dateStr).toList();
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: dayEvents.isEmpty
                          ? const Center(child: Text('—', style: TextStyle(color: AppColors.textMuted)))
                          : SingleChildScrollView(
                              child: Column(
                                children: dayEvents.map((e) => GestureDetector(
                                  onTap: () => _showSingleEventDialog(context, e),
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: e.type.color.withAlpha(26),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: e.type.color.withAlpha(77)),
                                    ),
                                    child: Text(e.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 10, color: e.type.color, fontWeight: FontWeight.w600)),
                                  ),
                                )).toList(),
                              ),
                            ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timeline View ──────────────────────────────────────────────────────
  Widget _buildTimelineView() {
    final sorted = [..._filteredEvents]..sort((a, b) => a.startDate.compareTo(b.startDate));
    if (sorted.isEmpty) return _buildEmptyState('No events match current filters.');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(
        height: 0,
        child: Row(children: [SizedBox(width: 28), Expanded(child: Divider())]),
      ),
      itemBuilder: (_, i) {
        final e = sorted[i];
        return _buildTimelineRow(e, i == sorted.length - 1);
      },
    );
  }

  Widget _buildTimelineRow(_CalEvent e, bool isLast) {
    final status = _evStatus(e);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline connector
        SizedBox(
          width: 56,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: e.type.color.withAlpha(26),
                  shape: BoxShape.circle,
                  border: Border.all(color: e.type.color, width: 2),
                ),
                child: Icon(e.type.icon, color: e.type.color, size: 16),
              ),
              if (!isLast)
                Container(width: 2, height: 40, color: AppColors.border),
            ],
          ),
        ),

        // Event card
        Expanded(
          child: GestureDetector(
            onTap: () => _showSingleEventDialog(context, e),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title, style: AppTypography.labelLarge.copyWith(fontSize: 13)),
                        const SizedBox(height: 4),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          _InfoChip(Icons.calendar_today_outlined, '${e.startDate} → ${e.endDate}'),
                          if (e.dept != 'ALL') _InfoChip(Icons.school_outlined, e.dept),
                          if (e.time.isNotEmpty) _InfoChip(Icons.access_time_rounded, e.time),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Agenda View ────────────────────────────────────────────────────────
  Widget _buildAgendaView() {
    final grouped = <String, List<_CalEvent>>{};
    for (final e in _filteredEvents) {
      grouped.putIfAbsent(e.startDate.substring(0, 7), () => []).add(e);
    }
    final months = grouped.keys.toList()..sort();

    if (months.isEmpty) return _buildEmptyState('No events match current filters.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: months.map((m) {
        final evts = grouped[m]!;
        final parts = m.split('-');
        final label = '${_monthName(int.parse(parts[1]))} ${parts[0]}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(label, style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
            ...evts.map((e) => GestureDetector(
              onTap: () => _showSingleEventDialog(context, e),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: e.type.color.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 44,
                      decoration: BoxDecoration(color: e.type.color, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 12),
                    Icon(e.type.icon, color: e.type.color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title, style: AppTypography.labelLarge.copyWith(fontSize: 13)),
                          Text('${e.startDate}  •  ${e.time}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    _StatusBadge(_evStatus(e)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  // ── Semester Timeline ──────────────────────────────────────────────────
  Widget _buildSemesterTimeline() {
    final milestones = [
      const _Milestone('Semester Start',             '03 Aug 2026',  AppColors.primary, Icons.play_arrow_rounded,       true),
      const _Milestone('Course Registration',        '03–07 Aug 2026', AppColors.success, Icons.how_to_reg_rounded,    true),
      const _Milestone('CIA – 1',                    '24–29 Aug 2026', AppColors.warning, Icons.quiz_rounded,           false),
      const _Milestone('CIA – 2',                    '21–26 Sep 2026', AppColors.warning, Icons.quiz_rounded,           false),
      const _Milestone('Attendance Lock (IA marks)', '05 Nov 2026',  AppColors.error,   Icons.lock_clock_rounded,       false),
      const _Milestone('CIA – 3 (Model Exam)',        '26 Oct–1 Nov 2026', AppColors.warning, Icons.quiz_rounded,       false),
      const _Milestone('Practical Examinations',     '08–14 Nov 2026', Color(0xFF6A1B9A), Icons.science_rounded, false),
      const _Milestone('Hall Ticket Release',        '15 Nov 2026',  AppColors.info,    Icons.badge_rounded,            false),
      const _Milestone('University Theory Exams',    '18 Nov–06 Dec', AppColors.error,  Icons.assignment_rounded,       false),
      const _Milestone('Results Publication',        '20 Dec 2026',  AppColors.success, Icons.emoji_events_rounded,     false),
      const _Milestone('Semester End',               '20 Dec 2026',  AppColors.darkBlue,Icons.stop_rounded,             false),
    ];

    return Column(
      children: List.generate(milestones.length, (i) {
        final m = milestones[i];
        final isLast = i == milestones.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left connector
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: m.done ? m.color : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: m.color, width: 2),
                    ),
                    child: Icon(m.icon, color: m.done ? Colors.white : m.color, size: 18),
                  ),
                  if (!isLast)
                    Container(width: 2, height: 48, color: AppColors.border),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: m.done ? m.color.withAlpha(20) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: m.done ? m.color.withAlpha(77) : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.title, style: AppTypography.labelLarge.copyWith(fontSize: 13, color: m.done ? m.color : AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(m.date, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      if (m.done)
                        Icon(Icons.check_circle_rounded, color: m.color, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  UPCOMING DEADLINES PANEL
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildUpcomingDeadlines() {
    final upcoming = _filteredEvents.where(_isUpcoming).take(5).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.upcoming_rounded, color: AppColors.warning, size: 18),
                SizedBox(width: 8),
                Text('Upcoming Deadlines', style: AppTypography.labelLarge),
              ]),
              Text('Next ${upcoming.length} events', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const Divider(height: 20),
          if (upcoming.isEmpty) _buildEmptyState('No upcoming events.') else LayoutBuilder(builder: (_, c) {
                  final cols = c.maxWidth > 900 ? 2 : 1;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: upcoming.map((e) => SizedBox(
                      width: cols == 2 ? (c.maxWidth - 12) / 2 : c.maxWidth,
                      child: _buildDeadlineRow(e),
                    )).toList(),
                  );
                }),
        ],
      ),
    );
  }

  Widget _buildDeadlineRow(_CalEvent e) {
    final daysLeft = DateTime.tryParse(e.startDate)?.difference(DateTime.now()).inDays ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: e.type.color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: e.type.color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
            child: Icon(e.type.icon, color: e.type.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: AppTypography.labelLarge.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(e.startDate, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: daysLeft < 7 ? AppColors.error.withAlpha(26) : AppColors.success.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              daysLeft == 0 ? 'Today' : 'In $daysLeft d',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold,
                color: daysLeft < 7 ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  DIALOGS
  // ═══════════════════════════════════════════════════════════════════════
  void _showEventListDialog(BuildContext ctx, String date, List<_CalEvent> events) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Events on $date', style: AppTypography.h3.copyWith(fontSize: 16)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: events.map((e) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: e.type.color.withAlpha(26), shape: BoxShape.circle),
                child: Icon(e.type.icon, color: e.type.color, size: 16),
              ),
              title: Text(e.title, style: AppTypography.labelLarge.copyWith(fontSize: 13)),
              subtitle: Text(e.type.label, style: AppTypography.bodySmall),
              trailing: _StatusBadge(_evStatus(e)),
              onTap: () { Navigator.pop(ctx); _showSingleEventDialog(ctx, e); },
            )).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showSingleEventDialog(BuildContext ctx, _CalEvent e) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: e.type.color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
              child: Icon(e.type.icon, color: e.type.color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(e.title, style: AppTypography.h3.copyWith(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(Icons.label_rounded,          'Type',       e.type.label),
            _DetailRow(Icons.calendar_today_rounded, 'Start',      e.startDate),
            _DetailRow(Icons.calendar_today_outlined, 'End',       e.endDate),
            _DetailRow(Icons.access_time_rounded,    'Time',       e.time),
            _DetailRow(Icons.school_outlined,        'Department', e.dept),
            _DetailRow(Icons.layers_outlined,        'Semester',   e.sem),
            const SizedBox(height: 10),
            _StatusBadge(_evStatus(e)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showAddEventSheet(BuildContext ctx) {
    _showSnack('Use the Academic Schedule module to manage events.');
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════
  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  static String _monthName(int m) {
    const n = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return n[m - 1];
  }

  Widget _buildEmptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(child: Column(children: [
      const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.border),
      const SizedBox(height: 12),
      Text(msg, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
    ])),
  );

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUPPORTING ENUMS & DATA CLASSES
// ─────────────────────────────────────────────────────────────────────────────

enum _CalView { monthly, weekly, timeline, agenda, semester }

enum _EvType {
  academic(      'Academic Classes',   Color(0xFF0056A6), Icons.menu_book_rounded),
  cia(           'CIA Assessment',     Color(0xFFF57C00), Icons.quiz_rounded),
  universityExam('University Exam',    Color(0xFF6A1B9A), Icons.assignment_rounded),
  practicalExam( 'Practical Exam',     Color(0xFF00897B), Icons.science_rounded),
  semester(      'Semester Event',     Color(0xFF1565C0), Icons.calendar_month_rounded),
  holiday(       'Holiday',            Color(0xFFD32F2F), Icons.beach_access_rounded),
  workshop(      'Workshop/Seminar',   Color(0xFF8E24AA), Icons.workspace_premium_rounded),
  event(         'Institutional Event',Color(0xFF00695C), Icons.celebration_rounded),
  sports(        'Sports/NSS/NCC',     Color(0xFF2E7D32), Icons.sports_soccer_rounded),
  meeting(       'Meeting',            Color(0xFF546E7A), Icons.groups_rounded),
  admin(         'Admin/Deadline',     Color(0xFF795548), Icons.lock_clock_rounded);

  const _EvType(this.label, this.color, this.icon);
  final String label;
  final Color  color;
  final IconData icon;
}

class _CalEvent {
  const _CalEvent(this.title, this.startDate, this.endDate, this.type, this.dept, this.sem, this.time);
  final String  title, startDate, endDate, dept, sem, time;
  final _EvType type;
}

class _StatDef {
  const _StatDef(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
}

class _CIADef {
  const _CIADef(this.name, this.week, this.dates, this.subtitle, this.color, this.icon, this.status);
  final String name, week, dates, subtitle, status;
  final Color color;
  final IconData icon;
}

class _Milestone {
  const _Milestone(this.title, this.date, this.color, this.icon, this.done);
  final String title, date;
  final Color color;
  final IconData icon;
  final bool done;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.label, required this.value, required this.items, required this.onChanged});
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
}

class _ViewToggleBar extends StatelessWidget {
  const _ViewToggleBar({required this.current, required this.onChanged});
  final _CalView current;
  final ValueChanged<_CalView> onChanged;

  static const _tabs = [
    (_CalView.monthly,  Icons.calendar_view_month_rounded, 'Monthly'),
    (_CalView.weekly,   Icons.calendar_view_week_rounded,  'Weekly'),
    (_CalView.timeline, Icons.view_timeline_rounded,       'Timeline'),
    (_CalView.agenda,   Icons.list_alt_rounded,            'Agenda'),
    (_CalView.semester, Icons.linear_scale_rounded,        'Semester'),
  ];

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _tabs.map((t) {
          final active = current == t.$1;
          return GestureDetector(
            onTap: () => onChanged(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(t.$2, size: 14, color: active ? Colors.white : AppColors.textMuted),
                const SizedBox(width: 4),
                Text(t.$3, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textMuted,
                )),
              ]),
            ),
          );
        }).toList(),
      ),
    );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  static Color _color(String s) => switch (s) {
    'Completed' => AppColors.success,
    'Running'   => AppColors.primary,
    'Upcoming'  => AppColors.warning,
    'Cancelled' => AppColors.error,
    _           => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final c = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withAlpha(26), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: AppTypography.bodySmall),
  ]);
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11, color: AppColors.textMuted),
    const SizedBox(width: 3),
    Text(label, style: AppTypography.bodySmall),
  ]);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        Expanded(child: Text(value, style: AppTypography.bodySmall)),
      ],
    ),
  );
}

class _ActionIconBtn extends StatefulWidget {
  const _ActionIconBtn({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_ActionIconBtn> createState() => _ActionIconBtnState();
}

class _ActionIconBtnState extends State<_ActionIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primary.withAlpha(26) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(widget.icon,
              size: 18,
              color: _hovered ? AppColors.primary : AppColors.textSecondary),
        ),
      ),
    ),
  );
}
