/// Output formats a report can be produced in.
enum ReportFormat { pdf, excel, csv }

extension ReportFormatX on ReportFormat {
  String get label {
    switch (this) {
      case ReportFormat.pdf:
        return 'PDF';
      case ReportFormat.excel:
        return 'Excel';
      case ReportFormat.csv:
        return 'CSV';
    }
  }
}

/// Period a report covers.
enum ReportPeriod { currentSemester, currentYear, lastYear, custom }

extension ReportPeriodX on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.currentSemester:
        return 'Current Semester';
      case ReportPeriod.currentYear:
        return 'Current Academic Year';
      case ReportPeriod.lastYear:
        return 'Previous Academic Year';
      case ReportPeriod.custom:
        return 'Custom Range';
    }
  }
}

/// Where a requested report has got to.
enum ReportRunState { queued, generating, ready, failed }

extension ReportRunStateX on ReportRunState {
  String get label {
    switch (this) {
      case ReportRunState.queued:
        return 'Queued';
      case ReportRunState.generating:
        return 'Generating';
      case ReportRunState.ready:
        return 'Ready';
      case ReportRunState.failed:
        return 'Failed';
    }
  }
}

/// One produced report, sitting in the recently-generated list.
class ReportRun {
  const ReportRun({
    required this.id,
    required this.title,
    required this.module,
    required this.format,
    required this.period,
    required this.requestedBy,
    required this.requestedAt,
    required this.state,
    this.sizeKb,
  });

  final String id;
  final String title;

  /// Portal area the report draws from.
  final String module;

  final ReportFormat format;
  final ReportPeriod period;
  final String requestedBy;
  final DateTime requestedAt;
  final ReportRunState state;

  /// Null until the report finishes generating.
  final int? sizeKb;

  String get formattedSize {
    if (sizeKb == null) return '—';
    if (sizeKb! >= 1024) return '${(sizeKb! / 1024).toStringAsFixed(1)} MB';
    return '$sizeKb KB';
  }
}

/// How often a scheduled report runs.
enum ReportFrequency { daily, weekly, monthly, semester }

extension ReportFrequencyX on ReportFrequency {
  String get label {
    switch (this) {
      case ReportFrequency.daily:
        return 'Daily';
      case ReportFrequency.weekly:
        return 'Weekly';
      case ReportFrequency.monthly:
        return 'Monthly';
      case ReportFrequency.semester:
        return 'Every Semester';
    }
  }
}

/// A report set to produce itself on a recurring basis.
class ScheduledReport {
  const ScheduledReport({
    required this.id,
    required this.title,
    required this.module,
    required this.frequency,
    required this.format,
    required this.nextRun,
    required this.recipients,
    required this.isEnabled,
  });

  final String id;
  final String title;
  final String module;
  final ReportFrequency frequency;
  final ReportFormat format;
  final DateTime nextRun;

  /// Roles the output is circulated to.
  final List<String> recipients;

  final bool isEnabled;

  ScheduledReport copyWith({bool? isEnabled}) {
    return ScheduledReport(
      id: id,
      title: title,
      module: module,
      frequency: frequency,
      format: format,
      nextRun: nextRun,
      recipients: recipients,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
