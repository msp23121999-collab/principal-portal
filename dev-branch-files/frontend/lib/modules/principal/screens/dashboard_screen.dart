import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../utils/responsive_utils.dart';
import '../widgets/layout/content_scaffold.dart';
import '../widgets/layout/page_header.dart';
import '../widgets/attendance_snapshot_section.dart';
import '../widgets/calendar_widget_section.dart';
import '../widgets/dashboard_kpi_grid.dart';
import '../widgets/department_summary_section.dart';
import '../widgets/faculty_summary_section.dart';
import '../widgets/pending_approvals_section.dart';
import '../widgets/placement_summary_section.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_activities_section.dart';
import '../widgets/result_summary_section.dart';
import '../widgets/student_summary_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentScaffold(
      children: [
        const PageHeader(
          title: 'Dashboard',
          subtitle: 'Institution-wide overview and quick actions',
        ),
        const DashboardKpiGrid(),
        ResponsiveGrid(
          minTileWidth: 320,
          children: const [
            DepartmentSummarySection(),
            FacultySummarySection(),
            StudentSummarySection(),
          ],
        ),
        const ResponsiveGrid(
          minTileWidth: 420,
          children: [AttendanceSnapshotSection(), ResultSummarySection()],
        ),
        const PlacementSummarySection(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: const RecentActivitiesSection()),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 2, child: const PendingApprovalsSection()),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: const CalendarWidgetSection()),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 2, child: const QuickActionsSection()),
          ],
        ),
      ],
    );
  }
}
