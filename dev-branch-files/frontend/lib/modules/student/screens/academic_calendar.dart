// ignore_for_file: avoid_web_libraries_in_flutter, unused_element, unused_local_variable, deprecated_member_use, unused_field
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../models/app_state.dart';

class AcademicCalendarScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const AcademicCalendarScreen({super.key, required this.onNavigate});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  // Local semester state - synced with selectedAcademicYear
  String _selectedSem = 'V';
  DateTime _focusedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _lastAcademicYear;
  bool _dateInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final appState = AppStateProvider.of(context);
      if (!_dateInitialized) {
        // First load: always show today's month
        _dateInitialized = true;
        _lastAcademicYear = appState.selectedAcademicYear;
        // Keep _focusedDate as today (already set in initializer)
      } else if (_lastAcademicYear != appState.selectedAcademicYear) {
        // Academic year changed by user — navigate to that year's month
        _lastAcademicYear = appState.selectedAcademicYear;
        _focusedDate = _parseAcademicYearToDate(appState.selectedAcademicYear);
      }
    } catch (_) {}
  }

  DateTime _parseAcademicYearToDate(String yearRange) {
    int startYear = 2025;
    final parts = yearRange.split('-').map((e) => e.trim()).toList();
    if (parts.isNotEmpty) {
      int? p = int.tryParse(parts[0]);
      if (p != null) {
        startYear = p < 100 ? (2000 + p) : p;
      }
    }
    final now = DateTime.now();
    if (now.year == startYear || now.year == (startYear + 1)) {
      return DateTime(now.year, now.month, 1);
    }
    return DateTime(startYear, 6, 1);
  }

  List<Map<String, dynamic>> _getEventsFromDb() {
    try {
      final appState = AppStateProvider.of(context);
      final dbEvents = appState.academicCalendarEvents;

      if (dbEvents.isEmpty) {
        return [];
      }

      final List<Map<String, dynamic>> list = [];
      for (var e in dbEvents) {
        final dateVal = e['event_date'] ?? e['date'];
        if (dateVal == null) continue;
        final dateStr = dateVal.toString();
        DateTime? dt;
        try {
          dt = DateTime.parse(dateStr);
        } catch (_) {
          continue;
        }

        Color eventColor = Colors.blue;
        if (e['color_code'] != null) {
          final hex = e['color_code'].toString().replaceAll('#', '');
          if (hex.length == 6) {
            eventColor = Color(int.parse('FF$hex', radix: 16));
          }
        }

        list.add({
          'day': dt.day,
          'month': dt.month,
          'year': dt.year,
          'title': e['title'] ?? 'Event',
          'time': e['start_time']?.toString() ?? '',
          'location': e['venue'] ?? e['place'] ?? 'Campus',
          'type': e['event_type'] ?? e['type'] ?? 'Event',
          'color': eventColor,
          'description': e['description'] ?? '',
        });
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get _eventsList {
    final dbList = _getEventsFromDb();
    if (dbList.isNotEmpty) return dbList;
    return [];
  }

  final List<Map<String, dynamic>> _events = [];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCardsRow(),
          const SizedBox(height: 16),
          _buildControlsRow(),
          const SizedBox(height: 16),
          _buildCalendarCard(),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(AppState appState) {
    final name = appState.studentName.isNotEmpty ? appState.studentName : 'Student Profile';
    final dept = appState.getProfileField('department', defaultValue: 'CSE');
    final rollNo = appState.getProfileField('roll_no', defaultValue: appState.studentId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0056A6), Color(0xFF003B73)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0056A6).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF4B400), width: 2.5),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dept • Roll No: $rollNo • Academic Calendar ${appState.selectedAcademicYear}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCardsRow() {
    final appState = AppStateProvider.of(context);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';
    
    int examCount = 0;
    int holidayCount = 0;
    int eventCount = 0;
    int attendanceEventsCount = 0;

    if (isCurrentActive) {
      final events = appState.academicCalendarEvents;
      final now = DateTime.now();
      for (var e in events) {
        final dateStr = e['event_date']?.toString() ?? '';
        if (dateStr.isEmpty) continue;
        
        DateTime? dt;
        try { dt = DateTime.parse(dateStr); } catch(_) {}
        if (dt == null) continue;
        
        if (dt.year == now.year && dt.month == now.month) {
          final type = (e['event_type'] ?? '').toString().toLowerCase();
          if (type.contains('exam') || type.contains('test')) {
            examCount++;
          } else if (type.contains('holiday')) {
            holidayCount++;
          } else {
            eventCount++;
          }
        }
      }

      for (var r in appState.attendanceRecords) {
        final dateStr = r['date']?.toString() ?? '';
        if (dateStr.isEmpty) continue;
        DateTime? dt;
        try { dt = DateTime.parse(dateStr); } catch(_) {}
        if (dt == null) continue;
        
        if (dt.year == now.year && dt.month == now.month) {
          bool hasAbsent = false;
          for (int p = 1; p <= 7; p++) {
            if (r['p$p'] == false) hasAbsent = true;
          }
          if (hasAbsent) {
            attendanceEventsCount++;
          }
        }
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 900;
      if (isMobile) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: 175, child: _buildMetricCard('Upcoming Exams', examCount.toString(), Colors.blue, Icons.event_note, (examCount / 10.0).clamp(0.0, 1.0))),
              const SizedBox(width: 12),
              SizedBox(width: 175, child: _buildMetricCard('Upcoming Holidays', holidayCount.toString(), Colors.red, Icons.calendar_month, (holidayCount / 10.0).clamp(0.0, 1.0))),
              const SizedBox(width: 12),
              SizedBox(width: 175, child: _buildMetricCard('Institute Events', eventCount.toString(), Colors.orange, Icons.campaign, (eventCount / 10.0).clamp(0.0, 1.0))),
              const SizedBox(width: 12),
              SizedBox(width: 175, child: _buildMetricCard('Attendance Events', attendanceEventsCount.toString(), Colors.green, Icons.person_outline, (attendanceEventsCount / 10.0).clamp(0.0, 1.0))),
            ],
          ),
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildMetricCard('Upcoming Exams', examCount.toString(), Colors.blue, Icons.event_note, (examCount / 10.0).clamp(0.0, 1.0))),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricCard('Upcoming Holidays', holidayCount.toString(), Colors.red, Icons.calendar_month, (holidayCount / 10.0).clamp(0.0, 1.0))),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricCard('Institute Events', eventCount.toString(), Colors.orange, Icons.campaign, (eventCount / 10.0).clamp(0.0, 1.0))),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricCard('Attendance Events', attendanceEventsCount.toString(), Colors.green, Icons.person_outline, (attendanceEventsCount / 10.0).clamp(0.0, 1.0))),
        ],
      );
    });
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon, double progress) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DateTime> _get12MonthsForAcademicYear(String yearRange) {
    int startYear = 2025;
    int endYear = 2026;
    final parts = yearRange.split('-').map((e) => e.trim()).toList();
    if (parts.isNotEmpty) {
      int? p1 = int.tryParse(parts[0]);
      if (p1 != null) {
        startYear = p1 < 100 ? (2000 + p1) : p1;
      }
      if (parts.length >= 2) {
        int? p2 = int.tryParse(parts[1]);
        if (p2 != null) {
          endYear = p2 < 100 ? (2000 + p2) : p2;
        } else {
          endYear = startYear + 1;
        }
      } else {
        endYear = startYear + 1;
      }
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

  Widget _buildAcademicYearPill(AppState appState, List<String> academicYears) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: appState.selectedAcademicYear,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB), size: 16),
          ),
          onChanged: (newYear) {
            if (newYear != null) {
              appState.setAcademicYear(newYear);
              final sems = appState.getAvailableSemestersForYear(newYear);
              setState(() {
                _selectedSem = sems.first;
                _lastAcademicYear = newYear;
                _focusedDate = _parseAcademicYearToDate(newYear);
              });
            }
          },
          selectedItemBuilder: (BuildContext context) {
            return academicYears.map<Widget>((year) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'AY $year',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: academicYears.map((year) {
            return DropdownMenuItem<String>(
              value: year,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'AY $year',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSemesterPill(List<String> availableSems) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSem,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB), size: 16),
          ),
          onChanged: (newSem) {
            if (newSem != null) {
              setState(() => _selectedSem = newSem);
            }
          },
          selectedItemBuilder: (BuildContext context) {
            return availableSems.map<Widget>((sem) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school_outlined, color: Color(0xFF2563EB), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'SEM $sem',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: availableSems.map((sem) {
            return DropdownMenuItem<String>(
              value: sem,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school_outlined, color: Color(0xFF2563EB), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'SEM $sem',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthPickerPill() {
    return InkWell(
      onTap: () async {
        final selected = await showMonthYearPicker(
          context: context,
          initialDate: _focusedDate,
          firstDate: DateTime(2019),
          lastDate: DateTime(2030),
        );
        if (selected != null) {
          setState(() {
            _focusedDate = selected;
          });
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF2563EB), size: 16),
            const SizedBox(width: 8),
            Text(
              DateFormat('MMMM yyyy').format(_focusedDate).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB), size: 18),
          ],
        ),
      ),
    );
  }

  void _triggerPrintCalendar() {
    final monthName = DateFormat('MMMM yyyy').format(_focusedDate);
    final year = _focusedDate.year;
    final month = _focusedDate.month;
    final appState = AppStateProvider.of(context);
    final ay = appState.selectedAcademicYear;

    final firstDayOfMonth = DateTime(year, month, 1);
    final int firstWeekdayOffset = (firstDayOfMonth.weekday - 1) % 7;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final int daysInPrevMonth = DateTime(year, month, 0).day;

    final List<Map<String, dynamic>> allDays = [];
    for (int i = firstWeekdayOffset - 1; i >= 0; i--) {
      allDays.add({
        'day': daysInPrevMonth - i,
        'isCurrent': false,
        'month': month == 1 ? 12 : month - 1,
        'year': month == 1 ? year - 1 : year,
      });
    }
    for (int d = 1; d <= daysInMonth; d++) {
      allDays.add({
        'day': d,
        'isCurrent': true,
        'month': month,
        'year': year,
      });
    }
    int nextMonthDay = 1;
    while (allDays.length % 7 != 0) {
      allDays.add({
        'day': nextMonthDay++,
        'isCurrent': false,
        'month': month == 12 ? 1 : month + 1,
        'year': month == 12 ? year + 1 : year,
      });
    }

    final dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final StringBuffer cellsHtml = StringBuffer();
    for (int index = 0; index < allDays.length; index++) {
      final dayData = allDays[index];
      final int day = dayData['day'];
      final bool isCurrent = dayData['isCurrent'];
      final int cellMonth = dayData['month'];
      final int cellYear = dayData['year'];
      final isSundayCol = (index % 7 == 6);
      final now = DateTime.now();
      final isToday = isCurrent && day == now.day && cellMonth == now.month && cellYear == now.year;

      final dayEvents = isCurrent
          ? _eventsList.where((e) => e['day'] == day && e['month'] == cellMonth && e['year'] == cellYear).toList()
          : [];
      final hasHoliday = dayEvents.any((e) =>
          (e['type'] ?? '').toString().toLowerCase().contains('holiday') ||
          (e['type'] ?? '').toString().toLowerCase().contains('leave') ||
          (e['type'] ?? '').toString().toLowerCase().contains('absent'));
      final hasEvent = dayEvents.any((e) =>
          (e['type'] ?? '').toString().toLowerCase().contains('event') ||
          (e['type'] ?? '').toString().toLowerCase().contains('symposium') ||
          (e['type'] ?? '').toString().toLowerCase().contains('seminar') ||
          (e['type'] ?? '').toString().toLowerCase().contains('workshop') ||
          (e['type'] ?? '').toString().toLowerCase().contains('exam') ||
          (e['type'] ?? '').toString().toLowerCase().contains('test'));

      final String customTitle = dayEvents.map((e) => e['title'] ?? e['name'] ?? '').join(' / ');

      String bg = '#ffffff';
      String color = '#0f172a';
      String reason = '';
      String badgeClass = '';

      final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';

      if (!isCurrentActive) {
        if (!isCurrent) {
          bg = '#fafafa';
          color = '#cbd5e1';
        } else if (isSundayCol) {
          bg = '#fee2e2';
          color = '#dc2626';
          reason = 'Sunday';
          badgeClass = 'badge-holiday';
        }
      } else {
        if (!isCurrent) {
          bg = '#fafafa';
          color = '#cbd5e1';
        } else if (hasHoliday) {
          bg = '#fee2e2';
          color = '#dc2626';
          reason = customTitle.isNotEmpty ? customTitle : 'Holiday';
          badgeClass = 'badge-holiday';
        } else if (hasEvent) {
          bg = '#dcfce7';
          color = '#15803d';
          reason = customTitle.isNotEmpty ? customTitle : 'Event';
          badgeClass = 'badge-event';
        } else if (isSundayCol) {
          bg = '#fee2e2';
          color = '#dc2626';
          reason = 'Sunday';
          badgeClass = 'badge-holiday';
        } else if (isToday) {
          bg = '#dbeafe';
          color = '#1d4ed8';
          reason = 'Today';
          badgeClass = 'badge-exam';
        } else {
          bg = '#ffffff';
          color = '#0f172a';
          reason = '';
        }
      }

      cellsHtml.write('''
        <div class="day-cell" style="background-color: $bg; color: $color;">
          <div class="day-num">$day</div>
          ${reason.isNotEmpty ? '<div class="day-reason $badgeClass">$reason</div>' : ''}
        </div>
      ''');
    }

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Academic Calendar - $monthName</title>
  <style>
    @page { size: A4 landscape; margin: 8mm; }
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; color: #0f172a; margin: 0; padding: 16px; }
    .header { text-align: center; margin-bottom: 14px; border-bottom: 2.5px solid #2563eb; padding-bottom: 10px; }
    .college-title { font-size: 19px; font-weight: 800; color: #0f172a; letter-spacing: 0.5px; }
    .college-sub { font-size: 11px; color: #64748b; margin-top: 2px; }
    .sub-title { font-size: 14px; font-weight: 700; color: #2563eb; margin-top: 6px; }
    .headers-row { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; margin-bottom: 4px; }
    .header-cell { font-size: 10px; font-weight: 800; text-align: center; color: #475569; padding: 6px 3px; background: #f1f5f9; border-radius: 5px; }
    .grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; }
    .day-cell { border: 1px solid #cbd5e1; border-radius: 6px; min-height: 48px; padding: 4px 3px; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; }
    .day-num { font-size: 12px; font-weight: 800; }
    .day-reason { font-size: 8px; font-weight: 700; margin-top: 2px; padding: 1px 3px; border-radius: 3px; max-width: 95%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .badge-holiday { background: #fee2e2; color: #dc2626; }
    .badge-event { background: #dcfce7; color: #15803d; }
    .badge-exam { background: #dbeafe; color: #1d4ed8; border: 1px solid #93c5fd; }
  </style>
</head>
<body>
  <div class="header">
    <div class="college-title">K.S.R. COLLEGE OF ENGINEERING (AUTONOMOUS)</div>
    <div class="college-sub">Tiruchengode - 637 215, Namakkal District, Tamil Nadu</div>
    <div class="sub-title">ACADEMIC CALENDAR — ${monthName.toUpperCase()} (AY $ay)</div>
  </div>
  <div class="headers-row">
    ${dayHeaders.map((h) => '<div class="header-cell">$h</div>').join('')}
  </div>
  <div class="grid">
    $cellsHtml
  </div>
  <script>
    window.onload = function() { setTimeout(function() { window.print(); }, 250); };
  </script>
</body>
</html>
    ''';

    try {
      // 1. Remove any previous calendar print iframe
      final oldIframe = html.document.getElementById('calendar_print_frame');
      if (oldIframe != null) {
        oldIframe.remove();
      }

      // 2. Create isolated hidden iframe to print ONLY the Academic Calendar
      final iframe = html.IFrameElement()
        ..id = 'calendar_print_frame'
        ..style.position = 'fixed'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.width = '0'
        ..style.height = '0'
        ..style.border = '0'
        ..style.visibility = 'hidden';

      iframe.onLoad.listen((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            final dynamic win = iframe.contentWindow;
            win?.focus();
            win?.print();
          } catch (_) {}
          Future.delayed(const Duration(seconds: 30), () {
            iframe.remove();
          });
        });
      });

      iframe.srcdoc = htmlContent;
      html.document.body?.append(iframe);
    } catch (_) {
      try {
        final blob = html.Blob([htmlContent], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        Future.delayed(const Duration(seconds: 15), () => html.Url.revokeObjectUrl(url));
      } catch (_) {}
    }
  }

  Widget _buildPrintButton() {
    return OutlinedButton.icon(
      onPressed: _triggerPrintCalendar,
      icon: const Icon(Icons.print_outlined, size: 16, color: Color(0xFF2563EB)),
      label: const Text('Print', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildControlsRow() {
    final appState = AppStateProvider.of(context);
    final availableSems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    if (!availableSems.contains(_selectedSem)) {
      _selectedSem = availableSems.first;
    }
    const List<String> academicYears = ['2023-24', '2024-25', '2025-26', '2026-27'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Row(
            children: [
              _buildAcademicYearPill(appState, academicYears),
              const SizedBox(width: 8),
              _buildSemesterPill(availableSems),
              const SizedBox(width: 12),
              _buildMonthPickerPill(),
              const Spacer(),
              _buildPrintButton(),
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildAcademicYearPill(appState, academicYears),
            _buildSemesterPill(availableSems),
            _buildMonthPickerPill(),
            _buildPrintButton(),
          ],
        );
      },
    );
  }


  Widget _buildImportantNotifications() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.notifications_active_outlined, size: 18, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  const Text('Important Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          _buildNotificationItem('Campus Registration', 'Open for 2025-26', Colors.blue, Icons.app_registration, 'Register'),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildNotificationItem('Hall Ticket', 'Available Now', Colors.green, Icons.confirmation_num, 'Download'),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildNotificationItem('Holiday Update', 'Independence Day', Colors.orange, Icons.celebration, 'Read'),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, Color color, IconData icon, String action) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(subtitle, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), minimumSize: Size.zero, side: BorderSide(color: color.withValues(alpha: 0.3))),
          child: Text(action, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildAcademicStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bar_chart_rounded, size: 18, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 10),
              const Text('Academic Statistics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildStatItem('Working Days', '112', Colors.blue, Icons.calendar_today_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatItem('Completed', '78', Colors.green, Icons.check_circle_outline)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatItem('Remaining', '34', Colors.red, Icons.schedule)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatItem('Attendance', '89%', Colors.green, Icons.person_outline)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatItem('Exams', '5', Colors.purple, Icons.quiz_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatItem('Events', '12', Colors.orange, Icons.event_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildCalendarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Calendar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),

          // Calendar Grid Component
          _buildMonthGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
    final year = _focusedDate.year;
    final month = _focusedDate.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    // Monday-first offset: 1=Mon(0), 2=Tue(1)... 7=Sun(6)
    final int firstWeekdayOffset = (firstDayOfMonth.weekday - 1) % 7;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final int daysInPrevMonth = DateTime(year, month, 0).day;

    final List<Map<String, dynamic>> allDays = [];

    // Leading days from previous month
    for (int i = firstWeekdayOffset - 1; i >= 0; i--) {
      allDays.add({
        'day': daysInPrevMonth - i,
        'isCurrent': false,
        'month': month == 1 ? 12 : month - 1,
        'year': month == 1 ? year - 1 : year,
      });
    }

    // Days of current month
    for (int d = 1; d <= daysInMonth; d++) {
      allDays.add({
        'day': d,
        'isCurrent': true,
        'month': month,
        'year': year,
      });
    }

    // Trailing days from next month
    int nextMonthDay = 1;
    while (allDays.length % 7 != 0) {
      allDays.add({
        'day': nextMonthDay++,
        'isCurrent': false,
        'month': month == 12 ? 1 : month + 1,
        'year': month == 12 ? year + 1 : year,
      });
    }

    final dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final isDesktopGrid = MediaQuery.of(context).size.width >= 900;

    return Column(
      children: [
        // Day Headers Row (Mon to Sun)
        Row(
          children: dayHeaders.map((dayName) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  dayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: isDesktopGrid ? 1.85 : 1.45,
          ),
          itemCount: allDays.length,
          itemBuilder: (context, index) {
            final dayData = allDays[index];
            final int day = dayData['day'];
            final bool isCurrent = dayData['isCurrent'];
            final int cellMonth = dayData['month'];
            final int cellYear = dayData['year'];

            final isSundayCol = (index % 7 == 6);
            final now = DateTime.now();
            final isToday = isCurrent && day == now.day && cellMonth == now.month && cellYear == now.year;

            final dayEvents = isCurrent
                ? _eventsList.where((e) => e['day'] == day && e['month'] == cellMonth && e['year'] == cellYear).toList()
                : [];
            final hasHoliday = dayEvents.any((e) =>
                (e['type'] ?? '').toString().toLowerCase().contains('holiday') ||
                (e['type'] ?? '').toString().toLowerCase().contains('leave') ||
                (e['type'] ?? '').toString().toLowerCase().contains('absent'));
            final hasEvent = dayEvents.any((e) =>
                (e['type'] ?? '').toString().toLowerCase().contains('event') ||
                (e['type'] ?? '').toString().toLowerCase().contains('symposium') ||
                (e['type'] ?? '').toString().toLowerCase().contains('seminar') ||
                (e['type'] ?? '').toString().toLowerCase().contains('workshop') ||
                (e['type'] ?? '').toString().toLowerCase().contains('exam') ||
                (e['type'] ?? '').toString().toLowerCase().contains('test'));

            final String customTitle = dayEvents.map((e) => e['title'] ?? e['name'] ?? '').join(' / ');
            final String detailsDesc = dayEvents.map((e) => e['description'] ?? '').where((d) => d.isNotEmpty).join('\n');

            Color bgColor = Colors.transparent;
            Color textColor = const Color(0xFF0F172A);
            Border? border;
            FontWeight fontWeight = FontWeight.w600;
            String reason = '';
            String computedDetails = '';

            final appState = AppStateProvider.of(context);
            final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';

            if (!isCurrentActive) {
              if (isSundayCol && isCurrent) {
                bgColor = const Color(0xFFFEE2E2);
                textColor = const Color(0xFFDC2626);
                fontWeight = FontWeight.bold;
                reason = 'Sunday';
                computedDetails = 'Weekly Sunday Holiday.';
              } else if (!isCurrent) {
                textColor = const Color(0xFF94A3B8);
                fontWeight = FontWeight.w500;
              } else {
                bgColor = Colors.transparent;
                textColor = const Color(0xFF0F172A);
                fontWeight = FontWeight.w600;
              }
            } else {
              // Dynamic styling based on Supabase database event data
              if (!isCurrent) {
                textColor = const Color(0xFF94A3B8);
                fontWeight = FontWeight.w500;
              } else if (hasHoliday) {
                bgColor = const Color(0xFFFEE2E2);
                textColor = const Color(0xFFDC2626);
                fontWeight = FontWeight.bold;
                reason = customTitle.isNotEmpty ? customTitle : 'Holiday';
                computedDetails = detailsDesc.isNotEmpty ? detailsDesc : 'Holiday / Leave Day.';
              } else if (hasEvent) {
                bgColor = const Color(0xFFDCFCE7);
                textColor = const Color(0xFF15803D);
                fontWeight = FontWeight.bold;
                reason = customTitle.isNotEmpty ? customTitle : 'Event';
                computedDetails = detailsDesc.isNotEmpty ? detailsDesc : 'Scheduled Event / Activity.';
              } else if (isSundayCol) {
                bgColor = const Color(0xFFFEE2E2);
                textColor = const Color(0xFFDC2626);
                fontWeight = FontWeight.bold;
                reason = 'Sunday';
                computedDetails = 'Weekly Sunday Holiday.';
              } else if (isToday) {
                bgColor = const Color(0xFFDBEAFE);
                textColor = const Color(0xFF1D4ED8);
                fontWeight = FontWeight.bold;
                border = Border.all(color: const Color(0xFF3B82F6), width: 2.0);
                reason = 'Today';
                computedDetails = 'Today\'s academic session.';
              } else {
                bgColor = Colors.transparent;
                textColor = const Color(0xFF0F172A);
                fontWeight = FontWeight.w600;
                reason = 'Working Day';
                computedDetails = 'Regular Scheduled Academic Session.';
              }
            }

            String cellLabel = '';
            if (isCurrent) {
              if (hasHoliday) {
                cellLabel = 'Holiday';
              } else if (hasEvent) {
                cellLabel = 'Event';
              } else if (isToday) {
                cellLabel = 'Today';
              } else if (isSundayCol) {
                cellLabel = 'Holiday';
              } else {
                cellLabel = 'Working Day';
              }
            }

            final monthName = DateFormat('MMMM').format(DateTime(cellYear, cellMonth));
            final fullDateStr = '$monthName $day, $cellYear';

            return InkWell(
              onTap: () {
                if (isCurrent) {
                  _showDayDetailsDialog(
                    context: context,
                    dateTitle: fullDateStr,
                    typeLabel: reason.isNotEmpty ? reason : 'Working Day',
                    description: computedDetails.isNotEmpty ? computedDetails : 'Regular Scheduled Academic Session.',
                    themeColor: textColor == const Color(0xFF0F172A) ? const Color(0xFF2563EB) : textColor,
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: border,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: isDesktopGrid ? 18 : 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (isDesktopGrid && cellLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        cellLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDayDetailsDialog({
    required BuildContext context,
    required String dateTitle,
    required String typeLabel,
    required String description,
    required Color themeColor,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: Dialog(
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SizedBox(
              width: 380,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              typeLabel.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: themeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      dateTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<DateTime?> showMonthYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;

    final List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SELECT MONTH & YEAR',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${DateFormat('MMMM').format(DateTime(selectedYear, selectedMonth))} $selectedYear',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Year Navigation Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Color(0xFF334155)),
                            onPressed: selectedYear > firstDate.year
                                ? () {
                                    setDialogState(() {
                                      selectedYear--;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            '$selectedYear',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Color(0xFF334155)),
                            onPressed: selectedYear < lastDate.year
                                ? () {
                                    setDialogState(() {
                                      selectedYear++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Months Grid (4 columns x 3 rows)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final monthNum = index + 1;
                          final isSelected = monthNum == selectedMonth;

                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedMonth = monthNum;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                monthNames[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Action Buttons (Cancel / Select)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, null),
                            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, DateTime(selectedYear, selectedMonth, 1));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
