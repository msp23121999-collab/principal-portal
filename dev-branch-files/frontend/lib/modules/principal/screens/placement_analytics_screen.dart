import 'package:flutter/material.dart';
import '../widgets/layout/content_scaffold.dart';
import '../widgets/layout/page_header.dart';
import '../widgets/companies_table.dart';
import '../widgets/placed_students_table.dart';
import '../widgets/placement_summary_cards.dart';
import '../widgets/top_companies_chart.dart';

class PlacementAnalyticsScreen extends StatelessWidget {
  const PlacementAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentScaffold(
      children: [
        PageHeader(
          title: 'Placement Analytics',
          breadcrumbSegments: ['Analytics', 'Placement Analytics'],
          subtitle: 'Companies, packages, and placement statistics',
        ),
        PlacementSummaryCards(),
        TopCompaniesChart(),
        CompaniesTable(),
        PlacedStudentsTable(),
      ],
    );
  }
}
