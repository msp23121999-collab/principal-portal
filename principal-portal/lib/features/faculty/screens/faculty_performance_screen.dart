import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filters/portal_filter_bar.dart';
import '../../../core/services/csv_export.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/widgets/buttons/primary_button.dart';

import '../../../core/widgets/layout/tabbed_page.dart';
import '../models/faculty.dart';
import '../providers/faculty_providers.dart';
import '../widgets/faculty_filters_bar.dart';
import '../widgets/faculty_research_tab.dart';
import '../widgets/faculty_summary_cards.dart';
import '../widgets/faculty_table.dart';
import '../widgets/faculty_workload_tab.dart';

/// Faculty Performance — the roster, teaching workload and appraisal, and
/// research output, with a profile drill-down on every row.
class FacultyPerformanceScreen extends ConsumerWidget {
  const FacultyPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabbedPage(
      title: 'Faculty Performance',
      breadcrumbSegments: const ['Analytics', 'Faculty'],
      subtitle:
          'Roster, workload, appraisal, attendance, and research output '
          'across all departments.',
      filterBar: PortalFilterBar(
        show: const [PortalFilterKind.department],
        trailingActions: [
          PrimaryButton(
            label: 'Export Report',
            icon: AppIcons.download,
            // Exports the filtered set, not the whole institution.
            onPressed: () => _exportFaculty(context, ref),
          ),
        ],
      ),
      tabs: const [
        PageTab(label: 'Roster', content: _FacultyRosterTab()),
        PageTab(label: 'Workload & Appraisal', content: FacultyWorkloadTab()),
        PageTab(label: 'Research Output', content: FacultyResearchTab()),
      ],
    );
  }
}

/// The summary cards, filters, and roster table that predate the redesign.
class _FacultyRosterTab extends StatelessWidget {
  const _FacultyRosterTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FacultySummaryCards(),
        SizedBox(height: 20),
        FacultyFiltersBar(),
        SizedBox(height: 20),
        FacultyTable(),
      ],
    );
  }
}

/// Writes the faculty roster in scope to a CSV.
void _exportFaculty(BuildContext context, WidgetRef ref) {
  final roster = ref.read(scopedFacultyProvider).valueOrNull ?? const [];
  final messenger = ScaffoldMessenger.of(context);

  if (roster.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nothing to export for this selection.')),
    );
    return;
  }

  CsvExport.download(
    fileName: 'faculty_performance',
    headers: const [
      'Name',
      'Employee ID',
      'Department',
      'Designation',
      'Experience (yrs)',
      'Attendance %',
      'Research Papers',
      'Performance Score',
    ],
    rows: [
      for (final f in roster)
        [
          f.name,
          f.id,
          DepartmentNormalizer.codeFor(f.departmentId),
          f.designation.label,
          f.experienceYears,
          f.attendancePercent,
          f.researchPapersCount,
          f.performanceScore,
        ],
    ],
  );

  messenger.showSnackBar(
    SnackBar(content: Text('Exported ${roster.length} faculty.')),
  );
}
