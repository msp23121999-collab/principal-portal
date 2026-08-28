/// Where an exam sitting has reached in its lifecycle.
enum ExamStage { scheduled, inProgress, completed, evaluated, published }

extension ExamStageX on ExamStage {
  String get label {
    switch (this) {
      case ExamStage.scheduled:
        return 'Scheduled';
      case ExamStage.inProgress:
        return 'In Progress';
      case ExamStage.completed:
        return 'Completed';
      case ExamStage.evaluated:
        return 'Evaluated';
      case ExamStage.published:
        return 'Published';
    }
  }
}

/// A single paper on the examination timetable.
class ExamSchedule {
  const ExamSchedule({
    required this.subjectCode,
    required this.subjectName,
    required this.departmentCode,
    required this.semester,
    required this.date,
    required this.session,
    required this.durationMinutes,
    required this.hall,
    required this.candidates,
    required this.stage,
  });

  final String subjectCode;
  final String subjectName;
  final String departmentCode;
  final String semester;
  final DateTime date;

  /// Forenoon or Afternoon.
  final String session;

  final int durationMinutes;
  final String hall;
  final int candidates;
  final ExamStage stage;
}

/// How far a department has progressed through the three continuous
/// internal assessments.
class CiaProgress {
  const CiaProgress({
    required this.departmentCode,
    required this.departmentName,
    required this.cia1Percent,
    required this.cia2Percent,
    required this.cia3Percent,
    required this.marksEntered,
    required this.marksExpected,
  });

  final String departmentCode;
  final String departmentName;
  final double cia1Percent;
  final double cia2Percent;
  final double cia3Percent;
  final int marksEntered;
  final int marksExpected;

  double get averagePercent => (cia1Percent + cia2Percent + cia3Percent) / 3;

  double get entryPercent =>
      marksExpected == 0 ? 0 : marksEntered / marksExpected * 100;
}

/// Hall-ticket issue position for one department.
class HallTicketStatus {
  const HallTicketStatus({
    required this.departmentCode,
    required this.departmentName,
    required this.eligible,
    required this.issued,
    required this.withheld,
  });

  final String departmentCode;
  final String departmentName;
  final int eligible;
  final int issued;

  /// Held back for attendance shortfall or unpaid dues.
  final int withheld;

  int get pending => eligible - issued - withheld;

  double get issuedPercent => eligible == 0 ? 0 : issued / eligible * 100;
}

/// Result publication position for one semester's examination.
class ResultPublication {
  const ResultPublication({
    required this.semester,
    required this.examEndedOn,
    required this.papersTotal,
    required this.papersEvaluated,
    required this.publishedOn,
    required this.stage,
  });

  final String semester;
  final DateTime examEndedOn;
  final int papersTotal;
  final int papersEvaluated;

  /// Null until the result is actually published.
  final DateTime? publishedOn;

  final ExamStage stage;

  double get evaluationPercent =>
      papersTotal == 0 ? 0 : papersEvaluated / papersTotal * 100;
}
