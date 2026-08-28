import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PremiumDatePickerMode { single, range }

class PremiumDatePickerDialog extends StatefulWidget {
  final PremiumDatePickerMode mode;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String leaveType;
  final int initialLeaveBalance;
  final List<Map<String, dynamic>> existingLeaves;
  final bool disablePastDates;

  const PremiumDatePickerDialog({
    super.key,
    required this.mode,
    this.initialStartDate,
    this.initialEndDate,
    this.leaveType = 'Casual Leave',
    this.initialLeaveBalance = 10,
    required this.existingLeaves,
    this.disablePastDates = true,
  });

  static Future<Map<String, DateTime?>?> show({
    required BuildContext context,
    required PremiumDatePickerMode mode,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    String leaveType = 'Casual Leave',
    int initialLeaveBalance = 10,
    required List<Map<String, dynamic>> existingLeaves,
    bool disablePastDates = true,
  }) {
    return showGeneralDialog<Map<String, DateTime?>?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurveTween(curve: Curves.easeOutBack).animate(anim1);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: PremiumDatePickerDialog(
              mode: mode,
              initialStartDate: initialStartDate,
              initialEndDate: initialEndDate,
              leaveType: leaveType,
              initialLeaveBalance: initialLeaveBalance,
              existingLeaves: existingLeaves,
              disablePastDates: disablePastDates,
            ),
          ),
        );
      },
    );
  }

  @override
  State<PremiumDatePickerDialog> createState() =>
      _PremiumDatePickerDialogState();
}

class _PremiumDatePickerDialogState extends State<PremiumDatePickerDialog> {
  late DateTime _focusedMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isSelectingEndDate = false;
  bool _saturdayIsWorking = false;

  // Mock College Holidays (MM-DD format for annual recurring, or exact date)
  final Map<String, String> _annualHolidays = {
    '01-01': 'New Year\'s Day',
    '01-26': 'Republic Day',
    '05-01': 'May Day',
    '08-15': 'Independence Day',
    '10-02': 'Gandhi Jayanti',
    '12-25': 'Christmas Day',
  };

  // Specific exact date holidays
  final Map<DateTime, String> _specificHolidays = {
    DateTime(2026, 11, 10): 'Deepavali',
    DateTime(2026, 6, 1): 'College Foundation Day',
  };

