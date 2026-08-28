import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/table_export.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../models/report_item.dart';
import '../providers/report_table_provider.dart';

/// A single report in the library — description, last-generated date, and the
/// export action.
class ReportCard extends ConsumerWidget {
  const ReportCard({super.key, required this.report});

  final ReportItem report;

  void _export(BuildContext context, WidgetRef ref) {
    final table = buildReportTable(ref, report.category.name);
    TableExport.run(
      context,
      fileName: reportFileName(report.category.name),
      noun: 'row',
      headers: table.headers,
      rows: table.rows,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip(
                status: AppStatus.info,
                customLabel: report.category.label,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            report.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Last generated: ${DateFormatter.shortDate(report.lastGeneratedAt)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => _export(context, ref),
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(0, 34)),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFFBFDBFE);
                }
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0xFFDBEAFE);
                }
                return const Color(0xFFEFF6FF);
              }),
              side: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.pressed)) {
                  return const BorderSide(color: Color(0xFF93C5FD), width: 1);
                }
                return const BorderSide(color: Color(0xFFBFDBFE), width: 1);
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.pressed)) {
                  return const Color(0xFF1D4ED8);
                }
                return const Color(0xFF2563EB);
              }),
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return 1.0;
                }
                return 0.0;
              }),
              shadowColor: WidgetStateProperty.all(
                const Color(0xFF2563EB).withValues(alpha: 0.12),
              ),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  AppIcons.download,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  'Export CSV',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
