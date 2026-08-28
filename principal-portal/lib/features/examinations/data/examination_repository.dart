import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/examination.dart';

/// Reads Examination Monitoring from `principal`.
///
/// `timetable.class_timetables` holds the *class* timetable — periods per day
/// per section — which is a different thing from an exam schedule, so exams
/// get their own table rather than being squeezed into someone else's shape.
class ExaminationRepository extends Repository {
  const ExaminationRepository();

  /// Enum values are stored as snake_case text to match the database CHECK
  /// constraints; Dart spells them in camelCase. This is the single place the
  /// two conventions meet.
  static ExamStage _stageFrom(String? value) {
    switch (value) {
      case 'in_progress':
        return ExamStage.inProgress;
      case 'completed':
        return ExamStage.completed;
      case 'evaluated':
        return ExamStage.evaluated;
      case 'published':
        return ExamStage.published;
      default:
        return ExamStage.scheduled;
    }
  }

  Future<Sourced<List<ExamSchedule>>> fetchSchedule() {
    return load<List<ExamSchedule>>(
      debugLabel: 'principal.exam_schedules',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('exam_schedules')
            .select('*, departments(code)')
            .order('exam_date', ascending: true);

        return [
          for (final raw in rows) _toSchedule(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Future<Sourced<List<CiaProgress>>> fetchCiaProgress() {
    return load<List<CiaProgress>>(
      debugLabel: 'principal.cia_progress',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('cia_progress').select('*, departments(code, name)');

        return [for (final raw in rows) _toCia(Map<String, dynamic>.from(raw))];
      },
    );
  }

  Future<Sourced<List<HallTicketStatus>>> fetchHallTickets() {
    return load<List<HallTicketStatus>>(
      debugLabel: 'principal.hall_ticket_status',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('hall_ticket_status').select('*, departments(code, name)');

        return [
          for (final raw in rows) _toHallTicket(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Future<Sourced<List<ResultPublication>>> fetchPublications() {
    return load<List<ResultPublication>>(
      debugLabel: 'principal.result_publications',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('result_publications')
            .select()
            .order('exam_ended_on', ascending: false);

        return [
          for (final raw in rows)
            _toPublication(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  String _deptField(Map<String, dynamic> row, String field) {
    final dept = row['departments'];
    if (dept is Map) {
      return Map<String, dynamic>.from(dept).strOr(field, '');
    }
    return '';
  }

  ExamSchedule _toSchedule(Map<String, dynamic> row) => ExamSchedule(
    subjectCode: row.strOr('subject_code', ''),
    subjectName: row.strOr('subject_name', ''),
    departmentCode: _deptField(row, 'code'),
    semester: row.strOr('semester', ''),
    date: row.dateOr('exam_date', DateTime.now()),
    session: row.strOr('session', 'FN'),
    durationMinutes: row.intOr('duration_minutes', 180),
    hall: row.strOr('hall', '—'),
    candidates: row.intOr('candidates', 0),
    stage: _stageFrom(row.str('stage')),
  );

  CiaProgress _toCia(Map<String, dynamic> row) => CiaProgress(
    departmentCode: _deptField(row, 'code'),
    departmentName: _deptField(row, 'name'),
    cia1Percent: row.doubleOr('cia1_percent', 0),
    cia2Percent: row.doubleOr('cia2_percent', 0),
    cia3Percent: row.doubleOr('cia3_percent', 0),
    marksEntered: row.intOr('marks_entered', 0),
    marksExpected: row.intOr('marks_expected', 0),
  );

  HallTicketStatus _toHallTicket(Map<String, dynamic> row) => HallTicketStatus(
    departmentCode: _deptField(row, 'code'),
    departmentName: _deptField(row, 'name'),
    eligible: row.intOr('eligible', 0),
    issued: row.intOr('issued', 0),
    withheld: row.intOr('withheld', 0),
  );

  ResultPublication _toPublication(Map<String, dynamic> row) =>
      ResultPublication(
        semester: row.strOr('semester', ''),
        examEndedOn: row.dateOr('exam_ended_on', DateTime.now()),
        papersTotal: row.intOr('papers_total', 0),
        papersEvaluated: row.intOr('papers_evaluated', 0),
        // Genuinely null until the result is published — not defaulted to a
        // date, which would claim a publication that has not happened.
        publishedOn: row.str('published_on') == null
            ? null
            : row.dateOr('published_on', DateTime.now()),
        stage: _stageFrom(row.str('stage')),
      );
}
