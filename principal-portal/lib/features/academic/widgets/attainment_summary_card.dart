import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/academic_performance.dart';
import '../providers/academic_providers.dart';

/// Course- and programme-outcome attainment counted by level, with each
/// level's share of the outcomes measured.
class AttainmentSummaryCard extends ConsumerWidget {
  const AttainmentSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(attainmentLevelsProvider);

    return levelsAsync.when(
      loading: () => const CardSkeleton(height: 200),
      error: (err, st) => const ErrorState(),
      data: (levels) {
        final totalCo = levels.fold(0, (sum, l) => sum + l.courseOutcomes);
        final totalPo = levels.fold(0, (sum, l) => sum + l.programOutcomes);
        final totalAll = totalCo + totalPo;

        return TableContainer(
          title: 'CO / PO Attainment Summary',
          subtitle: '$totalCo course outcomes, $totalPo programme outcomes',
          child: CustomDataTable(
            emptyMessage: 'Attainment has not been computed yet.',
            columns: const [
              DataColumnConfig(label: 'Attainment Level', size: ColumnSize.L),
              DataColumnConfig(label: 'CO', numeric: true),
              DataColumnConfig(label: 'PO', numeric: true),
              DataColumnConfig(label: 'Overall', numeric: true),
            ],
            rows: [
              for (final level in levels)
                _levelRow(level, totalCo, totalPo, totalAll),
            ],
          ),
        );
      },
    );
  }

  DataRow2 _levelRow(
    AttainmentLevel level,
    int totalCo,
    int totalPo,
    int totalAll,
  ) {
    String share(int count, int total) =>
        total == 0 ? '—' : '$count (${(count / total * 100).round()}%)';

    return DataRow2(
      cells: [
        DataCell(Text(level.label, overflow: TextOverflow.ellipsis)),
        DataCell(Text(share(level.courseOutcomes, totalCo))),
        DataCell(Text(share(level.programOutcomes, totalPo))),
        DataCell(Text(share(level.total, totalAll))),
      ],
    );
  }
}
