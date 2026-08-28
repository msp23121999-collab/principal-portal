import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/cards/mini_stat_tile.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/institution_providers.dart';

const List<Color> _accents = [
  AppColors.primaryBlue,
  AppColors.success,
  AppColors.accentGold,
  AppColors.darkBlue,
];

/// Campus facility counts — classrooms, labs, hostels, transport.
class AtAGlanceSection extends ConsumerWidget {
  const AtAGlanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilityStatsProvider);

    return facilitiesAsync.when(
      loading: () => const CardSkeleton(height: 180),
      error: (err, st) => const ErrorState(),
      data: (facilities) => AnalyticsCard(
        title: 'At a Glance',
        subtitle: 'Campus infrastructure',
        child: ResponsiveGrid(
          minTileWidth: 120,
          gutter: 12,
          children: [
            for (int i = 0; i < facilities.length; i++)
              MiniStatTile(
                icon: facilities[i].icon,
                label: facilities[i].label,
                value: '${facilities[i].count}',
                color: _accents[i % _accents.length],
              ),
          ],
        ),
      ),
    );
  }
}
