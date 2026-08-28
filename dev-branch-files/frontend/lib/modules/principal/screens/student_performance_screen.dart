import 'package:flutter/material.dart';
import '../widgets/layout/content_scaffold.dart';
import '../widgets/layout/page_header.dart';
import '../widgets/at_risk_students_table.dart';
import '../widgets/department_comparison_chart.dart';
import '../widgets/student_summary_cards.dart';
import '../widgets/top_students_table.dart';

class StudentPerformanceScreen extends StatelessWidget {
  const StudentPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentScaffold(
      children: [
        PageHeader(
          title: 'Student Performance',
          breadcrumbSegments: ['Analytics', 'Student Performance'],
          subtitle:
              'Top performers, at-risk students, and department comparison',
        ),
        StudentSummaryCards(),
        DepartmentComparisonChart(),
        TopStudentsTable(),
        AtRiskStudentsTable(),
      ],
    );
  }
}
