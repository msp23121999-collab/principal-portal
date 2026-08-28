import 'package:flutter/material.dart';
import '../widgets/layout/content_scaffold.dart';
import '../widgets/layout/page_header.dart';
import '../widgets/report_category_filter.dart';
import '../widgets/report_grid.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentScaffold(
      children: [
        PageHeader(
          title: 'Reports',
          breadcrumbSegments: ['Administration', 'Reports'],
          subtitle: 'Academic, attendance, faculty, and placement reports',
        ),
        ReportCategoryFilter(),
        ReportGrid(),
      ],
    );
  }
}
