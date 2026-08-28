import 'package:flutter/material.dart';
import '../../../../core/widgets/layout/responsive_row.dart';
import '../academic_kpi_grid.dart';
import '../at_risk_students_card.dart';
import '../attainment_summary_card.dart';
import '../pass_rate_by_department_card.dart';
import '../performance_trend_card.dart';
import '../semester_summary_table.dart';
import '../sgpa_distribution_card.dart';
import '../top_departments_card.dart';

/// The page's landing tab: headline figures, pass rate & SGPA charts,
/// semester table on the main column, with outcome attainment, performance trend,
/// and risk summary on the right rail.
class AcademicOverviewTab extends StatelessWidget {
  const AcademicOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveRow(
      crossAxisAlignment: CrossAxisAlignment.start,
      columns: [
        ResponsiveColumn(
          flex: 7,
          child: _MainAcademicColumn(),
        ),
        ResponsiveColumn(
          flex: 5,
          child: _SideRailColumn(),
        ),
      ],
    );
  }
}

class _MainAcademicColumn extends StatelessWidget {
  const _MainAcademicColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcademicKpiGrid(),
        SizedBox(height: 20),
        ResponsiveRow(
          columns: [
            ResponsiveColumn(flex: 1, child: PassRateByDepartmentCard()),
            ResponsiveColumn(flex: 1, child: SgpaDistributionCard()),
          ],
        ),
        SizedBox(height: 20),
        SemesterSummaryTable(),
      ],
    );
  }
}

class _SideRailColumn extends StatelessWidget {
  const _SideRailColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttainmentSummaryCard(),
        SizedBox(height: 20),
        PerformanceTrendCard(),
        SizedBox(height: 20),
        AtRiskStudentsCard(),
        SizedBox(height: 20),
        TopDepartmentsCard(),
      ],
    );
  }
}
