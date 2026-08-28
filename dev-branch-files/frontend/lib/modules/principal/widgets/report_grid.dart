import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/responsive_utils.dart';
import './feedback/empty_state.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/reports_providers.dart';
import 'report_card.dart';

/// Responsive grid of [ReportCard]s, filtered by [reportCategoryFilterProvider].
class ReportGrid extends ConsumerWidget {
  const ReportGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(filteredReportsProvider);

    return reportsAsync.when(
      loading: () => ResponsiveGrid(
        minTileWidth: 320,
        children: List.generate(6, (_) => const CardSkeleton(height: 220)),
      ),
      error: (err, st) => const ErrorState(),
      data: (reports) => reports.isEmpty
          ? const EmptyState(message: 'No reports match the selected category.')
          : ResponsiveGrid(
              minTileWidth: 320,
              children: [for (final r in reports) ReportCard(report: r)],
            ),
    );
  }
}
