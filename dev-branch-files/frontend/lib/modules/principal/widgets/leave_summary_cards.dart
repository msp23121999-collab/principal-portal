import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_icons.dart';
import '../utils/responsive_utils.dart';
import './cards/statistics_card.dart';
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
        ),
        StatisticsCard(
          label: 'Approved',
          value: approved.toString(),
          icon: AppIcons.approve,
        ),
        StatisticsCard(
          label: 'Rejected',
          value: rejected.toString(),
          icon: AppIcons.reject,
        ),
        StatisticsCard(
          label: 'Total Requests',
          value: all.length.toString(),
          icon: AppIcons.reports,
        ),
      ],
    );
  }
}
