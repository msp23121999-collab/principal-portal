import 'package:flutter/material.dart';
import '../widgets/layout/content_scaffold.dart';
import '../widgets/layout/page_header.dart';
import '../widgets/department_results_chart.dart';
import '../widgets/rank_holders_table.dart';
import '../widgets/result_summary_cards.dart';
import '../widgets/semester_filter_bar.dart';

class ResultAnalyticsScreen extends StatelessWidget {
  const ResultAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentScaffold(
      children: [
        PageHeader(
          title: 'Result Analytics',
          breadcrumbSegments: ['Analytics', 'Result Analytics'],
          subtitle: 'Semester results, pass percentage, and rank holders',
        ),
        SemesterFilterBar(),
        ResultSummaryCards(),
        DepartmentResultsChart(),
        RankHoldersTable(),
      ],
    );
  }
}
