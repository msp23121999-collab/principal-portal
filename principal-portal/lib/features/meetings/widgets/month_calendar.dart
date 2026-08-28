import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/meeting.dart';

/// Semantic categories for calendar entries.
enum CalendarCategory {
  meeting,
  exam,
  event,
  deadline,
  holiday,
  info,
  testSystem,
}

/// Classifies a calendar entry based on its title, type, and description.
CalendarCategory getCategoryForEntry({
  required String title,
  CalendarEntryType? type,
  String? description,
}) {
  final upper = title.trim().toUpperCase();

  // Low-priority classification for technical / debug / test entries
  if (upper.contains('DEBUG') ||
      upper.contains('SMOKE') ||
      upper.contains('AUDIT') ||
      upper == 'TEST_MEET' ||
      upper.startsWith('TEST_') ||
      upper.startsWith('MOCK_')) {
    return CalendarCategory.testSystem;
  }

  // Deadlines and important action items
  if (upper.contains('DEADLINE') ||
      upper.contains('DUE') ||
      upper.contains('SUBMISSION') ||
      upper.contains('LAST DATE')) {
    return CalendarCategory.deadline;
  }

  if (type != null) {
    switch (type) {
      case CalendarEntryType.examination:
        return CalendarCategory.exam;
      case CalendarEntryType.holiday:
        return CalendarCategory.holiday;
      case CalendarEntryType.meeting:
        return CalendarCategory.meeting;
      case CalendarEntryType.instruction:
        return CalendarCategory.info;
      case CalendarEntryType.event:
        return CalendarCategory.event;
    }
  }

  if (upper.contains('EXAM') || upper.contains('TEST')) {
    return CalendarCategory.exam;
  }
  if (upper.contains('HOLIDAY') || upper.contains('VACATION')) {
    return CalendarCategory.holiday;
  }
  if (upper.contains('MEETING') ||
      upper.contains('COUNCIL') ||
      upper.contains('BOARD')) {
    return CalendarCategory.meeting;
  }

  return CalendarCategory.event;
}

Color colorForCategory(CalendarCategory category) {
  switch (category) {
    case CalendarCategory.meeting:
      return AppColors.accentBlue; // #2563EB
    case CalendarCategory.exam:
      return AppColors.accentGreen; // #059669
    case CalendarCategory.event:
      return AppColors.accentPurple; // #7C3AED
    case CalendarCategory.deadline:
      return AppColors.accentOrange; // #D97706
    case CalendarCategory.holiday:
      return AppColors.danger; // #DC2626
    case CalendarCategory.info:
      return AppColors.accentCyan; // #0891B2
    case CalendarCategory.testSystem:
      return const Color(0xFF64748B); // #64748B
  }
}

Color softColorForCategory(CalendarCategory category) {
  switch (category) {
    case CalendarCategory.meeting:
      return AppColors.softBlue; // #EFF6FF
    case CalendarCategory.exam:
      return AppColors.softGreen; // #ECFDF5
    case CalendarCategory.event:
      return AppColors.softPurple; // #F5F3FF
    case CalendarCategory.deadline:
      return AppColors.softOrange; // #FFFBEB
    case CalendarCategory.holiday:
      return AppColors.softRed; // #FEF2F2
    case CalendarCategory.info:
      return AppColors.softCyan; // #ECFEFF
    case CalendarCategory.testSystem:
      return const Color(0xFFF1F5F9); // #F1F5F9
  }
}

String labelForCategory(CalendarCategory category) {
  switch (category) {
    case CalendarCategory.meeting:
      return 'Meeting';
    case CalendarCategory.exam:
      return 'Exam';
    case CalendarCategory.event:
      return 'Event';
    case CalendarCategory.deadline:
      return 'Deadline';
    case CalendarCategory.holiday:
      return 'Holiday';
    case CalendarCategory.info:
      return 'Information';
    case CalendarCategory.testSystem:
      return 'System/Test';
  }
}

/// Palette for calendar entry types, shared by grid cells and tables.
Color colorForEntryType(CalendarEntryType type) {
  return colorForCategory(getCategoryForEntry(title: '', type: type));
}

