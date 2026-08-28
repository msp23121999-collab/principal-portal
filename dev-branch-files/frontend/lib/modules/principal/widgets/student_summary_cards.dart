import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../utils/responsive_utils.dart';
import './cards/statistics_card.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../data/student_mock_data.dart';
import '../providers/student_providers.dart';

/// Headline KPI row for the Student Performance screen.
class StudentSummaryCards extends ConsumerWidget {
  const StudentSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentListProvider);

    return studentsAsync.when(
      loading: () => ResponsiveGrid(
        children: List.generate(4, (_) => const CardSkeleton()),
      ),
      error: (err, st) => const ErrorState(),
      data: (students) => ResponsiveGrid(
        children: [
          StatisticsCard(
            label: 'Total Students',
            value: students.length.toString(),
            icon: AppIcons.students,
          ),
          StatisticsCard(
            label: 'Average CGPA',
            value: StudentMockData.averageCgpa.toStringAsFixed(2),
            icon: AppIcons.results,
          ),
          StatisticsCard(
            label: 'Average Attendance',
            value: '${StudentMockData.averageAttendance.toStringAsFixed(1)}%',
            icon: AppIcons.attendance,
          ),
          StatisticsCard(
            label: 'At Risk',
            value: StudentMockData.atRisk.length.toString(),
            icon: AppIcons.warning,
            iconColor: AppColors.warning,
            iconBackground: AppColors.warningTint,
          ),
        ],
      ),
    );
  }
}
