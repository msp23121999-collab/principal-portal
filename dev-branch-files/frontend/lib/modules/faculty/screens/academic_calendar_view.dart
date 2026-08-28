import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:intl/intl.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';
import '../services/academic_calendar_service.dart';

class AcademicCalendarView extends StatefulWidget {
  const AcademicCalendarView({super.key});

  @override
  State<AcademicCalendarView> createState() => _AcademicCalendarViewState();
}

class _AcademicCalendarViewState extends State<AcademicCalendarView> {
  final repo = ErpRepository();
  DateTime _focusedMonth = DateTime.now();
  String _filterCategory = 'All Categories';
  String _filterType = 'All';
  DateTime? _selectedDay;
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;

  List<CalEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    AcademicCalendarService.seedIfEmpty();
    final loaded = await AcademicCalendarService.fetchFromSupabase();
    if (mounted) {
      setState(() {
        _events = loaded;
        _isLoading = false;
      });
    }
  }

  bool _isDepartmentMatch(String eventDept, String facultyDept) {
    if (eventDept == 'All' || eventDept.isEmpty || eventDept == 'College')
      return true;
    final evD = eventDept.toLowerCase();
    final facD = facultyDept.toLowerCase();
    if (evD == facD) return true;
    if (facD.contains('computer') || facD.contains('cse')) {
      if (evD == 'cse' || evD.contains('computer')) return true;
    }
    if (facD.contains('information') || facD.contains('it')) {
      if (evD == 'it' || evD.contains('information')) return true;
    }
    return false;
  }

  List<CalEvent> get _filteredEvents {
    final facultyDept =
        (repo.profile['dept'] ?? repo.profile['department'] ?? 'CSE')
            .toString();
    final query = _searchCtrl.text.trim().toLowerCase();

    return _events.where((e) {
      final matchDept = _isDepartmentMatch(e.department, facultyDept);
      if (!matchDept) return false;

      final matchCat =
          _filterCategory == 'All Categories' || e.category == _filterCategory;
      final matchType =
          _filterType == 'All' ||
          _filterType == 'All Types' ||
          e.eventType == _filterType;
      final matchQuery =
          query.isEmpty ||
          e.title.toLowerCase().contains(query) ||
          e.place.toLowerCase().contains(query) ||
          e.category.toLowerCase().contains(query);

      return matchCat && matchType && matchQuery;
    }).toList();
  }

  List<CalEvent> get _currentMonthEvents {
    return _filteredEvents
        .where(
          (e) =>
              e.date.year == _focusedMonth.year &&
              e.date.month == _focusedMonth.month,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<CalEvent> _eventsForDay(DateTime d) => _filteredEvents
      .where(
        (e) =>
            e.date.year == d.year &&
            e.date.month == d.month &&
            e.date.day == d.day,
      )
      .toList();

  List<CalEvent> get _upcomingEvents {
    final now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final list = _filteredEvents.where((e) => !e.date.isBefore(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list.take(5).toList();
  }

  void _prevMonth() => setState(
    () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1),
  );
  void _nextMonth() => setState(
    () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1),
  );
  void _goToday() {
    setState(() {
      _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
      _selectedDay = DateTime.now();
    });
  }

  Future<void> _pickMonthYear() async {
    int tempYear = _focusedMonth.year;
    int tempMonth = _focusedMonth.month;

    final selected = await showDialog<DateTime>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          const monthsList = [
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
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            elevation: 8,
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title & Year Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Month & Year',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setDialogState(() => tempYear--),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '$tempYear',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setDialogState(() => tempYear++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),
                  // Month Grid 4x3
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, idx) {
                      final monthNum = idx + 1;
                      final isSelected = monthNum == tempMonth;
                      return InkWell(
                        onTap: () => setDialogState(() => tempMonth = monthNum),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            monthsList[idx],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, null),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(
                          dialogCtx,
                          DateTime(tempYear, tempMonth),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'APPLY',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (selected != null) {
      setState(() {
        _focusedMonth = DateTime(selected.year, selected.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isMobile = sw < 700;
    final isWide = sw > 1050;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) repo.setGlobalPrintContent(_buildCalendarHtml());
    });

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.0 : 20.0,
        vertical: 12.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(isMobile),
          const SizedBox(height: 12),
          _buildFilterRow(isMobile),
          const SizedBox(height: 12),
          if (_isLoading && _events.isEmpty)
            const FacultyLoadingWidget()
          else
            isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildCalendarCard(isMobile)),
                      const SizedBox(width: 16),
                      SizedBox(width: 320, child: _buildUpcomingEventsCard()),
                    ],
                  )
                : Column(
                    children: [
                      _buildCalendarCard(isMobile),
                      const SizedBox(height: 16),
                      _buildUpcomingEventsCard(),
                    ],
                  ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(bool isMobile) {
    final btns = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _outlineBtn(
          Icons.print_outlined,
          'Print Calendar',
          _printAcademicCalendar,
        ),
        _outlineBtn(
          Icons.table_chart_outlined,
          'Export (Excel)',
          _exportExcelCalendar,
        ),
      ],
    );

    final titleCol = Text(
      'Academic Calendar',
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleCol, const SizedBox(height: 8), btns],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [titleCol, btns],
    );
  }

  Widget _buildFilterRow(bool isMobile) {
    final categoryDropdown = _filterDropdown(
      _filterCategory,
      [
        'All Categories',
        'Academic',
        'Examination',
        'Meeting',
        'Holiday',
        'Workshop',
        'Seminar',
        'Cultural',
        'Sports',
      ],
      Icons.category_outlined,
      (v) => setState(() => _filterCategory = v!),
    );

    final typeDropdown = _filterDropdown(
      _filterType,
      [
        'All',
        'College Events',
        'Department Events',
        'Faculty Events',
        'Class Events',
      ],
      Icons.filter_alt_outlined,
      (v) => setState(() => _filterType = v!),
    );

    final searchBar = Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search calendar events by title, venue or category...',
          hintStyle: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_outlined,
            size: 16,
            color: Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          categoryDropdown,
          const SizedBox(height: 8),
          typeDropdown,
          const SizedBox(height: 8),
          searchBar,
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: 180, child: categoryDropdown),
        const SizedBox(width: 10),
        SizedBox(width: 170, child: typeDropdown),
        const SizedBox(width: 10),
        Expanded(child: searchBar),
      ],
    );
  }

  Widget _filterDropdown(
    String value,
    List<String> items,
    IconData icon,
    ValueChanged<String?> onChanged,
  ) {
    final uniqueItems = items.toSet().toList();
    final validVal = uniqueItems.contains(value)
        ? value
        : (uniqueItems.isNotEmpty ? uniqueItems.first : value);

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
      onSelected: onChanged,
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
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              validVal,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF0F172A),
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

  // ─── Calendar Card ────────────────────────────────────────────────────────
  Widget _buildCalendarCard(bool isMobile) {
    final monthStr = '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: month navigation & picker
          Row(
            children: [
              InkWell(
                onTap: _pickMonthYear,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthStr,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _goToday,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Today',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left, color: Color(0xFF64748B)),
                tooltip: 'Previous Month',
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                tooltip: 'Next Month',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Days of week header
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      child: Text(
                        day,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: day == 'Sun'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          // Days Grid
          _buildMonthGrid(isMobile),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(bool isMobile) {
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;

    final leadingSpaces = firstDayOfMonth.weekday - 1;
    final totalGridCells = ((leadingSpaces + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: isMobile ? 0.72 : 1.25,
        crossAxisSpacing: isMobile ? 3 : 6,
        mainAxisSpacing: isMobile ? 3 : 6,
      ),
      itemCount: totalGridCells,
      itemBuilder: (context, idx) {
        final dayNum = idx - leadingSpaces + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        final cellDate = DateTime(
          _focusedMonth.year,
          _focusedMonth.month,
          dayNum,
        );
        final dayEvents = _eventsForDay(cellDate);
        final isToday =
            DateTime.now().year == cellDate.year &&
            DateTime.now().month == cellDate.month &&
            DateTime.now().day == cellDate.day;
        final isSelected =
            _selectedDay != null &&
            _selectedDay!.year == cellDate.year &&
            _selectedDay!.month == cellDate.month &&
            _selectedDay!.day == cellDate.day;
        final isSunday = cellDate.weekday == DateTime.sunday;

        return InkWell(
          onTap: () => setState(() => _selectedDay = cellDate),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFEFF6FF)
                  : (isToday ? const Color(0xFFF0FDF4) : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : (isToday
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFE2E8F0)),
                width: isSelected || isToday ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$dayNum',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSunday
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    if (dayEvents.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${dayEvents.length}',
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                if (dayEvents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: dayEvents.take(isMobile ? 1 : 2).map<Widget>((
                        ev,
                      ) {
                        final catColor = _getCategoryColor(ev.category);
                        return Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            ev.title,
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Examination':
        return const Color(0xFF2563EB);
      case 'Holiday':
        return const Color(0xFFDC2626);
      case 'Workshop':
      case 'Seminar':
        return const Color(0xFF059669);
      case 'Meeting':
        return const Color(0xFFD97706);
      case 'Cultural':
      case 'Sports':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF2563EB);
    }
  }

  // ─── Right Panel: Selected Day Events & Upcoming ──────────────────────────
  Widget _buildUpcomingEventsCard() {
    final selDate = _selectedDay ?? DateTime.now();
    final dayEvents = _eventsForDay(selDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_note_outlined,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${selDate.day} ${_monthName(selDate.month)} ${selDate.year}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const FacultyLoadingWidget(),
            )
          else if (dayEvents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'No events scheduled for this day.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            )
          else
            Column(
              children: dayEvents.map<Widget>((ev) => _eventTile(ev)).toList(),
            ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.star_outline_rounded,
                color: Color(0xFFD97706),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Upcoming Milestones',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: _upcomingEvents
                .map<Widget>((ev) => _upcomingTile(ev))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(CalEvent ev) {
    final catColor = _getCategoryColor(ev.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: catColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ev.title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time_outlined, size: 11, color: catColor),
              const SizedBox(width: 4),
              Text(
                '${ev.startTime} - ${ev.endTime}',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.location_on_outlined, size: 11, color: catColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ev.place,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _upcomingTile(CalEvent ev) {
    final catColor = _getCategoryColor(ev.category);
    final dateStr =
        '${ev.date.day} ${_monthName(ev.date.month).substring(0, 3)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: catColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ev.title,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  ev.category,
                  style: GoogleFonts.inter(
                    fontSize: 10,
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

  // ─── Helpers ───────────────────────────────────────────────────────────────
  BoxDecoration _cardDecor() => BoxDecoration(
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
  );

  Widget _outlineBtn(IconData icon, String text, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF475569),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _solidBtn(IconData icon, String text, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  void _showAddMilestoneDialog() {
    final titleCtrl = TextEditingController();
    final placeCtrl = TextEditingController();
    String category = 'Academic';
    String eventType = 'Department Events';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Add Academic Milestone',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: placeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Venue / Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items:
                    [
                          'Academic',
                          'Examination',
                          'Meeting',
                          'Holiday',
                          'Workshop',
                          'Seminar',
                          'Cultural',
                          'Sports',
                        ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) => setDialogState(() => category = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isNotEmpty) {
                  final newEv = CalEvent(
                    title: titleCtrl.text.trim(),
                    date: selectedDate,
                    type: category,
                    category: category,
                    eventType: eventType,
                    department:
                        (repo.profile['dept'] ??
                                repo.profile['department'] ??
                                'CSE')
                            .toString(),
                    place: placeCtrl.text.trim(),
                    startTime: '09:00 AM',
                    endTime: '05:00 PM',
                  );
                  await AcademicCalendarService.save(newEv);
                  _loadEvents();
                  if (mounted) Navigator.pop(dialogCtx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              child: Text(
                'Save Event',
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

  void _exportPdfCalendar() {
    final htmlContent = _buildCalendarHtml();
    repo.triggerPrintHtmlDocument(htmlContent);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Academic Calendar opened for printing / PDF export ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _printAcademicCalendar() {
    final htmlContent = _buildCalendarHtml();
    repo.triggerPrintHtmlDocument(htmlContent);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Academic Calendar opened for printing ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportExcelCalendar() {
    final monthStr = '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}';
    final events = _currentMonthEvents;

    final rowsXml = events
        .map((e) {
          final dStr =
              '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}';
          final dayName = _weekdayName(e.date.weekday);
          return '''
      <Row>
        <Cell ss:StyleID="CellPadding"><Data ss:Type="String">${_xmlEscape(dStr)}</Data></Cell>
        <Cell ss:StyleID="CellPadding"><Data ss:Type="String">${_xmlEscape(dayName)}</Data></Cell>
        <Cell ss:StyleID="CellPaddingBold"><Data ss:Type="String">${_xmlEscape(e.title)}</Data></Cell>
        <Cell ss:StyleID="CellPadding"><Data ss:Type="String">${_xmlEscape(e.category)}</Data></Cell>
        <Cell ss:StyleID="CellPadding"><Data ss:Type="String">${_xmlEscape(e.eventType)}</Data></Cell>
        <Cell ss:StyleID="CellPadding"><Data ss:Type="String">${_xmlEscape(e.place.isEmpty ? 'Main Campus' : e.place)}</Data></Cell>
        <Cell ss:StyleID="CellPadding"><Data ss:Type="String">${_xmlEscape(e.startTime)} - ${_xmlEscape(e.endTime)}</Data></Cell>
      </Row>
      ''';
        })
        .join('\n');

    final xmlContent =
        '''<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
 <Styles>
  <Style ss:ID="TitleStyle">
   <Font ss:FontName="Segoe UI" ss:Size="16" ss:Bold="1" ss:Color="#0F172A"/>
   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>
  </Style>
  <Style ss:ID="HeaderStyle">
   <Font ss:FontName="Segoe UI" ss:Size="11" ss:Bold="1" ss:Color="#FFFFFF"/>
   <Interior ss:Color="#2563EB" ss:Pattern="Solid"/>
   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
   <Borders>
    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#1D4ED8"/>
    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#1D4ED8"/>
    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#1D4ED8"/>
    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#1D4ED8"/>
   </Borders>
  </Style>
  <Style ss:ID="CellPadding">
   <Font ss:FontName="Segoe UI" ss:Size="10" ss:Color="#334155"/>
   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
   <Borders>
    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>
    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>
    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>
    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>
   </Borders>
  </Style>
  <Style ss:ID="CellPaddingBold">
   <Font ss:FontName="Segoe UI" ss:Size="10" ss:Bold="1" ss:Color="#0F172A"/>
   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>
   <Borders>
    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>
    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>
    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>
    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>
   </Borders>
  </Style>
 </Styles>
 <Worksheet ss:Name="Academic Calendar">
  <Table>
   <Column ss:Width="110"/>
   <Column ss:Width="110"/>
   <Column ss:Width="250"/>
   <Column ss:Width="140"/>
   <Column ss:Width="160"/>
   <Column ss:Width="180"/>
   <Column ss:Width="160"/>
   <Row ss:Height="30">
    <Cell ss:StyleID="TitleStyle"><Data ss:Type="String">ACADEMIC CALENDAR - ${_xmlEscape(monthStr.toUpperCase())}</Data></Cell>
   </Row>
   <Row ss:Height="26">
    <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">Date</Data></Cell>
    <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">Day</Data></Cell>
    <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">Event Title</Data></Cell>
    <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">Category</Data></Cell>
    <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">Scope</Data></Cell>
    <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">Venue / Location</Data></Cell>
    <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">Time</Data></Cell>
   </Row>
   $rowsXml
  </Table>
 </Worksheet>
</Workbook>''';

    final fileName =
        'Academic_Calendar_${_monthName(_focusedMonth.month)}_${_focusedMonth.year}.xls';
    repo.triggerFileDownload(fileName, xmlContent, 'application/vnd.ms-excel');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Academic Calendar exported to Excel ($fileName) ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _xmlEscape(String str) {
    return str
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
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

  String _buildCalendarHtml() {
    final monthStr = '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}';
    final events = _currentMonthEvents;

    final rows = events
        .map(
          (e) =>
              '''
      <tr>
        <td style="text-align: center; font-weight: bold;">${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}</td>
        <td style="text-align: center;">${_weekdayName(e.date.weekday)}</td>
        <td><b>${e.title}</b></td>
        <td style="text-align: center;"><span class="badge">${e.category}</span></td>
        <td style="text-align: center;">${e.eventType}</td>
        <td>${e.place.isEmpty ? 'Main Campus' : e.place}</td>
        <td style="text-align: center;">${e.startTime} - ${e.endTime}</td>
      </tr>
    ''',
        )
        .join('\n');

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <title>Academic Calendar - $monthStr</title>
        <style>
          @page { size: A4 landscape; margin: 15mm; }
          body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; padding: 24px; color: #0F172A; background-color: #FFFFFF; }
          .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #2563EB; padding-bottom: 12px; margin-bottom: 20px; }
          .title { font-size: 24px; font-weight: bold; color: #1E3A8A; margin: 0; }
          .subtitle { font-size: 14px; color: #2563EB; font-weight: 600; margin-top: 4px; }
          table { width: 100%; border-collapse: collapse; margin-top: 10px; }
          th, td { border: 1px solid #CBD5E1; padding: 10px 12px; font-size: 12px; vertical-align: middle; }
          th { background-color: #2563EB; color: #FFFFFF; font-weight: 700; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
          tr:nth-child(even) { background-color: #F8FAFC; }
          .badge { background-color: #EFF6FF; color: #2563EB; border: 1px solid #BFDBFE; padding: 3px 8px; border-radius: 4px; font-weight: 600; font-size: 11px; display: inline-block; }
          .footer { margin-top: 30px; font-size: 11px; color: #64748B; text-align: center; border-top: 1px solid #E2E8F0; padding-top: 12px; }
        </style>
      </head>
      <body>
        <div class="header">
          <div>
            <h1 class="title">COLLEGE ACADEMIC MANAGEMENT SYSTEM</h1>
            <div class="subtitle">ACADEMIC CALENDAR SCHEDULE — $monthStr</div>
          </div>
        </div>
        <table>
          <thead>
            <tr>
              <th style="width: 90px;">Date</th>
              <th style="width: 100px;">Day</th>
              <th>Event Title</th>
              <th style="width: 120px;">Category</th>
              <th style="width: 140px;">Scope</th>
              <th style="width: 150px;">Venue</th>
              <th style="width: 140px;">Time</th>
            </tr>
          </thead>
          <tbody>
            ${rows.isNotEmpty ? rows : '<tr><td colspan="7" style="text-align:center; padding: 20px; color: #64748B;">No events scheduled for $monthStr.</td></tr>'}
          </tbody>
        </table>
        <div class="footer">
          Generated automatically by CAMS Academic ERP System • Total Events: ${events.length}
        </div>
        <script>window.onload=function(){setTimeout(function(){window.print();},300);}</script>
      </body>
      </html>
    ''';
  }

  String _monthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}
