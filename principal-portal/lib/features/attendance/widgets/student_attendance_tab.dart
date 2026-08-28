import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../students/models/student.dart';
import '../providers/attendance_providers.dart';

AppStatus _statusFor(double percent) {
  if (percent >= 90) return AppStatus.present;
  if (percent >= 75) return AppStatus.pending;
  return AppStatus.absent;
}

/// Student attendance roster, sorted lowest-first so gaps surface at the
/// top of the list.
class StudentAttendanceTab extends ConsumerWidget {
  const StudentAttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentAttendanceProvider);
    final byYear = ref.watch(attendanceByYearProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 2.1: average attendance for each year of study, within
        // whatever the filter row above has narrowed to.
        if (byYear.isNotEmpty) ...[
          ResponsiveGrid(
            minTileWidth: 220,
            children: [
              for (final row in byYear)
                StatisticsCard(
                  label: '${row.year} Year',
                  value: row.average == 0
                      ? '—'
                      : '${row.average.toStringAsFixed(1)}%',
                  icon: AppIcons.attendance,
                  iconColor: AppChartPalette.at(0),
                  iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
                  subtitle:
                      '${row.students} '
                      '${row.students == 1 ? 'student' : 'students'}',
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        _buildTable(context, studentsAsync),
      ],
    );
  }

  Widget _buildTable(
    BuildContext context,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return TableContainer(
      title: 'Student Attendance',
      subtitle: 'Sorted lowest attendance first',
      child: studentsAsync.when(
        loading: () => const CardSkeleton(height: 320),
        error: (err, st) => const ErrorState(),
        data: (students) {
          final sorted = [
            ...students,
          ]..sort((a, b) => a.attendancePercent.compareTo(b.attendancePercent));
          return CustomDataTable(
            columns: const [
              DataColumnConfig(label: 'Name', size: ColumnSize.L),
              DataColumnConfig(label: 'Roll Number', size: ColumnSize.M),
              DataColumnConfig(label: 'Department', size: ColumnSize.S),
              DataColumnConfig(
                label: 'Semester',
                numeric: true,
                size: ColumnSize.S,
              ),
              DataColumnConfig(label: 'Attendance', size: ColumnSize.S),
            ],
            rows: [
              for (final s in sorted)
                DataRow2(
                  cells: [
                    DataCell(
                      Text(
                        s.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    DataCell(Text(s.rollNumber)),
                    DataCell(
                      Text(DepartmentNormalizer.codeFor(s.departmentId)),
                    ),
                    DataCell(Text(s.semester.toString())),
                    DataCell(
                      StatusChip(
                        status: _statusFor(s.attendancePercent),
                        customLabel:
                            '${s.attendancePercent.toStringAsFixed(1)}%',
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
