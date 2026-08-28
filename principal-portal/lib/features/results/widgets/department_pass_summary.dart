import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/result_providers.dart';

/// Department Pass Summary — section 6 of the requirements.
///
/// Appeared, passed, failed and pass percentage per department, summed from
/// the subject results rather than stored, so it cannot drift from the papers
/// behind it and it narrows with the same filters as the rest of the page.
class DepartmentPassSummary extends ConsumerWidget {
  const DepartmentPassSummary({super.key});

  /// Departments at or above this are considered on track.
  static const double _passTarget = 85;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(departmentPassSummaryProvider);

    return TableContainer(
      title: 'Department Pass Summary',
      subtitle: 'Appeared, passed and failed by department, strongest first',
      child: rowsAsync.when(
        loading: () => const CardSkeleton(height: 320),
        error: (err, st) => const ErrorState(),
        data: (rows) => CustomDataTable(
          emptyMessage: 'No results recorded for this selection.',
          columns: const [
            DataColumnConfig(label: 'Department', size: ColumnSize.M),
            DataColumnConfig(label: 'Appeared', numeric: true),
            DataColumnConfig(label: 'Passed', numeric: true),
            DataColumnConfig(label: 'Failed', numeric: true),
            DataColumnConfig(label: 'Pass %', numeric: true),
            DataColumnConfig(label: 'Status', size: ColumnSize.S),
          ],
          rows: [
            for (final row in rows) _row(context, row),
            if (rows.isNotEmpty) _totalRow(context, rows),
          ],
        ),
      ),
    );
  }

  DataRow2 _row(BuildContext context, DepartmentPassRow row) {
    final onTrack = row.passPercent >= _passTarget;

    return DataRow2(
      cells: [
        DataCell(Text(row.departmentCode)),
        DataCell(Text('${row.appeared}')),
        DataCell(Text('${row.passed}')),
        DataCell(
          Text(
            '${row.failed}',
            style: TextStyle(
              color: row.failed > 0 ? AppColors.danger : AppColors.primaryText,
            ),
          ),
        ),
        DataCell(Text('${row.passPercent.toStringAsFixed(2)}%')),
        DataCell(
          StatusChip(
            status: onTrack ? AppStatus.approved : AppStatus.pending,
            customLabel: onTrack ? 'On Track' : 'Below Target',
          ),
        ),
      ],
    );
  }

  /// The institution's own figures, summed from the rows above rather than
  /// averaged across them — a department of forty candidates must not weigh
  /// the same as one of four hundred.
  DataRow2 _totalRow(BuildContext context, List<DepartmentPassRow> rows) {
    final style = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

    final appeared = rows.fold(0, (sum, r) => sum + r.appeared);
    final passed = rows.fold(0, (sum, r) => sum + r.passed);
    final percent = appeared == 0 ? 0.0 : passed / appeared * 100;

    return DataRow2(
      color: WidgetStateProperty.all(AppColors.background),
      cells: [
        DataCell(Text('Overall', style: style)),
        DataCell(Text('$appeared', style: style)),
        DataCell(Text('$passed', style: style)),
        DataCell(Text('${appeared - passed}', style: style)),
        DataCell(Text('${percent.toStringAsFixed(2)}%', style: style)),
        const DataCell(SizedBox.shrink()),
      ],
    );
  }
}
