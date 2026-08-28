import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../inputs/filter_dropdown.dart';

/// Footer strip beneath a paginated table: a "Showing X to Y of Z" range,
/// numbered page buttons with ellipsis gaps, and a rows-per-page selector.
///
/// Stateless by design — the owning screen holds [page] and [rowsPerPage]
/// so pagination survives rebuilds and can be driven from a provider.
class TablePaginationBar extends StatelessWidget {
  const TablePaginationBar({
    super.key,
    required this.page,
    required this.rowsPerPage,
    required this.totalRows,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    this.rowsPerPageOptions = const [5, 10, 25, 50],
    this.itemNoun = 'records',
  });

  /// Zero-based index of the visible page.
  final int page;
  final int rowsPerPage;
  final int totalRows;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;
  final List<int> rowsPerPageOptions;

  /// Plural noun used in the range summary, e.g. "departments".
  final String itemNoun;

  int get _pageCount =>
      totalRows == 0 ? 1 : ((totalRows - 1) ~/ rowsPerPage) + 1;

  @override
  Widget build(BuildContext context) {
    final first = totalRows == 0 ? 0 : page * rowsPerPage + 1;
    final last = ((page + 1) * rowsPerPage).clamp(0, totalRows);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          Text(
            'Showing $first to $last of $totalRows $itemNoun',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final token in _pageTokens(page, _pageCount))
                token == null
                    ? const _PageGap()
                    : _PageButton(
                        pageNumber: token,
                        selected: token == page,
                        onTap: () => onPageChanged(token),
                      ),
              const SizedBox(width: AppSpacing.xs),
              FilterDropdown<int>(
                value: rowsPerPage,
                items: rowsPerPageOptions,
                itemLabel: (n) => '$n / page',
                onChanged: (value) {
                  if (value != null) onRowsPerPageChanged(value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Page indices to render, with `null` marking a collapsed ellipsis gap.
/// Always keeps the first page, the last page, and the current page's
/// immediate neighbours visible.
List<int?> _pageTokens(int current, int pageCount) {
  if (pageCount <= 7) {
    return [for (int i = 0; i < pageCount; i++) i];
  }

  final tokens = <int?>[0];
  final start = (current - 1).clamp(1, pageCount - 4);
  final end = (current + 1).clamp(3, pageCount - 2);

  if (start > 1) tokens.add(null);
  for (int i = start; i <= end; i++) {
    tokens.add(i);
  }
  if (end < pageCount - 2) tokens.add(null);
  tokens.add(pageCount - 1);

  return tokens;
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.pageNumber,
    required this.selected,
    required this.onTap,
  });

  final int pageNumber;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryBlue : AppColors.surface,
      borderRadius: AppRadius.smRadius,
      child: InkWell(
        borderRadius: AppRadius.smRadius,
        onTap: selected ? null : onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.smRadius,
            border: Border.all(
              color: selected ? AppColors.primaryBlue : AppColors.border,
            ),
          ),
          child: Text(
            '${pageNumber + 1}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: selected ? Colors.white : AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageGap extends StatelessWidget {
  const _PageGap();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 34,
      child: Center(
        child: Text('...', style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
