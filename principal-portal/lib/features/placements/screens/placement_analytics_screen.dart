import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filters/portal_filter_bar.dart';
import '../../../core/services/csv_export.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/layout/responsive_row.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../providers/placement_providers.dart';
import '../widgets/companies_table.dart';
import '../widgets/drive_summary_cards.dart';
import '../widgets/internships_table.dart';
import '../widgets/package_distribution_card.dart';
import '../widgets/placed_students_table.dart';
import '../widgets/placement_drives_table.dart';
import '../widgets/placement_summary_cards.dart';
import '../widgets/top_companies_chart.dart';

/// Placement Dashboard — recruitment drives, company visits, offers,
/// internships, and the season's placement statistics.
class PlacementAnalyticsScreen extends ConsumerWidget {
  const PlacementAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabbedPage(
      title: 'Placement Dashboard',
      breadcrumbSegments: const ['Analytics', 'Placements'],
      subtitle:
          'Recruitment drives, company visits, offers, and internships for '
          'the current placement season.',
      filterBar: PortalFilterBar(
        show: const [
          PortalFilterKind.academicYear,
          PortalFilterKind.department,
          PortalFilterKind.program,
          PortalFilterKind.batch,
        ],
        trailingActions: [
          PrimaryButton(
            label: 'Export Report',
            icon: AppIcons.download,
            // Exports the filtered set, not the whole institution.
            onPressed: () => _exportPlacements(context, ref),
          ),
        ],
      ),
      tabs: const [
        PageTab(label: 'Overview', content: _PlacementOverviewTab()),
        PageTab(label: 'Recruitment Drives', content: PlacementDrivesTable()),
        PageTab(label: 'Companies & Offers', content: _CompaniesTab()),
        PageTab(label: 'Internships', content: InternshipsTable()),
      ],
    );
  }
}

class _PlacementOverviewTab extends StatelessWidget {
  const _PlacementOverviewTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlacementSummaryCards(),
        SizedBox(height: 20),
        DriveSummaryCards(),
        SizedBox(height: 20),
        ResponsiveRow(
          columns: [
            ResponsiveColumn(flex: 6, child: TopCompaniesChart()),
            ResponsiveColumn(flex: 4, child: PackageDistributionCard()),
          ],
        ),
      ],
    );
  }
}

class _CompaniesTab extends StatelessWidget {
  const _CompaniesTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [CompaniesTable(), SizedBox(height: 20), PlacedStudentsTable()],
    );
  }
}

/// Writes the placement offers in scope to a CSV.
void _exportPlacements(BuildContext context, WidgetRef ref) {
  final offers = ref.read(filteredPlacementsProvider).valueOrNull ?? const [];
  final messenger = ScaffoldMessenger.of(context);

  if (offers.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nothing to export for this selection.')),
    );
    return;
  }

  CsvExport.download(
    fileName: 'placements',
    headers: const [
      'Student',
      'Register No',
      'Department',
      'Batch',
      'Company',
      'Package (LPA)',
      'Offer Date',
    ],
    rows: [
      for (final o in offers)
        [
          o.studentName,
          o.rollNumber,
          DepartmentNormalizer.codeFor(o.departmentId),
          o.batchRange ?? '',
          o.companyName,
          o.packageLpa,
          DateFormatter.fileStamp(o.offerDate),
        ],
    ],
  );

  messenger.showSnackBar(
    SnackBar(content: Text('Exported ${offers.length} offers.')),
  );
}
