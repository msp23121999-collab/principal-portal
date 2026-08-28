import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_spacing.dart';
import './inputs/filter_dropdown.dart';
import './inputs/search_field.dart';
import '../data/department_mock_data.dart';
import '../models/faculty.dart';
import '../providers/faculty_providers.dart';

/// Search + department + designation filter row driving
/// [filteredFacultyProvider].
class FacultyFiltersBar extends ConsumerWidget {
  const FacultyFiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentId = ref.watch(facultyDepartmentFilterProvider);
    final designation = ref.watch(facultyDesignationFilterProvider);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SearchField(
          width: 280,
          hintText: 'Search faculty by name...',
          onChanged: (value) =>
              ref.read(facultySearchQueryProvider.notifier).state = value,
        ),
        FilterDropdown<String?>(
          width: 220,
          value: departmentId,
          items: [null, for (final d in DepartmentMockData.all) d.id],
          itemLabel: (id) => id == null
              ? 'All Departments'
              : DepartmentMockData.byId(id).shortCode,
          onChanged: (value) =>
              ref.read(facultyDepartmentFilterProvider.notifier).state = value,
        ),
        FilterDropdown<FacultyDesignation?>(
          width: 220,
          value: designation,
          items: const [null, ...FacultyDesignation.values],
          itemLabel: (d) => d == null ? 'All Designations' : d.label,
          onChanged: (value) =>
              ref.read(facultyDesignationFilterProvider.notifier).state = value,
        ),
      ],
    );
  }
}
