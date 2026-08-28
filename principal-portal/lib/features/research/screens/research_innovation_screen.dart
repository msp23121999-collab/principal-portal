import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/table_export.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/layout/active_tab.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../models/research.dart';
import '../providers/research_providers.dart';
import '../widgets/tabs/patents_tab.dart';
import '../widgets/tabs/projects_consultancy_tab.dart';
import '../widgets/tabs/publications_tab.dart';
import '../widgets/tabs/research_overview_tab.dart';

/// Research & Innovation — publications, patents, funded projects, and
/// consultancy across every department.
class ResearchInnovationScreen extends ConsumerWidget {
  const ResearchInnovationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabbedPage(
      title: 'Research & Innovation',
      breadcrumbSegments: const ['Analytics', 'Research'],
      subtitle:
          'Research output, patents, funded projects, and consultancy '
          'engagements across all departments.',
      actions: [
        PrimaryButton(
          label: 'Export',
          icon: AppIcons.download,
          onPressed: () => _export(context, ref),
        ),
      ],
      onTabChanged: (index) =>
          ref.read(activeTabProvider(TabbedPageKeys.research).notifier).state =
              index,
      tabs: const [
        PageTab(label: 'Overview', content: ResearchOverviewTab()),
        PageTab(label: 'Publications', content: PublicationsTab()),
        PageTab(label: 'Patents & IPR', content: PatentsTab()),
        PageTab(
          label: 'Projects & Consultancy',
          content: ProjectsConsultancyTab(),
        ),
      ],
    );
  }

  /// Exports the table on the visible tab.
  void _export(BuildContext context, WidgetRef ref) {
    switch (ref.read(activeTabProvider(TabbedPageKeys.research))) {
      case 0:
        final output = ref.read(researchOutputProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'research_output_by_year',
          noun: 'year',
          headers: const ['Year', 'Publications', 'Patents', 'Funded Projects'],
          rows: [
            for (final o in output)
              [o.year, o.publications, o.patents, o.projects],
          ],
        );

      case 1:
        // The filtered list — the tab carries an index filter and a search box.
        final papers = ref.read(publicationsProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'publications',
          noun: 'publication',
          headers: const [
            'Title',
            'Lead Author',
            'Venue',
            'Department',
            'Type',
            'Index',
            'Year',
            'Citations',
            'Impact Factor',
          ],
          rows: [
            for (final p in papers)
              [
                p.title,
                p.leadAuthor,
                p.venue,
                p.departmentCode,
                p.type.label,
                p.index.label,
                p.year,
                p.citations,
                p.impactFactor,
              ],
          ],
        );

      case 2:
        final patents = ref.read(patentsProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'patents',
          noun: 'patent',
          headers: const [
            'Title',
            'Lead Inventor',
            'Department',
            'Application No.',
            'Filed',
            'Granted',
            'Stage',
          ],
          rows: [
            for (final p in patents)
              [
                p.title,
                p.leadInventor,
                p.departmentCode,
                p.applicationNumber,
                DateFormatter.shortDate(p.filedOn),
                // Blank while ungranted, never a stand-in date.
                p.grantedOn == null
                    ? ''
                    : DateFormatter.shortDate(p.grantedOn!),
                p.stage.label,
              ],
          ],
        );

      default:
        // Funded projects and consultancy share the tab, so both go in one
        // file under a Section column rather than one being dropped.
        final projects =
            ref.read(fundedProjectsProvider).valueOrNull ?? const [];
        final consultancy =
            ref.read(consultancyProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'projects_and_consultancy',
          noun: 'engagement',
          headers: const [
            'Section',
            'Title',
            'Lead',
            'Department',
            'Agency / Client',
            'Amount',
            'Duration (months)',
            'Sanctioned On',
            'Stage',
          ],
          rows: [
            for (final p in projects)
              [
                'Funded Project',
                p.title,
                p.principalInvestigator,
                p.departmentCode,
                p.agency,
                p.sanctionedAmount,
                p.durationMonths,
                DateFormatter.shortDate(p.sanctionedOn),
                p.stage.label,
              ],
            for (final c in consultancy)
              [
                'Consultancy',
                c.title,
                c.leadFaculty,
                c.departmentCode,
                c.client,
                c.revenue,
                '',
                '',
                c.stage.label,
              ],
          ],
        );
    }
  }
}
