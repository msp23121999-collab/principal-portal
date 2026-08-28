import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../feedback/empty_state.dart';

/// One column definition for [CustomDataTable].
class DataColumnConfig {
  const DataColumnConfig({
    required this.label,
    this.numeric = false,
    this.size = ColumnSize.M,
  });

  final String label;
  final bool numeric;
  final ColumnSize size;
}

/// Generic themed data table built on data_table_2 — fixed header, no
/// horizontal overflow, sortable-ready. Every list screen (faculty,
/// students, leave history, placements, results) uses this instead of
/// hand-rolling its own DataTable.
class CustomDataTable extends StatelessWidget {
  const CustomDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minHeight = 120,
    this.emptyMessage = 'No records found.',
  });

  final List<DataColumnConfig> columns;
  final List<DataRow2> rows;
  final double minHeight;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: EmptyState(message: emptyMessage),
      );
    }

    return SizedBox(
      height: (rows.length * 52 + 56).clamp(minHeight, 520).toDouble(),
      child: DataTable2(
        columnSpacing: AppSpacing.lg,
        horizontalMargin: AppSpacing.lg,
        minWidth: 700,
        headingRowColor: WidgetStateProperty.all(AppColors.background),
        headingRowHeight: 48,
        dataRowHeight: 52,
        dividerThickness: 1,
        columns: [
          for (final c in columns)
            DataColumn2(label: Text(c.label), numeric: c.numeric, size: c.size),
        ],
        rows: rows,
      ),
    );
  }
}
