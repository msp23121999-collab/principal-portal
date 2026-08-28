import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
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
///
/// When the number of rows exceeds [pageSize] the table paginates
/// automatically. Small datasets render without page controls, exactly
/// as they did before this was introduced.
class CustomDataTable extends StatefulWidget {
  const CustomDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minHeight = 120,
    this.emptyMessage = 'No records found.',
    this.pageSize = 25,
  });

  final List<DataColumnConfig> columns;
  final List<DataRow2> rows;
  final double minHeight;
  final String emptyMessage;

  /// Rows per page. Set to a very large number to disable pagination.
  final int pageSize;

  @override
  State<CustomDataTable> createState() => _CustomDataTableState();
}

class _CustomDataTableState extends State<CustomDataTable> {
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant CustomDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to first page when the data changes (e.g. filter applied).
    if (widget.rows.length != oldWidget.rows.length) {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: EmptyState(message: widget.emptyMessage),
      );
    }

    final totalRows = widget.rows.length;
    final needsPagination = totalRows > widget.pageSize;
    final totalPages = needsPagination
        ? (totalRows / widget.pageSize).ceil()
        : 1;

    // Clamp in case a filter narrowed the data below the current page.
    if (_currentPage >= totalPages) _currentPage = totalPages - 1;

    final visibleRows = needsPagination
        ? widget.rows
              .skip(_currentPage * widget.pageSize)
              .take(widget.pageSize)
              .toList()
        : widget.rows;

    final tableHeight = (visibleRows.length * 52 + 56)
        .clamp(widget.minHeight, 520)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: tableHeight,
          child: DataTable2(
            columnSpacing: AppSpacing.lg,
            horizontalMargin: AppSpacing.lg,
            minWidth: 700,
            headingRowColor: WidgetStateProperty.all(AppColors.elevatedSurface),
            // Column headings should read as labels, not as data: slightly
            // heavier, slightly tracked out, in the muted tone so the figures
            // beneath stay the loudest thing in the table.
            headingTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryText,
              letterSpacing: 0.4,
            ),
            // Row hover. On a wide table the eye loses its place between the
            // first and last column; a faint tint keeps the current row obvious
            // without drawing a border around every one of them.
            dataRowColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => states.contains(WidgetState.hovered)
                  ? AppColors.accentBlue.withValues(alpha: 0.04)
                  : null,
            ),
            // A single rule under the headings, and none between the rows.
            // Ruling every row boxed the data in and made a 25-row table read
            // as a grid of cells; separating the label band from the figures is
            // the only division the reader actually needs.
            border: const TableBorder(
              bottom: BorderSide(color: AppColors.border),
            ),
            headingRowHeight: 48,
            dataRowHeight: 52,
            dividerThickness: 1,
            columns: [
              for (final c in widget.columns)
                DataColumn2(
                  label: Text(c.label),
                  numeric: c.numeric,
                  size: c.size,
                ),
            ],
            rows: visibleRows,
          ),
        ),
        if (needsPagination) _buildPaginationControls(totalPages, totalRows),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages, int totalRows) {
    final start = _currentPage * widget.pageSize + 1;
    final end = (start + widget.pageSize - 1).clamp(1, totalRows);

    // The page controls read as a footer belonging to the table rather than as
    // loose buttons after it: tinted, ruled off, and squared into the card's
    // bottom corners.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.elevatedSurface,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.sm),
          bottomRight: Radius.circular(AppRadius.sm),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $start–$end of $totalRows',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                tooltip: 'Previous page',
                splashRadius: 18,
              ),
              Text(
                'Page ${_currentPage + 1} of $totalPages',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                tooltip: 'Next page',
                splashRadius: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
