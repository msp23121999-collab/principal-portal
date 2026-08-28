import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/institution_providers.dart';

/// The institution's headline figures.
///
/// Counted from `v_department_rollup` rather than read from the stored
/// `kpi_snapshots` text, so this page and the Dashboard cannot report
/// different student counts for the same institution — which they did, 4,740
/// against 10, until these were derived.
///
/// Every card carries a subtitle so the row ends flush; see
/// [StatisticsCard.minHeight].
class InstitutionKpiGrid extends ConsumerWidget {
  const InstitutionKpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final figuresAsync = ref.watch(institutionLiveKpisProvider);
    final department = ref.watch(portalFiltersProvider).departmentCode;
    final scope = department ?? 'Across the institution';

    return figuresAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(6, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (f) => ResponsiveGrid(
        children: [
          StatisticsCard(
            label: 'Total Students',
            value: NumberFormatter.thousands(f.totalStudents),
            icon: AppIcons.students,
            iconColor: AppChartPalette.at(0),
            iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
            subtitle: scope,
          ),
          StatisticsCard(
            label: 'Total Faculty',
            value: NumberFormatter.thousands(f.totalFaculty),
            icon: AppIcons.faculty,
            iconColor: AppChartPalette.at(1),
            iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
            subtitle: scope,
          ),
          StatisticsCard(
            label: 'Departments',
            value: f.departments.toString(),
            icon: AppIcons.department,
            iconColor: AppChartPalette.at(2),
            iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
            subtitle: 'Across engineering & technology',
          ),
          StatisticsCard(
            label: 'Avg. Attendance',
            // Weighted by head-count, so a six-student department does not
            // pull the institutional average as hard as a large one.
            value: f.averageAttendance == 0
                ? '—'
                : '${f.averageAttendance.toStringAsFixed(1)}%',
            icon: AppIcons.attendance,
            iconColor: AppChartPalette.at(3),
            iconBackground: AppChartPalette.at(3).withValues(alpha: 0.10),
            subtitle: 'Weighted by student numbers',
          ),
          StatisticsCard(
            label: 'Avg. Placement',
            value: f.averagePlacement == 0
                ? '—'
                : '${f.averagePlacement.toStringAsFixed(1)}%',
            icon: AppIcons.placements,
            iconColor: AppChartPalette.at(4),
            iconBackground: AppChartPalette.at(4).withValues(alpha: 0.10),
            subtitle: 'Weighted by student numbers',
          ),
          StatisticsCard(
            label: 'NIRF Ranking',
            // The one figure still read from `kpi_snapshots`: a ranking is
            // awarded and recorded, not counted from the rolls.
            value: f.nirfRanking ?? '—',
            icon: AppIcons.trendUp,
            iconColor: AppChartPalette.at(5),
            iconBackground: AppChartPalette.at(5).withValues(alpha: 0.10),
            trendValue: f.nirfTrend,
            subtitle: 'As last published',
          ),
        ],
      ),
    );
  }
}
