import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/filters/portal_filters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/program_level.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../core/widgets/motion/fade_in.dart';
import '../../attendance/models/daily_attendance.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../../faculty/providers/faculty_providers.dart';
import '../models/dashboard_summary.dart';
import '../providers/dashboard_providers.dart';

/// Top-of-page KPI row.
///
/// Six cards, and every one carries a subtitle. That is not decoration: a card
/// without one is shorter than the cards beside it, and a row of cards ending
/// at different heights is the first thing that reads as unfinished.
class DashboardKpiGrid extends ConsumerWidget {
  const DashboardKpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final filters = ref.watch(portalFiltersProvider);
    final scoped = ref.watch(filteredStudentSummaryProvider).valueOrNull;
    final facultyInScope = ref.watch(scopedFacultyProvider).valueOrNull;

    // Reuses the Attendance screen's own provider, which already reads
    // `v_attendance_daily_by_department` when a department is chosen. Building
    // a second query here would be a second answer to the same question.
    final attendance = _latestMarkedDay(
      ref.watch(overallAttendanceTrendProvider).valueOrNull,
    );

    return summaryAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(6, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (summary) {
        final overview = summary.institutionOverview;
        final placement = summary.placementSummary;

        var kpiIndex = 0;
        Widget staggered(Widget card) {
          // Cards arrive in reading order rather than all at once, which is
          // what makes the row look composed instead of dumped.
          final wrapped = FadeIn(
            delay: AppMotion.stagger(kpiIndex),
            child: card,
          );
          kpiIndex++;
          return wrapped;
        }

        return ResponsiveGrid(
          matchHeights: true,
          children: [
            staggered(
              StatisticsCard(
                label: 'Total Students',
                value: (scoped?.total ?? overview.totalStudents).toString(),
                icon: AppIcons.students,
                iconColor: AppColors.accentBlue,
                iconBackground: AppColors.softBlue,
                subtitle: _scopeLabel(filters),
              ),
            ),
            staggered(
              StatisticsCard(
                label: 'Total Faculty',
                value: (facultyInScope?.length ?? overview.totalFaculty)
                    .toString(),
                icon: AppIcons.faculty,
                iconColor: AppColors.accentGreen,
                iconBackground: AppColors.softGreen,
                subtitle: filters.departmentCode == null
                    ? 'Teaching staff on roll'
                    : '${filters.departmentCode} teaching staff',
              ),
            ),
            staggered(
              StatisticsCard(
                label: 'Departments',
                value: overview.totalDepartments.toString(),
                icon: AppIcons.department,
                iconColor: AppColors.accentPurple,
                iconBackground: AppColors.softPurple,
                subtitle: 'Across engineering & technology',
              ),
            ),
            staggered(
              StatisticsCard(
                label: "Today's Attendance",
                value: attendance == null
                    ? NumberFormatter.unrecorded
                    : '${attendance.toStringAsFixed(1)}%',
                icon: AppIcons.attendance,
                iconColor: AppColors.accentOrange,
                iconBackground: AppColors.softOrange,
                subtitle: attendance == null
                    ? 'No register marked yet'
                    : (filters.departmentCode == null
                          ? 'Latest marked day, institution-wide'
                          : 'Latest marked day · ${filters.departmentCode}'),
              ),
            ),
            staggered(
              StatisticsCard(
                label: 'Result Pass %',
                value:
                    '${summary.resultSummary.overallPassPercent.toStringAsFixed(1)}%',
                icon: AppIcons.results,
                iconColor: AppColors.accentCyan,
                iconBackground: AppColors.softCyan,
                subtitle: summary.resultSummary.semesterLabel,
              ),
            ),
            staggered(
              StatisticsCard(
                label: 'Placement %',
                value: placement.placementPercent == null
                    ? NumberFormatter.unrecorded
                    : '${placement.placementPercent!.toStringAsFixed(1)}%',
                icon: AppIcons.placements,
                iconColor: AppColors.accentPink,
                iconBackground: AppColors.softPink,
                subtitle: _placementLabel(placement),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The most recent day on the register that carries a figure.
  ///
  /// The trend arrives oldest-first and its newest entries are routinely null,
  /// because `v_attendance_daily` returns a null percentage for a date nobody
  /// marked. Walking back to the last real figure is the difference between
  /// "91.4% on the 11th" and "0.0% today".
  static double? _latestMarkedDay(List<DailyAttendance>? days) {
    if (days == null) return null;
    for (final day in days.reversed) {
      if (day.percent > 0) return day.percent;
    }
    return null;
  }

  /// What the student count is counting.
  ///
  /// Spelling out the scope means the Principal can tell a genuinely small
  /// number from a heavily filtered one without looking back up at the row of
  /// dropdowns.
  static String _scopeLabel(PortalFilters filters) {
    if (filters.activeCount == 0) return 'Across the institution';

    final parts = [
      if (filters.departmentCode != null) filters.departmentCode!,
      if (filters.programLevel != null) filters.programLevel!.label,
      if (filters.batch != null) 'Batch ${filters.batch}',
      if (filters.yearOfStudy != null) '${filters.yearOfStudy} Year',
      if (filters.academicYear != null) filters.academicYear!,
    ];

    return parts.isEmpty ? 'Filtered' : parts.join(' · ');
  }

  /// "X of Y placed", unless that reads as nonsense.
  ///
  /// Ten of the twelve departments have no students recorded, so placements can
  /// outnumber the roll and the card was reading "60 of 10 placed". Where the
  /// two cannot be reconciled the offer count is shown on its own rather than
  /// against a denominator that is plainly wrong.
  static String _placementLabel(PlacementSummary placement) {
    final placed = placement.totalPlaced;
    final eligible = placement.totalEligible;

    if (eligible == 0) return '$placed offers · roll not recorded';
    if (placed > eligible) return '$placed offers recorded';
    return '$placed of $eligible placed';
  }
}
