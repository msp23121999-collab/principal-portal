import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import './cards/analytics_card.dart';
import './cards/info_tile.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';

/// Faculty aggregate detail card (count, experience, attendance, research
/// output) — full filterable roster lives on Faculty Performance.
class FacultySummarySection extends ConsumerWidget {
  const FacultySummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => const ErrorState(),
      data: (summary) {
        final f = summary.facultySummary;
        return AnalyticsCard(
          title: 'Faculty Summary',
          subtitle: 'Institution-wide teaching staff overview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoTile(
                label: 'Total Faculty',
                value: f.totalFaculty.toString(),
                icon: AppIcons.faculty,
              ),
              const SizedBox(height: AppSpacing.lg),
              InfoTile(
                label: 'Average Experience',
                value: '${f.averageExperienceYears.toStringAsFixed(1)} years',
                icon: AppIcons.trendUp,
              ),
              const SizedBox(height: AppSpacing.lg),
              InfoTile(
                label: 'Average Attendance',
                value: '${f.averageAttendancePercent.toStringAsFixed(1)}%',
                icon: AppIcons.attendance,
              ),
              const SizedBox(height: AppSpacing.lg),
              InfoTile(
                label: 'Research Papers Published',
                value: f.totalResearchPapers.toString(),
                icon: AppIcons.research,
              ),
            ],
          ),
        );
      },
    );
  }
}
