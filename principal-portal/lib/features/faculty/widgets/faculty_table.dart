import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/widgets/buttons/icon_action_button.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/faculty.dart';
import '../models/faculty_detail.dart';
import '../providers/faculty_providers.dart';
import 'faculty_profile_dialog.dart';

AppStatus _tierForScore(double score) {
  if (score >= 85) return AppStatus.approved;
  if (score >= 70) return AppStatus.pending;
  return AppStatus.rejected;
}

String _tierLabel(double score) {
  if (score >= 85) return 'Excellent';
  if (score >= 70) return 'Good';
  return 'Needs Support';
}

/// Full filtered faculty roster with performance/attendance/research
/// columns — reads only from [filteredFacultyProvider].
class FacultyTable extends ConsumerWidget {
  const FacultyTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyAsync = ref.watch(filteredFacultyProvider);

    return TableContainer(
      title: 'Faculty Roster',
      child: facultyAsync.when(
        loading: () => const CardSkeleton(height: 320),
        error: (err, st) => const ErrorState(),
        data: (faculty) => CustomDataTable(
          emptyMessage: 'No faculty match the selected filters.',
          columns: const [
            DataColumnConfig(label: 'Name', size: ColumnSize.L),
            DataColumnConfig(label: 'Designation', size: ColumnSize.M),
            DataColumnConfig(label: 'Department', size: ColumnSize.S),
            DataColumnConfig(
              label: 'Experience',
              numeric: true,
              size: ColumnSize.S,
            ),
            DataColumnConfig(
              label: 'Attendance',
              numeric: true,
              size: ColumnSize.S,
            ),
            DataColumnConfig(
              label: 'Research',
              numeric: true,
              size: ColumnSize.S,
            ),
            DataColumnConfig(label: 'Performance', size: ColumnSize.S),
            DataColumnConfig(label: '', size: ColumnSize.S),
          ],
          rows: [
            for (final f in faculty)
              DataRow2(
                cells: [
                  DataCell(
                    Text(f.name, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  DataCell(Text(f.designation.label)),
                  DataCell(Text(DepartmentNormalizer.codeFor(f.departmentId))),
                  DataCell(Text('${f.experienceYears} yrs')),
                  DataCell(Text('${f.attendancePercent.toStringAsFixed(1)}%')),
                  DataCell(Text(f.researchPapersCount.toString())),
                  DataCell(
                    StatusChip(
                      status: _tierForScore(f.performanceScore),
                      customLabel: _tierLabel(f.performanceScore),
                    ),
                  ),
                  DataCell(
                    IconActionButton(
                      icon: AppIcons.chevronRight,
                      tooltip: 'View ${f.name}',
                      onPressed: () {
                        final detail =
                            ref.read(facultyDetailsProvider)[f.id] ??
                            FacultyDetail.fromRosterRow(f);
                        FacultyProfileDialog.show(
                          context,
                          faculty: f,
                          detail: detail,
                        );
                      },
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
