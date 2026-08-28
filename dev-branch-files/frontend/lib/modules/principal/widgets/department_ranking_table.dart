import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import './data_display/custom_data_table.dart';
import './data_display/table_container.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import './inputs/filter_dropdown.dart';
import '../providers/department_providers.dart';

/// Full department ranking table, sortable by the metric selected in the
/// header's [FilterDropdown].
class DepartmentRankingTable extends ConsumerWidget {
  const DepartmentRankingTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedAsync = ref.watch(sortedDepartmentsProvider);
    final metric = ref.watch(departmentSortMetricProvider);

    return TableContainer(
      title: 'Department Ranking',
      subtitle: 'Sorted by ${metric.label}',
      actions: [
        FilterDropdown<DepartmentSortMetric>(
          value: metric,
          items: DepartmentSortMetric.values,
          itemLabel: (m) => m.label,
          width: 200,
          onChanged: (value) {
            if (value != null) {
              ref.read(departmentSortMetricProvider.notifier).state = value;
            }
          },
        ),
      ],
      child: sortedAsync.when(
        loading: () => const CardSkeleton(height: 240),
        error: (err, st) => const ErrorState(),
        data: (departments) => CustomDataTable(
          columns: const [
            DataColumnConfig(label: 'Rank', size: ColumnSize.S),
            DataColumnConfig(label: 'Department', size: ColumnSize.L),
            DataColumnConfig(
              label: 'Faculty',
              numeric: true,
              size: ColumnSize.S,
            ),
            DataColumnConfig(
              label: 'Students',
              numeric: true,
              size: ColumnSize.S,
            ),
            DataColumnConfig(
              label: 'Attendance',
              numeric: true,
              size: ColumnSize.S,
            ),
            DataColumnConfig(
              label: 'Avg. CGPA',
              numeric: true,
              size: ColumnSize.S,
            ),
            DataColumnConfig(
              label: 'Placement',
              numeric: true,
              size: ColumnSize.S,
            ),
          ],
          rows: [
            for (final d in departments)
              DataRow2(
                cells: [
                  DataCell(Text('#${d.rank}')),
                  DataCell(
                    Text(d.name, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  DataCell(Text(d.facultyCount.toString())),
                  DataCell(Text(d.studentCount.toString())),
                  DataCell(Text('${d.attendancePercent.toStringAsFixed(1)}%')),
                  DataCell(Text(d.avgCgpa.toStringAsFixed(2))),
                  DataCell(
                    Text(
                      '${d.placementPercent.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
