import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../../core/widgets/inputs/filter_dropdown.dart';
import '../../models/examination.dart';
import '../../providers/examination_providers.dart';
import '../exam_stage_chip.dart';
import '../examination_kpi_grid.dart';

/// The examination timetable, filterable by lifecycle stage.
class ExamScheduleTab extends ConsumerWidget {
  const ExamScheduleTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(examScheduleProvider);
    final stage = ref.watch(examStageFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExaminationKpiGrid(),
        const SizedBox(height: 20),
        scheduleAsync.when(
          loading: () => const CardSkeleton(height: 420),
          error: (err, st) => const ErrorState(),
          data: (schedule) => TableContainer(
            title: 'Examination Timetable',
            // Read from the papers on screen. It used to say "April - May
            // 2025" whatever the timetable held, so it went wrong the moment
            // the next exam session was loaded — and it also ignored the
            // department and semester filters that narrow this very table.
            subtitle: _periodOf(schedule) ?? 'No papers scheduled',
            actions: [
              FilterDropdown<String>(
                value: stage?.name ?? _allStages,
                items: [_allStages, ...ExamStage.values.map((s) => s.name)],
                itemLabel: (value) => value == _allStages
                    ? 'All Stages'
                    : ExamStage.values.byName(value).label,
                width: 180,
                onChanged: (value) =>
                    ref
                        .read(examStageFilterProvider.notifier)
                        .state = value == _allStages
                    ? null
                    : ExamStage.values.byName(value!),
              ),
            ],
            child: CustomDataTable(
              emptyMessage: 'No papers at this stage.',
              columns: const [
                DataColumnConfig(label: 'Date', size: ColumnSize.M),
                DataColumnConfig(label: 'Session', size: ColumnSize.S),
                DataColumnConfig(label: 'Code', size: ColumnSize.S),
                DataColumnConfig(label: 'Subject', size: ColumnSize.L),
                DataColumnConfig(label: 'Dept', size: ColumnSize.S),
                DataColumnConfig(label: 'Semester', size: ColumnSize.M),
                DataColumnConfig(label: 'Hall', size: ColumnSize.L),
                DataColumnConfig(label: 'Candidates', numeric: true),
                DataColumnConfig(label: 'Stage', size: ColumnSize.M),
              ],
              rows: [for (final exam in schedule) _scheduleRow(exam)],
            ),
          ),
        ),
      ],
    );
  }

  static const String _allStages = '__all__';

  /// The months the papers on screen fall across.
  String? _periodOf(List<ExamSchedule> schedule) {
    final period = DateFormatter.monthRange([for (final e in schedule) e.date]);
    return period == null ? null : 'End-semester examinations, $period';
  }

  DataRow2 _scheduleRow(ExamSchedule exam) {
    return DataRow2(
      cells: [
        DataCell(Text(DateFormatter.shortDate(exam.date))),
        DataCell(Text(exam.session)),
        DataCell(Text(exam.subjectCode)),
        DataCell(Text(exam.subjectName, overflow: TextOverflow.ellipsis)),
        DataCell(Text(exam.departmentCode)),
        DataCell(Text(exam.semester)),
        DataCell(Text(exam.hall, overflow: TextOverflow.ellipsis)),
        DataCell(Text('${exam.candidates}')),
        DataCell(ExamStageChip(stage: exam.stage)),
      ],
    );
  }
}
