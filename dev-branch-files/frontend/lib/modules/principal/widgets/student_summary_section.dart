import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import './cards/analytics_card.dart';
import './cards/info_tile.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';

/// Student aggregate detail card (enrollment, CGPA, attendance, top/at-risk
/// counts) — full rankings live on Student Performance.
class StudentSummarySection extends ConsumerWidget {
  const StudentSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => const ErrorState(),
      data: (summary) {
        final s = summary.studentSummary;
        return AnalyticsCard(
          title: 'Student Summary',
          subtitle: 'Institution-wide enrollment overview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoTile(
                label: 'Total Students',
                value: s.totalStudents.toString(),
                icon: AppIcons.students,
              ),
              const SizedBox(height: AppSpacing.lg),
              InfoTile(
                label: 'Average CGPA',
                value: s.averageCgpa.toStringAsFixed(2),
                icon: AppIcons.results,
              ),
              const SizedBox(height: AppSpacing.lg),
              InfoTile(
                label: 'Average Attendance',
                value: '${s.averageAttendancePercent.toStringAsFixed(1)}%',
                icon: AppIcons.attendance,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: InfoTile(
                      label: 'Top Performers',
                      value: s.topPerformerCount.toString(),
                      icon: AppIcons.award,
                    ),
                  ),
                  Expanded(
                    child: InfoTile(
                      label: 'At Risk',
                      value: s.atRiskCount.toString(),
                      icon: AppIcons.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
