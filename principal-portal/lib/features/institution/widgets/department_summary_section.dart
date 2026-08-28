import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/widgets/buttons/icon_action_button.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/data_display/table_pagination_bar.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/department.dart';
import '../providers/institution_filter_providers.dart';

/// Department Summary: one row per department with programme, headcount
/// and performance figures, an Overall Total row, and pagination.
///
/// The total row always reflects the filtered set, not the full
/// institution, so the figures reconcile with what is on screen.
class DepartmentSummarySection extends ConsumerWidget {
  const DepartmentSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(filteredDepartmentsProvider);
    final rowsPerPage = ref.watch(departmentTableRowsPerPageProvider);
    final page = ref.watch(departmentTablePageProvider);

    return departmentsAsync.when(
      loading: () => const CardSkeleton(height: 420),
      error: (err, st) => const ErrorState(),
      data: (departments) {
        final pageCount = departments.isEmpty
            ? 1
            : ((departments.length - 1) ~/ rowsPerPage) + 1;
        final safePage = page.clamp(0, pageCount - 1);
        final start = safePage * rowsPerPage;
        final visible = departments.skip(start).take(rowsPerPage).toList();

        return TableContainer(
          title: 'Department Summary',
          subtitle: 'Programme, headcount, and performance by department',
          child: Column(
            children: [
              CustomDataTable(
                emptyMessage: 'No departments match the current filters.',
                columns: const [
                  DataColumnConfig(label: '#', size: ColumnSize.S),
                  DataColumnConfig(label: 'Department', size: ColumnSize.L),
                  DataColumnConfig(
                    label: 'Programs',
                    numeric: true,
                    size: ColumnSize.S,
                  ),
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
                  DataColumnConfig(label: 'Pass %', numeric: true),
                  DataColumnConfig(label: 'Placement %', numeric: true),
                  DataColumnConfig(label: 'Attendance %', numeric: true),
                  DataColumnConfig(label: 'Action', size: ColumnSize.S),
                ],
                rows: [
                  for (int i = 0; i < visible.length; i++)
                    _departmentRow(context, ref, visible[i], start + i + 1),
                  if (visible.isNotEmpty) _totalRow(context, departments),
                ],
              ),
              if (departments.isNotEmpty)
                TablePaginationBar(
                  page: safePage,
                  rowsPerPage: rowsPerPage,
                  totalRows: departments.length,
                  itemNoun: 'departments',
                  onPageChanged: (value) =>
                      ref.read(departmentTablePageProvider.notifier).state =
                          value,
                  onRowsPerPageChanged: (value) {
                    ref
                            .read(departmentTableRowsPerPageProvider.notifier)
                            .state =
                        value;
                    ref.read(departmentTablePageProvider.notifier).state = 0;
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  DataRow2 _departmentRow(
    BuildContext context,
    WidgetRef ref,
    Department department,
    int serial,
  ) {
    return DataRow2(
      cells: [
        DataCell(Text('$serial')),
        DataCell(Text(department.name, overflow: TextOverflow.ellipsis)),
        DataCell(Text('${department.programCount}')),
        DataCell(Text('${department.studentCount}')),
        DataCell(Text('${department.facultyCount}')),
        DataCell(Text('${department.passPercent.toStringAsFixed(2)}%')),
        DataCell(
          Text(
            department.placementPercent == 0
                ? '—'
                : '${department.placementPercent.toStringAsFixed(2)}%',
          ),
        ),
        DataCell(Text('${department.attendancePercent.toStringAsFixed(2)}%')),
        DataCell(
          IconActionButton(
            icon: AppIcons.chevronRight,
            tooltip: 'View ${department.shortCode} details',
            onPressed: () {
              final deptCode = DepartmentNormalizer.codeFor(
                department.shortCode,
              );
              ref.read(portalFiltersProvider.notifier).setDepartment(deptCode);
              context.go(AppRoutes.departmentPerformance);
            },
          ),
        ),
      ],
    );
  }

  DataRow2 _totalRow(BuildContext context, List<Department> departments) {
    final style = Theme.of(context).textTheme.titleSmall;
    final placing = departments.where((d) => d.placementPercent > 0);

    double average(
      double Function(Department) select,
      Iterable<Department> of,
    ) {
      if (of.isEmpty) return 0;
      return of.fold(0.0, (sum, d) => sum + select(d)) / of.length;
    }

    return DataRow2(
      color: WidgetStateProperty.all(AppColors.background),
      cells: [
        const DataCell(SizedBox.shrink()),
        DataCell(Text('Overall Total', style: style)),
        DataCell(
          Text(
            '${departments.fold(0, (sum, d) => sum + d.programCount)}',
            style: style,
          ),
        ),
        DataCell(
          Text(
            '${departments.fold(0, (sum, d) => sum + d.studentCount)}',
            style: style,
          ),
        ),
        DataCell(
          Text(
            '${departments.fold(0, (sum, d) => sum + d.facultyCount)}',
            style: style,
          ),
        ),
        DataCell(
          Text(
            '${average((d) => d.passPercent, departments).toStringAsFixed(2)}%',
            style: style,
          ),
        ),
        DataCell(
          Text(
            placing.isEmpty
                ? '—'
                : '${average((d) => d.placementPercent, placing).toStringAsFixed(2)}%',
            style: style,
          ),
        ),
        DataCell(
          Text(
            // Weighted by head-count and taken only over departments that have
            // one. A flat mean across all twelve counted ten unrecorded
            // departments as 0% and reported 14.60% against the 86.4% on the
            // card above it — the same institution, two different answers.
            () {
              final withRoll = departments.where((d) => d.studentCount > 0);
              final heads = withRoll.fold(0, (sum, d) => sum + d.studentCount);
              if (heads == 0) return '—';
              final weighted =
                  withRoll.fold(
                    0.0,
                    (sum, d) => sum + d.attendancePercent * d.studentCount,
                  ) /
                  heads;
              return '${weighted.toStringAsFixed(2)}%';
            }(),
            style: style,
          ),
        ),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }
}