  // Semester break range: June 15, 2026 to June 30, 2026
  final DateTime _semBreakStart = DateTime(2026, 6, 15);
  final DateTime _semBreakEnd = DateTime(2026, 6, 30);

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _focusedMonth = _startDate ?? DateTime.now();
    if (widget.mode == PremiumDatePickerMode.range &&
        _startDate != null &&
        _endDate == null) {
      _isSelectingEndDate = true;
    }
  }

  // ─── Validations ───
  String? _getDisabledReason(DateTime date) {
    final isSick =
        widget.leaveType == 'Sick Leave' || widget.leaveType == 'Medical Leave';

    // 1. Past dates (Sick Leave permits retroactive application up to past 30 days)
    if (widget.disablePastDates) {
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      if (isSick) {
        final thirtyDaysAgo = todayMidnight.subtract(const Duration(days: 30));
        if (date.isBefore(thirtyDaysAgo)) {
          return 'Exceeds 30 days prior';
        }
      } else {
        if (date.isBefore(todayMidnight)) {
          return 'Past Date';
        }
      }
    }

    // 2. Weekends (if Saturday is not working or it's Sunday)
    if (date.weekday == DateTime.sunday) {
      return 'Sunday Weekend';
    }
    if (date.weekday == DateTime.saturday && !_saturdayIsWorking) {
      return 'Saturday Weekend';
    }

    // 3. College Holidays (annual)
    final mmdd =
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_annualHolidays.containsKey(mmdd)) {
      return 'Holiday: ${_annualHolidays[mmdd]}';
    }

    // Specific Holidays
    final midnightDate = DateTime(date.year, date.month, date.day);
    if (_specificHolidays.containsKey(midnightDate)) {
      return 'Holiday: ${_specificHolidays[midnightDate]}';
    }

    // 4. Semester Break
    if (date.isAfter(_semBreakStart.subtract(const Duration(days: 1))) &&
        date.isBefore(_semBreakEnd.add(const Duration(days: 1)))) {
      return 'Semester Break';
    }

    // 5. Approved Leave Overlap
    for (final leave in widget.existingLeaves) {
      if (leave['status'] == 'Approved' ||
          leave['status'] == 'Approved automatically') {
        final fStr = leave['fromDate'] as String?;
        final tStr = leave['toDate'] as String?;
        if (fStr != null && tStr != null) {
          final fDate = _parseDate(fStr);
          final tDate = _parseDate(tStr);
          if (fDate != null && tDate != null) {
            if (date.isAfter(fDate.subtract(const Duration(days: 1))) &&
                date.isBefore(tDate.add(const Duration(days: 1)))) {
              return 'Leave Overlap (ID: ${leave['id']})';
            }
          }
        }
      }
    }

    return null;
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          // YYYY-MM-DD
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          // DD-MM-YYYY or DD/MM/YYYY
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  // ─── Calculations ───
  Map<String, int> _calculateCounts() {
    if (_startDate == null) {
      return {'working': 0, 'weekend': 0, 'holiday': 0, 'total': 0};
    }
    final end = _endDate ?? _startDate!;
    int total = end.difference(_startDate!).inDays + 1;
    int working = 0;
    int weekend = 0;
    int holiday = 0;

    for (int i = 0; i < total; i++) {
      final current = _startDate!.add(Duration(days: i));

      // Check if it's weekend
      bool isWeekend = false;
      if (current.weekday == DateTime.sunday) {
        isWeekend = true;
      } else if (current.weekday == DateTime.saturday && !_saturdayIsWorking) {
        isWeekend = true;
      }

      if (isWeekend) {
        weekend++;
        continue;
      }

      // Check if it's holiday
      final mmdd =
          '${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      final midnight = DateTime(current.year, current.month, current.day);
      bool isHoliday =
          _annualHolidays.containsKey(mmdd) ||
          _specificHolidays.containsKey(midnight);

      if (isHoliday) {
        holiday++;
        continue;
      }

      // If semester break
      if (current.isAfter(_semBreakStart.subtract(const Duration(days: 1))) &&
          current.isBefore(_semBreakEnd.add(const Duration(days: 1)))) {
        holiday++; // counts as academic non-working day / holiday
        continue;
      }

      working++;
    }

    return {
      'working': working,
      'weekend': weekend,
      'holiday': holiday,
      'total': total,
    };
  }

  // ─── Interaction Handlers ───
  void _onDateClick(DateTime date) {
    final reason = _getDisabledReason(date);
    if (reason != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Date disabled: $reason'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.mode == PremiumDatePickerMode.single) {
      setState(() {
        _startDate = date;
        _endDate = date;
      });
      return;
    }

    // Range selection flow
    if (!_isSelectingEndDate || _startDate == null) {
      setState(() {
        _startDate = date;
        _endDate = null;
        _isSelectingEndDate = true;
      });
    } else {
      if (date.isBefore(_startDate!)) {
        setState(() {
          _startDate = date;
          _endDate = null;
          _isSelectingEndDate = true;
        });
      } else {
        setState(() {
          _endDate = date;
          _isSelectingEndDate = false;
        });
      }
    }
  }

  void _applyQuickAction(String action) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    switch (action) {
      case 'Today':
        setState(() {
          _startDate = todayMidnight;
          _endDate = todayMidnight;
          _focusedMonth = todayMidnight;
          _isSelectingEndDate = false;
        });
        break;
      case 'Tomorrow':
        final tomorrow = todayMidnight.add(const Duration(days: 1));
        setState(() {
          _startDate = tomorrow;
          _endDate = tomorrow;
          _focusedMonth = tomorrow;
          _isSelectingEndDate = false;
        });
        break;
      case 'Next Monday':
        int daysUntilMonday = DateTime.monday - todayMidnight.weekday;
        if (daysUntilMonday <= 0) daysUntilMonday += 7;
        final nextMonday = todayMidnight.add(Duration(days: daysUntilMonday));
        setState(() {
          _startDate = nextMonday;
          _endDate = nextMonday;
          _focusedMonth = nextMonday;
          _isSelectingEndDate = false;
        });
        break;
      case 'Next Week':
        int daysUntilMonday = DateTime.monday - todayMidnight.weekday;
        if (daysUntilMonday <= 0) daysUntilMonday += 7;
        final nextMonday = todayMidnight.add(Duration(days: daysUntilMonday));
        final nextSunday = nextMonday.add(const Duration(days: 6));
        setState(() {
          _startDate = nextMonday;
          _endDate = nextSunday;
          _focusedMonth = nextMonday;
          _isSelectingEndDate = false;
        });
        break;
      case 'Clear':
        setState(() {
          _startDate = null;
          _endDate = null;
          _isSelectingEndDate = false;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    final counts = _calculateCounts();
    final remainingBalance = widget.initialLeaveBalance - counts['working']!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: Colors.white,
        width:
            widget.mode == PremiumDatePickerMode.range &&
                (isDesktop || isTablet)
            ? 820
            : 460,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Calendar area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildGrid(),
                      const SizedBox(height: 12),
                      _buildQuickActions(),
                      const Divider(height: 24),
                      _buildFooterButtons(),
                    ],
                  ),
                ),
              ),
              // Leave Details panel (on right, only for range mode on desktop/tablet)
              if (widget.mode == PremiumDatePickerMode.range &&
                  (isDesktop || isTablet)) ...[
                const VerticalDivider(width: 1),
                Container(
                  width: 320,
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.all(24),
                  child: _buildLeaveInfoPanel(counts, remainingBalance),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── UI Building Blocks ───

  Widget _buildHeader() {
    final List<String> months = [
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
    final List<int> years = List.generate(10, (index) => 2025 + index);

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF475569)),
          onPressed: () {
            setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month - 1,
              );
            });
          },
        ),
        const Spacer(),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: months[_focusedMonth.month - 1],
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
            items: months.map((m) {
              return DropdownMenuItem(
                value: m,
                child: Text(
                  m,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    months.indexOf(val) + 1,
                  );
                });
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _focusedMonth.year,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
            items: years.map((y) {
              return DropdownMenuItem(
                value: y,
                child: Text(
                  '$y',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _focusedMonth = DateTime(val, _focusedMonth.month);
                });
              }
            },
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0xFF475569)),
          onPressed: () {
            setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildGrid() {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstDayWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;

    final totalGridCells = firstDayWeekday + daysInMonth;
    final rowCount = (totalGridCells / 7).ceil();

    return Column(
      children: [
        // Weekday header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((day) {
            final isWeekend =
                day == 'Sun' || (day == 'Sat' && !_saturdayIsWorking);
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isWeekend
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Days grid
        Column(
          children: List.generate(rowCount, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (colIndex) {
                  final index = rowIndex * 7 + colIndex;
                  final dayNumber = index - firstDayWeekday + 1;

                  if (dayNumber <= 0 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox.shrink());
                  }

                  final currentDate = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month,
                    dayNumber,
                  );
                  return Expanded(child: _buildDayCell(currentDate));
                }),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime date) {
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    final disabledReason = _getDisabledReason(date);
    final isDisabled = disabledReason != null;

    final isSelectedStart =
        _startDate != null &&
        date.year == _startDate!.year &&
        date.month == _startDate!.month &&
        date.day == _startDate!.day;
    final isSelectedEnd =
        _endDate != null &&
        date.year == _endDate!.year &&
        date.month == _endDate!.month &&
        date.day == _endDate!.day;

    final isWithinRange =
        _startDate != null &&
        _endDate != null &&
        date.isAfter(_startDate!) &&
        date.isBefore(_endDate!);

    Color textColor = const Color(0xFF1E293B);
    Color? cellBg;
    BoxShape shape = BoxShape.circle;
    Border? border;

    if (isDisabled) {
      textColor = const Color(0xFFCBD5E1);
    } else if (isSelectedStart || isSelectedEnd) {
      textColor = Colors.white;
      cellBg = const Color(0xFF2563EB); // primary blue
    } else if (isWithinRange) {
      textColor = const Color(0xFF1E40AF);
      cellBg = const Color(0xFFDBEAFE); // light blue range bar
      shape = BoxShape.rectangle;
    } else {
      if (date.weekday == DateTime.sunday ||
          (date.weekday == DateTime.saturday && !_saturdayIsWorking)) {
        textColor = const Color(0xFFEF4444).withValues(alpha: 0.8);
      }
      // Check if it is a holiday/semester break to show subtle visual indicator
      final mmdd =
          '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final midnight = DateTime(date.year, date.month, date.day);
      final isHoliday =
          _annualHolidays.containsKey(mmdd) ||
          _specificHolidays.containsKey(midnight);
      final isSemBreak =
          date.isAfter(_semBreakStart.subtract(const Duration(days: 1))) &&
          date.isBefore(_semBreakEnd.add(const Duration(days: 1)));

      if (isHoliday) {
        cellBg = const Color(0xFFFEF3C7); // amber / holiday color
        textColor = const Color(0xFFD97706);
      } else if (isSemBreak) {
        cellBg = const Color(0xFFF3E8FF); // purple semester break
        textColor = const Color(0xFF9333EA);
      }
    }

    if (isToday && !isSelectedStart && !isSelectedEnd) {
      border = Border.all(color: const Color(0xFF2563EB), width: 1.5);
    }

    // Build the container
    Widget cell = Container(
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cellBg,
        shape: shape,
        border: border,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(4)
            : null,
      ),
      child: Text(
        '${date.day}',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: (isSelectedStart || isSelectedEnd || isToday)
              ? FontWeight.bold
              : FontWeight.normal,
          color: textColor,
        ),
      ),
    );

    // Apply tooltip if disabled or holiday
    if (disabledReason != null) {
      cell = Tooltip(
        message: disabledReason,
        preferBelow: false,
        textStyle: GoogleFonts.inter(fontSize: 10, color: Colors.white),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(4),
        ),
        child: cell,
      );
    } else {
      final mmdd =
          '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final midnight = DateTime(date.year, date.month, date.day);
      if (_annualHolidays.containsKey(mmdd)) {
        cell = Tooltip(
          message: 'Holiday: ${_annualHolidays[mmdd]}',
          child: cell,
        );
      } else if (_specificHolidays.containsKey(midnight)) {
        cell = Tooltip(
          message: 'Holiday: ${_specificHolidays[midnight]}',
          child: cell,
        );
      } else if (date.isAfter(
            _semBreakStart.subtract(const Duration(days: 1)),
          ) &&
          date.isBefore(_semBreakEnd.add(const Duration(days: 1)))) {
        cell = Tooltip(message: 'Semester Break', child: cell);
      }
    }

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(onTap: () => _onDateClick(date), child: cell),
    );
  }

  Widget _buildQuickActions() {
    final actions = ['Today', 'Tomorrow', 'Next Monday', 'Next Week', 'Clear'];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: actions.map((a) {
        return OutlinedButton(
          onPressed: () => _applyQuickAction(a),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            foregroundColor: const Color(0xFF475569),
          ),
          child: Text(
            a,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              color: const Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (_startDate != null) {
              Navigator.pop(context, {
                'start': _startDate,
                'end': _endDate ?? _startDate,
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select at least one date.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Apply',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveInfoPanel(Map<String, int> counts, int remainingBalance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave Duration Summary',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        _infoItem(
          'Selected From',
          _startDate != null
              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
              : '--',
        ),
        _infoItem(
          'Selected To',
          _endDate != null
              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
              : (_startDate != null
                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                    : '--'),
        ),
        const Divider(height: 24),
        _infoItem('Working Days', '${counts['working']}', isHighlight: true),
        _infoItem('Weekends Included', '${counts['weekend']}'),
        _infoItem('Holidays/Breaks Included', '${counts['holiday']}'),
        _infoItem('Total Duration Days', '${counts['total']}'),
        const Divider(height: 24),
        Text(
          'Leave Balance Info (${widget.leaveType})',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Balance:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              '${widget.initialLeaveBalance} Days',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Remaining Balance:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              '$remainingBalance Days',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: remainingBalance < 0
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Setting toggle for saturday working
        Row(
          children: [
            Checkbox(
              value: _saturdayIsWorking,
              activeColor: const Color(0xFF2563EB),
              onChanged: (val) {
                setState(() {
                  _saturdayIsWorking = val ?? false;
                });
              },
            ),
            Expanded(
              child: Text(
                'Saturday is Working Day',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoItem(String label, String val, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF475569),
            ),
          ),
          Text(
            val,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
