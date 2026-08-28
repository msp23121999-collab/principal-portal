import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/program_level.dart';
import '../widgets/inputs/filter_dropdown.dart';
import 'portal_filter_providers.dart';

/// Which filters a screen offers.
///
/// Not every filter means something everywhere — a subject is meaningless to
/// Attendance and a semester is meaningless to Placement — so each screen
/// names the ones it honours. Showing a control that changes nothing is worse
/// than showing none: it invites the Principal to narrow the scope and then
/// silently ignores them.
enum PortalFilterKind {
  academicYear,
  department,
  program,
  batch,
  yearOfStudy,
  semester,
  subject,
}

/// The shared filter row.
///
/// Reads and writes [portalFiltersProvider], so the scope chosen here is still
/// in force on the next screen. Every option list comes from the rows that
/// exist, and narrows as broader filters are applied.
class PortalFilterBar extends ConsumerWidget {
  const PortalFilterBar({
    super.key,
    required this.show,
    this.subjects = const [],
    this.trailingActions = const [],
  });

  final List<PortalFilterKind> show;

  /// Subject options, supplied by the screen because only Result Analysis has
  /// them and they depend on its own data.
  final List<String> subjects;
  final List<Widget> trailingActions;

  static const String _all = '__all__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(portalFiltersProvider);
    final notifier = ref.read(portalFiltersProvider.notifier);

    final controls = <Widget>[
      if (show.contains(PortalFilterKind.academicYear))
        _dropdown<String>(
          value: filters.academicYear,
          items: ref.watch(filterAcademicYearsProvider),
          labelFor: (v) => 'AY $v',
          allLabel: 'All Academic Years',
          onChanged: notifier.setAcademicYear,
        ),
      if (show.contains(PortalFilterKind.department))
        _dropdown<String>(
          value: filters.departmentCode,
          items: [for (final d in ref.watch(filterDepartmentsProvider)) d.code],
          labelFor: (v) => v,
          allLabel: 'All Departments',
          onChanged: notifier.setDepartment,
        ),
      if (show.contains(PortalFilterKind.program))
        _dropdown<ProgramLevel>(
          value: filters.programLevel,
          items: ref.watch(filterProgramLevelsProvider),
          labelFor: (v) => v.label,
          allLabel: 'All Programs',
          onChanged: notifier.setProgramLevel,
        ),
      if (show.contains(PortalFilterKind.batch))
        _dropdown<String>(
          value: filters.batch,
          items: ref.watch(filterBatchesProvider),
          labelFor: (v) => 'Batch $v',
          allLabel: 'All Batches',
          onChanged: notifier.setBatch,
        ),
      if (show.contains(PortalFilterKind.yearOfStudy))
        _dropdown<String>(
          value: filters.yearOfStudy,
          items: ref.watch(filterYearsOfStudyProvider),
          labelFor: (v) => '$v Year',
          allLabel: 'All Years of Study',
          onChanged: notifier.setYearOfStudy,
        ),
      if (show.contains(PortalFilterKind.semester))
        _dropdown<int>(
          value: filters.semester,
          items: ref.watch(filterSemestersProvider),
          labelFor: (v) => 'Semester $v',
          allLabel: 'All Semesters',
          onChanged: notifier.setSemester,
        ),
      if (show.contains(PortalFilterKind.subject))
        _dropdown<String>(
          value: filters.subject,
          items: subjects,
          labelFor: (v) => v,
          allLabel: 'All Subjects',
          onChanged: notifier.setSubject,
        ),
    ];

    // The controls used to sit bare on the page background, which left them
    // reading as loose furniture between the title and the first card. Giving
    // the row its own surface — the same one the cards below it use — makes the
    // scope an object on the page, and the labelled header says what the row is
    // for without the Principal having to infer it from the dropdowns.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.infoBackground,
                  borderRadius: AppRadius.smRadius,
                ),
                child: const Icon(
                  Icons.filter_list,
                  size: 18,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              if (filters.activeCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                // The count is worth stating plainly: a Principal who has
                // narrowed the scope on one screen carries that scope onto the
                // next, and a page showing fewer rows than expected is
                // otherwise indistinguishable from a page with no data.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.infoBackground,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    '${filters.activeCount} active',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: controls,
              ),
              if (filters.activeCount > 0 || trailingActions.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (filters.activeCount > 0)
                      TextButton.icon(
                        onPressed: notifier.clearAll,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text('Reset Filters (${filters.activeCount})'),
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.hovered)) {
                              return AppColors.danger;
                            }
                            return AppColors.secondaryText;
                          }),
                        ),
                      ),
                    ...trailingActions,
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// One dropdown, with "All" folded in as a sentinel.
  ///
  /// An empty option list leaves the control showing "All ..." with nothing
  /// else to pick, rather than hiding it: a row that changes shape as the
  /// scope narrows is harder to use than one with a quiet dead entry.
  Widget _dropdown<T extends Object>({
    required T? value,
    required List<T> items,
    required String Function(T) labelFor,
    required String allLabel,
    required void Function(T?) onChanged,
  }) {
    return FilterDropdown<Object>(
      // No `label:` — that prefixes the field name onto every option
      // ("Academic Year: All Years"), which no longer fits the control at this
      // type size and clipped to just the prefix. The options below name
      // themselves instead, which is shorter and reads the same.
      width: 220,
      value: value ?? _all,
      items: [_all, ...items],
      itemLabel: (item) => item == _all ? allLabel : labelFor(item as T),
      onChanged: (selected) =>
          onChanged(selected == _all ? null : selected as T?),
    );
  }
}
