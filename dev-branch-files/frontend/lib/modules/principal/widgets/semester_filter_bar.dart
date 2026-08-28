import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './inputs/filter_dropdown.dart';
import '../data/result_mock_data.dart';
import '../providers/result_providers.dart';

/// Semester/exam selector driving every section on the Result Analytics
/// screen.
class SemesterFilterBar extends ConsumerWidget {
  const SemesterFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSemesterProvider);

    return Align(
      alignment: Alignment.centerLeft,
      child: FilterDropdown<String>(
        value: selected,
        items: ResultMockData.semesters,
        itemLabel: (s) => s,
        width: 280,
        onChanged: (value) {
          if (value != null) {
            ref.read(selectedSemesterProvider.notifier).state = value;
          }
        },
      ),
    );
  }
}
