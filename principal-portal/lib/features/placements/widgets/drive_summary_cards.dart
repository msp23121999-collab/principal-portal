import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../providers/placement_providers.dart';

/// Season figures that sit alongside the offer summary: how many drives
/// ran, how they converted, and the internship position.
class DriveSummaryCards extends ConsumerWidget {
  const DriveSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(driveSummaryProvider).valueOrNull;
    final registrations = summary?.registrations ?? 0;
    final offers = summary?.offers ?? 0;

    return ResponsiveGrid(
      children: [
        StatisticsCard(
          label: 'Drives Held',
          value: '${summary?.drivesHeld ?? 0}',
          icon: AppIcons.company,
          iconColor: AppChartPalette.at(0),
          iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
          subtitle: '${summary?.upcomingDrives ?? 0} still upcoming',
        ),
        StatisticsCard(
          label: 'Total Registrations',
          value: '$registrations',
          icon: AppIcons.students,
          iconColor: AppChartPalette.at(1),
          iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
        ),
        StatisticsCard(
          label: 'Conversion Rate',
          value: registrations == 0
              ? '—'
              : '${(offers / registrations * 100).toStringAsFixed(1)}%',
          icon: AppIcons.trendUp,
          iconColor: AppColors.success,
          iconBackground: AppColors.successTint,
          subtitle: 'Offers against registrations',
        ),
        StatisticsCard(
          label: 'Students Interning',
          value: '${summary?.internshipStudents ?? 0}',
          icon: AppIcons.research,
          iconColor: AppChartPalette.at(3),
          iconBackground: AppChartPalette.at(3).withValues(alpha: 0.10),
          subtitle:
              '${summary?.paidInternshipStudents ?? 0} on paid internships',
        ),
      ],
    );
  }
}
