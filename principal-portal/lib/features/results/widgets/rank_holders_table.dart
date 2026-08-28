import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/result_providers.dart';

/// Institution-wide rank holders for the currently selected semester.
class RankHoldersTable extends ConsumerWidget {
  const RankHoldersTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankHoldersAsync = ref.watch(rankHoldersProvider);

    return TableContainer(
      title: 'Rank Holders',
      subtitle: 'Top-performing students institution-wide',
      child: rankHoldersAsync.when(
        loading: () => const CardSkeleton(height: 260),
        error: (err, st) => const ErrorState(),
        data: (holders) => CustomDataTable(
          emptyMessage: 'No rank holders published for this semester yet.',
          columns: const [
            DataColumnConfig(label: 'Rank', size: ColumnSize.S),
            DataColumnConfig(label: 'Student', size: ColumnSize.L),
            DataColumnConfig(label: 'Roll Number', size: ColumnSize.M),
            DataColumnConfig(label: 'Department', size: ColumnSize.S),
            DataColumnConfig(label: 'CGPA', numeric: true, size: ColumnSize.S),
          ],
          rows: [
            for (final h in holders)
              DataRow2(
                cells: [
                  DataCell(
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accentGoldTint,
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Text(
                        '#${h.rank}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      h.studentName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  DataCell(Text(h.rollNumber)),
                  DataCell(Text(DepartmentNormalizer.codeFor(h.departmentId))),
                  DataCell(
                    Text(
                      h.cgpa.toStringAsFixed(2),
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
