import 'package:flutter/material.dart';
import '../widgets/layout/content_scaffold.dart';
import '../widgets/layout/page_header.dart';
import '../widgets/department_card_grid.dart';
import '../widgets/department_ranking_table.dart';

class DepartmentAnalyticsScreen extends StatelessWidget {
  const DepartmentAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentScaffold(
      children: [
        PageHeader(
          title: 'Department Analytics',
          breadcrumbSegments: ['Analytics', 'Department'],
          subtitle: 'Department-wise performance, attendance, and staffing',
        ),
        DepartmentCardGrid(),
        DepartmentRankingTable(),
      ],
    );
  }
}
