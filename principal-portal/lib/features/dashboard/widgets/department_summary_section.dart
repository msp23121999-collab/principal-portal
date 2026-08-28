import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_card.dart';

/// Shared height floor for the three summary panels on the Dashboard.
///
/// Set to 460 to force equal-height cards without using IntrinsicHeight,
/// which under-calculates height when text wraps and causes RenderFlex overflows.
const double kDashboardPanelMinHeight = 460;

/// Ranked mini-list of departments (name, student count, attendance %) —
/// deeper department analytics live on the dedicated Department Analytics
/// screen; this is a glance-able summary only.
class DepartmentSummarySection extends ConsumerWidget {
  /// How many departments the dashboard panel lists.
  static const int _visibleDepartments = 5;

  const DepartmentSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final department = ref.watch(portalFiltersProvider).departmentCode;

    return summaryAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => ErrorState(error: err),
      data: (summary) {
        // Honours the department filter above. Picking CSE should leave this
        // panel showing CSE, not the whole institution beside a filter row
        // claiming otherwise.
        final inScope = department == null
            ? summary.departmentRows
            : summary.departmentRows
                  .where((r) => r.shortCode == department)
                  .toList();

        if (inScope.isEmpty) {
          return const DashboardCard(
            minHeight: kDashboardPanelMinHeight,
            title: 'Department',
            icon: AppIcons.department,
            iconColor: AppColors.primaryBlue,
            child: EmptyState(
              message: 'No department data for the selected filters.',
            ),
          );
        }

        // Capped at the leading departments. All twelve made this panel three
        // times the height of the two beside it, which is what left the row
        // uneven — and a Principal reading a dashboard wants the head of the
        // table, not the whole of it. Department Performance has the full list.
        final ranked = inScope.take(_visibleDepartments).toList();
        final remaining = inScope.length - ranked.length;

        return DashboardCard(
          minHeight: kDashboardPanelMinHeight,
          title: 'Department',
          icon: AppIcons.department,
          iconColor: AppColors.primaryBlue,
          subtitle: remaining > 0
              ? 'Top $_visibleDepartments by overall performance · '
                    '$remaining more in Department Performance'
              : 'Ranked by overall institutional performance',
          child: Column(
            children: [
              for (final row in ranked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueTint,
                          borderRadius: AppRadius.smRadius,
                        ),
                        child: Text(
                          '#${row.rank}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '${row.shortCode} · ${row.studentCount} students',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${row.attendancePercent.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
