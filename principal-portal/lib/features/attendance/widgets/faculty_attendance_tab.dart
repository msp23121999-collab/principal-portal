import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../faculty/models/faculty.dart';
import '../providers/attendance_providers.dart';

AppStatus _statusFor(double percent) {
  if (percent >= 90) return AppStatus.present;
  if (percent >= 80) return AppStatus.pending;
  return AppStatus.absent;
}

/// Faculty attendance roster, sorted lowest-first so gaps surface at the
/// top of the list.
class FacultyAttendanceTab extends ConsumerWidget {
  const FacultyAttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyAsync = ref.watch(facultyAttendanceProvider);

    return TableContainer(
      title: 'Faculty Attendance',
      subtitle: 'Sorted lowest attendance first',
      child: facultyAsync.when(
        loading: () => const CardSkeleton(height: 320),
        error: (err, st) => const ErrorState(),
        data: (faculty) {
          final sorted = [
            ...faculty,
          ]..sort((a, b) => a.attendancePercent.compareTo(b.attendancePercent));
          return CustomDataTable(
            columns: const [
              DataColumnConfig(label: 'Name', size: ColumnSize.L),
              DataColumnConfig(label: 'Department', size: ColumnSize.S),
              DataColumnConfig(label: 'Designation', size: ColumnSize.M),
              DataColumnConfig(label: 'Attendance', size: ColumnSize.S),
            ],
            rows: [
              for (final f in sorted)
                DataRow2(
                  cells: [
                    DataCell(
                      Text(
                        f.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    DataCell(
                      Text(DepartmentNormalizer.codeFor(f.departmentId)),
                    ),
                    DataCell(Text(f.designation.label)),
                    DataCell(
                      StatusChip(
                        status: _statusFor(f.attendancePercent),
                        customLabel:
                            '${f.attendancePercent.toStringAsFixed(1)}%',
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
