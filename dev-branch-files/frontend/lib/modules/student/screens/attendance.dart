// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/app_state.dart';
import '../widgets/academic_year_dropdown.dart';
import '../widgets/student_loading_widget.dart';

class AttendanceScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const AttendanceScreen({super.key, this.onNavigate});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class CalendarDay {
  final String text;
  final String status; // 'P', 'A', 'OD', 'ML', 'H', 'inactive'
  final bool isToday;
  final bool isSelected;
  CalendarDay(this.text, this.status, {this.isToday = false, this.isSelected = false});
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _selectedYear = '2025–26';
  String _selectedSem = 'V'; // Set default semester to V to match Marks Screen
  String _selectedSec = 'A';
  String _selectedProg = 'B.E IoT';
  String _searchQuery = '';
  bool _isLoading = false;

  static const List<String> _calendarMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Calendar Header selectors (defaulted to current date)
  late String _selectedCalendarMonth;
  late String _selectedCalendarYear;
  late DateTime _selectedDayDate;

  List<String> get _calendarYearList {
    final currentYear = DateTime.now().year;
    final years = <String>[];
    for (int y = currentYear + 2; y >= currentYear - 4; y--) {
      years.add(y.toString());
    }
    if (!years.contains(_selectedCalendarYear)) {
      years.add(_selectedCalendarYear);
      years.sort((a, b) => b.compareTo(a));
    }
    return years;
  }

  int _romanToSubspaceInt(String roman) {
    final trimmed = roman.trim();
    final parsed = int.tryParse(trimmed);
    if (parsed != null) return parsed;
    switch (trimmed.toUpperCase()) {
      case 'I': return 1;
      case 'II': return 2;
      case 'III': return 3;
      case 'IV': return 4;
      case 'V': return 5;
      case 'VI': return 6;
      case 'VII': return 7;
      case 'VIII': return 8;
      default: return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedCalendarMonth = _calendarMonths[now.month - 1];
    _selectedCalendarYear = now.year.toString();
    _selectedDayDate = DateTime(now.year, now.month, now.day);
  }



  // Helper method to generate calendar days continuously for any month/year
  List<CalendarDay> _generateCalendarDays() {
    final appState = AppStateProvider.of(context);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';
    final dbRecords = isCurrentActive ? appState.attendanceRecords : const [];
    final now = DateTime.now();

    final Map<String, int> monthNumbers = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12
    };

    final monthInt = monthNumbers[_selectedCalendarMonth] ?? now.month;
    final yearInt = int.tryParse(_selectedCalendarYear) ?? now.year;
    final isCurrentMonthAndYear = (now.year == yearInt && now.month == monthInt);

    // First day of the selected month
    final firstDayOfMonth = DateTime(yearInt, monthInt, 1);
    
    // Weekday of the first day: 1 = Mon, ..., 7 = Sun
    // In our weekly header we have: Mon, Tue, Wed, Thu, Fri, Sat, Sun.
    // So the empty slots before the first day is (firstDayOfMonth.weekday - 1)
    final int emptySlots = firstDayOfMonth.weekday - 1;

    // Number of days in this month
    final int totalDays = DateTime(yearInt, monthInt + 1, 0).day;

    final List<CalendarDay> days = [];

    // Get previous month's total days to show inactive trailing numbers
    final prevMonthDate = DateTime(yearInt, monthInt, 0);
    final int prevMonthDays = prevMonthDate.day;

    // Fill preceding empty slots (inactive days from previous month)
    for (int i = emptySlots - 1; i >= 0; i--) {
      days.add(CalendarDay('${prevMonthDays - i}', 'inactive', isToday: false));
    }

    // Fill actual month days with database records
    for (int i = 1; i <= totalDays; i++) {
      final currentDayDate = DateTime(yearInt, monthInt, i);
      final weekday = currentDayDate.weekday;
      final isTodayCell = isCurrentMonthAndYear && (now.day == i);
      
      String status = 'H'; // Default to holiday if Sunday
      if (weekday != 7) {
        final String datePrefix = "${currentDayDate.year}-${currentDayDate.month.toString().padLeft(2, '0')}-${currentDayDate.day.toString().padLeft(2, '0')}";
        
        final record = dbRecords.firstWhere(
          (r) => r['date']?.toString().split('T')[0] == datePrefix,
          orElse: () => <String, dynamic>{},
        );
        
        if (record.isNotEmpty) {
          bool hasAbsent = false;
          bool hasPresent = false;
          bool hasOD = false;
          bool hasML = false;

          for (int p = 1; p <= 8; p++) {
            final val = record['p$p']?.toString().trim().toUpperCase() ?? '';
            if (val == 'A' || val == 'ABSENT' || val == 'FALSE' || val == '0') {
              hasAbsent = true;
            } else if (val == 'P' || val == 'PRESENT' || val == 'TRUE' || val == '1') {
              hasPresent = true;
            } else if (val == 'OD') {
              hasOD = true;
            } else if (val == 'ML') {
              hasML = true;
            }
          }
          if (hasAbsent) {
            status = 'A'; // Absent
          } else if (hasOD) {
            status = 'OD'; // On Duty
          } else if (hasML) {
            status = 'ML'; // Medical Leave
          } else if (hasPresent) {
            status = 'P'; // Present
          } else {
            status = '-';
          }
        } else {
          status = '-'; // Unmarked / No Record
        }
      }

      final isSelectedCell = (_selectedDayDate.year == yearInt && _selectedDayDate.month == monthInt && _selectedDayDate.day == i);
      days.add(CalendarDay('$i', status, isToday: isTodayCell, isSelected: isSelectedCell));
    }

    // Fill succeeding empty slots (inactive days from next month)
    final int totalCellsSoFar = days.length;
    final int remainingCells = (7 - (totalCellsSoFar % 7)) % 7;
    for (int i = 1; i <= remainingCells; i++) {
      days.add(CalendarDay('$i', 'inactive', isToday: false));
    }

    return days;
  }

  List<String> _getAvailableSemesters() {
    final appState = AppStateProvider.of(context);
    return appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
  }

  // Daily details dialog removed. Click updates Today's Period Status directly.

