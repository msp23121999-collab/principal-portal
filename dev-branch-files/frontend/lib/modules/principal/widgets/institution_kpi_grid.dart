import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_icons.dart';
import '../utils/responsive_utils.dart';
import './cards/statistics_card.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/institution_providers.dart';

const List<IconData> _kpiIcons = [
  AppIcons.students,
  AppIcons.faculty,
  AppIcons.department,
  AppIcons.attendance,
  AppIcons.placements,
  AppIcons.trendUp,
];

/// Responsive grid of institution-wide KPI cards, sourced from
/// [institutionKpisProvider]. Thin data-to-widget mapping over the shared
/// [StatisticsCard] — no bespoke card implementation here.
class InstitutionKpiGrid extends ConsumerWidget {
  const InstitutionKpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(institutionKpisProvider);

    return kpisAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(6, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (kpis) => ResponsiveGrid(
        children: [
          for (int i = 0; i < kpis.length; i++)
            StatisticsCard(
              label: kpis[i].label,
              value: kpis[i].value,
              icon: _kpiIcons[i % _kpiIcons.length],
              trendValue: kpis[i].trendPercent,
              isTrendPositive: kpis[i].isPositive,
            ),
        ],
      ),
    );
  }
}
