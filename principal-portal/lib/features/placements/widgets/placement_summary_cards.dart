import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/placement_providers.dart';

/// Headline placement KPIs: placed/eligible, average package, highest
/// package, number of recruiting companies.
///
/// Every figure is computed from the offers and companies actually recorded,
/// rather than read from stored totals that could disagree with the tables
/// below them on the same screen.
class PlacementSummaryCards extends ConsumerWidget {
  const PlacementSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibilityAsync = ref.watch(placementEligibilityProvider);
    final placementsAsync = ref.watch(placementRecordsProvider);
    final companiesAsync = ref.watch(companiesProvider);

    if (eligibilityAsync.hasError ||
        placementsAsync.hasError ||
        companiesAsync.hasError) {
      return const ErrorState();
    }

    final eligibility = eligibilityAsync.valueOrNull;
    final placements = placementsAsync.valueOrNull;
    final companies = companiesAsync.valueOrNull;
    // Who and where behind each figure — section 9.2 asks for the student,
    // department, batch and company, not the number on its own.
    final extremes = ref.watch(packageExtremesProvider).valueOrNull;

    if (eligibility == null || placements == null || companies == null) {
      return ResponsiveGrid(
        children: List.generate(4, (_) => const CardSkeleton()),
      );
    }

    // Ten of the twelve departments have nobody recorded on the roll, so the
    // offers can outnumber the students eligible for them. '60/10' with a
    // '100.0% placement rate' beneath it is not a figure anyone can act on.
    final reconciles =
        eligibility.eligible > 0 && eligibility.placed <= eligibility.eligible;
    final placementPercent = reconciles
        ? eligibility.placed / eligibility.eligible * 100
        : null;

    final packages = placements.map((p) => p.packageLpa).toList();
    final averagePackage = packages.isEmpty
        ? 0.0
        : packages.reduce((a, b) => a + b) / packages.length;
    final highestPackage = packages.isEmpty
        ? 0.0
        : packages.reduce((a, b) => a > b ? a : b);
    final lowestPackage = packages.isEmpty
        ? 0.0
        : packages.reduce((a, b) => a < b ? a : b);

    return ResponsiveGrid(
      children: [
        StatisticsCard(
          label: 'Students Placed',
          value: reconciles
              ? '${eligibility.placed}/${eligibility.eligible}'
              : '${eligibility.placed}',
          icon: AppIcons.placements,
          iconColor: AppChartPalette.at(0),
          iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
          subtitle: placementPercent == null
              ? 'Offers recorded · roll incomplete'
              : '${placementPercent.toStringAsFixed(1)}% placement rate',
        ),
        StatisticsCard(
          label: 'Average Package',
          value: '₹${averagePackage.toStringAsFixed(1)} LPA',
          icon: AppIcons.currency,
          iconColor: AppChartPalette.at(1),
          iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
        ),
        StatisticsCard(
          label: 'Highest Package',
          value: '₹${highestPackage.toStringAsFixed(1)} LPA',
          icon: AppIcons.trendUp,
          iconColor: AppChartPalette.at(2),
          iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
          subtitle: _extremeDetail(extremes?.highest),
        ),
        StatisticsCard(
          // Section 9.2 asks for the lowest as well as the highest. A season
          // is described by its range, not by its best offer alone.
          label: 'Lowest Package',
          value: '₹${lowestPackage.toStringAsFixed(1)} LPA',
          icon: AppIcons.trendDown,
          iconColor: AppChartPalette.at(3),
          iconBackground: AppChartPalette.at(3).withValues(alpha: 0.10),
          subtitle: _extremeDetail(extremes?.lowest),
        ),
        StatisticsCard(
          label: 'Companies Visited',
          value: companies.length.toString(),
          icon: AppIcons.company,
          iconColor: AppChartPalette.at(4),
          iconBackground: AppChartPalette.at(4).withValues(alpha: 0.10),
        ),
      ],
    );
  }
}

/// "Name · DEPT · Batch · Company" for a package card, or a fallback.
///
/// A package with nobody attached to it is not something a Principal can act
/// on, so the card names the offer it came from.
String _extremeDetail(PackageExtreme? extreme) {
  if (extreme == null) return 'No offers in this scope';
  return [
    extreme.studentName,
    extreme.departmentCode,
    if (extreme.batchRange != null) extreme.batchRange!,
    extreme.companyName,
  ].join(' · ');
}
