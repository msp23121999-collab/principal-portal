import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './data_display/custom_data_table.dart';
import './data_display/status_chip.dart';
import './data_display/table_container.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../data/department_mock_data.dart';
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
                      Text(DepartmentMockData.byId(s.departmentId).shortCode),
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
