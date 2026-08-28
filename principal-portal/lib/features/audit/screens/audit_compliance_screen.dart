import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/table_export.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/layout/active_tab.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../models/audit.dart';
import '../providers/audit_providers.dart';
import '../widgets/tabs/audit_log_tab.dart';
import '../widgets/tabs/compliance_tab.dart';
import '../widgets/tabs/inspections_tab.dart';

/// Audit & Compliance — the recorded action trail, the compliance
/// scorecard, external inspections, and policy adherence.
class AuditComplianceScreen extends ConsumerWidget {
  const AuditComplianceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(auditSummaryProvider).valueOrNull;

    return TabbedPage(
      title: 'Audit & Compliance',
      breadcrumbSegments: const ['Compliance', 'Audit'],
      // Blank until the figures load, rather than showing zeros that read as
      // a real "0% compliant".
      subtitle: summary == null
          ? ''
          : '${summary.averageComplianceScore.toStringAsFixed(1)}% overall '
                'compliance, ${summary.areasNeedingAction} area(s) needing '
                'action.',
      actions: [
        PrimaryButton(
          label: 'Export Report',
          icon: AppIcons.download,
          onPressed: () => _export(context, ref),
        ),
      ],
      // One button sits above four unrelated tables, so it exports the one in
      // view rather than guessing which the Principal meant.
      onTabChanged: (index) =>
          ref.read(activeTabProvider(TabbedPageKeys.audit).notifier).state =
              index,
      tabs: const [
        PageTab(label: 'Audit Log', content: AuditLogTab()),
        PageTab(label: 'Compliance', content: ComplianceTab()),
        PageTab(label: 'Inspections', content: InspectionsTab()),
      ],
    );
  }

  /// Exports the table on the visible tab, after its own filters.
  void _export(BuildContext context, WidgetRef ref) {
    switch (ref.read(activeTabProvider(TabbedPageKeys.audit))) {
      case 0:
        // The filtered entries, not the whole trail — the tab's module,
        // severity and search controls are the point of the screen.
        final entries = ref.read(auditEntriesProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'audit_log',
          noun: 'entry',
          headers: const [
            'Timestamp',
            'Actor',
            'Role',
            'Action',
            'Module',
            'Detail',
            'IP Address',
            'Severity',
          ],
          rows: [
            for (final e in entries)
              [
                '${DateFormatter.shortDate(e.timestamp)} ${DateFormatter.time(e.timestamp)}',
                e.actor,
                e.actorRole,
                e.action.label,
                e.module,
                e.description,
                e.ipAddress,
                e.severity.label,
              ],
          ],
        );

      case 1:
        final areas = ref.read(complianceAreasProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'compliance_scorecard',
          noun: 'area',
          headers: const [
            'Area',
            'Category',
            'Owner',
            'Score',
            'Maximum',
            'Score %',
            'Last Reviewed',
            'Status',
          ],
          rows: [
            for (final a in areas)
              [
                a.name,
                a.category,
                a.owner,
                a.score,
                a.maximumScore,
                a.scorePercent.toStringAsFixed(1),
                DateFormatter.shortDate(a.lastReviewed),
                a.state.label,
              ],
          ],
        );

      case 2:
        final reports = ref.read(inspectionsProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'inspection_reports',
          noun: 'inspection',
          headers: const [
            'Inspection',
            'Authority',
            'Date',
            'Inspector',
            'Major Findings',
            'Minor Findings',
            'Observations',
            'Closed',
            'Outcome',
          ],
          rows: [
            for (final r in reports)
              [
                r.title,
                r.authority,
                DateFormatter.shortDate(r.inspectedOn),
                r.inspector,
                r.majorFindings,
                r.minorFindings,
                r.observations,
                // Blank, not a date, while findings remain open.
                r.closedOn == null ? '' : DateFormatter.shortDate(r.closedOn!),
                r.outcome.label,
              ],
          ],
        );
    }
  }
}