  List<Map<String, dynamic>> _getSemesterSubjectsFromDb() {
    try {
      final appState = AppStateProvider.of(context);
      final dbRecords = appState.attendanceRecords;
      final selectedSemInt = _romanToSubspaceInt(_selectedSem);
      final studentDept = appState.getProfileField('department', defaultValue: 'CSE').toString().trim().toUpperCase();

      // Get all matching regulations for this semester & department
      final activeRegs = appState.regulationsList.where((reg) {
        final regSem = int.tryParse(reg['semester']?.toString() ?? '') ?? 0;
        final regDept = reg['department']?.toString().toUpperCase() ?? '';
        return regSem == selectedSemInt && regDept == studentDept;
      }).toList();

      final Map<String, Map<String, dynamic>> subjectMap = {};

      // Seed with matching semester regulations courses
      for (var reg in activeRegs) {
        final code = (reg['course_code'] ?? '').toString().trim().toUpperCase();
        final name = (reg['course_name'] ?? '').toString().trim();
        if (code.isNotEmpty && name.isNotEmpty) {
          // Remove parentheses from subject names if they exist
          String cleanName = name;
          if (cleanName.contains('(') && cleanName.contains(')')) {
            final start = cleanName.indexOf('(');
            cleanName = cleanName.substring(0, start).trim();
          }
          subjectMap[code] = {
            'code': code,
            'name': cleanName,
            'present': 0,
            'absent': 0,
            'od': 0,
          };
        }
      }

      // Read from attendance logs/records to aggregate
      for (var rec in dbRecords) {
        if (rec['date'] == null) continue;
        for (int p = 1; p <= 8; p++) {
          final rawVal = (rec['p$p'] ?? '').toString().trim().toUpperCase();
          if (rawVal.isEmpty || rawVal == 'NULL') continue;

          String code = (rec['p${p}_code'] ?? '').toString().trim().toUpperCase();

          if (code.isEmpty || code.startsWith('P')) continue;

          // Only aggregate if it belongs to our seed subjects (for this semester)
          if (subjectMap.containsKey(code)) {
            if (rawVal == 'P' || rawVal == 'PRESENT' || rawVal == 'TRUE' || rawVal == '1') {
              subjectMap[code]!['present'] = (subjectMap[code]!['present'] as int) + 1;
            } else if (rawVal == 'A' || rawVal == 'ABSENT' || rawVal == 'FALSE' || rawVal == '0') {
              subjectMap[code]!['absent'] = (subjectMap[code]!['absent'] as int) + 1;
            } else if (rawVal == 'OD' || rawVal == 'ML') {
              subjectMap[code]!['od'] = (subjectMap[code]!['od'] as int) + 1;
            }
          }
        }
      }

      final List<Map<String, dynamic>> list = [];
      subjectMap.forEach((code, data) {
        final pres  = data['present'] as int;
        final abs   = data['absent']  as int;
        final od    = data['od']      as int;
        final total = pres + abs + od;
        final pct   = total > 0 ? (((pres + od) / total) * 100).round() : 100;

        // Resolve faculty name from facultyCourseAllocations
        String facultyName = 'Faculty';
        for (var alloc in appState.facultyCourseAllocations) {
          final allocCode = (alloc['course_code'] ?? '').toString().trim().toUpperCase();
          final allocFac = (alloc['assigned_fac_name'] ?? alloc['faculty_name'] ?? '').toString().trim();
          if (allocCode == code && allocFac.isNotEmpty) {
            facultyName = allocFac;
            break;
          }
        }

        // Hardcoded defaults fallback for known KSRCE staff if allocations are empty
        if (facultyName == 'Faculty') {
          if (code == '24CST51' || code == '24CST56') {
            facultyName = 'Dr. K. Ravichandran';
          } else if (code == '24CST57' || code == '24ADI51') {
            facultyName = 'Mr. P. Kalaiyarasan';
          } else if (code == '24ITT56') {
            facultyName = 'Mrs. S. Vinothini';
          }
        }

        list.add({
          'code': code,
          'name': data['name'],
          'faculty': facultyName,
          'present': pres,
          'absent': abs,
          'od': od,
          'pct': pct,
          'status': pct >= 85 ? 'Excellent' : (pct >= 75 ? 'Good' : 'Warning'),
        });
      });

      // Sort consistently by course code
      list.sort((a, b) => (a['code'] ?? '').toString().compareTo((b['code'] ?? '').toString()));
      return list;
    } catch (_) {
      return [];
    }
  }



