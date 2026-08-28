import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_icons.dart';
import '../utils/responsive_utils.dart';
import './cards/statistics_card.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../data/faculty_mock_data.dart';
import '../providers/faculty_providers.dart';

/// Headline KPI row for the Faculty Performance screen.
class FacultySummaryCards extends ConsumerWidget {
  const FacultySummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyAsync = ref.watch(facultyListProvider);

    return facultyAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(4, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (faculty) => ResponsiveGrid(
        children: [
          StatisticsCard(
            label: 'Total Faculty',
            value: faculty.length.toString(),
            icon: AppIcons.faculty,
          ),
          StatisticsCard(
            label: 'Avg. Experience',
            value:
                '${FacultyMockData.averageExperience.toStringAsFixed(1)} yrs',
            icon: AppIcons.trendUp,
          ),
          StatisticsCard(
            label: 'Avg. Attendance',
            value: '${FacultyMockData.averageAttendance.toStringAsFixed(1)}%',
            icon: AppIcons.attendance,
          ),
          StatisticsCard(
            label: 'Research Papers',
            value: FacultyMockData.totalResearchPapers.toString(),
            icon: AppIcons.research,
          ),
        ],
      ),
    );
  }
}
