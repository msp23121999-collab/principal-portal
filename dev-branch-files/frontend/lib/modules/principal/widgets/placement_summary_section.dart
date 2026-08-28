import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_icons.dart';
import './cards/analytics_card.dart';
import './cards/info_tile.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';

/// Placement aggregate detail card — full company/drive breakdown lives on
/// Placement Analytics.
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
        return AnalyticsCard(
          title: 'Placement Summary',
          subtitle: 'Current academic year',
          child: Row(
            children: [
              Expanded(
                child: InfoTile(
                  label: 'Placed',
                  value: '${p.totalPlaced}/${p.totalEligible}',
                  icon: AppIcons.placements,
                ),
              ),
              Expanded(
                child: InfoTile(
                  label: 'Average Package',
                  value: '₹${p.averagePackageLpa.toStringAsFixed(1)} LPA',
                  icon: AppIcons.currency,
                ),
              ),
              Expanded(
                child: InfoTile(
                  label: 'Highest Package',
                  value: '₹${p.highestPackageLpa.toStringAsFixed(1)} LPA',
                  icon: AppIcons.trendUp,
                ),
              ),
              Expanded(
                child: InfoTile(
                  label: 'Top Recruiter',
                  value: p.topRecruiter,
                  icon: AppIcons.company,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