  // Helper method to filter row data
  List<Map<String, dynamic>> _getFilteredRows() {
    final List<Map<String, dynamic>> subjects = _getSemesterSubjectsFromDb();
    if (subjects.isEmpty) {
      return [];
    }
    if (_searchQuery.isEmpty) return subjects;

    return subjects.where((sub) {
      final code = sub['code'].toString().toLowerCase();
      final name = sub['name'].toString().toLowerCase();
      final faculty = sub['faculty'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return code.contains(query) || name.contains(query) || faculty.contains(query);
    }).toList();
  }

  // Calculate Overall Attendance Dynamically
  double _calculateOverallAttendance() {
    final appState = AppStateProvider.of(context);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';
    if (!isCurrentActive) return 0.0;

    final dbRecords = appState.attendanceRecords;
    if (dbRecords.isNotEmpty) {
      double sum = 0;
      int count = 0;
      for (var r in dbRecords) {
        final pctVal = r['attendance_percentage'];
        if (pctVal != null) {
          final p = double.tryParse(pctVal.toString());
          if (p != null) {
            sum += p;
            count++;
          }
        }
      }
      if (count > 0) return sum / count;
    }

    final subjects = _getSemesterSubjectsFromDb();
    if (subjects.isEmpty) return 0.0;
    double sum = 0;
    for (var sub in subjects) {
      sum += (sub['pct'] as num).toDouble();
    }
    return sum / subjects.length;
  }

  // CSV Export Trigger
  void _triggerCsvExport() {
    final filtered = _getFilteredRows();
    String csv = 'Subject Code,Subject Name,Faculty,Present,Absent,OD,Percentage,Status\n';
    for (var row in filtered) {
      csv += '${row['code']},${row['name']},${row['faculty']},${row['present']},${row['absent']},${row['od']},${row['pct']}%,${row['status']}\n';
    }
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "attendance_report_${_selectedSem}_sem.csv")
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV Attendance Report downloaded successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final appState = AppStateProvider.of(context);
    
    if (appState.isLoading || _isLoading) {
      return const SizedBox(
        height: 500,
        child: Center(
          child: StudentLoadingWidget(
            size: 60,
            showMessage: false,
          ),
        ),
      );
    }

    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    if (!sems.contains(_selectedSem)) {
      _selectedSem = sems.first;
    }

    final overallPct = _calculateOverallAttendance();
    final overallPctStr = '${overallPct.toInt()}%';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header & Controls (Section and Programme dropdowns removed)
          _buildHeader(),
          const SizedBox(height: 8),

          // 2. Top Metric Cards
          _buildTopMetricsGrid(overallPctStr),
          const SizedBox(height: 20),

          // 3. Attendance Status Banner
          _buildStatusBanner(overallPctStr),
          const SizedBox(height: 20),

          // 4. Weekly Trend & Attendance Insights
          _buildTrendAndInsightsRow(overallPctStr),
          const SizedBox(height: 20),

          // 5. Detailed Attendance Table by Subject (Extended to fit the width)
          _buildDetailedAttendanceTable(),
          const SizedBox(height: 20),

          // 7. Today's Attendance Card (student.attendance_table)
          _buildTodayAttendanceCard(),
          const SizedBox(height: 20),

          // 8. Monthly Calendar
          _buildCalendarCard(),
          const SizedBox(height: 20),

          // 9. Stats, leave, alerts, internals, rules, faculty panel
          _buildBottomSection(isDesktop),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- 1. HEADER & CONTROLS (Section & Programme filters removed) ---
  Widget _buildHeader() {
    final appState = AppStateProvider.of(context);
    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const AcademicYearDropdown(),
          const SizedBox(width: 8),
          _buildPillDropdown<String>(
            icon: Icons.school_outlined,
            prefixText: 'SEMESTER',
            value: _selectedSem,
            items: sems,
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedSem = v);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillDropdown<T>({
    required IconData icon,
    required String prefixText,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB), size: 18),
          alignment: Alignment.center,
          onChanged: onChanged,
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((T val) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF2563EB), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '$prefixText ${val.toString().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items.map<DropdownMenuItem<T>>((T val) {
            return DropdownMenuItem<T>(
              value: val,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF2563EB), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '$prefixText ${val.toString().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
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

  Map<String, dynamic> _calculateDetailedAttendanceStats() {
    final appState = AppStateProvider.of(context);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';
    if (!isCurrentActive) {
      return {
        'theoryPct': 0,
        'labPct': 0,
        'present': 0,
        'absent': 0,
        'total': 0,
        'od': 0,
        'ml': 0,
      };
    }
    final dbRecords = appState.attendanceRecords;
    final dbTimetables = appState.timetables;

    int theoryTotal = 0;
    int theoryPresent = 0;
    int labTotal = 0;
    int labPresent = 0;
    int totalPresent = 0;
    int totalAbsent = 0;
    int totalOd = 0;
    int totalMl = 0;

    final Map<String, bool> isLabCode = {};
    for (var t in dbTimetables) {
      for (int i = 1; i <= 7; i++) {
        final code = t['period_$i']?.toString() ?? '';
        final name = (t['subject_name'] ?? '').toString().toLowerCase();
        if (code.isNotEmpty) {
          isLabCode[code] = name.contains('lab');
        }
      }
    }

    for (var rec in dbRecords) {
      for (int p = 1; p <= 8; p++) {
        final rawVal = rec['p$p']?.toString().trim().toUpperCase() ?? '';
        if (rawVal.isEmpty || rawVal == 'NULL') continue;

        if (rawVal == 'P' || rawVal == 'PRESENT' || rawVal == 'TRUE' || rawVal == '1') {
          totalPresent++;
          theoryPresent++;
          theoryTotal++;
        } else if (rawVal == 'OD') {
          totalOd++;
          totalPresent++;
          theoryPresent++;
          theoryTotal++;
        } else if (rawVal == 'ML') {
          totalMl++;
          totalPresent++;
          theoryPresent++;
          theoryTotal++;
        } else if (rawVal == 'A' || rawVal == 'ABSENT' || rawVal == 'FALSE' || rawVal == '0') {
          totalAbsent++;
          theoryTotal++;
        }
      }
    }

    final double theoryPct = theoryTotal > 0 ? (theoryPresent / theoryTotal) * 100 : (dbRecords.isNotEmpty ? 100.0 : 0.0);
    final double labPct = labTotal > 0 ? (labPresent / labTotal) * 100 : (dbRecords.isNotEmpty ? 100.0 : 0.0);
    final int overallPresent = totalPresent;
    final int overallTotal = totalPresent + totalAbsent;

    return {
      'theoryPct': theoryPct.round(),
      'labPct': labPct.round(),
      'present': overallPresent,
      'absent': totalAbsent,
      'total': overallTotal,
      'od': totalOd,
      'ml': totalMl,
    };
  }

  // --- 2. TOP METRICS GRID (Responsive without horizontal scrolling) ---
  Widget _buildTopMetricsGrid(String overallPctStr) {
    final stats = _calculateDetailedAttendanceStats();
    final int theoryPct = stats['theoryPct'] ?? 0;
    final int labPct = stats['labPct'] ?? 0;
    final int presentCount = stats['present'] ?? 0;
    final int absentCount = stats['absent'] ?? 0;
    final int totalCount = stats['total'] ?? 0;
    final int odCount = stats['od'] ?? 0;
    final int mlCount = stats['ml'] ?? 0;

    final cards = [
      _buildBigStatCard('Overall Attendance', overallPctStr, overallPctStr.replaceAll('%', '') == '0' ? '● Good' : '● Excellent', const Color(0xFF2563EB), const Color(0xFFEFF6FF), const Color(0xFF15803D), Icons.pie_chart_outline),
      _buildBigStatCard('Theory Attendance', '$theoryPct%', '$theoryPct' == '0' ? '● Good' : '● Excellent', const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFF9A3412), Icons.menu_book_outlined),
      _buildBigStatCard('Lab Attendance', '$labPct%', '$labPct' == '0' ? '● Good' : '● Excellent', const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFF9A3412), Icons.science_outlined),
      _buildSmallMetricCard('Classes Present', presentCount.toString(), 'of $totalCount', Icons.calendar_today_outlined, const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _buildSmallMetricCard('Classes Absent', absentCount.toString(), 'of $totalCount', Icons.cancel_outlined, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
      _buildSmallMetricCard('On Duty', odCount.toString(), 'of $totalCount', Icons.badge_outlined, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
      _buildSmallMetricCard('Leave Utilized', mlCount.toString(), 'Approved', Icons.assignment_turned_in_outlined, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        if (isDesktop) {
          final allCards = [
            _buildBigStatCard('Overall Attendance', overallPctStr, overallPctStr.replaceAll('%', '') == '0' ? '● Good' : '● Excellent', const Color(0xFF2563EB), const Color(0xFFEFF6FF), const Color(0xFF15803D), Icons.pie_chart_outline),
            _buildBigStatCard('Theory Attendance', '$theoryPct%', '$theoryPct' == '0' ? '● Good' : '● Excellent', const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFF9A3412), Icons.menu_book_outlined),
            _buildBigStatCard('Lab Attendance', '$labPct%', '$labPct' == '0' ? '● Good' : '● Excellent', const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFF9A3412), Icons.science_outlined),
            _buildSmallMetricCard('Classes Present', presentCount.toString(), 'of $totalCount', Icons.calendar_today_outlined, const Color(0xFF10B981), const Color(0xFFECFDF5)),
            _buildSmallMetricCard('Classes Absent', absentCount.toString(), 'of $totalCount', Icons.cancel_outlined, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
            _buildSmallMetricCard('On Duty', odCount.toString(), 'of $totalCount', Icons.badge_outlined, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
            _buildSmallMetricCard('Leave Utilized', mlCount.toString(), 'Approved', Icons.assignment_turned_in_outlined, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
          ];
          return Row(
            children: allCards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
          );
        } else {
          final row1Cards = [
            _buildBigStatCard('Overall Attendance', overallPctStr, overallPctStr.replaceAll('%', '') == '0' ? '● Good' : '● Excellent', const Color(0xFF2563EB), const Color(0xFFEFF6FF), const Color(0xFF15803D), Icons.pie_chart_outline),
            _buildBigStatCard('Theory Attendance', '$theoryPct%', '$theoryPct' == '0' ? '● Good' : '● Excellent', const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFF9A3412), Icons.menu_book_outlined),
            _buildBigStatCard('Lab Attendance', '$labPct%', '$labPct' == '0' ? '● Good' : '● Excellent', const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFF9A3412), Icons.science_outlined),
          ];

          final row2Cards = [
            _buildSmallMetricCard('Classes Present', presentCount.toString(), 'of $totalCount', Icons.calendar_today_outlined, const Color(0xFF10B981), const Color(0xFFECFDF5)),
            _buildSmallMetricCard('Classes Absent', absentCount.toString(), 'of $totalCount', Icons.cancel_outlined, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
            _buildSmallMetricCard('On Duty', odCount.toString(), 'of $totalCount', Icons.badge_outlined, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
            _buildSmallMetricCard('Leave Utilized', mlCount.toString(), 'Approved', Icons.assignment_turned_in_outlined, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
          ];

          return Column(
            children: [
              Row(
                children: row1Cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: row2Cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildBigStatCard(String title, String val, String status, Color iconCol, Color iconBg, Color statusText, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(status, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: statusText), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSmallMetricCard(String title, String val, String sub, IconData icon, Color col, Color iconBg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(sub, style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // --- 3. STATUS BANNER ---
  Widget _buildStatusBanner(String overallPctStr) {
    final double pct = double.tryParse(overallPctStr.replaceAll('%', '')) ?? 0.0;
    final bool isEligible = pct >= 75.0;
    final String standing = pct >= 85.0 ? 'Excellent Standing' : (pct >= 75.0 ? 'Good Standing' : 'Low Standing');
    final Color mainColor = isEligible ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final Color bgColor = isEligible ? const Color(0xFFFEF2F2) : const Color(0xFFFEF2F2);
    final Color borderColor = isEligible ? const Color(0xFFFECACA) : const Color(0xFFFECACA);
    final Color textColor = isEligible ? const Color(0xFF991B1B) : const Color(0xFF991B1B);

    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    final statusLeft = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: mainColor, shape: BoxShape.circle),
          child: Icon(isEligible ? Icons.verified : Icons.warning_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Attendance Status', style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('$overallPctStr $standing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
          ],
        ),
      ],
    );

    final minReq = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Minimum Required', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('75%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
      ],
    );

    final eligibilityBadge = Container(
      width: isDesktop ? null : double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: isDesktop ? 24 : 12),
      decoration: BoxDecoration(
        color: mainColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isEligible ? Icons.check_circle_rounded : Icons.cancel, color: mainColor, size: 18),
          const SizedBox(width: 6),
          Text(
            isEligible ? 'Eligible for Examination' : 'Not Eligible for Examination',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mainColor),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                statusLeft,
                eligibilityBadge,
                minReq,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    statusLeft,
                    minReq,
                  ],
                ),
                const SizedBox(height: 16),
                eligibilityBadge,
              ],
            ),
    );
  }

  // --- 4. WEEKLY TREND & INSIGHTS ---
  Map<String, double> _calculateWeeklyTrend() {
    final appState = AppStateProvider.of(context);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';

    if (!isCurrentActive) {
      return {
        'Mon': 0.0,
        'Tue': 0.0,
        'Wed': 0.0,
        'Thu': 0.0,
        'Fri': 0.0,
      };
    }

    final dbRecords = appState.attendanceRecords;
    
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    
    final Map<int, List<bool>> weekdayAttendance = {
      DateTime.monday: [],
      DateTime.tuesday: [],
      DateTime.wednesday: [],
      DateTime.thursday: [],
      DateTime.friday: [],
    };
    
    for (var r in dbRecords) {
      if (r['date'] == null) continue;
      DateTime? dt;
      try { dt = DateTime.parse(r['date'].toString()); } catch(_) {}
      if (dt == null) continue;
      
      if (dt.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && dt.isBefore(startOfWeek.add(const Duration(days: 6)))) {
        final list = weekdayAttendance[dt.weekday];
        if (list != null) {
          for (int p = 1; p <= 7; p++) {
            final val = r['p$p'];
            if (val == true) {
              list.add(true);
            } else if (val == false) {
              list.add(false);
            }
          }
        }
      }
    }
    
    final Map<String, double> result = {};
    weekdayAttendance.forEach((dayCode, list) {
      final String label = dayCode == DateTime.monday ? 'Mon' :
                           dayCode == DateTime.tuesday ? 'Tue' :
                           dayCode == DateTime.wednesday ? 'Wed' :
                           dayCode == DateTime.thursday ? 'Thu' : 'Fri';
      if (list.isEmpty) {
        result[label] = 100.0;
      } else {
        final int pres = list.where((x) => x).length;
        result[label] = (pres / list.length) * 100;
      }
    });
    return result;
  }

  Widget _buildTrendAndInsightsRow(String overallPctStr) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final trend = _calculateWeeklyTrend();
    final monVal = trend['Mon']?.round() ?? 100;
    final tueVal = trend['Tue']?.round() ?? 100;
    final wedVal = trend['Wed']?.round() ?? 100;
    final thuVal = trend['Thu']?.round() ?? 100;
    final friVal = trend['Fri']?.round() ?? 100;

    final subjects = _getSemesterSubjectsFromDb();
    
    String bestSubject = 'None';
    String bestPct = '0%';
    String lowestSubject = 'None';
    String lowestPct = '0%';
    String atRisk = 'None';
    String atRiskStatus = '✓ Safe';
    Color atRiskColor = const Color(0xFF16A34A);

    if (subjects.isNotEmpty) {
      final sorted = List<Map<String, dynamic>>.from(subjects);
      sorted.sort((a, b) => (b['pct'] as num).compareTo(a['pct'] as num));
      bestSubject = sorted.first['code'] ?? '';
      bestPct = '${sorted.first['pct']}% ↑';
      
      lowestSubject = sorted.last['code'] ?? '';
      lowestPct = '${sorted.last['pct']}% ↓';
      
      final atRiskList = sorted.where((s) => (s['pct'] as num) < 75.0).map((s) => s['code']?.toString() ?? '').toList();
      if (atRiskList.isNotEmpty) {
        atRisk = atRiskList.join(', ');
        atRiskStatus = '⚠ Low';
        atRiskColor = const Color(0xFFDC2626);
      }
    }

    final trendCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Weekly Attendance Trend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('This Week', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarCol('Mon', monVal),
                _buildBarCol('Tue', tueVal),
                _buildBarCol('Wed', wedVal),
                _buildBarCol('Thu', thuVal),
                _buildBarCol('Fri', friVal),
              ],
            ),
          ),
        ],
      ),
    );

    final insightsCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Attendance Insights', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('This Month', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInsightBox('Best Subject', bestSubject, bestPct, const Color(0xFF16A34A))),
              const SizedBox(width: 8),
              Expanded(child: _buildInsightBox('Lowest Subject', lowestSubject, lowestPct, const Color(0xFFDC2626))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildInsightBox('Average Attendance', overallPctStr, '', const Color(0xFF1D4ED8))),
              const SizedBox(width: 8),
              Expanded(child: _buildInsightBox('At Risk Subjects', atRisk, atRiskStatus, atRiskColor)),
            ],
          ),
        ],
      ),
    );

    if (!isDesktop) {
      return Column(
        children: [
          trendCard,
          const SizedBox(height: 16),
          insightsCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: trendCard),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: insightsCard),
      ],
    );
  }

  Widget _buildBarCol(String day, int pct) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$pct%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: pct * 1.0,
          decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 6),
        Text(day, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildInsightBox(String label, String subject, String val, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subject, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (val.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // --- 5. SUBJECT-WISE ATTENDANCE CARDS ---
  Widget _buildSubjectWiseSection() {
    final filtered = _getFilteredRows();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Subject-wise Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: filtered.map((sub) {
            final color = sub['status'] == 'Warning' ? const Color(0xFFEA580C) : const Color(0xFF16A34A);
            return _buildSubjectCard(
              sub['name'],
              sub['code'],
              '${sub['pct']}%',
              '${sub['present']} / ${sub['present'] + sub['absent']}',
              sub['status'],
              sub['faculty'],
              color,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(String title, String code, String pct, String classes, String status, String faculty, Color statusCol) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(code, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(pct, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(classes, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: double.parse(pct.replaceAll('%', '')) / 100, minHeight: 5, backgroundColor: const Color(0xFFE2E8F0), valueColor: AlwaysStoppedAnimation<Color>(statusCol)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusCol)),
              Text(faculty, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. DETAILED TABLE (Stretched to take full card width) ---
  Widget _buildDetailedAttendanceTable() {
    final filtered = _getFilteredRows();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktopHeader = constraints.maxWidth >= 850;

              final searchBarWidget = SizedBox(
                height: 40,
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search subject...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    fillColor: Colors.white,
                    filled: true,
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
                  ),
                ),
              );

              final actionButtonsWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _triggerCsvExport,
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text('Export', style: TextStyle(fontSize: 11)),
                  ),
                ],
              );

              if (isDesktopHeader) {
                return Row(
                  children: [
                    const Text(
                      'Detailed Attendance by Subject',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: searchBarWidget),
                    const SizedBox(width: 16),
                    actionButtonsWidget,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detailed Attendance by Subject', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: searchBarWidget),
                      const SizedBox(width: 12),
                      actionButtonsWidget,
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowHeight: 30,
                    dataRowHeight: 36,
                    headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Subject Code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Subject Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Faculty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Present', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Absent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('OD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Percentage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((sub) {
                      final statusCol = sub['status'] == 'Warning' ? const Color(0xFF92400E) : const Color(0xFF166534);
                      final statusBg = sub['status'] == 'Warning' ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7);
                      return _buildTableRow(
                        sub['code'],
                        sub['name'],
                        sub['faculty'],
                        '${sub['present']}',
                        '${sub['absent']}',
                        '${sub['od']}',
                        '${sub['pct']}%',
                        sub['status'],
                        statusBg,
                        statusCol,
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  DataRow _buildTableRow(String code, String name, String faculty, String p, String a, String od, String pct, String status, Color bg, Color textCol) {
    return DataRow(cells: [
      DataCell(Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
      DataCell(Text(name, style: const TextStyle(fontSize: 11))),
      DataCell(Text(faculty, style: const TextStyle(fontSize: 11))),
      DataCell(Text(p, style: const TextStyle(fontSize: 11))),
      DataCell(Text(a, style: const TextStyle(fontSize: 11, color: Colors.red))),
      DataCell(Text(od, style: const TextStyle(fontSize: 11))),
      DataCell(Text(pct, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
          child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textCol)),
        ),
      ),
    ]);
  }

  // --- TODAY'S / SELECTED DAY'S ATTENDANCE STATUS CARD (student.attendance_table) ---
  Widget _buildTodayAttendanceCard() {
    final appState = AppStateProvider.of(context);
    final isCurrentActive = appState.isCurrentAcademicYear && _selectedSem == 'V';
    final dbRecords = isCurrentActive ? appState.attendanceRecords : const [];
    final dbTimetables = appState.timetables;
    final now = DateTime.now();
    
    final isToday = (now.year == _selectedDayDate.year && now.month == _selectedDayDate.month && now.day == _selectedDayDate.day);
    final selectedPrefix = "${_selectedDayDate.year}-${_selectedDayDate.month.toString().padLeft(2, '0')}-${_selectedDayDate.day.toString().padLeft(2, '0')}";
    final selectedFormatted = "${_selectedDayDate.day} ${_calendarMonths[_selectedDayDate.month - 1]} ${_selectedDayDate.year}";
    final titleText = isToday ? "Today's Period Status ($selectedFormatted)" : "Period Status ($selectedFormatted)";

    final record = isCurrentActive
        ? dbRecords.firstWhere(
            (r) => r['date']?.toString().split('T')[0] == selectedPrefix,
            orElse: () => <String, dynamic>{},
          )
        : <String, dynamic>{};

    // Get selected day's name and build subject lookup from timetable
    String dayName = '';
    switch (_selectedDayDate.weekday) {
      case DateTime.monday: dayName = 'monday'; break;
      case DateTime.tuesday: dayName = 'tuesday'; break;
      case DateTime.wednesday: dayName = 'wednesday'; break;
      case DateTime.thursday: dayName = 'thursday'; break;
      case DateTime.friday: dayName = 'friday'; break;
      case DateTime.saturday: dayName = 'saturday'; break;
      case DateTime.sunday: dayName = 'sunday'; break;
    }

    final defaultPeriodCodes = {
      1: '24CST51',
      2: '24CST57',
      3: '24ADI51',
      4: '24CST56',
      5: '24ITT56',
      6: '24CST51',
      7: '24CST57',
      8: '24ADI51',
    };

    final defaultSubjectNames = {
      '24CST51': 'Data Warehousing and Data Mining',
      '24CST56': 'Full Stack Development',
      '24CST57': 'Principles of Compiler Design',
      '24ADI51': 'Artificial Intelligence',
      '24ITT56': 'Computer Networks',
    };

    final defaultFaculties = {
      '24CST51': 'Dr. K. Ravichandran',
      '24CST56': 'Dr. K. Ravichandran',
      '24CST57': 'Mr. P. Kalaiyarasan',
      '24ADI51': 'Mr. P. Kalaiyarasan',
      '24ITT56': 'Mrs. S. Vinothini',
    };

    final Map<int, String> periodSubjectCode = {};
    final Map<String, String> subjectNames = {};
    for (var t in dbTimetables) {
      final day = (t['day_of_week'] ?? '').toString().trim().toLowerCase();
      if (day == dayName || day == dayName.substring(0, 3)) {
        for (int i = 1; i <= 8; i++) {
          final code = t['period_$i']?.toString() ?? '';
          if (code.isNotEmpty) {
            periodSubjectCode[i] = code;
            subjectNames[code] = t['subject_name']?.toString() ?? code;
          }
        }
      }
    }

    final List<Widget> periodCards = [];

    for (int p = 1; p <= 8; p++) {
      final rawVal = record['p$p']?.toString().trim().toUpperCase() ?? '';
      
      String displayVal = '-';
      String ratioText = '-';
      double progress = 0.0;
      Color barCol = const Color(0xFFE2E8F0);
      String statusText = '-';
      Color statusCol = const Color(0xFF94A3B8);

      if (rawVal == 'P' || rawVal == 'PRESENT' || rawVal == 'TRUE' || rawVal == '1') {
        displayVal = '100%';
        ratioText = '1 / 1';
        progress = 1.0;
        barCol = const Color(0xFF22C55E);
        statusText = 'Present';
        statusCol = const Color(0xFF16A34A);
      } else if (rawVal == 'A' || rawVal == 'ABSENT' || rawVal == 'FALSE' || rawVal == '0') {
        displayVal = '0%';
        ratioText = '0 / 1';
        progress = 0.0;
        barCol = const Color(0xFFEF4444);
        statusText = 'Absent';
        statusCol = const Color(0xFFDC2626);
      } else if (rawVal == 'OD') {
        displayVal = '100%';
        ratioText = '1 / 1';
        progress = 1.0;
        barCol = const Color(0xFFF97316);
        statusText = 'On Duty';
        statusCol = const Color(0xFFC2410C);
      } else if (rawVal == 'ML') {
        displayVal = '100%';
        ratioText = '1 / 1';
        progress = 1.0;
        barCol = const Color(0xFF3B82F6);
        statusText = 'Medical Leave';
        statusCol = const Color(0xFF1D4ED8);
      } else if (_selectedDayDate.weekday == 7) {
        displayVal = '-';
        ratioText = '-';
        progress = 0.0;
        barCol = const Color(0xFFCBD5E1);
        statusText = 'Sunday';
        statusCol = const Color(0xFF64748B);
      } else {
        // null or empty -> show '-'
        displayVal = '-';
        ratioText = '-';
        progress = 0.0;
        barCol = const Color(0xFFCBD5E1);
        statusText = 'Unmarked';
        statusCol = const Color(0xFF94A3B8);
      }

      // Get subject name and code for this period
      final subCode = isCurrentActive ? (periodSubjectCode[p] ?? defaultPeriodCodes[p] ?? '') : '';
      final subName = isCurrentActive 
          ? (subjectNames[subCode] ?? defaultSubjectNames[subCode] ?? (subCode.isNotEmpty ? subCode : 'Period $p'))
          : 'Free Period';
      final String periodTitle = subName;
      final String periodSubtitle = subCode.isNotEmpty ? 'P$p • $subCode' : 'Period $p';

      // Resolve Faculty name
      String facultyName = 'Faculty Incharge';
      if (isCurrentActive) {
        facultyName = defaultFaculties[subCode] ?? 'Faculty Professor';
        for (var alloc in appState.facultyCourseAllocations) {
          final allocCode = (alloc['course_code'] ?? '').toString().trim();
          final allocFac = (alloc['assigned_fac_name'] ?? alloc['faculty_name'] ?? '').toString().trim();
          if (allocCode == subCode && allocFac.isNotEmpty) {
            facultyName = allocFac;
            break;
          }
        }
      }

      periodCards.add(
        Container(
          width: 210,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top title & subtitle - Subject Name (Code)
              Text(
                periodTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                periodSubtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Main value & count ratio
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    displayVal,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: displayVal == '-' ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(ratioText, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(barCol),
                ),
              ),
              const SizedBox(height: 10),

              // Footer: Status label & Faculty Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusCol),
                  ),
                  Expanded(
                    child: Text(
                      facultyName,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titleText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const Text('Periods P1 – P8', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: periodCards.map((c) => Padding(padding: const EdgeInsets.only(right: 12), child: c)).toList(),
          ),
        ),
      ],
    );
  }

  int _getMonthInt(String monthName) {
    const months = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12
    };
    return months[monthName] ?? DateTime.now().month;
  }

  // --- 7. CALENDAR CARD ---
  Widget _buildCalendarCard() {
    final calendarDays = _generateCalendarDays();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Monthly Attendance Calendar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final initialYear = int.tryParse(_selectedCalendarYear) ?? DateTime.now().year;
                  final initialMonth = _getMonthInt(_selectedCalendarMonth);
                  final selected = await showMonthYearPicker(
                    context: context,
                    initialDate: DateTime(initialYear, initialMonth, 1),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (selected != null) {
                    final monthNames = [
                      'January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'
                    ];
                    setState(() {
                      _selectedCalendarMonth = monthNames[selected.month - 1];
                      _selectedCalendarYear = selected.year.toString();
                      _selectedDayDate = DateTime(selected.year, selected.month, 1);
                    });
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: Color(0xFF2563EB), size: 15),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedCalendarMonth.toUpperCase()} $_selectedCalendarYear',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Text('Mon', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)))),
              Expanded(child: Text('Tue', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)))),
              Expanded(child: Text('Wed', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)))),
              Expanded(child: Text('Thu', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)))),
              Expanded(child: Text('Fri', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)))),
              Expanded(child: Text('Sat', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)))),
              Expanded(child: Text('Sun', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)))),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: isDesktop ? 1.85 : 1.3,
            ),
            itemCount: calendarDays.length,
            itemBuilder: (context, index) {
              final day = calendarDays[index];
              return InkWell(
                onTap: () {
                  if (day.status == 'inactive') return;
                  final dNum = int.tryParse(day.text);
                  if (dNum != null) {
                    final monthInt = _getMonthInt(_selectedCalendarMonth);
                    final yearInt = int.tryParse(_selectedCalendarYear) ?? DateTime.now().year;
                    setState(() {
                      _selectedDayDate = DateTime(yearInt, monthInt, dNum);
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: _buildCalendarCell(day),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(CalendarDay day) {
    Color bg = Colors.transparent;
    Color textCol = const Color(0xFF0F172A);
    FontWeight fontWeight = FontWeight.w600;
    Border? border;

    switch (day.status) {
      case 'P':
        bg = const Color(0xFFDCFCE7);
        textCol = const Color(0xFF16A34A);
        fontWeight = FontWeight.bold;
        break;
      case 'A':
        bg = const Color(0xFFFEE2E2);
        textCol = const Color(0xFFEF4444);
        fontWeight = FontWeight.bold;
        break;
      case 'OD':
        bg = const Color(0xFFFFEDD5);
        textCol = const Color(0xFFC2410C);
        fontWeight = FontWeight.bold;
        break;
      case 'ML':
        bg = const Color(0xFFDBEAFE);
        textCol = const Color(0xFF1D4ED8);
        fontWeight = FontWeight.bold;
        break;
      case 'H':
        bg = const Color(0xFFF1F5F9);
        textCol = const Color(0xFF64748B);
        fontWeight = FontWeight.w500;
        break;
      case 'inactive':
        bg = Colors.transparent;
        textCol = const Color(0xFF94A3B8);
        fontWeight = FontWeight.w500;
        break;
      default:
        bg = Colors.transparent;
        textCol = const Color(0xFF0F172A);
        fontWeight = FontWeight.w600;
        break;
    }

    if (day.isSelected) {
      bg = Colors.white;
      border = Border.all(color: const Color(0xFF2563EB), width: 2);
      textCol = const Color(0xFF2563EB);
      fontWeight = FontWeight.bold;
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Text(
        day.text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: fontWeight,
          color: textCol,
        ),
      ),
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

                    // Dialog Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, null),
                            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, DateTime(selectedYear, selectedMonth, 1));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildLegendItem(String label, Color col) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
      ],
    );
  }

  Widget _buildBottomSection(bool isDesktop) {
    return const SizedBox.shrink();
  }

  Widget _buildStatMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildLeaveCountRow(String label, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
            ],
          ),
          Text(count, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final appState = AppStateProvider.of(context);
    final totalDays = appState.attendanceRecords.length;
    
    int presentDays = 0;
    int absentDays = 0;
    int odDays = 0;
    for (var r in appState.attendanceRecords) {
      bool hasAbsent = false;
      bool hasPresent = false;
      for (int p = 1; p <= 7; p++) {
        if (r['p$p'] == true) hasPresent = true;
        if (r['p$p'] == false) hasAbsent = true;
      }
      if (hasAbsent) {
        absentDays++;
      } else if (hasPresent) {
        presentDays++;
      } else {
        odDays++;
      }
    }
    
    final double pct = totalDays > 0 ? (presentDays / totalDays) * 100 : 100.0;
    final String pctStr = '${pct.round()}%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Semester Statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Semester $_selectedSem', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          const SizedBox(height: 16),
          _buildStatMetricRow('Working Days', totalDays.toString()),
          _buildStatMetricRow('Classes Held', totalDays.toString()),
          _buildStatMetricRow('Present', presentDays.toString()),
          _buildStatMetricRow('Absent', absentDays.toString()),
          _buildStatMetricRow('On Duty', odDays.toString()),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attendance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                Text(pctStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              Text('Count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ],
          ),
          const Divider(),
          _buildLeaveCountRow('Medical Leave', ''),
          _buildLeaveCountRow('On Duty', ''),
          _buildLeaveCountRow('Permission', ''),
          _buildLeaveCountRow('Late Entry', ''),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFDCFCE7))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Approved', style: TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFEDD5))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Pending', style: TextStyle(fontSize: 11, color: Color(0xFF9A3412), fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Important Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),
          _buildAlertBadge('', isWarning: true),
          _buildAlertBadge('', isWarning: false),
          _buildAlertBadge('', isWarning: false),
          _buildAlertBadge('', isWarning: true),
          const SizedBox(height: 10),
          const Center(
            child: Text('View All Alerts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalsCard() {
    final appState = AppStateProvider.of(context);
    final subjects = _getSemesterSubjectsFromDb();
    final dbMarks = appState.marksList;

    final List<Widget> list = [];
    for (var sub in subjects) {
      final code = sub['code']?.toString() ?? '';
      final name = sub['name']?.toString() ?? '';
      final pct = '${sub['pct']}%';
      
      String marksText = '- / 50';
      for (var row in dbMarks) {
        final rowSub = (row['subject'] ?? '').toString();
        final rowSubCode = (row['subject_code'] ?? '').toString();
        if (rowSubCode == code || rowSub.contains(code) || rowSub.contains(name)) {
          final cia = row['cia']?.toString() ?? '-';
          final assignment = row['assignment']?.toString() ?? '-';
          final lab = row['lab']?.toString() ?? '-';
          final project = row['project']?.toString() ?? '-';
          final double ciaVal = double.tryParse(cia) ?? 0.0;
          final double assignVal = double.tryParse(assignment) ?? 0.0;
          final double labVal = double.tryParse(lab) ?? 0.0;
          final double projVal = double.tryParse(project) ?? 0.0;
          final double internalVal = ciaVal + assignVal + labVal + projVal;
          marksText = '${internalVal.round()} / 50';
          break;
        }
      }
      
      list.add(_buildInternalMarksRow('$name ($code)', pct, marksText));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Internal Marks & Attendance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                flex: 4,
                child: Text('Subject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.center,
                  child: Text('Attendance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Internal Marks', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ),
              ),
            ],
          ),
          const Divider(),
          if (subjects.isEmpty)
            const SizedBox(
              height: 100,
              child: Center(
                child: Text('No attendance or marks data found.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ),
            )
          else
            ...list,
          const SizedBox(height: 12),
          const Center(
            child: Text('Good attendance improves internal marks.', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    final appState = AppStateProvider.of(context);
    final totalDays = appState.attendanceRecords.length;
    
    int presentDays = 0;
    for (var r in appState.attendanceRecords) {
      bool hasAbsent = false;
      bool hasPresent = false;
      for (int p = 1; p <= 7; p++) {
        if (r['p$p'] == true) hasPresent = true;
        if (r['p$p'] == false) hasAbsent = true;
      }
      if (!hasAbsent && hasPresent) {
        presentDays++;
      }
    }
    
    final double pct = totalDays > 0 ? (presentDays / totalDays) * 100 : 100.0;
    final double safeMargin = (pct - 75.0).clamp(0.0, 100.0);
    
    int canMiss = 0;
    if (pct >= 75.0 && totalDays > 0) {
      canMiss = ((presentDays / 0.75) - totalDays).floor();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Attendance Rules', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Icon(Icons.shield_outlined, size: 16, color: Color(0xFF2563EB)),
            ],
          ),
          const SizedBox(height: 8),
          _buildRuleRow('Minimum Required', '%', const Color(0xFF0F172A)),
          _buildRuleRow('Current Attendance', '${pct.round()}%', const Color(0xFF16A34A)),
          _buildRuleRow('Safe Margin', '${safeMargin.round()}%', const Color(0xFF16A34A)),
          _buildRuleRow('Can Miss', '$canMiss More Classes', const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildFacultyPanelCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Faculty Attendance Panel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop&q=80'), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text('', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const Divider(height: 14),
          const Text('Attendance Updated', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          const Text('Today, ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.email_outlined, size: 12, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text('', style: TextStyle(fontSize: 10.5, color: Color(0xFF2563EB))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text('', style: TextStyle(fontSize: 10.5, color: Color(0xFF334155))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String label, String value, Color col) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: col)),
        ],
      ),
    );
  }

  Widget _buildInternalMarksRow(String subject, String att, String marks) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.center,
              child: _buildAttendanceCell(att),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(marks, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCell(String att) {
    final pctVal = double.tryParse(att.replaceAll('%', '')) ?? 0.0;
    final isLow = pctVal < 75;
    final attColor = isLow ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final icon = isLow ? Icons.cancel : Icons.check_circle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(att, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: attColor)),
        const SizedBox(width: 4),
        Icon(icon, size: 14, color: attColor),
      ],
    );
  }

  Widget _buildAlertBadge(String text, {required bool isWarning}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isWarning ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline, size: 14, color: isWarning ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isWarning ? const Color(0xFF78350F) : const Color(0xFF14532D)),
            ),
          ),
        ],
      ),
    );
  }
}
