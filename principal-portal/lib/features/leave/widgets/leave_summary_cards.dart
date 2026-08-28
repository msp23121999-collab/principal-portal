import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../models/leave_request.dart';
import '../providers/leave_providers.dart';

/// Headline KPI row for the Leave Approval screen.
class LeaveSummaryCards extends ConsumerWidget {
  const LeaveSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(leaveRequestsProvider);
    final pending = all.where((r) => r.status == LeaveStatus.pending).length;
    final approved = all.where((r) => r.status == LeaveStatus.approved).length;
    final rejected = all.where((r) => r.status == LeaveStatus.rejected).length;

    return ResponsiveGrid(
      children: [
        StatisticsCard(
          label: 'Pending',
          value: pending.toString(),
          icon: AppIcons.leave,
          iconColor: AppChartPalette.at(0),
          iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
        ),
        StatisticsCard(
          label: 'Approved',
          value: approved.toString(),
          icon: AppIcons.approve,
          iconColor: AppChartPalette.at(1),
          iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
        ),
        StatisticsCard(
          label: 'Rejected',
          value: rejected.toString(),
          icon: AppIcons.reject,
          iconColor: AppChartPalette.at(2),
          iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
        ),
        StatisticsCard(
          label: 'Total Requests',
          value: all.length.toString(),
          icon: AppIcons.reports,
          iconColor: AppChartPalette.at(3),
          iconBackground: AppChartPalette.at(3).withValues(alpha: 0.10),
        ),
      ],
    );
  }
}
