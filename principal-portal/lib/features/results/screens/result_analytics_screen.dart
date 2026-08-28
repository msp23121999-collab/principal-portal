import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filters/portal_filter_bar.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../providers/result_providers.dart';
import '../widgets/department_pass_summary.dart';
import '../widgets/department_results_chart.dart';
import '../widgets/rank_holders_table.dart';
import '../widgets/result_summary_cards.dart';
import '../widgets/tabs/result_analysis_tab.dart';
import '../widgets/tabs/subject_analysis_tab.dart';

/// Result — the single place results are analysed.
///
/// Results Analysis and Subject Performance used to be tabs on Academic
/// Performance as well as living here, so the same figures were reachable by
/// two routes and could be read as two different reports. They are now one
/// page: Academic Performance keeps what is genuinely about learning outcomes
/// (SGPA/CGPA bands, CO/PO attainment, performers) and everything about
/// results is here.
class ResultAnalyticsScreen extends ConsumerWidget {
  const ResultAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subjects come from the results themselves, so the dropdown can only ever
    // offer a subject that has marks behind it — and it narrows as the
    // department and semester above it are chosen.
    final subjects = ref.watch(resultSubjectOptionsProvider);

    return TabbedPage(
      title: 'Result',
      breadcrumbSegments: const ['Analytics', 'Result'],
      subtitle:
          'Pass summary, subject-wise and department-wise analysis, and '
          'rank holders.',
      filterBar: PortalFilterBar(
        show: const [
          PortalFilterKind.academicYear,
          PortalFilterKind.department,
          PortalFilterKind.program,
          PortalFilterKind.batch,
          PortalFilterKind.semester,
          PortalFilterKind.subject,
        ],
        subjects: subjects,
      ),
      tabs: const [
        PageTab(label: 'Result Analysis', content: ResultAnalysisTab()),
        PageTab(label: 'Subject-wise', content: SubjectAnalysisTab()),
        PageTab(label: 'Department-wise', content: _DepartmentResultsTab()),
        PageTab(label: 'Rank Holders', content: _RankHoldersTab()),
      ],
    );
  }
}

/// Pass summary and pass rate per department — section 6 of the requirements.
class _DepartmentResultsTab extends StatelessWidget {
  const _DepartmentResultsTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResultSummaryCards(),
        SizedBox(height: 20),
        // Section 6.
        DepartmentPassSummary(),
        SizedBox(height: 20),
        DepartmentResultsChart(),
      ],
    );
  }
}

class _RankHoldersTab extends StatelessWidget {
  const _RankHoldersTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [RankHoldersTable()],
    );
  }
}
