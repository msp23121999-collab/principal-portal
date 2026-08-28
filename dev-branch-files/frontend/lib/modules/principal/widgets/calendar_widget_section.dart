import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/date_formatter.dart';
import './cards/analytics_card.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../models/calendar_event.dart';
import '../providers/dashboard_providers.dart';

Color _colorForEventType(CalendarEventType type) {
  switch (type) {
    case CalendarEventType.exam:
      return AppColors.danger;
    case CalendarEventType.holiday:
      return AppColors.success;
    case CalendarEventType.event:
      return AppColors.accentGold;
    case CalendarEventType.meeting:
      return AppColors.primaryBlue;
  }
}

/// Simple month-grid calendar highlighting upcoming academic events, plus
/// a legend list beneath it.
class CalendarWidgetSection extends ConsumerWidget {
  const CalendarWidgetSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(calendarEventsProvider);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leadingBlanks = (firstDayOfMonth.weekday % 7);

    return eventsAsync.when(
      loading: () => const CardSkeleton(height: 360),
      error: (err, st) => const ErrorState(),
      data: (events) {
        final eventsByDay = <int, CalendarEvent>{
          for (final e in events)
            if (e.date.month == now.month) e.date.day: e,
        };

        return AnalyticsCard(
          title: 'Academic Calendar',
          subtitle: DateFormatter.monthYear(now),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: leadingBlanks + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) return const SizedBox.shrink();
                  final day = index - leadingBlanks + 1;
                  final event = eventsByDay[day];
                  final isToday = day == now.day;

                  return Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primaryBlue
                          : (event != null
                                ? _colorForEventType(
                                    event.type,
                                  ).withValues(alpha: 0.12)
                                : Colors.transparent),
                      borderRadius: AppRadius.smRadius,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isToday ? Colors.white : AppColors.primaryText,
                        fontWeight: event != null
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in events.where(
                    (e) => e.date.month == now.month,
                  ))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _colorForEventType(e.type),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            DateFormatter.dayMonth(e.date),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              e.title,
                              style: Theme.of(context).textTheme.bodySmall,
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
      },
    );
  }
}
