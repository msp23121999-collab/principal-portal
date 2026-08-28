import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/placement_providers.dart';

/// Individual student placement offers, most recent first.
class PlacedStudentsTable extends ConsumerWidget {
  const PlacedStudentsTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(placementRecordsProvider);

    return TableContainer(
      title: 'Placement Offers',
      subtitle: 'Most recent offers first',
      child: recordsAsync.when(
        loading: () => const CardSkeleton(height: 320),
        error: (err, st) => const ErrorState(),
        data: (records) {
          final sorted = [...records]
            ..sort((a, b) => b.offerDate.compareTo(a.offerDate));
          return CustomDataTable(
            columns: const [
              DataColumnConfig(label: 'Student', size: ColumnSize.L),
              DataColumnConfig(label: 'Roll Number', size: ColumnSize.M),
              DataColumnConfig(label: 'Department', size: ColumnSize.S),
              DataColumnConfig(label: 'Company', size: ColumnSize.M),
              DataColumnConfig(
                label: 'Package',
                numeric: true,
                size: ColumnSize.S,
              ),
              DataColumnConfig(label: 'Offer Date', size: ColumnSize.S),
            ],
            rows: [
              for (final r in sorted)
                DataRow2(
                  cells: [
                    DataCell(
                      Text(
                        r.studentName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    DataCell(Text(r.rollNumber)),
                    DataCell(
                      Text(DepartmentNormalizer.codeFor(r.departmentId)),
                    ),
                    DataCell(Text(r.companyName)),
                    DataCell(
                      Text(
                        '₹${r.packageLpa.toStringAsFixed(1)} LPA',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(Text(DateFormatter.shortDate(r.offerDate))),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
