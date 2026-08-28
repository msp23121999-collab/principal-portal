import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/chart_container.dart';
import '../../../core/widgets/charts/bar_chart_widget.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/placement_providers.dart';

/// Offers grouped by package range, so the spread of the season's offers
/// reads at a glance rather than only its average.
class PackageDistributionCard extends ConsumerWidget {
  const PackageDistributionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bandsAsync = ref.watch(packageBandsProvider);

    return bandsAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => const ErrorState(),
      data: (bands) {
        final total = bands.fold(0, (sum, band) => sum + band.offerCount);

        return ChartContainer(
          title: 'Offer Distribution by Package',
          subtitle: '$total offers made this season',
          height: 240,
          chart: BarChartWidget(
            barColor: AppColors.primaryBlue,
            data: [
              for (final band in bands)
                BarChartDatum(
                  label: band.label.replaceAll('₹', ''),
                  value: band.offerCount.toDouble(),
                ),
            ],
          ),
        );
      },
    );
  }
}
