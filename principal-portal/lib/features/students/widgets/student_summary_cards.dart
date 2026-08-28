import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/student.dart';

/// Headline KPI row for the Student Performance screen.
class StudentSummaryCards extends ConsumerWidget {
  const StudentSummaryCards({super.key});

  /// Mean of one field across the roll, skipping unrecorded (zero) values.
  ///
  /// A student whose CGPA has not been entered yet must not drag the
  /// institutional average down towards zero — that would understate every
  /// department at the start of a semester.
  static double _average(
    List<Student> students,
    double Function(Student) field,
  ) {
    final recorded = students.map(field).where((v) => v > 0);
    if (recorded.isEmpty) return 0;
    return recorded.reduce((a, b) => a + b) / recorded.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(filteredStudentsProvider);

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
            iconColor: AppChartPalette.at(0),
            iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
          ),
          StatisticsCard(
            label: 'Average Attendance',
            value:
                '${_average(students, (s) => s.attendancePercent).toStringAsFixed(1)}%',
            icon: AppIcons.attendance,
            iconColor: AppChartPalette.at(1),
            iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
          ),
          StatisticsCard(
            label: 'At Risk',
            value: students.where((s) => s.isAtRisk).length.toString(),
            icon: AppIcons.warning,
            iconColor: AppColors.warning,
            iconBackground: AppColors.warningTint,
          ),
        ],
      ),
    );
  }
}
