import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/academic_performance.dart';
import '../providers/academic_providers.dart';

/// Semester-by-semester results, closing with an overall row. Honours the
/// page's semester filter.
class SemesterSummaryTable extends ConsumerWidget {
  const SemesterSummaryTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(semesterSummariesProvider);

    return summariesAsync.when(
      loading: () => const CardSkeleton(height: 240),
      error: (err, st) => const ErrorState(),
      data: (summaries) => TableContainer(
        title: 'Semester Wise Performance',
        subtitle: 'Appearance, pass rate, grade averages, and backlogs',
        child: CustomDataTable(
          emptyMessage: 'No results published for the selected semester.',
          columns: const [
            DataColumnConfig(label: 'Semester', size: ColumnSize.M),
            DataColumnConfig(label: 'Appeared', numeric: true),
            DataColumnConfig(label: 'Passed', numeric: true),
            DataColumnConfig(label: 'Pass %', numeric: true),
            DataColumnConfig(label: 'Avg SGPA', numeric: true),
            DataColumnConfig(label: 'Avg CGPA', numeric: true),
            DataColumnConfig(label: 'Backlogs', numeric: true),
            DataColumnConfig(label: 'Top Performer', size: ColumnSize.L),
          ],
          rows: [
            for (final summary in summaries) _summaryRow(summary),
            if (summaries.length > 1) _overallRow(context, summaries),
          ],
        ),
      ),
    );
  }

  DataRow2 _summaryRow(SemesterSummary summary) {
    return DataRow2(
      cells: [
        DataCell(Text(summary.semester)),
        DataCell(Text('${summary.appeared}')),
        DataCell(Text('${summary.passed}')),
        DataCell(Text('${summary.passPercent.toStringAsFixed(2)}%')),
        DataCell(Text(summary.averageSgpa.toStringAsFixed(2))),
        DataCell(Text(summary.averageCgpa.toStringAsFixed(2))),
        DataCell(Text('${summary.backlogs}')),
        DataCell(
          Text(
            '${summary.topPerformer} (${summary.topPerformerCgpa.toStringAsFixed(2)})',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  DataRow2 _overallRow(BuildContext context, List<SemesterSummary> summaries) {
    final style = Theme.of(context).textTheme.titleSmall;
    final appeared = summaries.fold(0, (sum, s) => sum + s.appeared);
    final passed = summaries.fold(0, (sum, s) => sum + s.passed);
    final backlogs = summaries.fold(0, (sum, s) => sum + s.backlogs);
    final sgpa =
        summaries.fold(0.0, (sum, s) => sum + s.averageSgpa) / summaries.length;
    final cgpa =
        summaries.fold(0.0, (sum, s) => sum + s.averageCgpa) / summaries.length;

    return DataRow2(
      color: WidgetStateProperty.all(AppColors.background),
      cells: [
        DataCell(Text('Overall', style: style)),
        DataCell(Text('$appeared', style: style)),
        DataCell(Text('$passed', style: style)),
        DataCell(
          Text(
            '${(appeared == 0 ? 0 : passed / appeared * 100).toStringAsFixed(2)}%',
            style: style,
          ),
        ),
        DataCell(Text(sgpa.toStringAsFixed(2), style: style)),
        DataCell(Text(cgpa.toStringAsFixed(2), style: style)),
        DataCell(Text('$backlogs', style: style)),
        const DataCell(Text('—')),
      ],
    );
  }
}
