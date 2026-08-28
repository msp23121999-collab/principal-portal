import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filters/portal_filter_bar.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/layout/content_scaffold.dart';
import '../../../core/widgets/layout/page_header.dart';
import '../../../core/widgets/layout/responsive_row.dart';
import '../widgets/department_summary_section.dart';
import '../widgets/faculty_overview_section.dart';
import '../widgets/institution_kpi_grid.dart';
import '../widgets/institution_year_controls.dart';
import '../widgets/institutional_alerts_section.dart';
import '../widgets/key_highlights_section.dart';
import '../widgets/overall_performance_section.dart';

/// Institution Overview — institution-wide statistics across every
/// department, scoped by academic year and the department/programme/
/// semester filters.
class InstitutionAnalyticsScreen extends ConsumerWidget {
  const InstitutionAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentScaffold(
      children: [
        PageHeader(
          title: 'Institution Overview',
          breadcrumbSegments: const ['Analytics', 'Institution'],
          subtitle:
              'Institution-level analysis across all departments and key '
              'performance indicators.',
          actions: [const InstitutionYearControls()],
        ),

        PortalFilterBar(
          show: const [
            PortalFilterKind.department,
            PortalFilterKind.program,
            PortalFilterKind.batch,
            PortalFilterKind.semester,
          ],
          trailingActions: [
            Consumer(
              builder: (context, ref, child) {
                return PrimaryButton(
                  label: 'Export Report',
                  icon: AppIcons.download,
                  onPressed: () => InstitutionYearControls.export(context, ref),
                );
              },
            ),
          ],
        ),

        // 1. Institution Snapshot
        const InstitutionKpiGrid(),

        // 2. Academic Performance Trend + Key Highlights
        const ResponsiveRow(
          columns: [
            ResponsiveColumn(flex: 7, child: OverallPerformanceSection()),
            ResponsiveColumn(flex: 5, child: KeyHighlightsSection()),
          ],
        ),

        // 3. Department Comparison (full table)
        const DepartmentSummarySection(),

        // 4. Faculty Overview + Institutional Alerts
        const ResponsiveRow(
          columns: [
            ResponsiveColumn(flex: 7, child: FacultyOverviewSection()),
            ResponsiveColumn(flex: 5, child: InstitutionalAlertsSection()),
          ],
        ),
      ],
    );
  }
}
