import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards/chart_container.dart';
import '../../../core/widgets/charts/bar_chart_widget.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/attendance_providers.dart';

/// Department-wise attendance comparison — chart plus a supporting table.
class DepartmentAttendanceTab extends ConsumerWidget {
  const DepartmentAttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentAttendanceProvider);

    return departmentsAsync.when(
      loading: () => const CardSkeleton(height: 400),
      error: (err, st) => const ErrorState(),
      data: (departments) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartContainer(
            title: 'Department Attendance',
            subtitle: 'Current semester average',
            chart: BarChartWidget(
              barColor: AppColors.primaryBlue,
              maxY: 100,
              data: [
                for (final d in departments)
                  BarChartDatum(label: d.shortCode, value: d.attendancePercent),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TableContainer(
            title: 'Department Attendance Detail',
            child: CustomDataTable(
              columns: const [
                DataColumnConfig(label: 'Department', size: ColumnSize.L),
                DataColumnConfig(
                  label: 'Students',
                  numeric: true,
                  size: ColumnSize.S,
                ),
                DataColumnConfig(
                  label: 'Faculty',
                  numeric: true,
                  size: ColumnSize.S,
                ),
                DataColumnConfig(
                  label: 'Attendance',
                  numeric: true,
                  size: ColumnSize.S,
                ),
              ],
              rows: [
                for (final d in departments)
                  DataRow2(
                    cells: [
                      DataCell(
                        Text(
                          d.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      DataCell(Text(d.studentCount.toString())),
                      DataCell(Text(d.facultyCount.toString())),
                      DataCell(
                        Text('${d.attendancePercent.toStringAsFixed(1)}%'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
