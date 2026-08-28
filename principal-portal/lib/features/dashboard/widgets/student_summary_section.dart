import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_card.dart';
import 'department_summary_section.dart';

/// Student aggregate detail card (enrollment, CGPA, attendance, top/at-risk
/// counts) — full rankings live on Student Performance.
class StudentSummarySection extends ConsumerWidget {
  const StudentSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    // Falls back to the institution figures until the filtered roll resolves,
    // so the panel never blanks while a filter is being applied.
    final scoped = ref.watch(filteredStudentSummaryProvider).valueOrNull;

    return summaryAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => const ErrorState(),
      data: (summary) {
        final s = summary.studentSummary;
        return DashboardCard(
          minHeight: kDashboardPanelMinHeight,
          title: 'Student',
          icon: AppIcons.students,
          iconColor: AppColors.primaryBlue,
          subtitle: scoped == null
              ? 'Institution-wide enrollment overview'
              : 'Enrollment overview for the current scope',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardInfoTile(
                label: 'Total Students',
                value: (scoped?.total ?? s.totalStudents).toString(),
                icon: AppIcons.students,
              ),
              const SizedBox(height: AppSpacing.sm),
              DashboardInfoTile(
                label: 'Average Attendance',
                value:
                    '${(scoped?.averageAttendance ?? s.averageAttendancePercent).toStringAsFixed(1)}%',
                icon: AppIcons.attendance,
              ),
              // No Average CGPA here. It was removed from the Principal's
              // dashboard deliberately: a single institution-wide grade average
              // is not a figure anyone acts on, and it hid the two counts below
              // that are. It came back once; `test/dashboard_filter_test.dart`
              // now fails if it does again.
              const SizedBox(height: AppSpacing.sm),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: DashboardInfoTile(
                        label: 'Top Performers',
                        value: (scoped?.topPerformers ?? s.topPerformerCount)
                            .toString(),
                        icon: AppIcons.award,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DashboardInfoTile(
                        label: 'At Risk',
                        value: (scoped?.atRisk ?? s.atRiskCount).toString(),
                        icon: AppIcons.warning,
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
