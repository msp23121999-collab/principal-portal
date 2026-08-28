import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reports_repository.dart';
import '../models/report_item.dart';
import '../models/report_run.dart';

final reportsRepositoryProvider = Provider((ref) => const ReportsRepository());

final reportsProvider = FutureProvider<List<ReportItem>>((ref) async {
  return (await ref.watch(reportsRepositoryProvider).fetchLibrary()).value;
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

/// Generated reports, newest first.
final reportRunsProvider = FutureProvider<List<ReportRun>>((ref) async {
  return (await ref.watch(reportsRepositoryProvider).fetchRuns()).value;
});

final scheduledReportsProvider = FutureProvider<List<ScheduledReport>>((
  ref,
) async {
  return (await ref.watch(reportsRepositoryProvider).fetchSchedules()).value;
});

/// Requests a report and flips schedules on or off.
///
/// A requested report is recorded as `queued` and stays there — nothing
/// generates files yet. The screen says so rather than implying a download is
/// coming.
final reportActionsProvider = Provider((ref) => ReportActions(ref));

class ReportActions {
  const ReportActions(this._ref);

  final Ref _ref;

  Future<void> request({
    required String title,
    required String module,
    required ReportFormat format,
    required ReportPeriod period,
  }) async {
    await _ref
        .read(reportsRepositoryProvider)
        .requestReport(
          title: title,
          module: module,
          format: format,
          period: period,
        );

    _ref.invalidate(reportRunsProvider);
  }

  Future<void> setScheduleEnabled(String scheduleId, bool enabled) async {
    await _ref
        .read(reportsRepositoryProvider)
        .setScheduleEnabled(scheduleId, enabled);

    _ref.invalidate(scheduledReportsProvider);
  }
}

/// The modules a report can be generated for — the portal's own feature list,
/// which is a UI concern rather than something to store.
const reportModules = <String>[
  'academic',
  'attendance',
  'faculty',
  'placement',
  'finance',
  'approvals',
  'audit',
];

/// Display name for a module slug.
///
/// The slug is what `principal.report_runs.module` stores and what the rest of
/// the portal keys on; this is only ever for reading. Without it the dropdown
/// and both tables printed 'academic' and 'placement' at the user.
String reportModuleLabel(String module) {
  switch (module) {
    case 'academic':
      return 'Academic Performance';
    case 'attendance':
      return 'Attendance';
    case 'faculty':
      return 'Faculty Performance';
    case 'placement':
      return 'Placements';
    case 'finance':
      return 'Finance';
    case 'approvals':
      return 'Approvals';
    case 'audit':
      return 'Audit & Compliance';
    default:
      return module;
  }
}

/// Configurator selections, held until the user presses Generate.
final reportModuleSelectionProvider = StateProvider<String>(
  (ref) => reportModules.first,
);

/// CSV, because that is the only format the portal can actually write. The
/// default used to be PDF, which nothing here can produce.
final reportFormatSelectionProvider = StateProvider<ReportFormat>(
  (ref) => ReportFormat.csv,
);

final reportPeriodSelectionProvider = StateProvider<ReportPeriod>(
  (ref) => ReportPeriod.currentSemester,
);
