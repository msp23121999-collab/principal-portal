import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_bar.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/services/csv_export.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/utils/program_level.dart';
import '../../../core/widgets/buttons/primary_button.dart';

import '../../../core/widgets/layout/tabbed_page.dart';
import '../widgets/at_risk_students_table.dart';
import '../widgets/department_comparison_chart.dart';
import '../widgets/student_achievements_tab.dart';
import '../widgets/student_placements_tab.dart';
import '../widgets/student_summary_cards.dart';
import '../widgets/top_students_table.dart';

/// Student Performance — attendance and results, placement outcomes,
/// achievements, and the students who need intervention.
class StudentPerformanceScreen extends ConsumerWidget {
  const StudentPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabbedPage(
      title: 'Student Performance',
      breadcrumbSegments: const ['Analytics', 'Students'],
      subtitle:
          'Attendance, results, placements, achievements, and students '
          'flagged for intervention.',
      actions: const [],
      tabs: const [
        PageTab(label: 'Overview', content: _StudentOverviewTab()),
        PageTab(label: 'Placements', content: StudentPlacementsTab()),
        PageTab(label: 'Achievements', content: StudentAchievementsTab()),
      ],
    );
  }
}

/// The summary, comparison chart, and student tables.
///
/// Everything below the filter bar reads `filteredStudentsProvider`, so the
/// cards, the comparison chart and both tables always describe the same set
/// of students.
class _StudentOverviewTab extends StatelessWidget {
  const _StudentOverviewTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subject is left out: it means nothing to a roll of students.
        PortalFilterBar(
          show: const [
            PortalFilterKind.academicYear,
            PortalFilterKind.department,
            PortalFilterKind.program,
            PortalFilterKind.batch,
            PortalFilterKind.yearOfStudy,
            PortalFilterKind.semester,
          ],
          trailingActions: [
            Consumer(
              builder: (context, ref, child) {
                return PrimaryButton(
                  label: 'Download Report',
                  icon: AppIcons.download,
                  // Exports what is on screen, filters and all — a report of the whole
                  // institution when the Principal is looking at one department would
                  // not be the report they asked for.
                  onPressed: () => _exportStudents(context, ref),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        const StudentSummaryCards(),
        const SizedBox(height: 20),
        const DepartmentComparisonChart(),
        const SizedBox(height: 20),
        const TopStudentsTable(),
        const SizedBox(height: 20),
        const AtRiskStudentsTable(),
      ],
    );
  }
}

/// Writes the filtered roll to a CSV.
void _exportStudents(BuildContext context, WidgetRef ref) {
  final students = ref.read(filteredStudentsProvider).valueOrNull ?? const [];
  final messenger = ScaffoldMessenger.of(context);

  if (students.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nothing to export for this selection.')),
    );
    return;
  }

  CsvExport.download(
    fileName: 'student_performance',
    headers: const [
      'Name',
      'Register No',
      'Department',
      'Programme',
      'Batch',
      'Year',
      'Semester',
      'CGPA',
      'Attendance %',
      'At Risk',
    ],
    rows: [
      for (final s in students)
        [
          s.name,
          s.rollNumber,
          DepartmentNormalizer.codeFor(s.departmentId),
          s.programLevel?.label ?? '',
          s.batch ?? '',
          s.yearOfStudy ?? '',
          s.semester,
          s.cgpa,
          s.attendancePercent,
          s.isAtRisk ? 'Yes' : 'No',
        ],
    ],
  );

  messenger.showSnackBar(
    SnackBar(content: Text('Exported ${students.length} students.')),
  );
}
