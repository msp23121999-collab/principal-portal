import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_card.dart';

/// Placement headline for the Principal — full company, drive and package
/// analysis lives on Placement Dashboard.
class PlacementSummarySection extends ConsumerWidget {
  const PlacementSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const CardSkeleton(height: 140),
      error: (err, st) => const ErrorState(),
      data: (summary) {
        final p = summary.placementSummary;

        if (p.totalPlaced == 0) {
          return const DashboardCard(
            title: 'Placement',
            icon: AppIcons.placements,
            iconColor: AppColors.warning,
            child: EmptyState(message: 'No placement data available.'),
          );
        }

        // The repository returns null where placements and the roll do not
        // describe the same population, so there is nothing to second-guess
        // here.
        final percent = p.placementPercent;
        final reconciles = percent != null;

        return DashboardCard(
          title: 'Placement',
          icon: AppIcons.placements,
          iconColor: AppColors.warning,
          subtitle: reconciles
              ? 'Current academic year'
              : 'Current academic year · roll not yet reconciled with offers',
          // Wraps to two rows on a laptop rather than squeezing five tiles
          // into one line, which is where the labels started clipping.
          child: ResponsiveGrid(
            minTileWidth: 200,
            children: [
              DashboardInfoTile(
                label: 'Placed',
                value: reconciles
                    ? '${p.totalPlaced}/${p.totalEligible}'
                    : '${p.totalPlaced}',
                icon: AppIcons.placements,
              ),
              DashboardInfoTile(
                label: 'Placement %',
                value: percent == null
                    ? NumberFormatter.unrecorded
                    : '${percent.toStringAsFixed(1)}%',
                icon: AppIcons.trendUp,
              ),
              DashboardInfoTile(
                label: 'Average Package',
                value: p.averagePackageLpa == 0
                    ? NumberFormatter.unrecorded
                    : '₹${p.averagePackageLpa.toStringAsFixed(1)} LPA',
                icon: AppIcons.currency,
              ),
              DashboardInfoTile(
                label: 'Highest Package',
                value: p.highestPackageLpa == 0
                    ? NumberFormatter.unrecorded
                    : '₹${p.highestPackageLpa.toStringAsFixed(1)} LPA',
                icon: AppIcons.award,
              ),
              DashboardInfoTile(
                label: 'Top Recruiter',
                value: p.topRecruiter,
                icon: AppIcons.company,
              ),
            ],
          ),
        );
      },
    );
  }
}
