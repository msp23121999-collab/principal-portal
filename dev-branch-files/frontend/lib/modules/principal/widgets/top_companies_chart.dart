import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import './cards/chart_container.dart';
import './charts/bar_chart_widget.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/placement_providers.dart';

/// Students hired by the top recruiting companies this season.
class TopCompaniesChart extends ConsumerWidget {
  const TopCompaniesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);

    return companiesAsync.when(
      loading: () => const CardSkeleton(height: 280),
      error: (err, st) => const ErrorState(),
      data: (companies) {
        final sorted = [...companies]
          ..sort((a, b) => b.studentsHired.compareTo(a.studentsHired));
        final top6 = sorted.take(6).toList();

        return ChartContainer(
          title: 'Top Recruiters',
          subtitle: 'Students hired this placement season',
          chart: BarChartWidget(
            barColor: AppColors.accentGold,
            data: [
              for (final c in top6)
                BarChartDatum(label: c.name, value: c.studentsHired.toDouble()),
            ],
          ),
        );
      },
    );
  }
}
