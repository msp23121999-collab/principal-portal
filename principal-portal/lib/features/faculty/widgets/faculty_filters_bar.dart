import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/widgets/inputs/filter_dropdown.dart';
import '../../../core/widgets/inputs/search_field.dart';
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

    // Departments are taken from the roster on screen rather than a fixed list,
    // so the dropdown can never offer a department with nobody in it.
    final departmentIds =
        ref
            .watch(facultyListProvider)
            .valueOrNull
            ?.map((f) => f.departmentId)
            .toSet()
            .toList()
          ?..sort();

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
          items: [null, ...?departmentIds],
          itemLabel: (id) =>
              id == null ? 'All Departments' : DepartmentNormalizer.codeFor(id),
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
