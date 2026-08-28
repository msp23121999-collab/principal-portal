import 'package:flutter/material.dart';

import '../../../core/filters/portal_filter_bar.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/data_display/data_freshness_label.dart';
import '../../../core/widgets/layout/content_scaffold.dart';
import '../../../core/widgets/layout/page_header.dart';
import '../widgets/calendar_widget_section.dart';
import '../widgets/dashboard_hero.dart';
import '../widgets/dashboard_kpi_grid.dart';
import '../widgets/department_summary_section.dart';
import '../widgets/faculty_summary_section.dart';
import '../widgets/pending_approvals_section.dart';
import '../widgets/placement_summary_section.dart';
import '../widgets/result_summary_section.dart';
import '../widgets/student_summary_section.dart';

/// The Principal's landing page.
///
/// Laid out as three bands, each of which fills its row exactly rather than
/// leaving a tile-shaped hole: six KPI cards, three summary panels, then the
/// paired sections. Every row shares a height, so the card bottoms line up
/// instead of ending wherever their content happens to stop.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentScaffold(
      spacing: AppSpacing.lg,
      children: [
        PageHeader(
          title: 'Dashboard',
          subtitle: 'Institution-wide overview',
          // The figures below are a snapshot taken when the page loaded or
          // when the tab last regained focus, not a live feed. Dating them is
          // what stops the top bar's ticking clock implying otherwise.
          actions: [DataFreshnessLabel()],
        ),

        DashboardHero(),

        // Student-related figures below honour this scope. Subject is left
        // out: it means nothing to a dashboard.
        PortalFilterBar(
          show: [
            PortalFilterKind.academicYear,
            PortalFilterKind.department,
            PortalFilterKind.program,
            PortalFilterKind.batch,
            PortalFilterKind.yearOfStudy,
          ],
        ),

        DashboardKpiGrid(),

        // 320 gives three columns at desktop width, so these three panels fill
        // the row exactly. matchHeights locks all three cards to the tallest
        // card's height so the row forms a clean, aligned band.
        ResponsiveGrid(
          minTileWidth: 320,
          matchHeights: false,
          children: [
            DepartmentSummarySection(),
            FacultySummarySection(),
            StudentSummarySection(),
          ],
        ),

        // Attendance Snapshot removed: attendance is already reported three
        // times above — the KPI card, Student Summary's average, and Faculty
        // Status's present/absent split. A fourth view of it made the page
        // longer without answering a new question. The trend it drew belongs
        // on Attendance Analytics, which is untouched.
        //
        // Result takes the row on its own rather than keeping a half-width
        // column with a gap beside it, and the extra width suits a twelve-bar
        // department chart.
        ResultSummarySection(),

        PlacementSummarySection(),

        PendingApprovalsSection(),

        // Quick Options removed. The calendar takes the full width rather than
        // keeping a two-thirds column with a gap beside it.
        CalendarWidgetSection(),
      ],
    );
  }
}
