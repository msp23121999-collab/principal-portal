import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/buttons/icon_action_button.dart';
import '../../../../core/widgets/cards/statistics_card.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/status_chip.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/confirmation_dialog.dart';
import '../../models/meeting.dart';
import '../../providers/meetings_providers.dart';

AppStatus _statusFor(MeetingStatus status) {
  switch (status) {
    case MeetingStatus.scheduled:
      return AppStatus.pending;
    case MeetingStatus.completed:
      return AppStatus.approved;
    case MeetingStatus.cancelled:
      return AppStatus.rejected;
  }
}

/// Upcoming meetings with the option to cancel, and the record of those
/// already held.
class MeetingsTab extends ConsumerWidget {
  const MeetingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingMeetingsProvider);
    final past = ref.watch(pastMeetingsProvider);
    final minutesPending = ref.watch(minutesPendingProvider);
    final openActionItems = ref.watch(openActionItemsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Upcoming Meetings',
              value: '${upcoming.length}',
              icon: AppIcons.meetings,
              iconColor: AppChartPalette.at(0),
              iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
            ),
            StatisticsCard(
              label: 'Held This Year',
              value:
                  '${past.where((m) => m.status == MeetingStatus.completed).length}',
              icon: AppIcons.check,
              iconColor: AppColors.success,
              iconBackground: AppColors.successTint,
            ),
            StatisticsCard(
              label: 'Meeting Records Pending',
              value: '$minutesPending',
              icon: AppIcons.document,
              iconColor: AppColors.warning,
              iconBackground: AppColors.warningTint,
            ),
            StatisticsCard(
              label: 'Open Action Items',
              value: '$openActionItems',
              icon: AppIcons.warning,
              iconColor: AppColors.danger,
              iconBackground: AppColors.dangerTint,
            ),
          ],
        ),
        const SizedBox(height: 20),
        TableContainer(
          title: 'Upcoming Meetings',
          subtitle: 'Scheduled from ${DateFormatter.shortDate(DateTime.now())}',
          child: CustomDataTable(
            emptyMessage: 'No meetings are currently scheduled.',
            columns: const [
              DataColumnConfig(label: 'Meeting', size: ColumnSize.L),
              DataColumnConfig(label: 'Forum', size: ColumnSize.M),
              DataColumnConfig(label: 'Date', size: ColumnSize.M),
              DataColumnConfig(label: 'Time', size: ColumnSize.S),
              DataColumnConfig(label: 'Venue', size: ColumnSize.L),
              DataColumnConfig(label: 'Attendees', numeric: true),
              DataColumnConfig(label: 'Agenda', numeric: true),
              DataColumnConfig(label: '', size: ColumnSize.S),
            ],
            rows: [
              for (final meeting in upcoming)
                _upcomingRow(context, ref, meeting),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TableContainer(
          title: 'Meeting Record',
          subtitle: 'Meetings already held or cancelled',
          child: CustomDataTable(
            emptyMessage: 'No meetings have been held yet.',
            columns: const [
              DataColumnConfig(label: 'Meeting', size: ColumnSize.L),
              DataColumnConfig(label: 'Forum', size: ColumnSize.M),
              DataColumnConfig(label: 'Date', size: ColumnSize.M),
              DataColumnConfig(label: 'Attendees', numeric: true),
              DataColumnConfig(label: 'Meeting Records', size: ColumnSize.S),
              DataColumnConfig(label: 'Status', size: ColumnSize.S),
            ],
            rows: [for (final meeting in past) _pastRow(meeting)],
          ),
        ),
      ],
    );
  }

  DataRow2 _upcomingRow(BuildContext context, WidgetRef ref, Meeting meeting) {
    return DataRow2(
      cells: [
        DataCell(Text(meeting.title, overflow: TextOverflow.ellipsis)),
        DataCell(Text(meeting.type.label)),
        DataCell(Text(DateFormatter.shortDate(meeting.scheduledAt))),
        DataCell(Text(DateFormatter.time(meeting.scheduledAt))),
        DataCell(Text(meeting.venue, overflow: TextOverflow.ellipsis)),
        DataCell(Text('${meeting.attendeeCount}')),
        DataCell(Text('${meeting.agenda.length}')),
        DataCell(
          IconActionButton(
            icon: AppIcons.close,
            tooltip: 'Cancel meeting',
            color: AppColors.danger,
            onPressed: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Cancel Meeting',
                message:
                    'Cancel "${meeting.title}"? Attendees will need to be '
                    'informed separately.',
                confirmLabel: 'Cancel Meeting',
                cancelLabel: 'Keep',
                isDestructive: true,
              );
              if (confirmed != true || !context.mounted) return;

              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(meetingSchedulerProvider).cancel(meeting.id);
                messenger.showSnackBar(
                  SnackBar(content: Text('"${meeting.title}" cancelled.')),
                );
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Could not cancel: $error')),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  DataRow2 _pastRow(Meeting meeting) {
    return DataRow2(
      cells: [
        DataCell(Text(meeting.title, overflow: TextOverflow.ellipsis)),
        DataCell(Text(meeting.type.label)),
        DataCell(Text(DateFormatter.shortDate(meeting.scheduledAt))),
        DataCell(Text('${meeting.attendeeCount}')),
        DataCell(
          Text(
            meeting.status == MeetingStatus.cancelled
                ? '—'
                : (meeting.minutesRecorded ? 'Filed' : 'Pending'),
            style: TextStyle(
              color:
                  meeting.status == MeetingStatus.completed &&
                      !meeting.minutesRecorded
                  ? AppColors.warning
                  : AppColors.primaryText,
            ),
          ),
        ),
        DataCell(
          StatusChip(
            status: _statusFor(meeting.status),
            customLabel: meeting.status.label,
          ),
        ),
      ],
    );
  }
}
