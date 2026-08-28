import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_delay.dart';
import '../data/reports_mock_data.dart';
import '../models/report_item.dart';

final reportsProvider = FutureProvider<List<ReportItem>>((ref) {
  return mockDelay(ReportsMockData.all);
});

/// null = all categories.
final reportCategoryFilterProvider = StateProvider<ReportCategory?>(
  (ref) => null,
);

final filteredReportsProvider = Provider<AsyncValue<List<ReportItem>>>((ref) {
  final reportsAsync = ref.watch(reportsProvider);
  final category = ref.watch(reportCategoryFilterProvider);

  return reportsAsync.whenData((reports) {
    if (category == null) return reports;
    return reports.where((r) => r.category == category).toList();
  });
});
