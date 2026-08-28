import 'package:flutter/material.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../widgets/generated_reports_tab.dart';
import '../widgets/report_category_filter.dart';
import '../widgets/report_configurator_tab.dart';
import '../widgets/report_grid.dart';
import '../widgets/scheduled_reports_tab.dart';

/// Reports & Analytics — the standing report library, an on-demand
/// generator, the recently produced runs, and recurring schedules.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabbedPage(
      title: 'Reports & Analytics',
      breadcrumbSegments: ['Administration', 'Reports'],
      subtitle:
          'Generate institution-wide reports across every module, and manage '
          'what runs on a schedule.',
      tabs: [
        PageTab(label: 'Report Library', content: _ReportLibraryTab()),
        PageTab(label: 'Generate', content: ReportConfiguratorTab()),
        PageTab(label: 'Recently Generated', content: GeneratedReportsTab()),
        PageTab(label: 'Scheduled', content: ScheduledReportsTab()),
      ],
    );
  }
}

/// The category filter and report grid that predate the redesign.
class _ReportLibraryTab extends StatelessWidget {
  const _ReportLibraryTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [ReportCategoryFilter(), SizedBox(height: 20), ReportGrid()],
    );
  }
}
