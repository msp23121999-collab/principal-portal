import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/cards/statistics_card.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/status_chip.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../models/audit.dart';
import '../../providers/audit_providers.dart';

/// Standing policies, how closely each is followed, and when it is next
/// due for review.
class PolicyAdherenceTab extends ConsumerWidget {
  const PolicyAdherenceTab({super.key});

  /// Adherence at or above this level counts as being followed.
  static const double _adherenceTarget = 85;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policiesAsync = ref.watch(policiesProvider);
    final summary = ref.watch(auditSummaryProvider).valueOrNull;

    return policiesAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (policies) {
        final average =
            policies.fold(0.0, (sum, p) => sum + p.adherencePercent) /
            policies.length;
        final belowTarget = policies
            .where((p) => p.adherencePercent < _adherenceTarget)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              children: [
                StatisticsCard(
                  label: 'Policies Tracked',
                  value: '${policies.length}',
                  icon: AppIcons.document,
                  iconColor: AppChartPalette.at(0),
                  iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Average Adherence',
                  value: '${average.toStringAsFixed(1)}%',
                  icon: AppIcons.trendUp,
                  iconColor: AppChartPalette.at(1),
                  iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Below Target',
                  value: '$belowTarget',
                  icon: AppIcons.warning,
                  iconColor: AppColors.warning,
                  iconBackground: AppColors.warningTint,
                  subtitle: 'Under ${_adherenceTarget.round()}% adherence',
                ),
                StatisticsCard(
                  label: 'Reviews Overdue',
                  value: '${summary?.overduePolicyReviews ?? 0}',
                  icon: AppIcons.clock,
                  iconColor: AppColors.danger,
                  iconBackground: AppColors.dangerTint,
                  subtitle:
                      '${summary?.openPolicyIssues ?? 0} open issues in total',
                ),
              ],
            ),
            const SizedBox(height: 20),
            TableContainer(
              title: 'Policy Adherence',
              subtitle: 'Overdue reviews listed first',
              child: CustomDataTable(
                emptyMessage: 'No policies are being tracked.',
                columns: const [
                  DataColumnConfig(label: 'Policy', size: ColumnSize.L),
                  DataColumnConfig(label: 'Owner', size: ColumnSize.M),
                  DataColumnConfig(label: 'Last Reviewed', size: ColumnSize.M),
                  DataColumnConfig(label: 'Next Review', size: ColumnSize.M),
                  DataColumnConfig(label: 'Adherence', numeric: true),
                  DataColumnConfig(label: 'Open Issues', numeric: true),
                  DataColumnConfig(label: 'Review', size: ColumnSize.S),
                ],
                rows: [for (final policy in policies) _policyRow(policy)],
              ),
            ),
          ],
        );
      },
    );
  }

  DataRow2 _policyRow(PolicyAdherence policy) {
    final overdue = policy.isReviewOverdue(DateTime.now());
    final belowTarget = policy.adherencePercent < _adherenceTarget;

    return DataRow2(
      cells: [
        DataCell(Text(policy.policy, overflow: TextOverflow.ellipsis)),
        DataCell(Text(policy.owner, overflow: TextOverflow.ellipsis)),
        DataCell(Text(DateFormatter.shortDate(policy.lastReviewed))),
        DataCell(
          Text(
            DateFormatter.shortDate(policy.nextReview),
            style: TextStyle(
              color: overdue ? AppColors.danger : AppColors.primaryText,
              fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        DataCell(
          Text(
            '${policy.adherencePercent.toStringAsFixed(0)}%',
            style: TextStyle(
              color: belowTarget ? AppColors.warning : AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(Text(policy.openIssues == 0 ? '—' : '${policy.openIssues}')),
        DataCell(
          StatusChip(
            status: overdue ? AppStatus.rejected : AppStatus.approved,
            customLabel: overdue ? 'Overdue' : 'Current',
          ),
        ),
      ],
    );
  }
}
