import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../meetings/providers/meetings_providers.dart';
import '../../meetings/widgets/month_calendar.dart';
import '../models/calendar_event.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_card.dart';

CalendarCategory _categoryForDashboardEvent(CalendarEvent e) {
  final cat = getCategoryForEntry(title: e.title);
  if (cat != CalendarCategory.event && cat != CalendarCategory.meeting) {
    return cat;
  }
  switch (e.type) {
    case CalendarEventType.exam:
      return CalendarCategory.exam;
    case CalendarEventType.holiday:
      return CalendarCategory.holiday;
    case CalendarEventType.event:
      return CalendarCategory.event;
    case CalendarEventType.meeting:
      return CalendarCategory.meeting;
  }
}

/// Simple month-grid calendar highlighting upcoming academic events, plus
/// a legend list beneath it.
class CalendarWidgetSection extends ConsumerStatefulWidget {
  const CalendarWidgetSection({super.key});

  @override
  ConsumerState<CalendarWidgetSection> createState() =>
      _CalendarWidgetSectionState();
}

class _CalendarWidgetSectionState extends ConsumerState<CalendarWidgetSection> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final leadingBlanks = (firstDayOfMonth.weekday - 1) % 7;
    final isCurrentMonth =
        _displayedMonth.year == now.year && _displayedMonth.month == now.month;

    return eventsAsync.when(
      loading: () => const CardSkeleton(height: 360),
      error: (err, st) => const ErrorState(),
      data: (events) {
        final eventsByDay = <int, List<CalendarEvent>>{};
        for (final e in events) {
          if (e.date.year == _displayedMonth.year &&
              e.date.month == _displayedMonth.month) {
            (eventsByDay[e.date.day] ??= []).add(e);
          }
        }

        final monthEvents = events
            .where((e) =>
                e.date.year == _displayedMonth.year &&
                e.date.month == _displayedMonth.month)
            .toList();

        return DashboardCard(
          title: 'Academic Calendar',
          subtitle: DateFormatter.monthYear(_displayedMonth),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavIconButton(
                icon: Icons.chevron_left,
                tooltip: 'Previous month',
                onPressed: _goToPreviousMonth,
              ),
              const SizedBox(width: 6),
              _NavIconButton(
                icon: Icons.chevron_right,
                tooltip: 'Next month',
                onPressed: _goToNextMonth,
              ),
            ],
          ),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  mainAxisExtent: 54,
                ),
                itemCount: leadingBlanks + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) return const SizedBox.shrink();
                  final day = index - leadingBlanks + 1;
                  final dayEvents = eventsByDay[day] ?? const [];
                  final isToday = isCurrentMonth && day == now.day;

                  return _DayGridCell(
                    day: day,
                    dayEvents: dayEvents,
                    isToday: isToday,
                    onTap: () {
                      if (dayEvents.isNotEmpty) {
                        ref.read(selectedCalendarDayProvider.notifier).state =
                            DateTime(
                          _displayedMonth.year,
                          _displayedMonth.month,
                          day,
                        );
                        context.go(AppRoutes.meetingsCalendar);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (monthEvents.isNotEmpty) ...[
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in monthEvents) ...[
                      _DashboardEventRow(event: e),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DayGridCell extends StatefulWidget {
  const _DayGridCell({
    required this.day,
    required this.dayEvents,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final List<CalendarEvent> dayEvents;
  final bool isToday;
  final VoidCallback onTap;

  @override
  State<_DayGridCell> createState() => _DayGridCellState();
}

class _DayGridCellState extends State<_DayGridCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final visibleEvents = widget.dayEvents.take(3).toList();
    final overflowCount =
        widget.dayEvents.length > 3 ? widget.dayEvents.length - 3 : 0;

    Widget child = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: _isHovered ? AppColors.softBlue : Colors.transparent,
        borderRadius: AppRadius.smRadius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.smRadius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.smRadius,
              border: Border.all(
                color: _isHovered
                    ? AppColors.accentBlue.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            alignment: Alignment.center,
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
                      '${widget.day}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  )
                else
                  Text(
                    '${widget.day}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: widget.dayEvents.isNotEmpty
                              ? FontWeight.bold
                              : FontWeight.w400,
                        ),
                  ),
                const SizedBox(height: 2),
                if (widget.dayEvents.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final e in visibleEvents) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorForCategory(
                                _categoryForDashboardEvent(e)),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      if (overflowCount > 0) ...[
                        const SizedBox(width: 1),
                        Text(
                          '+$overflowCount',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
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
    );

    if (widget.dayEvents.isEmpty) {
      return child;
    }

    final tooltipLines = widget.dayEvents
        .map((e) =>
            '• ${e.title} (${labelForCategory(_categoryForDashboardEvent(e))})')
        .join('\n');

    return Tooltip(
      message: tooltipLines,
      child: child,
    );
  }
}

class _DashboardEventRow extends StatelessWidget {
  const _DashboardEventRow({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final cat = _categoryForDashboardEvent(event);
    final accentColor = colorForCategory(cat);
    final catLabel = labelForCategory(cat);
    final isTestSystem = cat == CalendarCategory.testSystem;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: softColorForCategory(cat),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              DateFormatter.dayMonth(event.date),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              event.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isTestSystem ? FontWeight.w400 : FontWeight.w600,
                    color: isTestSystem
                        ? const Color(0xFF64748B)
                        : AppColors.primaryText,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            catLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatefulWidget {
  const _NavIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

class _NavIconButtonState extends State<_NavIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: Material(
          color: _hovered ? AppColors.softBlue : Colors.white,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _hovered ? AppColors.accentBlue : AppColors.border,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: _hovered ? AppColors.accentBlue : AppColors.primaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

