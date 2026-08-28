import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/department_providers.dart';

/// Matrix for comparing department performance side-by-side.
class DepartmentComparisonMatrix extends ConsumerWidget {
  const DepartmentComparisonMatrix({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(departmentInsightsProvider);

    return TableContainer(
      title: 'Department Comparison Matrix',
      subtitle:
          'Side-by-side performance comparison against institutional baselines.',
      child: insightsAsync.when(
        loading: () => const CardSkeleton(height: 240),
        error: (err, st) => const ErrorState(),
        data: (insights) => CustomDataTable(
          columns: const [
            DataColumnConfig(label: 'Department', size: ColumnSize.L),
            DataColumnConfig(label: 'Status', size: ColumnSize.M),
            DataColumnConfig(
              label: 'Result (CGPA)',
              numeric: true,
              size: ColumnSize.M,
            ),
            DataColumnConfig(
              label: 'Attendance',
              numeric: true,
              size: ColumnSize.M,
            ),
            DataColumnConfig(
              label: 'Placement',
              numeric: true,
              size: ColumnSize.S,
            ),
          ],
          rows: [
            for (final d in insights)
              DataRow2(
                cells: [
                  DataCell(
                    Text(
                      d.departmentCode,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataCell(_buildStatusBadge(context, d.status)),
                  DataCell(
                    _buildTrendValue(
                      d.cgpa.toStringAsFixed(2),
                      d.cgpaTrend,
                      d.cgpaDiff > 0
                          ? '+${d.cgpaDiff.toStringAsFixed(2)}'
                          : d.cgpaDiff.toStringAsFixed(2),
                    ),
                  ),
                  DataCell(
                    _buildTrendValue(
                      '${d.attendance.toStringAsFixed(1)}%',
                      d.attendanceTrend,
                      d.attendanceDiff > 0
                          ? '+${d.attendanceDiff.toStringAsFixed(1)}%'
                          : '${d.attendanceDiff.toStringAsFixed(1)}%',
                    ),
                  ),
                  DataCell(
                    Text(
                      '${d.placement.toStringAsFixed(1)}%',
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

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color bgColor;
    Color textColor;
    if (status == 'Strong') {
      bgColor = AppColors.successTint;
      textColor = AppColors.success;
    } else if (status == 'Needs Attention') {
      bgColor = AppColors.warningTint;
      textColor = AppColors.warning;
    } else {
      bgColor = AppColors.dangerTint;
      textColor = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      // Size comes from the theme, never stated here — a page that sets its own
      // is how the type scale drifts apart. labelSmall is the badge slot.
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTrendValue(
    String value,
    TrendDirection direction,
    String diffStr,
  ) {
    IconData icon;
    Color color;

    if (direction == TrendDirection.improving) {
      icon = AppIcons.trendUp;
      color = AppColors.success;
    } else if (direction == TrendDirection.declining) {
      icon = AppIcons.trendDown;
      color = AppColors.danger;
    } else {
      icon = AppIcons.horizontalRule;
      color = AppColors.secondaryText;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        Tooltip(
          message: direction == TrendDirection.stable ? 'Stable' : diffStr,
          child: Icon(icon, size: 14, color: color),
        ),
      ],
    );
  }
}
