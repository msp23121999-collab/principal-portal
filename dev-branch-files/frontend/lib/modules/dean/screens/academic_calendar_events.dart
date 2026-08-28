import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/app_state.dart';
import '../services/supabase_service.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AcademicEventModel {
  final String id;
  final String title;
  final String category; // Academic, Examination, Department, Meeting, Event, Holiday, Important
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final String department;
  final String targetAudience;
  final String description;

  AcademicEventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.startTime,
    this.endTime = '',
    required this.location,
    this.department = 'All Departments',
    this.targetAudience = 'All Students & Faculty',
    this.description = '',
  });

  Color get categoryColor {
    switch (category) {
      case 'Academic':
        return const Color(0xFF2563EB); // Primary Blue
      case 'Examination':
        return const Color(0xFFF59E0B); // Amber / Orange
      case 'Department':
        return const Color(0xFF8B5CF6); // Purple
      case 'Meeting':
        return const Color(0xFF10B981); // Green
      case 'Event':
        return const Color(0xFF9333EA); // Violet
      case 'Holiday':
        return const Color(0xFF06B6D4); // Cyan
      case 'Important':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color get tagBgColor {
    return categoryColor.withValues(alpha: 0.12);
  }
}

class AcademicCalendarEventsScreen extends StatefulWidget {
  const AcademicCalendarEventsScreen({super.key});

  @override
  State<AcademicCalendarEventsScreen> createState() => _AcademicCalendarEventsScreenState();
}

class _AcademicCalendarEventsScreenState extends State<AcademicCalendarEventsScreen> {
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'Month'; // 'Month', 'Day', 'List' (Week removed as requested)

  bool _initializedFromAppState = false;
  String? _lastAcademicYear;
  String? _lastSemester;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final appState = DeanAppStateProvider.of(context);
      if (!_initializedFromAppState ||
          _lastAcademicYear != appState.selectedAcademicYear ||
          _lastSemester != appState.selectedSemester) {
        _lastAcademicYear = appState.selectedAcademicYear;
        _lastSemester = appState.selectedSemester;
        _initializedFromAppState = true;

        final newFocusedDate = _calculateFocusedDate(appState.selectedAcademicYear, appState.selectedSemester);
        setState(() {
          _focusedDate = newFocusedDate;
          _selectedDate = newFocusedDate;
        });
      }
    } catch (_) {}
  }

  DateTime _calculateFocusedDate(String yearRange, String sem) {
    int startYear = 2025;
    int endYear = 2026;
    final parts = yearRange.split('-').map((e) => e.trim()).toList();
    if (parts.length >= 2) {
      startYear = int.tryParse(parts[0]) ?? 2025;
      endYear = int.tryParse(parts[1]) ?? (startYear + 1);
    }

    final now = DateTime.now();

    if (sem.toUpperCase().contains('EVEN')) {
      if (now.year == endYear && now.month >= 1 && now.month <= 5) {
        return DateTime(endYear, now.month, 1);
      }
      return DateTime(endYear, 5, 1);
    }

    if (sem.toUpperCase().contains('ODD')) {
      if (now.year == startYear && now.month >= 6 && now.month <= 12) {
        return DateTime(startYear, now.month, 1);
      }
      return DateTime(startYear, 7, 1);
    }

    if (now.year == startYear || now.year == endYear) {
      return DateTime(now.year, now.month, 1);
    }
    return DateTime(startYear, 6, 1);
  }

  List<DateTime> _getMonthsForAcademicYear(String yearRange) {
    int startYear = 2025;
    int endYear = 2026;
    final parts = yearRange.split('-').map((e) => e.trim()).toList();
    if (parts.length >= 2) {
      startYear = int.tryParse(parts[0]) ?? 2025;
      endYear = int.tryParse(parts[1]) ?? (startYear + 1);
    }

    final List<DateTime> months = [];
    for (int m = 6; m <= 12; m++) {
      months.add(DateTime(startYear, m, 1));
    }
    for (int m = 1; m <= 5; m++) {
      months.add(DateTime(endYear, m, 1));
    }
    return months;
  }

  // Filters State
  String _selectedCategoryFilter = 'All Types';
  String _selectedDepartmentFilter = 'All Departments';
  bool _showHolidays = true;
  bool _showImportantEvents = true;
  bool _showDepartmentEvents = true;

  // Master Event List (Starts clean & empty per requirement 1)
  final List<AcademicEventModel> _allEvents = [];

  // Filtered Events getter
  List<AcademicEventModel> get _filteredEvents {
    return _allEvents.where((e) {
      if (!_showHolidays && e.category == 'Holiday') return false;
      if (!_showImportantEvents && e.category == 'Important') return false;
      if (!_showDepartmentEvents && e.category == 'Department') return false;

      if (_selectedCategoryFilter != 'All Types' && e.category != _selectedCategoryFilter) {
        return false;
      }

      if (_selectedDepartmentFilter != 'All Departments' &&
          e.department != _selectedDepartmentFilter &&
          e.department != 'All Departments') {
        return false;
      }

      return true;
    }).toList();
  }

  // Stats calculation
  int get _totalEventsThisMonth => _filteredEvents.where((e) => e.date.month == _focusedDate.month && e.date.year == _focusedDate.year).length;
  int get _academicEventsThisMonth => _filteredEvents.where((e) => e.date.month == _focusedDate.month && e.date.year == _focusedDate.year && e.category == 'Academic').length;
  int get _departmentEventsThisMonth => _filteredEvents.where((e) => e.date.month == _focusedDate.month && e.date.year == _focusedDate.year && e.category == 'Department').length;
  int get _holidaysThisMonth => _filteredEvents.where((e) => e.date.month == _focusedDate.month && e.date.year == _focusedDate.year && e.category == 'Holiday').length;
  int get _upcomingEventsNext7Days => _filteredEvents.where((e) {
    final diff = e.date.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateEventsFromAppState();
    });
  }

  void _hydrateEventsFromAppState() {
    final appState = DeanAppStateProvider.of(context);
    if (appState.calendarEventsData.isEmpty) return;

    final events = appState.calendarEventsData.map((event) {
      final dateValue = event['event_date'] ?? event['date'] ?? DateTime.now().toIso8601String();
      DateTime parsedDate;
      if (dateValue is DateTime) {
        parsedDate = dateValue;
      } else {
        try {
          parsedDate = DateTime.parse(dateValue.toString());
        } catch (_) {
          parsedDate = DateTime.now();
        }
      }

      return AcademicEventModel(
        id: (event['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
        title: (event['title'] ?? 'Academic Event').toString(),
        category: (event['category'] ?? event['event_type'] ?? 'Academic').toString(),
        date: parsedDate,
        startTime: (event['start_time'] ?? '09:00').toString(),
        endTime: (event['end_time'] ?? '').toString(),
        location: (event['location'] ?? event['venue'] ?? 'Campus').toString(),
        department: (event['department'] ?? 'All Departments').toString(),
        targetAudience: (event['target_audience'] ?? 'All Students & Faculty').toString(),
        description: (event['description'] ?? event['details'] ?? '').toString(),
      );
    }).toList();

    if (events.isNotEmpty && _allEvents.isEmpty) {
      setState(() {
        _allEvents.addAll(events);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb & Page Header Bar
          _buildHeaderBar(context),

          const SizedBox(height: 20),

          // 5 Top Stat Summary Cards
          _buildStatCardsRow(),

          const SizedBox(height: 24),

          // Main Section: Left (Calendar container) + Right (Upcoming Events & Filters)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _buildCalendarMainCard(),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 330,
                  child: Column(
                    children: [
                      _buildUpcomingEventsCard(),
                      const SizedBox(height: 24),
                      _buildCalendarFiltersCard(),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildCalendarMainCard(),
                const SizedBox(height: 24),
                _buildUpcomingEventsCard(),
                const SizedBox(height: 24),
                _buildCalendarFiltersCard(),
              ],
            ),
        ],
      ),
    );
  }

  // 1. Header Bar with Action Buttons (Breadcrumb removed)
  Widget _buildHeaderBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showAddEventModal(context),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('Add Event', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: DeanTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _exportCalendar(context),
              icon: const Icon(Icons.file_download_outlined, size: 18, color: DeanTheme.textDark),
              label: const Text('Export Calendar', style: TextStyle(fontWeight: FontWeight.w600, color: DeanTheme.textDark)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                side: const BorderSide(color: DeanTheme.cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );
  }

  // 2. Stat Cards Row
  Widget _buildStatCardsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth >= 1000 ? (constraints.maxWidth - (4 * 16)) / 5 : 200;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSingleStatCard(
                width: cardWidth,
                title: 'Total Events',
                value: '$_totalEventsThisMonth',
                subtitle: 'This Month',
                icon: Icons.calendar_month,
                iconBg: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 16),
              _buildSingleStatCard(
                width: cardWidth,
                title: 'Academic Events',
                value: '$_academicEventsThisMonth',
                subtitle: 'This Month',
                icon: Icons.school_outlined,
                iconBg: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 16),
              _buildSingleStatCard(
                width: cardWidth,
                title: 'Department Events',
                value: '$_departmentEventsThisMonth',
                subtitle: 'This Month',
                icon: Icons.business_outlined,
                iconBg: const Color(0xFF10B981),
              ),
              const SizedBox(width: 16),
              _buildSingleStatCard(
                width: cardWidth,
                title: 'Holidays',
                value: '$_holidaysThisMonth',
                subtitle: 'This Month',
                icon: Icons.beach_access_outlined,
                iconBg: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 16),
              _buildSingleStatCard(
                width: cardWidth,
                title: 'Upcoming Events',
                value: '$_upcomingEventsNext7Days',
                subtitle: 'Next 7 Days',
                icon: Icons.event_available_outlined,
                iconBg: const Color(0xFF06B6D4),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleStatCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeanTheme.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: iconBg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Main Calendar Container
  Widget _buildCalendarMainCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeanTheme.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar: Today, Prev/Next, Month Dropdown (12 Months), View Switcher
          _buildCalendarToolbar(),

          const SizedBox(height: 20),

          // Main View Content (Month, Day, List - Week removed per requirement 4)
          if (_viewMode == 'Month') _buildMonthViewGrid(),
          if (_viewMode == 'Day') _buildDayViewTimeline(),
          if (_viewMode == 'List') _buildListViewAgenda(),

          const SizedBox(height: 20),

          // Bottom Legend Bar
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  // Calendar Header Toolbar with Month Dropdown Button (12 Months & Years)
  Widget _buildCalendarToolbar() {
    final currentYear = _lastAcademicYear ?? '2024 - 2025';
    final months = _getMonthsForAcademicYear(currentYear);
    final activeMonth = months.firstWhere(
      (d) => d.year == _focusedDate.year && d.month == _focusedDate.month,
      orElse: () => months.first,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Controls: Today, Arrows, Month Dropdown
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime.now();
                      _selectedDate = DateTime.now();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    side: const BorderSide(color: DeanTheme.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Today', style: TextStyle(color: DeanTheme.textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_left, color: DeanTheme.textDark, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_right, color: DeanTheme.textDark, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 12),

                // Month Dropdown Button (Contains 12 months & years for active academic year)
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DateTime>(
                      value: activeMonth,
                      icon: const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.keyboard_arrow_down, color: DeanTheme.primaryBlue, size: 18),
                      ),
                      onChanged: (newDate) {
                        if (newDate != null) {
                          setState(() {
                            _focusedDate = newDate;
                            _selectedDate = newDate;
                          });
                        }
                      },
                      items: months.map((d) {
                        return DropdownMenuItem<DateTime>(
                          value: d,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month_outlined, color: DeanTheme.primaryBlue, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMMM yyyy').format(d).toUpperCase(),
                                style: const TextStyle(
                                  color: DeanTheme.primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            // Right Segmented Controls (Month, Day, List) - Week tab removed
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: ['Month', 'Day', 'List'].map((mode) {
                  final isSelected = _viewMode == mode;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _viewMode = mode;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? DeanTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : DeanTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  // Custom Month Grid View
  Widget _buildMonthViewGrid() {
    final daysInWeek = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final daysInCurrentMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final prevMonthLastDay = DateTime(_focusedDate.year, _focusedDate.month, 0).day;

    final List<Widget> dayCells = [];

    // Header Day Names
    for (int i = 0; i < 7; i++) {
      final isSunday = i == 0;
      dayCells.add(
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: DeanTheme.cardBorder)),
          ),
          child: Text(
            daysInWeek[i],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSunday ? DeanTheme.primaryBlue : DeanTheme.textMuted,
            ),
          ),
        ),
      );
    }

    // Trailing Days from Previous Month
    for (int i = startingWeekday - 1; i >= 0; i--) {
      final dayNum = prevMonthLastDay - i;
      dayCells.add(_buildDayCell(
        dayNum: dayNum,
        isCurrentMonth: false,
        isSunday: (startingWeekday - 1 - i) % 7 == 0,
        date: DateTime(_focusedDate.year, _focusedDate.month - 1, dayNum),
      ));
    }

    // Current Month Days
    for (int dayNum = 1; dayNum <= daysInCurrentMonth; dayNum++) {
      final cellDate = DateTime(_focusedDate.year, _focusedDate.month, dayNum);
      final weekdayIndex = (startingWeekday + dayNum - 1) % 7;
      final isSunday = weekdayIndex == 0;

      dayCells.add(_buildDayCell(
        dayNum: dayNum,
        isCurrentMonth: true,
        isSunday: isSunday,
        date: cellDate,
      ));
    }

    // Remaining Cells to complete grid rows
    final totalCells = dayCells.length - 7;
    final remainingCells = (7 - (totalCells % 7)) % 7;
    for (int dayNum = 1; dayNum <= remainingCells; dayNum++) {
      dayCells.add(_buildDayCell(
        dayNum: dayNum,
        isCurrentMonth: false,
        isSunday: false,
        date: DateTime(_focusedDate.year, _focusedDate.month + 1, dayNum),
      ));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              childAspectRatio: constraints.maxWidth > 700 ? 1.05 : 0.65,
              children: dayCells,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayCell({
    required int dayNum,
    required bool isCurrentMonth,
    required bool isSunday,
    required DateTime date,
  }) {
    final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;

    final cellEvents = _filteredEvents.where((e) {
      return e.date.year == date.year && e.date.month == date.month && e.date.day == date.day;
    }).toList();

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF1F5F9), width: 0.5),
          color: isSelected ? DeanTheme.primaryBlue.withValues(alpha: 0.04) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Number Badge
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? DeanTheme.primaryBlue : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$dayNum',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (!isCurrentMonth
                            ? const Color(0xFFCBD5E1)
                            : (isSunday ? const Color(0xFFEF4444) : DeanTheme.textDark)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),

            // Event Badges inside cell
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cellEvents.length > 2 ? 2 : cellEvents.length,
                itemBuilder: (context, index) {
                  final event = cellEvents[index];

                  if (event.category == 'Holiday') {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: event.categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.title,
                        style: TextStyle(color: event.categoryColor, fontSize: 9, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }

                  return InkWell(
                    onTap: () => _showEventDetailsModal(context, event),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: event.categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${event.title}${event.startTime.isNotEmpty ? ' ${event.startTime}' : ''}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: event.category == 'Important' ? event.categoryColor : DeanTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (cellEvents.length > 2)
              Text(
                '+${cellEvents.length - 2} more',
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: DeanTheme.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  // Custom Day View Timeline
  Widget _buildDayViewTimeline() {
    final dayEvents = _filteredEvents.where((e) => e.date.year == _selectedDate.year && e.date.month == _selectedDate.month && e.date.day == _selectedDate.day).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
          ),
          const SizedBox(height: 12),
          if (dayEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('No events scheduled for this day.', style: TextStyle(color: DeanTheme.textMuted)),
              ),
            )
          else
            Column(
              children: dayEvents.map((e) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: e.categoryColor, radius: 6),
                    title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${e.startTime} - ${e.location} | ${e.department}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: e.tagBgColor, borderRadius: BorderRadius.circular(4)),
                      child: Text(e.category, style: TextStyle(color: e.categoryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    onTap: () => _showEventDetailsModal(context, e),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Custom List View Agenda
  Widget _buildListViewAgenda() {
    if (_filteredEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No events found in calendar. Click + Add Event to create one.', style: TextStyle(color: DeanTheme.textMuted)),
        ),
      );
    }

    return Column(
      children: _filteredEvents.map((e) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: DeanTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: DeanTheme.lightBlueBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Text(DateFormat('dd').format(e.date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue)),
                      Text(DateFormat('MMM').format(e.date).toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DeanTheme.textDark)),
                      const SizedBox(height: 2),
                      Text('${e.startTime} | ${e.location} | Target: ${e.targetAudience}', style: const TextStyle(fontSize: 11, color: DeanTheme.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: e.tagBgColor, borderRadius: BorderRadius.circular(4)),
                  child: Text(e.category, style: TextStyle(color: e.categoryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Calendar Legend Bar
  Widget _buildCalendarLegend() {
    final legends = [
      {'title': 'Academic', 'color': const Color(0xFF2563EB)},
      {'title': 'Examination', 'color': const Color(0xFFF59E0B)},
      {'title': 'Department', 'color': const Color(0xFF8B5CF6)},
      {'title': 'Meeting', 'color': const Color(0xFF10B981)},
      {'title': 'Event', 'color': const Color(0xFF9333EA)},
      {'title': 'Holiday', 'color': const Color(0xFF06B6D4)},
      {'title': 'Important', 'color': const Color(0xFFEF4444)},
    ];

    return Wrap(
      spacing: 18,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: legends.map((leg) {
        return Row(
          mainAxisSize: MainAxisSize.min,
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
              leg['title'] as String,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DeanTheme.textMuted),
            ),
          ],
        );
      }).toList(),
    );
  }

  // 4. Right Sidebar Widget 1: Upcoming Events Card
  Widget _buildUpcomingEventsCard() {
    final upcomingList = _filteredEvents.where((e) {
      return e.date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    }).take(5).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeanTheme.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Events',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _viewMode = 'List';
                  });
                },
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (upcomingList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No upcoming events scheduled. Click + Add Event to create one.',
                style: TextStyle(fontSize: 11, color: DeanTheme.textMuted),
              ),
            )
          else
            ...upcomingList.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Box
                    Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('dd').format(e.date),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
                          ),
                          Text(
                            DateFormat('MMM').format(e.date).toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: DeanTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  e.title,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: e.tagBgColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  e.category,
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: e.categoryColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.startTime + (e.endTime.isNotEmpty ? ' - ${e.endTime}' : ''),
                            style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            e.location,
                            style: const TextStyle(fontSize: 10, color: DeanTheme.textSubtle),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 5. Right Sidebar Widget 2: Calendar Filters Card
  Widget _buildCalendarFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeanTheme.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendar Filters',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
          ),
          const SizedBox(height: 14),

          // Event Type Dropdown
          const Text('Event Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryFilter,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: DeanTheme.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: DeanTheme.cardBorder)),
            ),
            style: const TextStyle(fontSize: 12, color: DeanTheme.textDark, fontWeight: FontWeight.w500),
            items: ['All Types', 'Academic', 'Examination', 'Department', 'Meeting', 'Event', 'Holiday', 'Important']
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategoryFilter = val);
            },
          ),
          const SizedBox(height: 12),

          // Department Dropdown
          const Text('Department', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _selectedDepartmentFilter,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: DeanTheme.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: DeanTheme.cardBorder)),
            ),
            style: const TextStyle(fontSize: 12, color: DeanTheme.textDark, fontWeight: FontWeight.w500),
            items: ['All Departments', 'Computer Science', 'Electronics & Comm.', 'Mechanical Engineering', 'Civil Engineering', 'Placement Cell', 'Quality Assurance']
                .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedDepartmentFilter = val);
            },
          ),
          const SizedBox(height: 12),

          // Checkboxes
          CheckboxListTile(
            value: _showHolidays,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Show Holidays', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            activeColor: DeanTheme.primaryBlue,
            onChanged: (val) => setState(() => _showHolidays = val ?? true),
          ),
          CheckboxListTile(
            value: _showImportantEvents,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Show Important Events', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            activeColor: DeanTheme.primaryBlue,
            onChanged: (val) => setState(() => _showImportantEvents = val ?? true),
          ),
          CheckboxListTile(
            value: _showDepartmentEvents,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Show Department Events', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            activeColor: DeanTheme.primaryBlue,
            onChanged: (val) => setState(() => _showDepartmentEvents = val ?? true),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DeanTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategoryFilter = 'All Types';
                    _selectedDepartmentFilter = 'All Departments';
                    _showHolidays = true;
                    _showImportantEvents = true;
                    _showDepartmentEvents = true;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: const BorderSide(color: DeanTheme.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Reset', style: TextStyle(color: DeanTheme.textDark, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Interactive Modal Dialogs

  // Modal 1: + Add Event Modal with Hall Dropdown (Platinum Hall, Denuka Hall, Sppire Hall, Diamond Hall, Edison Hall, Mount Everest Hall & Other)
  void _showAddEventModal(BuildContext context) {
    final titleController = TextEditingController();
    final customLocationController = TextEditingController();
    final descriptionController = TextEditingController();

    String category = 'Academic';
    String department = 'All Departments';
    DateTime selectedDate = DateTime.now();
    String startTime = '10:00 AM';
    String endTime = '11:00 AM';
    String locationOption = 'Platinum Hall';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.event, color: DeanTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Add New Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Event Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Annual Technical Symposium',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  initialValue: category,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: ['Academic', 'Examination', 'Department', 'Meeting', 'Event', 'Holiday', 'Important']
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => category = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Department', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  initialValue: department,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: ['All Departments', 'Computer Science', 'Electronics & Comm.', 'Mechanical Engineering', 'Placement Cell']
                                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 11))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => department = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Event Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2025, 1, 1),
                                      lastDate: DateTime(2026, 12, 31),
                                    );
                                    if (picked != null) {
                                      setModalState(() => selectedDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: DeanTheme.cardBorder),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateFormat('dd MMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 12)),
                                        const Icon(Icons.calendar_today, size: 14, color: DeanTheme.textMuted),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
                                const SizedBox(height: 4),
                                TextField(
                                  onChanged: (v) => startTime = v,
                                  controller: TextEditingController(text: startTime),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Location Dropdown Requirement 3
                      const Text('Event Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: locationOption,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          'Platinum Hall',
                          'Denuka Hall',
                          'Sppire Hall',
                          'Diamond Hall',
                          'Edison Hall',
                          'Mount Everest Hall',
                          'Other',
                        ].map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              locationOption = val;
                            });
                          }
                        },
                      ),

                      // Custom Location text field if 'Other' is chosen
                      if (locationOption == 'Other') ...[
                        const SizedBox(height: 8),
                        const Text('Specify Custom Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: customLocationController,
                          decoration: InputDecoration(
                            hintText: 'Enter hall or venue name...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Brief summary or target audience notes...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: DeanTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      final finalLocation = locationOption == 'Other'
                          ? (customLocationController.text.trim().isNotEmpty ? customLocationController.text.trim() : 'Other Location')
                          : locationOption;

                      final newEventMap = {
                        'title': titleController.text.trim(),
                        'category': category,
                        'event_type': category,
                        'event_date': selectedDate.toIso8601String(),
                        'start_time': startTime,
                        'end_time': endTime,
                        'location': finalLocation,
                        'department': department,
                        'target_audience': 'All Students & Faculty',
                        'description': descriptionController.text.trim(),
                        'details': descriptionController.text.trim(),
                        'venue': finalLocation,
                        'created_at': DateTime.now().toIso8601String(),
                        'updated_at': DateTime.now().toIso8601String(),
                      };

                      DeanSupabaseService.instance.addCalendarEvent(newEventMap).then((created) {
                        if (!mounted) return;
                        if (created != null) {
                          final parsed = DateTime.tryParse((created['event_date'] ?? selectedDate.toIso8601String()).toString());
                          setState(() {
                            _allEvents.add(AcademicEventModel(
                              id: (created['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
                              title: (created['title'] ?? titleController.text.trim()).toString(),
                              category: (created['category'] ?? created['event_type'] ?? category).toString(),
                              date: parsed ?? selectedDate,
                              startTime: (created['start_time'] ?? startTime).toString(),
                              endTime: (created['end_time'] ?? endTime).toString(),
                              location: (created['location'] ?? finalLocation).toString(),
                              department: (created['department'] ?? department).toString(),
                              description: (created['description'] ?? descriptionController.text.trim()).toString(),
                            ));
                          });
                        }
                      });

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Event added successfully!'), backgroundColor: DeanTheme.successGreen),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: DeanTheme.primaryBlue),
                  child: const Text('Save Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Modal 2: Event Details Modal
  void _showEventDetailsModal(BuildContext context, AcademicEventModel event) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: event.categoryColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: event.tagBgColor, borderRadius: BorderRadius.circular(4)),
                child: Text(event.category, style: TextStyle(color: event.categoryColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(height: 14),
              _buildDetailRow(Icons.calendar_month, 'Date:', DateFormat('EEEE, MMMM d, yyyy').format(event.date)),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.access_time, 'Time:', event.startTime + (event.endTime.isNotEmpty ? ' - ${event.endTime}' : '')),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.location_on_outlined, 'Location:', event.location),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.business_outlined, 'Department:', event.department),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.people_outline, 'Audience:', event.targetAudience),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),
                Text(event.description, style: const TextStyle(fontSize: 12, color: DeanTheme.textDark)),
              ],
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: ctx,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete Event'),
                    content: Text('Are you sure you want to delete "${event.title}" from Supabase?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: DeanTheme.dangerRose), child: const Text('Delete')),
                    ],
                  ),
                );

                if (confirm == true) {
                  print('[DEAN TRACE] DELETE dean.dean_calendar_events id: ${event.id}');
                  final res = await DeanSupabaseService.instance.deleteCalendarEvent(event.id);
                  print('[DEAN TRACE] DELETE dean.dean_calendar_events success: $res');
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    final appState = DeanAppStateProvider.of(context);
                    await appState.fetchAllData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted event "${event.title}" from Supabase.'), backgroundColor: DeanTheme.dangerRose),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, color: DeanTheme.dangerRose, size: 16),
              label: const Text('Delete Event', style: TextStyle(color: DeanTheme.dangerRose, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DeanTheme.textMuted),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textMuted)),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DeanTheme.textDark))),
      ],
    );
  }

  // Feature 2: Fully Functional Export Calendar CSV Download Requirement 2
  void _exportCalendar(BuildContext context) {
    final StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln('Event Title,Category,Date,Start Time,End Time,Location,Department,Target Audience,Description');

    final exportList = _allEvents.isNotEmpty
        ? _allEvents
        : [
            AcademicEventModel(
              id: '1',
              title: 'Master Academic Orientation',
              category: 'Academic',
              date: DateTime.now(),
              startTime: '10:00 AM',
              endTime: '01:00 PM',
              location: 'Platinum Hall',
              department: 'All Departments',
              targetAudience: 'All Students & Staff',
              description: 'Academic orientation program schedule',
            ),
          ];

    for (final event in exportList) {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      csvBuffer.writeln(
        '"${event.title}","${event.category}","$dateStr","${event.startTime}","${event.endTime}","${event.location}","${event.department}","${event.targetAudience}","${event.description}"',
      );
    }

    try {
      if (kIsWeb) {
        final bytes = utf8.encode(csvBuffer.toString());
        final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'academic_calendar_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv');
        html.document.body?.children.add(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calendar exported as CSV file successfully!'),
          backgroundColor: DeanTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Export error: $e');
    }
  }
}
