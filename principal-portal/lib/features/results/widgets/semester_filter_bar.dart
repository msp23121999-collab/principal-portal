import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../core/widgets/inputs/filter_dropdown.dart';
import '../providers/result_providers.dart';

/// Semester/exam selector driving every section on the Result Analytics
/// screen.
///
/// The list comes from the database rather than a constant, so a newly
/// published semester appears here without a code change.
class SemesterFilterBar extends ConsumerWidget {
  const SemesterFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersAsync = ref.watch(availableSemestersProvider);
    final effectiveAsync = ref.watch(effectiveSemesterProvider);

    return Align(
      alignment: Alignment.centerLeft,
      child: semestersAsync.when(
        loading: () => const LoadingSkeleton(height: 44, width: 280),
        error: (err, st) => const SizedBox.shrink(),
        data: (semesters) {
          if (semesters.isEmpty) return const SizedBox.shrink();

          final selected = effectiveAsync.valueOrNull ?? semesters.first;

          return FilterDropdown<String>(
            value: semesters.contains(selected) ? selected : semesters.first,
            items: semesters,
            itemLabel: (s) => s,
            width: 280,
            onChanged: (value) {
              if (value != null) {
                ref.read(selectedSemesterProvider.notifier).state = value;
              }
            },
          );
        },
      ),
    );
  }
}
