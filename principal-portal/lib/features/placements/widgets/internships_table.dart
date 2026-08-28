import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../models/placement_drive.dart';
import '../providers/placement_providers.dart';

/// Internships running this year, and which of them carry a
/// pre-placement offer route.
class InternshipsTable extends ConsumerWidget {
  const InternshipsTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internshipsAsync = ref.watch(internshipsProvider);

    return internshipsAsync.when(
      loading: () => const CardSkeleton(height: 380),
      error: (err, st) => const ErrorState(),
      data: (internships) {
        final students = internships.fold(0, (sum, r) => sum + r.students);

        return TableContainer(
          title: 'Internships',
          subtitle:
              '$students students placed across '
              '${internships.length} organisations',
          child: CustomDataTable(
            emptyMessage: 'No internships recorded this year.',
            columns: const [
              DataColumnConfig(label: 'Organisation', size: ColumnSize.M),
              DataColumnConfig(label: 'Domain', size: ColumnSize.L),
              DataColumnConfig(label: 'Dept', size: ColumnSize.S),
              DataColumnConfig(label: 'Students', numeric: true),
              DataColumnConfig(label: 'Duration', size: ColumnSize.S),
              DataColumnConfig(label: 'Stipend', numeric: true),
              DataColumnConfig(label: 'PPO Route', size: ColumnSize.S),
            ],
            rows: [for (final record in internships) _internshipRow(record)],
          ),
        );
      },
    );
  }

  DataRow2 _internshipRow(InternshipRecord record) {
    return DataRow2(
      cells: [
        DataCell(Text(record.companyName, overflow: TextOverflow.ellipsis)),
        DataCell(Text(record.domain, overflow: TextOverflow.ellipsis)),
        DataCell(Text(record.departmentCode)),
        DataCell(Text('${record.students}')),
        DataCell(Text('${record.durationWeeks} wks')),
        DataCell(
          Text(
            record.monthlyStipend == 0
                ? 'Unpaid'
                : '₹${record.monthlyStipend.toStringAsFixed(0)}/mo',
          ),
        ),
        DataCell(
          StatusChip(
            status: record.convertsToOffer
                ? AppStatus.approved
                : AppStatus.inactive,
            customLabel: record.convertsToOffer ? 'Yes' : 'No',
          ),
        ),
      ],
    );
  }
}
