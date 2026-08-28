import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/table_export.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../core/widgets/cards/analytics_card.dart';
import '../../../../core/widgets/data_display/status_chip.dart';
import '../../../../core/widgets/feedback/empty_state.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../models/meeting.dart';
import '../../providers/meetings_providers.dart';

/// Minutes filed against completed meetings, with the resolutions passed
/// and any action items still open.
class MinutesTab extends ConsumerWidget {
  const MinutesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(meetingMinutesProvider)
        .when(
          loading: () => const CardSkeleton(height: 280),
          error: (err, st) => const ErrorState(),
          data: (records) {
            if (records.isEmpty) {
              return const EmptyState(
                message: 'No meeting records have been filed yet.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final record in records) ...[
                  _MinutesCard(record: record),
                  if (record != records.last) const SizedBox(height: 20),
                ],
              ],
            );
          },
        );
  }
}

class _MinutesCard extends StatelessWidget {
  const _MinutesCard({required this.record});

  final MeetingMinutes record;

  @override
  Widget build(BuildContext context) {
    return AnalyticsCard(
      title: record.meetingTitle,
      subtitle:
          '${record.meetingId} · held ${DateFormatter.shortDate(record.heldOn)} '
          '· recorded by ${record.recordedBy}',
      trailing: SecondaryButton(
        label: 'Download',
        icon: AppIcons.download,
        // One file per meeting, one row per resolution. It used to say the
        // minutes were "queued for export" and queue nothing.
        onPressed: () => TableExport.run(
          context,
          fileName: 'minutes_${record.meetingId}',
          noun: 'resolution',
          headers: const [
            'Meeting ID',
            'Meeting',
            'Held On',
            'Recorded By',
            'Resolution',
            'Open Action Items',
          ],
          rows: [
            for (final decision in record.decisions)
              [
                record.meetingId,
                record.meetingTitle,
                DateFormatter.shortDate(record.heldOn),
                record.recordedBy,
                decision,
                record.openActionItems,
              ],
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resolutions', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final decision in record.decisions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    AppIcons.check,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      decision,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          StatusChip(
            status: record.openActionItems == 0
                ? AppStatus.approved
                : AppStatus.pending,
            customLabel: record.openActionItems == 0
                ? 'All action items closed'
                : '${record.openActionItems} action item'
                      '${record.openActionItems == 1 ? '' : 's'} open',
          ),
        ],
      ),
    );
  }
}
