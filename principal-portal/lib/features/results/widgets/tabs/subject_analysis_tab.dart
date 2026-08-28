import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../../core/widgets/inputs/search_field.dart';
import '../../../academic/models/academic_performance.dart';
import '../../providers/result_providers.dart';

/// Subject-level results, searchable by code, title, department, or the
/// faculty member who handled the paper.
class SubjectAnalysisTab extends ConsumerWidget {
  const SubjectAnalysisTab({super.key});

  /// Papers under this pass rate are surfaced as needing attention.
  static const double _concernThreshold = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(filteredSubjectResultsProvider);
    final ranges = ref.watch(subjectMarkRangesProvider).valueOrNull ?? const {};

    return subjectsAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (subjects) {
        final sorted = [...subjects]
          ..sort((a, b) => a.passPercent.compareTo(b.passPercent));
        final ofConcern = sorted
            .where((s) => s.passPercent < _concernThreshold)
            .length;

        return TableContainer(
          title: 'Subject Performance',
          subtitle: ofConcern == 0
              ? 'All papers are above the ${_concernThreshold.round()}% pass threshold'
              : '$ofConcern of ${sorted.length} papers below the ${_concernThreshold.round()}% pass threshold',
          actions: [
            SearchField(
              width: 260,
              hintText: 'Search subject, code, or faculty',
              onChanged: (value) =>
                  ref.read(resultSubjectSearchProvider.notifier).state = value,
            ),
          ],
          child: CustomDataTable(
            emptyMessage: 'No subjects match the current search.',
            columns: const [
              DataColumnConfig(label: 'Code', size: ColumnSize.S),
              DataColumnConfig(label: 'Subject', size: ColumnSize.L),
              DataColumnConfig(label: 'Dept', size: ColumnSize.S),
              DataColumnConfig(label: 'Sem', size: ColumnSize.S),
              DataColumnConfig(label: 'Faculty', size: ColumnSize.S),
              DataColumnConfig(label: 'Appeared', numeric: true),
              DataColumnConfig(label: 'Passed', numeric: true),
              DataColumnConfig(label: 'Failed', numeric: true),
              DataColumnConfig(label: 'Pass %', numeric: true),
              DataColumnConfig(label: 'Avg', numeric: true),
              DataColumnConfig(label: 'Highest', numeric: true),
              DataColumnConfig(label: 'Lowest', numeric: true),
            ],
            rows: [
              for (final subject in sorted)
                _subjectRow(subject, ranges[subject.name]),
            ],
          ),
        );
      },
    );
  }

  DataRow2 _subjectRow(
    SubjectResult subject,
    ({double highest, double lowest})? range,
  ) {
    final belowThreshold = subject.passPercent < _concernThreshold;

    return DataRow2(
      cells: [
        DataCell(Text(subject.code)),
        DataCell(Text(subject.name, overflow: TextOverflow.ellipsis)),
        DataCell(Text(subject.departmentCode)),
        // Just the number: 'Semester 4' repeated down a narrow column is
        // eleven characters of which one carries the information.
        DataCell(
          Text(
            RegExp(r'(\d+)').firstMatch(subject.semester)?.group(1) ??
                subject.semester,
          ),
        ),
        DataCell(Text(subject.faculty, overflow: TextOverflow.ellipsis)),
        DataCell(Text('${subject.appeared}')),
        DataCell(Text('${subject.passed}')),
        DataCell(
          Text(
            '${subject.appeared - subject.passed}',
            style: TextStyle(
              color: subject.appeared > subject.passed
                  ? AppColors.danger
                  : AppColors.primaryText,
            ),
          ),
        ),
        DataCell(
          Text(
            '${subject.passPercent.toStringAsFixed(1)}%',
            style: TextStyle(
              color: belowThreshold ? AppColors.danger : AppColors.primaryText,
              fontWeight: belowThreshold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        DataCell(Text(subject.averageMarks.toStringAsFixed(1))),
        // Em dash where the Faculty Portal has recorded no marks for the
        // paper: an invented range would read as a real one.
        DataCell(Text(range == null ? '—' : range.highest.toStringAsFixed(0))),
        DataCell(Text(range == null ? '—' : range.lowest.toStringAsFixed(0))),
      ],
    );
  }
}
