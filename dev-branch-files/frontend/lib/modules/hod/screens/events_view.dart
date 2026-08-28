import 'package:flutter/material.dart';
import '../responsive.dart';
import '../hod_toast.dart';
import '../../faculty/services/postgres_client.dart';

class EventsModuleView extends StatefulWidget {
  const EventsModuleView({super.key});

  @override
  State<EventsModuleView> createState() => _EventsModuleViewState();
}

class _EventsModuleViewState extends State<EventsModuleView> {
  int _selectedTab = 0; // 0: Academic Calendar, 1: Department Events
  String _calendarViewMode = 'Month'; // Month, Week, Day, Agenda
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _eventsList.clear();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final rows = await SupabaseClientHelper.select('hod_events', schema: 'hod');
    if (!mounted) return;
    final firstEventDate = rows
        .map((row) => _parseDate(row['start_date']))
        .whereType<DateTime>()
        .firstOrNull;
    setState(() {
      if (firstEventDate != null) {
        _currentMonth = DateTime(firstEventDate.year, firstEventDate.month, 1);
      }
      _eventsList
        ..clear()
        ..addAll(
          rows.map(
            (row) => {
              'id': row['display_id'] ?? row['id'] ?? '',
              'name': row['event_name'] ?? '',
              'category': row['category'] ?? '',
              'inCharge': row['in_charge'] ?? '',
              'venue': row['venue'] ?? '',
              'dates': row['dates_description'] ?? '',
              'time': '',
              'day': _parseDate(row['start_date'])?.day ?? 0,
              'startDate': row['start_date'],
              'endDate': row['end_date'],
              'spanDays': _eventDays(row['start_date'], row['end_date']),
              'registered': row['registered_count'] ?? 0,
              'status': row['status'] ?? 'UPCOMING',
              'color': const Color(0xFF2563EB),
              'bgLight': const Color(0xFFEFF6FF),
            },
          ),
        );
    });
  }

  final List<Map<String, dynamic>> _eventsList = [];

  DateTime? _parseDate(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '');

  String _monthName(int month) => const [
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
  ][month - 1];

  List<int> _eventDays(dynamic startValue, dynamic endValue) {
    final start = _parseDate(startValue);
    final end = _parseDate(endValue) ?? start;
    if (start == null || end == null) return [];
    return [
      for (
        var day = start;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))
      )
        if (day.year == _currentMonth.year && day.month == _currentMonth.month)
          day.day,
    ];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = HodResponsive.pagePaddingInsets(context);

    return SingleChildScrollView(
      padding: padding.copyWith(top: 16, bottom: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. TOP HEADER CONTAINER WITH TABS & CREATE EVENT ──
          _buildTopHeaderCard(),
          const SizedBox(height: 16),

          // ── 2. 5 KPI CARDS ROW ──
          _buildKpiRow(),
          const SizedBox(height: 20),

          // ── 4. DYNAMIC TAB CONTENT (Academic Calendar vs Department Events) ──
          if (_selectedTab == 0) ...[
            _buildAcademicCalendarSection(),
          ] else ...[
            _buildDepartmentEventsSection(),
          ],
        ],
      ),
    );
  }

  // ── 1. TOP HEADER CONTAINER WITH SEGMENTED TABS & CREATE EVENT BUTTON ──
  Widget _buildTopHeaderCard() {
    final isMobile = HodResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderTitleGroup(),
                const SizedBox(height: 12),
                _buildSegmentedTabSelector(),
                if (_selectedTab == 1) ...[
                  const SizedBox(height: 12),
                  _buildCreateEventButton(isFullWidth: true),
                ],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildHeaderTitleGroup()),
                const SizedBox(width: 16),
                _buildSegmentedTabSelector(),
                if (_selectedTab == 1) ...[
                  const SizedBox(width: 16),
                  _buildCreateEventButton(isFullWidth: false),
                ],
              ],
            ),
    );
  }

  Widget _buildHeaderTitleGroup() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Center(
            child: Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic Calendar & Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'HOD Administrative Portal • Academics & Events Hub',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentedTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentedTabItem(
            index: 0,
            icon: Icons.calendar_today_rounded,
            label: 'Academic Calendar',
          ),
          _buildSegmentedTabItem(
            index: 1,
            icon: Icons.assignment_outlined,
            label: 'Department Events (${_eventsList.length})',
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateEventButton({required bool isFullWidth}) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 42,
      child: ElevatedButton.icon(
        onPressed: () => _openCreateEventModal(context),
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: const Text(
          'Create Event',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ── 3. 5 KPI CARDS ROW ──
  Widget _buildKpiRow() {
    final kpis = [
      {
        'title': 'Working Days',
        'subtitle': 'This semester',
        'value': '112',
        'icon': Icons.calendar_month_outlined,
        'borderColor': const Color(0xFF2563EB),
        'iconBg': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF2563EB),
      },
      {
        'title': 'Days Completed',
        'subtitle': 'This semester',
        'value': '78',
        'icon': Icons.check_circle_outline,
        'borderColor': const Color(0xFF10B981),
        'iconBg': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
      },
      {
        'title': 'Days Remaining',
        'subtitle': 'This semester',
        'value': '34',
        'icon': Icons.hourglass_empty_rounded,
        'borderColor': const Color(0xFFF97316),
        'iconBg': const Color(0xFFFFF7ED),
        'iconColor': const Color(0xFFF97316),
      },
      {
        'title': 'Institute Events',
        'subtitle': 'This Month',
        'value': '8',
        'icon': Icons.account_balance_outlined,
        'borderColor': const Color(0xFF9333EA),
        'iconBg': const Color(0xFFF3E8FF),
        'iconColor': const Color(0xFF9333EA),
      },
      {
        'title': 'Holidays',
        'subtitle': 'This Month',
        'value': '5',
        'icon': Icons.event_busy_outlined,
        'borderColor': const Color(0xFFEF4444),
        'iconBg': const Color(0xFFFEF2F2),
        'iconColor': const Color(0xFFEF4444),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cols = availableWidth >= 1100
            ? 5
            : (availableWidth >= 700 ? 3 : 2);

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kpis.map((kpi) {
            final cardWidth = (availableWidth - ((cols - 1) * 12)) / cols;

            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Colored Left Accent Border
                    Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kpi['borderColor'] as Color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Icon Circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: kpi['iconBg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        kpi['icon'] as IconData,
                        size: 18,
                        color: kpi['iconColor'] as Color,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Titles & Value
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            kpi['title'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            kpi['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            kpi['value'] as String,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kpi['borderColor'] as Color,
                            ),
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

  // ── 4A. ACADEMIC CALENDAR TAB CONTENT ──
  Widget _buildAcademicCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View Toggle Toolbar + Month Controls + Print/Sync Actions
        _buildCalendarToolbar(),
        const SizedBox(height: 14),

        // Legend Row
        _buildCalendarLegendRow(),
        const SizedBox(height: 14),

        // Month Grid View
        _buildMonthCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarToolbar() {
    final isMobile = HodResponsive.isMobile(context);

    final viewModes = ['Month', 'Week', 'Day', 'Agenda'];

    final viewModePills = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: viewModes.map((mode) {
          final isSelected = _calendarViewMode == mode;
          return InkWell(
            onTap: () {
              setState(() {
                _calendarViewMode = mode;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                mode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    final filterBtn = OutlinedButton.icon(
      onPressed: () {
        HodToast.show(context, message: 'Filter criteria applied.');
      },
      icon: const Icon(
        Icons.filter_list_rounded,
        size: 14,
        color: Color(0xFF64748B),
      ),
      label: const Text(
        'Filter',
        style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    final monthNavigator = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () async {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
            });
          },
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 20,
            color: Color(0xFF475569),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: 8),
        Text(
          '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
              );
            });
          },
          icon: const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Color(0xFF475569),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );

    final actionBtns = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            HodToast.show(context, message: 'Preparing calendar print view...');
          },
          icon: const Icon(
            Icons.print_outlined,
            size: 14,
            color: Color(0xFF2563EB),
          ),
          label: const Text(
            'Print',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            side: const BorderSide(color: Color(0xFFBFDBFE)),
            backgroundColor: const Color(0xFFEFF6FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {
            HodToast.show(
              context,
              message: 'Calendar synchronized successfully!',
              isSuccess: true,
            );
          },
          icon: const Icon(
            Icons.sync_rounded,
            size: 14,
            color: Color(0xFF2563EB),
          ),
          label: const Text(
            'Sync Calendar',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            side: const BorderSide(color: Color(0xFFBFDBFE)),
            backgroundColor: const Color(0xFFEFF6FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [viewModePills, const SizedBox(width: 8), filterBtn]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [monthNavigator, actionBtns],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [viewModePills, const SizedBox(width: 10), filterBtn]),
        monthNavigator,
        actionBtns,
      ],
    );
  }

  Widget _buildCalendarLegendRow() {
    final legends = [
      {'label': 'Examination', 'color': const Color(0xFF2563EB)},
      {'label': 'Test', 'color': const Color(0xFF10B981)},
      {'label': 'Event', 'color': const Color(0xFFF97316)},
      {'label': 'Holiday', 'color': const Color(0xFFEF4444)},
      {'label': 'Seminar', 'color': const Color(0xFF9333EA)},
      {'label': 'Meeting', 'color': const Color(0xFFEC4899)},
      {'label': 'Placement', 'color': const Color(0xFF0D9488)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: legends.map((leg) {
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: leg['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  leg['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── MONTH CALENDAR GRID (Sunday to Saturday) ──
  Widget _buildMonthCalendarGrid() {
    final daysOfWeek = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final previousMonthDays = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      0,
    ).day;
    final leadingDays = firstDay.weekday % 7;
    final gridCells = List.generate(42, (index) {
      final offset = index - leadingDays + 1;
      if (offset < 1) {
        return {'dayNum': previousMonthDays + offset, 'isCurrentMonth': false};
      }
      if (offset > daysInMonth) {
        return {'dayNum': offset - daysInMonth, 'isCurrentMonth': false};
      }
      return {'dayNum': offset, 'isCurrentMonth': true};
    });

    return Container(
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
        children: [
          // Header Row (SUN, MON, TUE, WED, THU, FRI, SAT)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: daysOfWeek.map((day) {
                final isSun = day == 'SUN';
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSun
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 5 Rows x 7 Cols Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cellHeight = 110.0;

              return Table(
                border: TableBorder.all(
                  color: const Color(0xFFF1F5F9),
                  width: 1,
                ),
                children: List.generate(6, (rowIndex) {
                  return TableRow(
                    children: List.generate(7, (colIndex) {
                      final cellIndex = (rowIndex * 7) + colIndex;
                      final cellData = gridCells[cellIndex];
                      final int dayNum = cellData['dayNum'] as int;
                      final bool isCurrent = cellData['isCurrentMonth'] as bool;

                      // Find events whose database date range contains this day.
                      final dayEvents = isCurrent
                          ? _eventsList.where((e) {
                              final start = _parseDate(e['startDate']);
                              final end = _parseDate(e['endDate']) ?? start;
                              final date = DateTime(
                                _currentMonth.year,
                                _currentMonth.month,
                                dayNum,
                              );
                              return start != null &&
                                  end != null &&
                                  !date.isBefore(
                                    DateTime(
                                      start.year,
                                      start.month,
                                      start.day,
                                    ),
                                  ) &&
                                  !date.isAfter(
                                    DateTime(end.year, end.month, end.day),
                                  );
                            }).toList()
                          : [];

                      return Container(
                        height: cellHeight,
                        padding: const EdgeInsets.all(6),
                        color: isCurrent
                            ? Colors.white
                            : const Color(0xFFFAFAFA),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day Number Header
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrent
                                    ? (colIndex == 0
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF475569))
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Events inside cell
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  children: dayEvents.map((evt) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: InkWell(
                                        onTap: () {
                                          HodToast.show(
                                            context,
                                            message:
                                                '${evt['name']} (${evt['time']} at ${evt['venue']})',
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: evt['bgLight'] as Color,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border(
                                              left: BorderSide(
                                                color: evt['color'] as Color,
                                                width: 3.5,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                evt['name'] as String,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: evt['color'] as Color,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 9,
                                                    color:
                                                        evt['color'] as Color,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Expanded(
                                                    child: Text(
                                                      evt['time'] as String,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color:
                                                            evt['color']
                                                                as Color,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on_outlined,
                                                    size: 9,
                                                    color:
                                                        evt['color'] as Color,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Expanded(
                                                    child: Text(
                                                      evt['venue'] as String,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color:
                                                            evt['color']
                                                                as Color,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
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
                    }),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 4B. DEPARTMENT EVENTS TAB CONTENT ──
  Widget _buildDepartmentEventsSection() {
    final filteredEvents = _eventsList.where((e) {
      final query = _searchCtrl.text.toLowerCase();
      final matchQuery =
          e['name'].toString().toLowerCase().contains(query) ||
          e['category'].toString().toLowerCase().contains(query) ||
          e['inCharge'].toString().toLowerCase().contains(query);

      if (_selectedCategoryFilter == 'All') return matchQuery;
      return matchQuery && e['category'] == _selectedCategoryFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Category Chips Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText:
                              'Search department events by name, faculty or category...',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                        'All',
                        'Examination',
                        'Test',
                        'Seminar',
                        'Meeting',
                        'Event',
                      ].map((cat) {
                        final isSelected = _selectedCategoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedCategoryFilter = cat;
                                });
                              }
                            },
                            selectedColor: const Color(0xFFEFF6FF),
                            backgroundColor: const Color(0xFFF8FAFC),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF64748B),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFBFDBFE)
                                  : const Color(0xFFE2E8F0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Events Register Table Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Department Events Register (${filteredEvents.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // DataTable View
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Event Code & Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Category',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Faculty In-Charge',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Venue',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Date & Time',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Registered',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                  rows: filteredEvents.map((e) {
                    final status = e['status'] as String;
                    final Color color = e['color'] as Color;

                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                e['id'] as String,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              Text(
                                e['name'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: e['bgLight'] as Color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              e['category'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            e['inCharge'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            e['venue'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                e['dates'] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                e['time'] as String,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${e['registered']} Pax',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: Color(0xFF2563EB),
                                ),
                                tooltip: 'Edit Event',
                                onPressed: () {
                                  HodToast.show(
                                    context,
                                    message: 'Editing ${e['name']}...',
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                                tooltip: 'Mark Completed',
                                onPressed: () {
                                  setState(() {
                                    e['status'] = 'COMPLETED';
                                  });
                                  HodToast.show(
                                    context,
                                    message:
                                        '${e['name']} marked as Completed!',
                                    isSuccess: true,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Color(0xFFEF4444),
                                ),
                                tooltip: 'Delete Event',
                                onPressed: () {
                                  setState(() {
                                    _eventsList.remove(e);
                                  });
                                  HodToast.show(
                                    context,
                                    message: 'Event deleted.',
                                    isError: true,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── CREATE EVENT MODAL DIALOG ──
  void _openCreateEventModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Seminar');
    final inChargeCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    final datesCtrl = TextEditingController(text: '15-Jul-2026');
    final timeCtrl = TextEditingController(text: '10:00 AM');
    final regCtrl = TextEditingController(text: '50');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(
              Icons.event_available_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Create Department Event',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Event Name *',
                    hintText: 'e.g. Workshop on IoT Protocols',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    hintText: 'Workshop / Seminar / Examination / Test / Event',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: inChargeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Faculty In-Charge *',
                    hintText: 'e.g. Dr. S. Karthi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: venueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Venue *',
                    hintText: 'e.g. Seminar Hall / Lab 201',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: datesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Event Date *',
                          hintText: '15-Jul-2026',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: timeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Event Time *',
                          hintText: '10:00 AM',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: regCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Expected Registrations',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty ||
                  inChargeCtrl.text.trim().isEmpty) {
                HodToast.show(
                  context,
                  message: 'Please enter Event Name and Faculty In-Charge!',
                  isError: true,
                );
                return;
              }

              final startDate = _parseDate(datesCtrl.text.trim());
              final inserted = await SupabaseClientHelper.insert('hod_events', {
                'event_name': nameCtrl.text.trim(),
                'category': categoryCtrl.text.trim(),
                'in_charge': inChargeCtrl.text.trim(),
                'venue': venueCtrl.text.trim().isEmpty
                    ? 'null'
                    : venueCtrl.text.trim(),
                'dates_description': datesCtrl.text.trim().isEmpty
                    ? 'null'
                    : datesCtrl.text.trim(),
                'start_date': startDate?.toIso8601String(),
                'registered_count': int.tryParse(regCtrl.text.trim()) ?? 0,
                'status': 'UPCOMING',
              }, schema: 'hod');
              if (inserted == null) {
                if (ctx.mounted) {
                  HodToast.show(
                    ctx,
                    message: 'Unable to publish event.',
                    isError: true,
                  );
                }
                return;
              }
              if (!ctx.mounted) return;
              await _loadEvents();

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              HodToast.show(
                ctx,
                message: '"${nameCtrl.text.trim()}" published successfully!',
                isSuccess: true,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Publish Event',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
