import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../models/department.dart';
import 'institution_providers.dart';

/// The user's explicit year choices, null until they pick one.
///
/// Held as null rather than a hardcoded label because the available years come
/// from `principal.academic_years` and are not known synchronously. The two
/// resolved providers below fill the gap.
final academicYearSelectionProvider = StateProvider<String?>((ref) => null);
final comparisonYearSelectionProvider = StateProvider<String?>((ref) => null);

/// Academic year the page is scoped to — the user's choice, or the current
/// year once the list loads.
final academicYearProvider = Provider<String>((ref) {
  final chosen = ref.watch(academicYearSelectionProvider);
  if (chosen != null) return chosen;

  final years = ref.watch(academicYearsProvider).valueOrNull ?? const [];
  if (years.isEmpty) return '';
  // The year flagged current in the database, falling back to the most recent.
  return years.firstWhere((y) => y.isCurrent, orElse: () => years.first).label;
});

/// The year the scoped year is compared against — the one before it.
final comparisonYearProvider = Provider<String>((ref) {
  final chosen = ref.watch(comparisonYearSelectionProvider);
  if (chosen != null) return chosen;

  final years = ref.watch(academicYearsProvider).valueOrNull ?? const [];
  final current = ref.watch(academicYearProvider);
  final index = years.indexWhere((y) => y.label == current);
  if (index < 0 || index + 1 >= years.length) return '';
  return years[index + 1].label;
});

/// Departments in the current scope — the source for the Department Summary
/// table and its Overall Total row.
///
/// Reads the portal-wide filter rather than a filter of this page's own. The
/// page used to carry a second row of department/programme/semester dropdowns
/// with its own Apply and Reset, so narrowing here did nothing anywhere else
/// and narrowing elsewhere did nothing here.
final filteredDepartmentsProvider = FutureProvider<List<Department>>((
  ref,
) async {
  final departments = await ref.watch(departmentsProvider.future);
  final code = ref.watch(portalFiltersProvider).departmentCode;
  if (code == null) return departments;
  return departments.where((d) => d.shortCode == code).toList();
});

/// Zero-based page index of the Department Summary table. Resets whenever
/// the applied filter changes so the view never lands on an empty page.
final departmentTablePageProvider = StateProvider<int>((ref) {
  ref.watch(portalFiltersProvider);
  return 0;
});

final departmentTableRowsPerPageProvider = StateProvider<int>((ref) => 5);
