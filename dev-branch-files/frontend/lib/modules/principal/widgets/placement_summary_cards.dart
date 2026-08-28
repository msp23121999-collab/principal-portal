import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_icons.dart';
import '../utils/responsive_utils.dart';
import './cards/statistics_card.dart';
import '../data/placement_mock_data.dart';
import '../providers/placement_providers.dart';

/// Headline placement KPIs: placed/eligible, average package, highest
/// package, number of recruiting companies.
class PlacementSummaryCards extends ConsumerWidget {
  const PlacementSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibility = ref.watch(placementEligibilityProvider);
    final placementPercent = eligibility.eligible == 0
        ? 0
        : (eligibility.placed / eligibility.eligible * 100).clamp(0, 100);

    return ResponsiveGrid(
      children: [
        StatisticsCard(
          label: 'Students Placed',
          value: '${eligibility.placed}/${eligibility.eligible}',
          icon: AppIcons.placements,
          subtitle: '${placementPercent.toStringAsFixed(1)}% placement rate',
        ),
        StatisticsCard(
          label: 'Average Package',
          value:
              '₹${PlacementMockData.averagePackageLpa.toStringAsFixed(1)} LPA',
          icon: AppIcons.currency,
        ),
        StatisticsCard(
          label: 'Highest Package',
          value:
              '₹${PlacementMockData.highestPackageLpa.toStringAsFixed(1)} LPA',
          icon: AppIcons.trendUp,
        ),
        StatisticsCard(
          label: 'Companies Visited',
          value: PlacementMockData.companies.length.toString(),
          icon: AppIcons.company,
        ),
      ],
    );
  }
}