const List<String> _weekdayLabels = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// A month grid with categorized dots per calendar entry. Selecting a day
/// reports it upward; the owning screen decides what to show for it.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.entries,
    required this.today,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<AcademicCalendarEntry> entries;
  final DateTime today;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final leadingBlanks = firstOfMonth.weekday - 1;
    final cellCount = leadingBlanks + daysInMonth;
    final rowCount = (cellCount / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (int i = 0; i < _weekdayLabels.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    _weekdayLabels[i],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: i >= 5
                              ? AppColors.secondaryText.withValues(alpha: 0.7)
                              : AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
          ],
        ),
        for (int row = 0; row < rowCount; row++)
          Row(
            children: [
              for (int column = 0; column < 7; column++)
                Expanded(
                  child: _buildCell(
                    context,
                    row * 7 + column - leadingBlanks + 1,
                    daysInMonth,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, int dayNumber, int daysInMonth) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 58);
    }

    final day = DateTime(month.year, month.month, dayNumber);
    final dayEntries = entries.where((entry) => entry.coversDay(day)).toList();
    final isToday = _isSameDay(day, today);
    final isSelected = selectedDay != null && _isSameDay(day, selectedDay!);

    return _MonthCalendarCell(
      dayNumber: dayNumber,
      day: day,
      dayEntries: dayEntries,
      isToday: isToday,
      isSelected: isSelected,
      onTap: () => onDaySelected(day),
    );
  }
}

class _MonthCalendarCell extends StatefulWidget {
  const _MonthCalendarCell({
    required this.dayNumber,
    required this.day,
    required this.dayEntries,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final int dayNumber;
  final DateTime day;
  final List<AcademicCalendarEntry> dayEntries;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_MonthCalendarCell> createState() => _MonthCalendarCellState();
}

class _MonthCalendarCellState extends State<_MonthCalendarCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color cellBgColor = Colors.transparent;
    Color borderColor = Colors.transparent;
    double borderWidth = 1.0;

    if (widget.isSelected) {
      cellBgColor = AppColors.softBlue;
      borderColor = AppColors.accentBlue;
      borderWidth = 1.5;
    } else if (_isHovered) {
      cellBgColor = AppColors.softBlue;
      borderColor = AppColors.accentBlue.withValues(alpha: 0.3);
    }

    final visibleEntries = widget.dayEntries.take(3).toList();
    final overflowCount = widget.dayEntries.length > 3
        ? widget.dayEntries.length - 3
        : 0;

    Widget cellContent = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: cellBgColor,
          borderRadius: AppRadius.smRadius,
          child: InkWell(
            borderRadius: AppRadius.smRadius,
            onTap: widget.onTap,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: AppRadius.smRadius,
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isToday)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.dayNumber}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    )
                  else
                    Text(
                      '${widget.dayNumber}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: widget.isSelected
                                ? AppColors.accentBlue
                                : AppColors.primaryText,
                            fontWeight: widget.isSelected || widget.dayEntries.isNotEmpty
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                    ),
                  const SizedBox(height: 3),
                  if (widget.dayEntries.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final entry in visibleEntries) ...[
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: colorForCategory(getCategoryForEntry(
                                title: entry.title,
                                type: entry.type,
                                description: entry.description,
                              )),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        if (overflowCount > 0) ...[
                          const SizedBox(width: 1),
                          Text(
                            '+$overflowCount',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondaryText,
                                ),
                          ),
                        ],
                      ],
                    )
                  else
                    const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.dayEntries.isEmpty) {
      return cellContent;
    }

    final tooltipLines = <String>[];
    for (final e in widget.dayEntries) {
      final cat = labelForCategory(getCategoryForEntry(
        title: e.title,
        type: e.type,
        description: e.description,
      ));
      final dateRange = DateFormatter.shortDate(e.from) == DateFormatter.shortDate(e.to)
          ? DateFormatter.shortDate(e.from)
          : '${DateFormatter.shortDate(e.from)} - ${DateFormatter.shortDate(e.to)}';
      tooltipLines.add('• ${e.title} ($cat) · $dateRange');
    }

    return Tooltip(
      message: tooltipLines.join('\n'),
      preferBelow: false,
      child: cellContent,
    );
  }
}

/// Compact legend for entry types beneath the calendar.
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final legendItems = [
      (CalendarCategory.meeting, 'Meetings'),
      (CalendarCategory.exam, 'Exams'),
      (CalendarCategory.event, 'Events'),
      (CalendarCategory.deadline, 'Deadlines'),
      (CalendarCategory.holiday, 'Holidays'),
    ];

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        for (final item in legendItems)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorForCategory(item.$1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                item.$2,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
      ],
    );
  }
}

