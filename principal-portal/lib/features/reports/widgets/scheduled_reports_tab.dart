import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/report_run.dart';
import '../providers/reports_providers.dart';

/// Recurring report schedules, each switchable on or off.
class ScheduledReportsTab extends ConsumerWidget {
  const ScheduledReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(scheduledReportsProvider)
        .when(
          loading: () => ResponsiveGrid(
            children: List.generate(4, (_) => const CardSkeleton()),
          ),
          error: (err, st) => const ErrorState(),
          data: _buildBody,
        );
  }

  Widget _buildBody(List<ScheduledReport> schedules) {
    final active = schedules.where((s) => s.isEnabled).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          children: [
            StatisticsCard(
              label: 'Schedules Configured',
              value: '${schedules.length}',
              icon: AppIcons.calendar,
              iconColor: AppChartPalette.at(0),
              iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
            ),
            StatisticsCard(
              label: 'Currently Active',
              value: '${active.length}',
              icon: AppIcons.check,
              iconColor: AppColors.success,
              iconBackground: AppColors.successTint,
            ),
            StatisticsCard(
              label: 'Paused',
              value: '${schedules.length - active.length}',
              icon: AppIcons.clock,
              iconColor: AppColors.secondaryText,
              iconBackground: AppColors.secondaryTint,
            ),
            StatisticsCard(
              label: 'Next Run',
              value: active.isEmpty
                  ? '—'
                  : DateFormatter.shortDate(
                      active
                          .map((s) => s.nextRun)
                          .reduce((a, b) => a.isBefore(b) ? a : b),
                    ),
              icon: AppIcons.trendUp,
              iconColor: AppChartPalette.at(3),
              iconBackground: AppChartPalette.at(3).withValues(alpha: 0.10),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (schedules.isEmpty)
          const EmptyState(message: 'No recurring reports are configured.')
        else
          for (final schedule in schedules)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ScheduleCard(schedule: schedule),
            ),
      ],
    );
  }
}

class _ScheduleCard extends ConsumerWidget {
  const _ScheduleCard({required this.schedule});

  final ScheduledReport schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      schedule.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    StatusChip(
                      status: schedule.isEnabled
                          ? AppStatus.active
                          : AppStatus.inactive,
                      customLabel: schedule.isEnabled ? 'Active' : 'Paused',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Meta(
                      icon: AppIcons.dashboard,
                      text: reportModuleLabel(schedule.module),
                    ),
                    _Meta(icon: AppIcons.clock, text: schedule.frequency.label),
                    _Meta(icon: AppIcons.document, text: schedule.format.label),
                    _Meta(
                      icon: AppIcons.calendar,
                      text: schedule.isEnabled
                          ? 'Next ${DateFormatter.shortDate(schedule.nextRun)}'
                          : 'Not scheduled',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Circulated to ${schedule.recipients.join(', ')}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: schedule.isEnabled,
            onChanged: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(reportActionsProvider)
                    .setScheduleEnabled(schedule.id, value);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '${schedule.title} ${value ? 'resumed' : 'paused'}.',
                    ),
                  ),
                );
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Could not update: $error')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.secondaryText),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
