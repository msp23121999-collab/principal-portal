import 'package:flutter/material.dart';
import '../widgets/layout/content_scaffold.dart';
import '../widgets/layout/page_header.dart';
import '../widgets/faculty_filters_bar.dart';
import '../widgets/faculty_summary_cards.dart';
import '../widgets/faculty_table.dart';

class FacultyPerformanceScreen extends StatelessWidget {
  const FacultyPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentScaffold(
      children: [
        PageHeader(
          title: 'Faculty Performance',
          breadcrumbSegments: ['Analytics', 'Faculty Performance'],
          subtitle: 'Search, filter, and review faculty performance metrics',
        ),
        FacultySummaryCards(),
        FacultyFiltersBar(),
        FacultyTable(),
      ],
    );
  }
}
