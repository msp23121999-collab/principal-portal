import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import './data_display/custom_data_table.dart';
import './data_display/table_container.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/placement_providers.dart';

/// Full list of companies that visited campus this season.
class CompaniesTable extends ConsumerWidget {
  const CompaniesTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);

    return TableContainer(
      title: 'Recruiting Companies',
      child: companiesAsync.when(
        loading: () => const CardSkeleton(height: 320),
        error: (err, st) => const ErrorState(),
        data: (companies) => CustomDataTable(
          columns: const [
            DataColumnConfig(label: 'Company', size: ColumnSize.L),
            DataColumnConfig(label: 'Sector', size: ColumnSize.M),
            DataColumnConfig(
              label: 'Students Hired',
              numeric: true,
              size: ColumnSize.S,
            ),
            DataColumnConfig(
              label: 'Avg. Package',
              numeric: true,
              size: ColumnSize.S,
            ),
          ],
          rows: [
            for (final c in companies)
              DataRow2(
                cells: [
                  DataCell(
                    Text(c.name, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  DataCell(Text(c.sector)),
                  DataCell(Text(c.studentsHired.toString())),
                  DataCell(
                    Text(
                      '₹${c.avgPackageLpa.toStringAsFixed(1)} LPA',
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
