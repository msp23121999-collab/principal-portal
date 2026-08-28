import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/examination_repository.dart';
import '../models/examination.dart';

final examinationRepositoryProvider = Provider(
  (ref) => const ExaminationRepository(),
);

/// Stage filter for the timetable, null meaning every stage.
final examStageFilterProvider = StateProvider<ExamStage?>((ref) => null);

final _allExamSchedulesProvider = FutureProvider<List<ExamSchedule>>((
  ref,
) async {
  return (await ref.watch(examinationRepositoryProvider).fetchSchedule()).value;
});

/// Timetable narrowed by the stage dropdown.
///
/// Filtered in Dart rather than re-queried: the schedule is forty rows, and
/// the user flicks between stages faster than a round trip.
final examScheduleProvider = FutureProvider<List<ExamSchedule>>((ref) async {
  final stage = ref.watch(examStageFilterProvider);
  final schedule = await ref.watch(_allExamSchedulesProvider.future);
  if (stage == null) return schedule;
  return schedule.where((exam) => exam.stage == stage).toList();
});

final ciaProgressProvider = FutureProvider<List<CiaProgress>>((ref) async {
  return (await ref.watch(examinationRepositoryProvider).fetchCiaProgress())
      .value;
});

final hallTicketStatusProvider = FutureProvider<List<HallTicketStatus>>((
  ref,
) async {
  return (await ref.watch(examinationRepositoryProvider).fetchHallTickets())
      .value;
});

final resultPublicationProvider = FutureProvider<List<ResultPublication>>((
  ref,
) async {
  return (await ref.watch(examinationRepositoryProvider).fetchPublications())
      .value;
});

/// Where the current examination cycle stands, for the KPI row.
///
/// Derived from the four lists the tabs already show rather than stored, so a
/// figure in the header can never contradict the table underneath it. Kept
/// unfiltered — these describe the cycle, not the current stage selection.
typedef ExaminationSummary = ({
  int papersYetToBeHeld,
  int totalCandidates,
  int hallTicketsIssued,
  int hallTicketsWithheld,
  double averageCiaCompletion,
  int resultsPublished,
  int resultsTotal,
});

final examinationSummaryProvider = FutureProvider<ExaminationSummary>((
  ref,
) async {
  final schedules = await ref.watch(_allExamSchedulesProvider.future);
  final cia = await ref.watch(ciaProgressProvider.future);
  final tickets = await ref.watch(hallTicketStatusProvider.future);
  final publications = await ref.watch(resultPublicationProvider.future);

  // A paper is still to be held while it is scheduled or under way. Once it is
  // completed, evaluated or published it is behind the institution.
  final pending = schedules.where(
    (s) => s.stage == ExamStage.scheduled || s.stage == ExamStage.inProgress,
  );

  return (
    papersYetToBeHeld: pending.length,
    totalCandidates: schedules.fold(0, (sum, s) => sum + s.candidates),
    hallTicketsIssued: tickets.fold(0, (sum, t) => sum + t.issued),
    hallTicketsWithheld: tickets.fold(0, (sum, t) => sum + t.withheld),
    // Weighted by marks expected, so a large department's entry backlog is not
    // hidden behind a small department that has finished.
    averageCiaCompletion: () {
      final expected = cia.fold(0, (sum, c) => sum + c.marksExpected);
      if (expected == 0) return 0.0;
      return cia.fold(0, (sum, c) => sum + c.marksEntered) / expected * 100;
    }(),
    resultsPublished: publications
        .where((p) => p.stage == ExamStage.published)
        .length,
    resultsTotal: publications.length,
  );
});
