import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../models/examination.dart';
import '../../providers/examination_providers.dart';
import '../exam_stage_chip.dart';

/// Result publication position for every semester in the cycle.
class ResultPublicationTab extends ConsumerWidget {
  const ResultPublicationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicationsAsync = ref.watch(resultPublicationProvider);

    return publicationsAsync.when(
      loading: () => const CardSkeleton(height: 420),
      error: (err, st) => const ErrorState(),
      data: (publications) {
        final outstanding = publications
            .where((p) => p.stage != ExamStage.published)
            .length;

        return TableContainer(
          title: 'Result Publication Status',
          subtitle: outstanding == 0
              ? 'All semester results have been published'
              : '$outstanding of ${publications.length} semesters awaiting publication',
          actions: [
            SecondaryButton(
              label: 'Publish Pending',
              onPressed: outstanding == 0
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$outstanding semester result(s) submitted for publication.',
                        ),
                      ),
                    ),
            ),
          ],
          child: CustomDataTable(
            emptyMessage: 'No examinations have concluded yet.',
            columns: const [
              DataColumnConfig(label: 'Semester', size: ColumnSize.M),
              DataColumnConfig(label: 'Exam Ended', size: ColumnSize.M),
              DataColumnConfig(label: 'Papers', numeric: true),
              DataColumnConfig(label: 'Evaluated', numeric: true),
              DataColumnConfig(label: 'Evaluation %', numeric: true),
              DataColumnConfig(label: 'Published On', size: ColumnSize.M),
              DataColumnConfig(label: 'Stage', size: ColumnSize.M),
            ],
            rows: [
              for (final publication in publications)
                _publicationRow(publication),
            ],
          ),
        );
      },
    );
  }

  DataRow2 _publicationRow(ResultPublication publication) {
    final complete = publication.evaluationPercent >= 100;

    return DataRow2(
      cells: [
        DataCell(Text(publication.semester)),
        DataCell(Text(DateFormatter.shortDate(publication.examEndedOn))),
        DataCell(Text('${publication.papersTotal}')),
        DataCell(Text('${publication.papersEvaluated}')),
        DataCell(
          Text(
            '${publication.evaluationPercent.toStringAsFixed(0)}%',
            style: TextStyle(
              color: complete ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          Text(
            publication.publishedOn == null
                ? '—'
                : DateFormatter.shortDate(publication.publishedOn!),
          ),
        ),
        DataCell(ExamStageChip(stage: publication.stage)),
      ],
    );
  }
}
