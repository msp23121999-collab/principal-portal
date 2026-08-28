import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../providers/meetings_providers.dart';
import '../widgets/schedule_meeting_dialog.dart';
import '../widgets/tabs/academic_calendar_tab.dart';
import '../widgets/tabs/calendar_tab.dart';
import '../widgets/tabs/meetings_tab.dart';
import '../widgets/tabs/minutes_tab.dart';

/// Meetings & Calendar — the institutional calendar, the meeting
/// schedule, and the minutes filed against meetings already held.
class MeetingsCalendarScreen extends ConsumerWidget {
  const MeetingsCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingMeetingsProvider).length;

    return TabbedPage(
      title: 'Meetings & Calendar',
      breadcrumbSegments: const ['Administration', 'Meetings'],
      subtitle:
          '$upcoming meetings scheduled, with the academic calendar and '
          'institutional events for the year.',
      actions: [
        PrimaryButton(
          label: 'Schedule Meeting',
          icon: AppIcons.add,
          onPressed: () => _scheduleMeeting(context, ref),
        ),
      ],
      tabs: const [
        PageTab(label: 'Calendar', content: CalendarTab()),
        PageTab(label: 'Meetings', content: MeetingsTab()),
        PageTab(label: 'Academic Calendar', content: AcademicCalendarTab()),
        PageTab(label: 'Meeting Records', content: MinutesTab()),
      ],
    );
  }

  Future<void> _scheduleMeeting(BuildContext context, WidgetRef ref) async {
    final selectedDay = ref.read(selectedCalendarDayProvider);

    final draft = await ScheduleMeetingDialog.show(
      context,
      // A week out from today, unless a day is already selected in the grid.
      initialDate: selectedDay ?? DateTime.now().add(const Duration(days: 7)),
    );
    if (draft == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(meetingSchedulerProvider)
          .schedule(
            title: draft.title,
            type: draft.type,
            // Meetings default to a 10:00 start; the form captures the date.
            scheduledAt: DateTime(
              draft.date.year,
              draft.date.month,
              draft.date.day,
              10,
            ),
            durationMinutes: draft.durationMinutes,
            venue: draft.venue,
            // The chair is whoever scheduled the meeting, taken from their own
            // profile. A name compiled into the app put the same chairperson
            chairperson: 'Principal, Principal',
            agenda: draft.agenda,
          );

      messenger.showSnackBar(
        SnackBar(content: Text('"${draft.title}" scheduled.')),
      );
    } catch (error) {
      // The raw driver error names schemas, tables and constraints. The
      // Principal gets told what failed; the detail stays in the debug console.
      if (kDebugMode) {
        debugPrint('Meeting scheduling failed: $error');
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not schedule the meeting. Please try again.'),
        ),
      );
    }
  }
}
