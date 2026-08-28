import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/table_export.dart';
import '../../../core/widgets/inputs/filter_dropdown.dart';
import '../providers/institution_filter_providers.dart';
import '../providers/institution_providers.dart';

/// Header actions for Institution Overview: the academic year being
/// viewed, the year it is compared against, and the export action.
class InstitutionYearControls extends ConsumerWidget {
  const InstitutionYearControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(academicYearProvider);
    final years = [
      ...?ref.watch(academicYearsProvider).valueOrNull?.map((y) => y.label),
    ];

    return FilterDropdown<String>(
      label: 'Academic Year',
      value: year,
      items: years,
      itemLabel: (value) => value,
      onChanged: (value) {
        if (value != null) {
          ref.read(academicYearSelectionProvider.notifier).state = value;
        }
      },
    );
  }

  /// Exports the department comparison — the table this page is built around.
  ///
  /// Institution Overview has no tabs, so there is one thing to export: the
  /// per-department roll-up every card and chart on the page summarises. It
  /// honours the department, programme, batch and semester filters above it.
  static void export(BuildContext context, WidgetRef ref) {
    final departments = ref.read(departmentsProvider).valueOrNull ?? const [];

    TableExport.run(
      context,
      fileName: 'institution_overview',
      noun: 'department',
      headers: const [
        'Rank',
        'Department',
        'Department Name',
        'HOD',
        'Programmes',
        'Faculty',
        'Students',
        'Attendance %',
        'Average CGPA',
        'Pass %',
        'Placement %',
      ],
      rows: [
        for (final d in departments)
          [
            d.rank,
            d.shortCode,
            d.name,
            d.hodName,
            d.programCount,
            d.facultyCount,
            d.studentCount,
            d.attendancePercent,
            d.avgCgpa,
            d.passPercent,
            d.placementPercent,
          ],
      ],
    );
  }
}
