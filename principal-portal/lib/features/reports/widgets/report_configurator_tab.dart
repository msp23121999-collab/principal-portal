import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/csv_export.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/inputs/filter_dropdown.dart';
import '../../../core/widgets/layout/responsive_row.dart';
import '../models/report_run.dart';
import '../providers/report_table_provider.dart';
import '../providers/reports_providers.dart';

/// Build a report: pick the source module, the period, and the output
/// format, then queue it. The queued run appears in Recently Generated.
class ReportConfiguratorTab extends ConsumerWidget {
  const ReportConfiguratorTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(reportModuleSelectionProvider);
    final format = ref.watch(reportFormatSelectionProvider);
    final period = ref.watch(reportPeriodSelectionProvider);

    // Shown in the preview so the Principal knows what they are about to get
    // before pressing Generate — in particular whether it is empty.
    final rowCount = buildReportTable(ref, module).rows.length;

    return ResponsiveRow(
      columns: [
        ResponsiveColumn(
          flex: 6,
          child: AnalyticsCard(
            title: 'Generate a Report',
            subtitle: 'Choose what to include, then queue it for production',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    FilterDropdown<String>(
                      label: 'Module',
                      value: module,
                      items: reportModules,
                      itemLabel: reportModuleLabel,
                      width: 280,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                                  .read(reportModuleSelectionProvider.notifier)
                                  .state =
                              value;
                        }
                      },
                    ),
                    FilterDropdown<ReportPeriod>(
                      label: 'Period',
                      value: period,
                      items: ReportPeriod.values,
                      itemLabel: (value) => value.label,
                      width: 280,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                                  .read(reportPeriodSelectionProvider.notifier)
                                  .state =
                              value;
                        }
                      },
                    ),
                    FilterDropdown<ReportFormat>(
                      label: 'Format',
                      value: format,
                      // CSV only. Nothing in this project can typeset a PDF or
                      // write a native Excel workbook, and offering formats
                      // that silently produce a CSV anyway would be a second
                      // promise the portal cannot keep. The enum keeps its
                      // other values because older runs in the history were
                      // recorded with them.
                      items: const [ReportFormat.csv],
                      itemLabel: (value) => value.label,
                      width: 200,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                                  .read(reportFormatSelectionProvider.notifier)
                                  .state =
                              value;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PrimaryButton(
                    label: 'Generate Report',
                    icon: AppIcons.reports,
                    onPressed: () => _queue(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
        ResponsiveColumn(
          flex: 4,
          child: AnalyticsCard(
            title: 'What Will Be Produced',
            subtitle: 'A preview of the request',
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.smRadius,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The module slug ('placement') was shown raw here while
                  // every other surface reads the display name.
                  _PreviewRow(
                    label: 'Source',
                    value: reportModuleLabel(module),
                  ),
                  _PreviewRow(label: 'Period', value: period.label),
                  _PreviewRow(label: 'Format', value: format.label),
                  _PreviewRow(label: 'Rows', value: '$rowCount'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'The file downloads immediately, and the request is added '
                    'to Recently Generated.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Produces the report and records that it was produced.
  ///
  /// The file comes first. Recording the run is bookkeeping; if that write
  /// fails the Principal still has their report, and saying so is more useful
  /// than refusing to hand it over because a log entry did not save.
  Future<void> _queue(BuildContext context, WidgetRef ref) async {
    final module = ref.read(reportModuleSelectionProvider);
    final format = ref.read(reportFormatSelectionProvider);
    final period = ref.read(reportPeriodSelectionProvider);
    final title = '${reportModuleLabel(module)} — ${period.label}';
    final messenger = ScaffoldMessenger.of(context);

    final table = buildReportTable(ref, module);
    if (table.rows.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'That module has nothing to report on right now. '
            'Try widening the filters or choosing another module.',
          ),
        ),
      );
      return;
    }

    CsvExport.download(
      fileName: reportFileName(module),
      headers: table.headers,
      rows: table.rows,
    );

    try {
      await ref
          .read(reportActionsProvider)
          .request(
            title: title,
            module: module,
            format: format,
            period: period,
          );

      messenger.showSnackBar(
        SnackBar(
          content: Text('$title downloaded — ${table.rows.length} rows.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Report downloaded, but it could not be added to the run history: '
            '$error',
          ),
        ),
      );
    }
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}
