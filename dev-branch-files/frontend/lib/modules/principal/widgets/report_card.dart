import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/date_formatter.dart';
import './buttons/secondary_button.dart';
import './data_display/status_chip.dart';
import '../models/report_item.dart';

/// A single exportable report — description, last-generated date, and
/// PDF/Excel export actions (stubbed: no real file generation yet).
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report});

  final ReportItem report;

  void _export(BuildContext context, String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${report.title} — $format export simulated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'PDF',
                  icon: AppIcons.document,
                  onPressed: () => _export(context, 'PDF'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  label: 'Excel',
                  icon: AppIcons.download,
                  onPressed: () => _export(context, 'Excel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
