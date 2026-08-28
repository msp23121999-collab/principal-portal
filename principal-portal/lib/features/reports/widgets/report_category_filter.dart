import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/inputs/filter_chip_group.dart';
import '../models/report_item.dart';
import '../providers/reports_providers.dart';

/// Category filter chips (All / Academic / Attendance / Faculty /
/// Placement) driving [filteredReportsProvider].
class ReportCategoryFilter extends ConsumerWidget {
  const ReportCategoryFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportCategoryFilterProvider);

    return FilterChipGroup<ReportCategory>(
      value: selected,
      items: ReportCategory.values,
      itemLabel: (c) => c.label,
      allLabel: 'All Reports',
      onChanged: (value) =>
          ref.read(reportCategoryFilterProvider.notifier).state = value,
    );
  }
}
