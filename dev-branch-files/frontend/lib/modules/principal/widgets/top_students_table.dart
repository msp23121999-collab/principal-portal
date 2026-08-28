import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import './data_display/custom_data_table.dart';
import './data_display/table_container.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../data/department_mock_data.dart';
import '../providers/student_providers.dart';

/// Top-performing students ranked by CGPA.
class TopStudentsTable extends ConsumerWidget {
  const TopStudentsTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(topPerformersProvider);

    return TableContainer(
      title: 'Top Performers',
      subtitle: 'Ranked by CGPA',
      child: topAsync.when(
        loading: () => const CardSkeleton(height: 260),
        error: (err, st) => const ErrorState(),
        data: (students) => CustomDataTable(
          emptyMessage: 'No top performers to display.',
          columns: const [
            DataColumnConfig(label: 'Name', size: ColumnSize.L),
            DataColumnConfig(label: 'Roll Number', size: ColumnSize.M),
            DataColumnConfig(label: 'Department', size: ColumnSize.S),
            DataColumnConfig(
              label: 'Semester',
              numeric: true,
              size: ColumnSize.S,
            ),
            DataColumnConfig(label: 'CGPA', numeric: true, size: ColumnSize.S),
            DataColumnConfig(
              label: 'Attendance',
              numeric: true,
              size: ColumnSize.S,
            ),
          ],
          rows: [
            for (final s in students)
              DataRow2(
                cells: [
                  DataCell(
                    Text(s.name, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  DataCell(Text(s.rollNumber)),
                  DataCell(
                    Text(DepartmentMockData.byId(s.departmentId).shortCode),
                  ),
                  DataCell(Text(s.semester.toString())),
                  DataCell(
                    Text(
                      s.cgpa.toStringAsFixed(2),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataCell(Text('${s.attendancePercent.toStringAsFixed(1)}%')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
