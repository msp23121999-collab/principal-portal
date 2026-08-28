import 'package:flutter/material.dart';
import '../../../core/filters/portal_filter_bar.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../widgets/tabs/academic_overview_tab.dart';
import '../widgets/tabs/copo_attainment_tab.dart';
import '../widgets/tabs/sgpa_cgpa_tab.dart';

/// Academic Performance — semester results, pass rates, grade-point
/// analysis, outcome attainment, and departmental comparison.
class AcademicPerformanceScreen extends StatelessWidget {
  const AcademicPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabbedPage(
      title: 'Academic Performance',
      breadcrumbSegments: ['Analytics', 'Academic Performance'],
      subtitle:
          'Grade-point distribution, outcome attainment, and performance across '
          'all departments.',
      // The page carried its own year and semester dropdowns. They are the
      // portal's filters by another name, so narrowing here now narrows
      // everywhere rather than only on this screen.
      filterBar: PortalFilterBar(
        show: [
          PortalFilterKind.academicYear,
          PortalFilterKind.department,
          PortalFilterKind.program,
          PortalFilterKind.semester,
        ],
      ),
      tabs: [
        PageTab(label: 'Overview', content: AcademicOverviewTab()),
        PageTab(label: 'SGPA / CGPA Analysis', content: SgpaCgpaTab()),
        PageTab(label: 'CO / PO Attainment', content: CopoAttainmentTab()),
      ],
    );
  }
}
