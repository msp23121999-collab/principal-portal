import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/cards/highlight_list_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/institution_providers.dart';

/// Thresholds used to derive alerts from existing department data.
///
/// Kept as named constants so a future requirement to make them configurable
/// has one place to point at.
const double _attendanceThreshold = 75.0;
const double _passThreshold = 70.0;
const double _placementThreshold = 50.0;
const double _strongPerformanceThreshold = 85.0;

/// Institutional alerts derived from live department data.
///
/// Every alert is computed from `v_department_rollup` — no additional
/// backend, no stored alerts, and nothing hardcoded.
class InstitutionalAlertsSection extends ConsumerWidget {
  const InstitutionalAlertsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsProvider);

    return departmentsAsync.when(
      loading: () => const CardSkeleton(height: 240),
      error: (err, st) => const ErrorState(),
      data: (departments) {
        final alerts = <HighlightEntry>[];

        // Only consider departments that have students on the roll.
        final withStudents = departments.where((d) => d.studentCount > 0);

        // --- Warning alerts ---

        for (final d in withStudents) {
          if (d.attendancePercent > 0 &&
              d.attendancePercent < _attendanceThreshold) {
            alerts.add(
              HighlightEntry(
                icon: AppIcons.warning,
                title: '${d.shortCode} attendance below threshold',
                detail:
                    '${d.attendancePercent.toStringAsFixed(1)}% — '
                    'below the ${_attendanceThreshold.toStringAsFixed(0)}% mark',
                color: AppColors.warning,
              ),
            );
          }
        }

        for (final d in withStudents) {
          if (d.passPercent > 0 && d.passPercent < _passThreshold) {
            alerts.add(
              HighlightEntry(
                icon: AppIcons.results,
                title: '${d.shortCode} pass percentage dropped',
                detail:
                    '${d.passPercent.toStringAsFixed(1)}% — '
                    'below ${_passThreshold.toStringAsFixed(0)}% target',
                color: AppColors.danger,
              ),
            );
          }
        }

        for (final d in departments) {
          if (d.placementPercent > 0 &&
              d.placementPercent < _placementThreshold) {
            alerts.add(
              HighlightEntry(
                icon: AppIcons.placements,
                title: '${d.shortCode} placement needs attention',
                detail:
                    '${d.placementPercent.toStringAsFixed(1)}% placed — '
                    'below ${_placementThreshold.toStringAsFixed(0)}% target',
                color: AppColors.warning,
              ),
            );
          }
        }

        // Faculty availability: flag departments with no faculty recorded.
        for (final d in departments) {
          if (d.studentCount > 0 && d.facultyCount == 0) {
            alerts.add(
              HighlightEntry(
                icon: AppIcons.faculty,
                title: '${d.shortCode} has no faculty recorded',
                detail:
                    '${d.studentCount} students with no faculty on the roll',
                color: AppColors.danger,
              ),
            );
          }
        }

        // --- Positive highlights ---

        for (final d in withStudents) {
          if (d.passPercent >= _strongPerformanceThreshold &&
              d.attendancePercent >= _attendanceThreshold) {
            alerts.add(
              HighlightEntry(
                icon: AppIcons.award,
                title: '${d.shortCode} showing strong performance',
                detail:
                    '${d.passPercent.toStringAsFixed(1)}% pass rate, '
                    '${d.attendancePercent.toStringAsFixed(1)}% attendance',
                color: AppColors.success,
              ),
            );
          }
        }

        return HighlightListCard(
          title: 'Institutional Alerts',
          subtitle: 'Auto-generated from live department data',
          emptyMessage: 'No alerts — all departments are performing well.',
          entries: alerts,
        );
      },
    );
  }
}
