import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/report_item.dart';
import '../models/report_run.dart';

/// Reads and writes the Reports screen.
///
/// IMPORTANT: no file is ever produced. These tables record that a report was
/// requested and what state it is in; rendering an actual PDF or spreadsheet
/// needs a backend that does not exist yet. Requesting a report therefore
/// leaves a row in `queued` that nothing will pick up — which is honest, and
/// better than a download button that silently does nothing.
class ReportsRepository extends Repository {
  const ReportsRepository();

  static ReportCategory _categoryFrom(String? value) {
    switch (value) {
      case 'attendance':
        return ReportCategory.attendance;
      case 'faculty':
        return ReportCategory.faculty;
      case 'placement':
        return ReportCategory.placement;
      default:
        return ReportCategory.academic;
    }
  }

  static ReportFormat _formatFrom(String? value) {
    switch (value) {
      case 'excel':
        return ReportFormat.excel;
      case 'csv':
        return ReportFormat.csv;
      default:
        return ReportFormat.pdf;
    }
  }

  static String formatTo(ReportFormat format) => switch (format) {
    ReportFormat.excel => 'excel',
    ReportFormat.csv => 'csv',
    ReportFormat.pdf => 'pdf',
  };

  static ReportPeriod _periodFrom(String? value) {
    switch (value) {
      case 'current_year':
        return ReportPeriod.currentYear;
      case 'last_year':
        return ReportPeriod.lastYear;
      case 'custom':
        return ReportPeriod.custom;
      default:
        return ReportPeriod.currentSemester;
    }
  }

  static String periodTo(ReportPeriod period) => switch (period) {
    ReportPeriod.currentYear => 'current_year',
    ReportPeriod.lastYear => 'last_year',
    ReportPeriod.custom => 'custom',
    ReportPeriod.currentSemester => 'current_semester',
  };

  static ReportRunState _stateFrom(String? value) {
    switch (value) {
      case 'generating':
        return ReportRunState.generating;
      case 'ready':
        return ReportRunState.ready;
      case 'failed':
        return ReportRunState.failed;
      default:
        return ReportRunState.queued;
    }
  }

  static ReportFrequency _frequencyFrom(String? value) {
    switch (value) {
      case 'weekly':
        return ReportFrequency.weekly;
      case 'monthly':
        return ReportFrequency.monthly;
      case 'semester':
        return ReportFrequency.semester;
      default:
        return ReportFrequency.daily;
    }
  }

  Future<Sourced<List<ReportItem>>> fetchLibrary() {
    return load<List<ReportItem>>(
      debugLabel: 'principal.report_items',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('report_items').select().order('title', ascending: true);

        return [
          for (final raw in rows)
            ReportItem(
              id: Map<String, dynamic>.from(raw).strOr('id', ''),
              title: Map<String, dynamic>.from(raw).strOr('title', ''),
              category: _categoryFrom(
                Map<String, dynamic>.from(raw).str('category'),
              ),
              description: Map<String, dynamic>.from(
                raw,
              ).strOr('description', ''),
              lastGeneratedAt: Map<String, dynamic>.from(
                raw,
              ).dateOr('last_generated_at', DateTime.now()),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<ReportRun>>> fetchRuns() {
    return load<List<ReportRun>>(
      debugLabel: 'principal.report_runs',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('report_runs').select().order('requested_at', ascending: false);

        return [for (final raw in rows) _toRun(Map<String, dynamic>.from(raw))];
      },
    );
  }

  Future<Sourced<List<ScheduledReport>>> fetchSchedules() {
    return load<List<ScheduledReport>>(
      debugLabel: 'principal.scheduled_reports',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('scheduled_reports')
            .select('*, scheduled_report_recipients(email)')
            .order('next_run', ascending: true);

        return [
          for (final raw in rows) _toSchedule(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  /// Records a report request. The row lands in `queued` and stays there —
  /// there is no generator behind it yet.
  Future<void> requestReport({
    required String title,
    required String module,
    required ReportFormat format,
    required ReportPeriod period,
  }) {
    return insertRow('report_runs', {
      'title': title,
      'module': module,
      'format': formatTo(format),
      'period': periodTo(period),
      'state': 'queued',
    });
  }

  Future<void> setScheduleEnabled(String scheduleId, bool enabled) {
    return updateRow('scheduled_reports', scheduleId, {'is_enabled': enabled});
  }

  ReportRun _toRun(Map<String, dynamic> row) => ReportRun(
    id: row.strOr('id', ''),
    title: row.strOr('title', ''),
    module: row.strOr('module', ''),
    format: _formatFrom(row.str('format')),
    period: _periodFrom(row.str('period')),
    requestedBy: row.strOr('requested_by', 'principal'),
    requestedAt: row.dateOr('requested_at', DateTime.now()),
    state: _stateFrom(row.str('state')),
    // Null until a file exists — which, for now, is always.
    sizeKb: row.str('size_kb') == null ? null : row.intOr('size_kb', 0),
  );

  ScheduledReport _toSchedule(Map<String, dynamic> row) {
    final recipients = <String>[];
    final raw = row['scheduled_report_recipients'];
    if (raw is List) {
      for (final entry in raw) {
        final email = Map<String, dynamic>.from(
          entry as Map,
        ).strOr('email', '');
        if (email.isNotEmpty) recipients.add(email);
      }
    }

    return ScheduledReport(
      id: row.strOr('id', ''),
      title: row.strOr('title', ''),
      module: row.strOr('module', ''),
      frequency: _frequencyFrom(row.str('frequency')),
      format: _formatFrom(row.str('format')),
      nextRun: row.dateOr('next_run', DateTime.now()),
      recipients: recipients,
      isEnabled: row.boolOr('is_enabled', true),
    );
  }
}
