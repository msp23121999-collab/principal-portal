import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../faculty/providers/faculty_providers.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_card.dart';
import 'department_summary_section.dart';

/// Faculty aggregate detail card (count, experience, attendance, research
/// output) — full filterable roster lives on Faculty Performance.
class FacultySummarySection extends ConsumerWidget {
  const FacultySummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    // Section 4.3: the panel reports who is actually in today, not just how
    // many people are employed. Falls back to the roster figures until the
    // register resolves.
    final attendance = ref.watch(scopedFacultyAttendanceProvider).valueOrNull;

    return summaryAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => const ErrorState(),
      data: (summary) {
        final f = summary.facultySummary;
        return DashboardCard(
          minHeight: kDashboardPanelMinHeight,
          title: 'Faculty',
          icon: AppIcons.faculty,
          iconColor: AppColors.primaryBlue,
          subtitle: switch (attendance) {
            null => 'Institution-wide teaching staff overview',
            // Falling back to today's date here would imply the register was
            // marked and everybody was away, which is a different claim.
            final a when a.total == 0 => 'No register for this selection',
            final a =>
              'Register for ${DateFormatter.shortDate(a.attendanceDate)}',
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "On Register", not "Total Faculty".
              //
              // This counts the staff who have a row in today's attendance
              // register — 12 of the 16 on roll, because only two departments
              // mark it. Labelling that "Total Faculty" put 12 directly beside
              // a KPI card reading 16, two different answers to one question
              // about 400px apart.
              // A "Total Faculty" tile was later added beside this one, which
              // is the exact duplication the note above exists to prevent — the
              // KPI card at the top of the same page already answers it.
              DashboardInfoTile(
                label: 'On Register',
                value: (attendance?.total ?? f.totalFaculty).toString(),
                icon: AppIcons.check,
              ),
              const SizedBox(height: AppSpacing.sm),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: DashboardInfoTile(
                        label: 'Present',
                        value: attendance == null
                            ? '—'
                            : attendance.present.toString(),
                        icon: AppIcons.check,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DashboardInfoTile(
                        label: 'Absent',
                        value: attendance == null
                            ? '—'
                            : attendance.absent.toString(),
                        icon: AppIcons.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: DashboardInfoTile(
                        label: 'On Leave',
                        value: attendance == null
                            ? '—'
                            : attendance.onLeave.toString(),
                        icon: AppIcons.calendar,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DashboardInfoTile(
                        label: 'Research Papers',
                        value: f.totalResearchPapers.toString(),
                        icon: AppIcons.research,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DashboardInfoTile(
                label: 'Faculty Attendance',
                value: '${f.averageAttendancePercent.toStringAsFixed(1)}%',
                icon: AppIcons.attendance,
              ),
            ],
          ),
        );
      },
    );
  }
}
