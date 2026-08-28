import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../providers/examination_providers.dart';

/// Where the current examination cycle stands at a glance.
class ExaminationKpiGrid extends ConsumerWidget {
  const ExaminationKpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(examinationSummaryProvider).valueOrNull;

    return ResponsiveGrid(
      children: [
        StatisticsCard(
          label: 'Papers Yet to Be Held',
          value: '${summary?.papersYetToBeHeld ?? 0}',
          icon: AppIcons.calendar,
          iconColor: AppChartPalette.at(0),
          iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
        ),
        StatisticsCard(
          label: 'Total Candidates',
          value: '${summary?.totalCandidates ?? 0}',
          icon: AppIcons.students,
          iconColor: AppChartPalette.at(1),
          iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
        ),
        StatisticsCard(
          label: 'Hall Tickets Issued',
          value: '${summary?.hallTicketsIssued ?? 0}',
          icon: AppIcons.document,
          iconColor: AppColors.success,
          iconBackground: AppColors.successTint,
        ),
        StatisticsCard(
          label: 'Hall Tickets Withheld',
          value: '${summary?.hallTicketsWithheld ?? 0}',
          icon: AppIcons.warning,
          iconColor: AppColors.danger,
          iconBackground: AppColors.dangerTint,
          subtitle: 'Attendance shortfall or dues',
        ),
        StatisticsCard(
          label: 'CIA Completion',
          value: '${summary?.averageCiaCompletion.toStringAsFixed(1) ?? '—'}%',
          icon: AppIcons.examinations,
          iconColor: AppChartPalette.at(4),
          iconBackground: AppChartPalette.at(4).withValues(alpha: 0.10),
        ),
        StatisticsCard(
          label: 'Results Published',
          value:
              '${summary?.resultsPublished ?? 0} of ${summary?.resultsTotal ?? 0}',
          icon: AppIcons.results,
          iconColor: AppColors.success,
          iconBackground: AppColors.successTint,
          subtitle: 'Semesters on record',
        ),
      ],
    );
  }
}
