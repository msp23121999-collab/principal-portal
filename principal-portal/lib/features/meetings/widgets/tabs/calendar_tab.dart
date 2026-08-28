import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/cards/analytics_card.dart';
import '../../../../core/widgets/cards/highlight_list_card.dart';
import '../../../../core/widgets/feedback/empty_state.dart';
import '../../../../core/widgets/layout/responsive_row.dart';
import '../../models/meeting.dart';
import '../../providers/meetings_providers.dart';
import '../month_calendar.dart';

/// Month grid with everything scheduled that month, and the detail for a
/// selected day beside it.
class CalendarTab extends ConsumerWidget {
  const CalendarTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final selectedDay = ref.watch(selectedCalendarDayProvider);
    final entries =
        ref.watch(calendarEntriesProvider).valueOrNull ??
        const <AcademicCalendarEntry>[];
    final upcoming = ref.watch(upcomingMeetingsProvider);

    return ResponsiveRow(
      columns: [
        ResponsiveColumn(
          flex: 7,
          child: AnalyticsCard(
            title: DateFormatter.monthYear(month),
            subtitle: 'Institutional calendar',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CalendarNavButton(
                  icon: Icons.chevron_left,
                  tooltip: 'Previous month',
                  onPressed: () =>
                      ref.read(calendarMonthProvider.notifier).state = DateTime(
                        month.year,
                        month.month - 1,
                      ),
                ),
                const SizedBox(width: 8),
                _CalendarNavButton(
                  icon: Icons.chevron_right,
                  tooltip: 'Next month',
                  onPressed: () =>
                      ref.read(calendarMonthProvider.notifier).state = DateTime(
                        month.year,
                        month.month + 1,
                      ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonthCalendar(
                  month: month,
                  entries: entries,
                  today: DateTime.now(),
                  selectedDay: selectedDay,
                  onDaySelected: (day) =>
                      ref.read(selectedCalendarDayProvider.notifier).state =
                          day,
                ),
                const SizedBox(height: AppSpacing.lg),
                const CalendarLegend(),
              ],
            ),
          ),
        ),
        ResponsiveColumn(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SelectedDayCard(day: selectedDay),
              const SizedBox(height: 20),
              HighlightListCard(
                title: 'Next Meetings',
                subtitle: '${upcoming.length} scheduled',
                emptyMessage: 'No meetings are currently scheduled.',
                entries: [
                  for (final meeting in upcoming.take(5))
                    HighlightEntry(
                      icon: AppIcons.meetings,
                      title: meeting.title,
                      detail:
                          '${DateFormatter.shortDate(meeting.scheduledAt)} · '
                          '${DateFormatter.time(meeting.scheduledAt)} · '
                          '${meeting.venue}',
                      color: colorForCategory(getCategoryForEntry(
                        title: meeting.title,
                        description: meeting.venue,
                      )),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarNavButton extends StatefulWidget {
  const _CalendarNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_CalendarNavButton> createState() => _CalendarNavButtonState();
}

class _CalendarNavButtonState extends State<_CalendarNavButton> {
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
              width: 32,
              height: 32,
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

/// Entries covering the day the user tapped in the grid.
class _SelectedDayCard extends ConsumerWidget {
  const _SelectedDayCard({required this.day});

  final DateTime? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (day == null) {
      return const AnalyticsCard(
        title: 'Day Detail',
        subtitle: 'Select a date on the calendar',
        child: EmptyState(
          message: 'Pick a day to see what is scheduled.',
          icon: Icons.event_outlined,
        ),
      );
    }

    final entries = ref.watch(entriesForDayProvider(day!));

    return AnalyticsCard(
      title: DateFormatter.fullDate(day!),
      subtitle: entries.isEmpty
          ? 'Nothing scheduled'
          : '${entries.length} entr${entries.length == 1 ? 'y' : 'ies'}',
      child: entries.isEmpty
          ? const EmptyState(
              message: 'No calendar entries on this date.',
              icon: Icons.event_available_outlined,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in entries) ...[
                  _EntryRow(entry: entry),
                  if (entry != entries.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final AcademicCalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    final category = getCategoryForEntry(
      title: entry.title,
      type: entry.type,
      description: entry.description,
    );
    final accentColor = colorForCategory(category);
    final softBgColor = softColorForCategory(category);
    final categoryLabel = labelForCategory(category);
    final isTestSystem = category == CalendarCategory.testSystem;

    final dayStr = entry.from.day.toString().padLeft(2, '0');
    final monthStr = DateFormatter.monthShort(entry.from).toUpperCase();

    final dateRangeStr = entry.from == entry.to
        ? DateFormatter.shortDate(entry.from)
        : '${DateFormatter.shortDate(entry.from)} - ${DateFormatter.shortDate(entry.to)}';

    final tooltipMsg = [
      entry.title,
      'Category: $categoryLabel',
      'Date: $dateRangeStr',
      if (entry.description.isNotEmpty) entry.description,
    ].join('\n');

    return Tooltip(
      message: tooltipMsg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.smRadius,
          border: Border.all(
            color: isTestSystem
                ? const Color(0xFFE2E8F0)
                : accentColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date Badge Box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: softBgColor,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayStr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          height: 1.0,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monthStr,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor.withValues(alpha: 0.85),
                          height: 1.0,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        categoryLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: isTestSystem ? FontWeight.w500 : FontWeight.w600,
                          color: isTestSystem
                              ? const Color(0xFF64748B)
                              : AppColors.primaryText,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
