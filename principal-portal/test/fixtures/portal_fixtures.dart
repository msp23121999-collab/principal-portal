import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:principal_portal/core/services/repository.dart';
import 'package:principal_portal/core/theme/app_icons.dart';
import 'package:principal_portal/features/academic/data/academic_repository.dart';
import 'package:principal_portal/features/academic/models/academic_performance.dart';
import 'package:principal_portal/features/academic/providers/academic_providers.dart';
import 'package:principal_portal/features/approvals/data/approvals_repository.dart';
import 'package:principal_portal/features/approvals/models/approval_request.dart';
import 'package:principal_portal/features/approvals/providers/approvals_providers.dart';
import 'package:principal_portal/features/attendance/data/attendance_repository.dart';
import 'package:principal_portal/features/attendance/models/daily_attendance.dart';
import 'package:principal_portal/features/attendance/providers/attendance_providers.dart';
import 'package:principal_portal/features/circulars/data/circulars_repository.dart';
import 'package:principal_portal/features/circulars/models/circular.dart';
import 'package:principal_portal/features/circulars/providers/circulars_providers.dart';
import 'package:principal_portal/features/dashboard/data/dashboard_repository.dart';
import 'package:principal_portal/features/dashboard/models/dashboard_summary.dart';
import 'package:principal_portal/features/dashboard/models/recent_activity.dart';
import 'package:principal_portal/features/dashboard/providers/dashboard_providers.dart';
import 'package:principal_portal/features/faculty/data/faculty_detail_repository.dart';
import 'package:principal_portal/features/faculty/data/faculty_repository.dart';
import 'package:principal_portal/features/faculty/models/faculty.dart';
import 'package:principal_portal/features/faculty/models/faculty_detail.dart';
import 'package:principal_portal/features/faculty/providers/faculty_providers.dart';
import 'package:principal_portal/features/finance/data/finance_repository.dart';
import 'package:principal_portal/features/finance/models/finance.dart';
import 'package:principal_portal/features/finance/providers/finance_providers.dart';
import 'package:principal_portal/features/institution/data/department_repository.dart';
import 'package:principal_portal/features/institution/data/institution_repository.dart';
import 'package:principal_portal/features/institution/models/department.dart';
import 'package:principal_portal/features/institution/models/institution_overview.dart';
import 'package:principal_portal/features/institution/models/institution_trend.dart';
import 'package:principal_portal/features/institution/providers/institution_providers.dart';
import 'package:principal_portal/features/meetings/data/meetings_repository.dart';
import 'package:principal_portal/features/meetings/models/meeting.dart';
import 'package:principal_portal/features/meetings/providers/meetings_providers.dart';
import 'package:principal_portal/features/reports/data/reports_repository.dart';
import 'package:principal_portal/features/reports/models/report_item.dart';
import 'package:principal_portal/features/reports/models/report_run.dart';
import 'package:principal_portal/features/reports/providers/reports_providers.dart';
import 'package:principal_portal/features/students/data/student_repository.dart';
import 'package:principal_portal/features/students/models/student.dart';
import 'package:principal_portal/features/students/providers/student_providers.dart';

/// Test data for the widget and interaction tests.
///
/// `flutter_test` blocks real network calls, so a test can never reach the
/// database. Since the mock-data files were deleted, `Repository.load` now
/// throws when there is no connection and every screen renders its error
/// state — correct behaviour for the app, but it leaves nothing for a test
/// that wants to click Approve on a request and check what happened.
///
/// These fixtures fill that gap by replacing the repository providers, so
/// everything above them — filters, sorting, pagination, the summary
/// providers, the write-through notifiers — runs its real code against known
/// input. Only the database round trip is replaced.
///
/// **The values are copied from the seeded database, not invented.** Titles,
/// reference numbers, amounts and department figures were read out of the live
/// tables so that a test asserting `'Laboratory Equipment Purchase'` is
/// asserting something the application genuinely shows.
///
/// This is the one place in the repository where data is written by hand
/// rather than read. It is confined to `test/` and no screen can reach it.
///
/// Usage:
///
/// ```dart
/// await tester.pumpWidget(
///   ProviderScope(overrides: portalOverrides(), child: const PrincipalPortalApp()),
/// );
/// ```
/// Writes are kept in memory and returned by the next fetch, exactly as the
/// real repositories persist then re-read. That is what lets a test publish a
/// circular, schedule a meeting or queue a report and then assert it appears:
/// the whole write-then-refresh cycle runs, only the database is replaced.
///
/// Fresh instances every call, so state never leaks between tests.
///
/// [auditTrailFails] makes the approvals fake report that the decision applied
/// but the audit entry did not — the partial-write case the two-statement
/// decision path can genuinely produce against the live database.
List<Override> portalOverrides({bool auditTrailFails = false}) => [
  departmentRepositoryProvider.overrideWithValue(const _FakeDepartments()),
  institutionRepositoryProvider.overrideWithValue(const _FakeInstitution()),
  approvalsRepositoryProvider.overrideWithValue(
    _FakeApprovals(auditTrailFails: auditTrailFails),
  ),
  circularsRepositoryProvider.overrideWithValue(_FakeCirculars()),
  meetingsRepositoryProvider.overrideWithValue(_FakeMeetings()),
  reportsRepositoryProvider.overrideWithValue(_FakeReports()),
  facultyRepositoryProvider.overrideWithValue(const _FakeFaculty()),
  facultyDetailRepositoryProvider.overrideWithValue(
    const _FakeFacultyDetails(),
  ),
  financeRepositoryProvider.overrideWithValue(const _FakeFinance()),
  academicRepositoryProvider.overrideWithValue(const _FakeAcademic()),
  // The Dashboard had no fixture, so every widget test rendered it as seven
  // error cards and nothing ever asserted its contents.
  dashboardRepositoryProvider.overrideWithValue(const _FakeDashboard()),
  attendanceRepositoryProvider.overrideWithValue(const _FakeAttendance()),
  studentRepositoryProvider.overrideWithValue(const _FakeStudents()),
];

/// Stands in for the network round trip.
///
/// Without it every fetch would resolve on the microtask queue and the first
/// rendered frame would already hold data, so the loading skeletons could
/// never be observed — and a skeleton nobody has seen render is an assertion,
/// not a fact. Short enough that `pumpAndSettle` drains it immediately.
const fixtureLatency = Duration(milliseconds: 200);

/// Wraps a value in the shape the providers expect, after a brief delay.
Future<Sourced<T>> _live<T>(T value) async {
  await Future<void>.delayed(fixtureLatency);
  return Sourced(value, DataSource.live);
}

// ---------------------------------------------------------------------------
// Institution — 12 departments, matching `principal.departments`.
// ---------------------------------------------------------------------------

/// Code, name, HOD and rank as seeded. Head counts are the live rollup: only
/// CSE and IOT have students on the roll, which is the real state of
/// `student.students` and is what the Institution screen shows today.
const _departments =
    <
      ({
        String code,
        String name,
        String hod,
        int students,
        int faculty,
        int programs,
        double pass,
        double cgpa,
        double attendance,
        double placement,
        int rank,
      })
    >[
      (
        code: 'IOT',
        name: 'Internet of Things',
        hod: 'Dr. M. Govindharaj',
        students: 4,
        faculty: 6,
        programs: 1,
        pass: 81,
        cgpa: 8.79,
        attendance: 93.98,
        placement: 100,
        rank: 1,
      ),
      (
        code: 'CSE',
        name: 'Computer Science & Engineering',
        hod: 'Dr. K. S. Ravichandran',
        students: 6,
        faculty: 6,
        programs: 4,
        pass: 73,
        cgpa: 8.64,
        attendance: 81.76,
        placement: 83.33,
        rank: 2,
      ),
      (
        code: 'CHEM',
        name: 'Chemical Engineering',
        hod: 'Dr. V. Prakash',
        students: 0,
        faculty: 0,
        programs: 1,
        pass: 87,
        cgpa: 0,
        attendance: 0,
        placement: 0,
        rank: 3,
      ),
      (
        code: 'ECE',
        name: 'Electronics & Communication Engineering',
        hod: 'Dr. S. Meenakshi',
        students: 0,
        faculty: 0,
        programs: 2,
        pass: 86,
        cgpa: 0,
        attendance: 0,
        placement: 0,
        rank: 4,
      ),
      (
        code: 'IT',
        name: 'Information Technology',
        hod: 'Dr. N. Saravanan',
        students: 0,
        faculty: 0,
        programs: 2,
        pass: 85,
        cgpa: 0,
        attendance: 0,
        placement: 0,
        rank: 5,
      ),
      (
        code: 'AIDS',
        name: 'Artificial Intelligence & Data Science',
        hod: 'Dr. R. Kavitha',
        students: 0,
        faculty: 0,
        programs: 1,
        pass: 84,
        cgpa: 0,
        attendance: 0,
        placement: 0,
        rank: 6,
      ),
      (
        code: 'EEE',
        name: 'Electrical & Electronics Engineering',
        hod: 'Dr. P. Vijayakumar',
        students: 0,
        faculty: 0,
        programs: 2,
        pass: 83,
        cgpa: 0,
        attendance: 0,
        placement: 0,
        rank: 7,
      ),
      (
        code: 'MECH',
        name: 'Mechanical Engineering',
        hod: 'Dr. K. Balasubramaniam',
        students: 0,
        faculty: 0,
        programs: 3,
        pass: 82,
        cgpa: 0,
        attendance: 0,
        placement: 0,
        rank: 8,
      ),
      (
        code: 'CIVIL',
        name: 'Civil Engineering',
        hod: 'Dr. A. Rajendran',
        students: 0,
        faculty: 0,
        programs: 2,
        pass: 80,
        cgpa: 0,
        attendance: 0,
        placement: 0,
        rank: 9,
      ),
      (
        code: 'MBA',
        name: 'Master of Business Administration',
        hod: 'Dr. G. Anbarasi',
        students: 0,
        faculty: 0,
        programs: 1,
        pass: 79,
        cgpa: 0,
        attendance: 0,
        placement: 0,
        rank: 10,
      ),
      (
        code: 'MCA',
        name: 'Master of Computer Applications',
        hod: 'Dr. T. Anitha',
        students: 0,
        faculty: 0,
        programs: 1,
        pass: 78,
        cgpa: 0,
        attendance: 0,
        placement: 0,
        rank: 11,
      ),
      (
        code: 'SCI',
        name: 'Science & Humanities',
        hod: 'Dr. R. Jayalakshmi',
        students: 0,
        faculty: 0,
        programs: 1,
        pass: 77,
        cgpa: 0,
        attendance: 0,
        placement: 0,
        rank: 12,
      ),
    ];

class _FakeDepartments implements DepartmentRepository {
  const _FakeDepartments();

  @override
  Future<Sourced<List<Department>>> fetchAll() => _live([
    for (final d in _departments)
      Department(
        id: d.code.toLowerCase(),
        name: d.name,
        shortCode: d.code,
        hodName: d.hod,
        programCount: d.programs,
        facultyCount: d.faculty,
        studentCount: d.students,
        attendancePercent: d.attendance,
        passPercent: d.pass,
        avgCgpa: d.cgpa,
        placementPercent: d.placement,
        rank: d.rank,
      ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInstitution implements InstitutionRepository {
  const _FakeInstitution();

  @override
  Future<Sourced<List<InstitutionKpi>>> fetchKpis() => _live(const [
    InstitutionKpi(
      label: 'Total Students',
      value: '3,696',
      trendPercent: '+5.2%',
      isPositive: true,
    ),
    InstitutionKpi(
      label: 'Total Faculty',
      value: '248',
      trendPercent: '+3.1%',
      isPositive: true,
    ),
  ]);

  @override
  Future<Sourced<List<YearlyMetric>>> fetchTrend(String series) => _live(const [
    YearlyMetric(year: '2023', value: 820),
    YearlyMetric(year: '2024', value: 910),
    YearlyMetric(year: '2025', value: 985),
  ]);

  @override
  Future<Sourced<List<AcademicYear>>> fetchAcademicYears() => _live(const [
    AcademicYear(label: '2026-27', isCurrent: false),
    AcademicYear(label: '2025-26', isCurrent: true),
    AcademicYear(label: '2024-25', isCurrent: false),
    AcademicYear(label: '2023-24', isCurrent: false),
  ]);

  @override
  Future<Sourced<List<FacultyStatusSlice>>> fetchFacultyComposition() =>
      _live(const [
        FacultyStatusSlice(label: 'Permanent', count: 10),
        FacultyStatusSlice(label: 'Contract', count: 2),
      ]);

  @override
  Future<Sourced<List<ProgramLevelEnrolment>>> fetchEnrolment() => _live(const [
    ProgramLevelEnrolment(level: 'UG', currentYear: 3180, previousYear: 3020),
    ProgramLevelEnrolment(level: 'PG', currentYear: 420, previousYear: 398),
    ProgramLevelEnrolment(level: 'Diploma', currentYear: 96, previousYear: 104),
  ]);

  @override
  Future<Sourced<List<SemesterPerformance>>> fetchSemesterPerformance() =>
      _live(const [
        SemesterPerformance(
          semester: 'Semester 1',
          passPercent: 88,
          averageSgpa: 8.1,
        ),
        SemesterPerformance(
          semester: 'Semester 2',
          passPercent: 86,
          averageSgpa: 8.0,
        ),
      ]);

  @override
  Future<Sourced<List<FacilityStat>>> fetchFacilities() => _live(const [
    FacilityStat(icon: AppIcons.department, label: 'Classrooms', count: 96),
    FacilityStat(icon: AppIcons.research, label: 'Laboratories', count: 54),
  ]);

  @override
  Future<Sourced<List<InstitutionHighlight>>> fetchHighlights() => _live(const [
    InstitutionHighlight(
      icon: AppIcons.award,
      title: 'NAAC A++ Accreditation',
      detail: 'Awarded for the 2025 cycle',
    ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Approvals — the four pending requests seeded in the database.
// ---------------------------------------------------------------------------

class _FakeApprovals implements ApprovalsRepository {
  _FakeApprovals({this.auditTrailFails = false});

  /// Simulates the audit-trail write failing while the decision itself lands.
  ///
  /// That split is the whole point of [DecisionOutcome]: the two writes are not
  /// one transaction, so the case where a decision applies and the record of it
  /// does not is reachable in production and has to be reachable in a test.
  final bool auditTrailFails;

  /// Decisions taken during the test, applied on the next fetch.
  final Map<String, ({ApprovalDecision decision, String? remarks})> _decided =
      {};

  @override
  Future<Sourced<List<ApprovalRequest>>> fetchAll() => _live([
    for (final request in _seed)
      if (_decided[request.id] case final taken?)
        request.copyWith(decision: taken.decision, remarks: taken.remarks)
      else
        request,
  ]);

  static final _seed = <ApprovalRequest>[
    ApprovalRequest(
      id: 'req-budget-lab',
      category: ApprovalCategory.budget,
      title: 'Laboratory Equipment Purchase',
      requesterName: 'Dr. K. S. Ravichandran',
      requesterRole: 'HOD',
      departmentCode: 'CSE',
      submittedAt: DateTime(2026, 8, 6),
      summary: 'Eight workstations for the AI laboratory',
      priority: ApprovalPriority.high,
      decision: ApprovalDecision.pending,
      amount: 1840000,
    ),
    ApprovalRequest(
      id: 'req-event-symposium',
      category: ApprovalCategory.event,
      title: 'National Technical Symposium',
      requesterName: 'Dr. N. Saravanan',
      requesterRole: 'HOD',
      departmentCode: 'IT',
      submittedAt: DateTime(2026, 8, 7),
      summary: 'Two-day symposium with 600 expected participants',
      priority: ApprovalPriority.high,
      decision: ApprovalDecision.pending,
    ),
    ApprovalRequest(
      id: 'req-purchase-library',
      category: ApprovalCategory.purchase,
      title: 'Library Journal Subscriptions',
      requesterName: 'Dr. R. Jayalakshmi',
      requesterRole: 'Librarian',
      departmentCode: 'SCI',
      submittedAt: DateTime(2026, 8, 4),
      summary: 'Annual renewal of 42 international journals',
      priority: ApprovalPriority.routine,
      decision: ApprovalDecision.pending,
      amount: 960000,
    ),
    ApprovalRequest(
      id: 'req-academic-fdp',
      category: ApprovalCategory.academic,
      title: 'Faculty Development Programme',
      requesterName: 'Dr. S. Meenakshi',
      requesterRole: 'HOD',
      departmentCode: 'ECE',
      submittedAt: DateTime(2026, 7, 23),
      summary: 'One-week FDP on VLSI design',
      priority: ApprovalPriority.routine,
      decision: ApprovalDecision.pending,
    ),
  ];

  @override
  Future<DecisionOutcome> decide({
    required String requestId,
    required ApprovalDecision decision,
    required ApprovalDecision previousDecision,
    String? remarks,
  }) async {
    // The decision write always lands — a failure there throws in the real
    // repository and never produces an outcome at all.
    _decided[requestId] = (decision: decision, remarks: remarks);

    return auditTrailFails
        ? const DecisionOutcome(
            recorded: false,
            auditError: 'The audit trail refused the entry.',
          )
        : const DecisionOutcome(recorded: true);
  }

  @override
  Future<DecisionOutcome> decideLeave({
    required String leaveId,
    required ApprovalDecision decision,
    required String previousStatus,
    String? remarks,
  }) async {
    return auditTrailFails
        ? const DecisionOutcome(
            recorded: false,
            auditError: 'The audit trail refused the entry.',
          )
        : const DecisionOutcome(recorded: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Circulars
// ---------------------------------------------------------------------------

class _FakeCirculars implements CircularsRepository {
  _FakeCirculars();

  final List<Circular> _added = [];
  final Map<String, CircularStatus> _statuses = {};
  var _nextReference = 4;

  @override
  Future<Sourced<List<Circular>>> fetchAll() => _live([
    for (final c in [..._seed, ..._added])
      if (_statuses[c.id] case final status?) c.copyWith(status: status) else c,
  ]);

  static final _seed = <Circular>[
    Circular(
      id: 'cir-timetable',
      reference: 'KSRCE/PRIN/2026/001',
      title: 'Revised Odd Semester Timetable',
      body: 'The revised timetable takes effect from Monday.',
      category: CircularCategory.academic,
      audience: CircularAudience.everyone,
      status: CircularStatus.published,
      author: 'Dr. S. Venkataraman',
      createdAt: DateTime(2026, 7, 20),
      recipients: 3696,
      acknowledgements: 2840,
      publishedAt: DateTime(2026, 7, 20),
      isPinned: true,
    ),
    Circular(
      id: 'cir-naac',
      reference: 'KSRCE/PRIN/2026/002',
      title: 'NAAC Peer Team Visit Schedule',
      body: 'The peer team visits between the 12th and the 14th.',
      category: CircularCategory.administrative,
      audience: CircularAudience.faculty,
      status: CircularStatus.published,
      author: 'Dr. S. Venkataraman',
      createdAt: DateTime(2026, 7, 18),
      recipients: 248,
      acknowledgements: 210,
      publishedAt: DateTime(2026, 7, 18),
      isPinned: false,
    ),
    Circular(
      id: 'cir-exam-fee',
      reference: 'KSRCE/PRIN/2026/003',
      title: 'Examination Fee Payment Deadline',
      body: 'The deadline is extended by one week.',
      category: CircularCategory.examination,
      audience: CircularAudience.students,
      status: CircularStatus.published,
      author: 'Dr. S. Venkataraman',
      createdAt: DateTime(2026, 7, 10),
      recipients: 3696,
      acknowledgements: 1920,
      publishedAt: DateTime(2026, 7, 10),
      isPinned: false,
    ),
  ];

  @override
  Future<void> publish({
    required String title,
    required String body,
    required CircularCategory category,
    required CircularAudience audience,
    required bool asDraft,
    String? author,
  }) async {
    final n = _nextReference++;
    final padded = n.toString().padLeft(3, '0');
    _added.add(
      Circular(
        id: 'cir-new-$n',
        reference: 'KSRCE/PRIN/2026/$padded',
        title: title,
        body: body,
        category: category,
        audience: audience,
        status: asDraft ? CircularStatus.draft : CircularStatus.published,
        // Mirrors the repository: an unspecified author resolves to the
        // signed-in Principal, and a fixture has no session to resolve to.
        author: author ?? 'Principal',
        createdAt: DateTime.now(),
        recipients: 0,
        acknowledgements: 0,
        publishedAt: asDraft ? null : DateTime.now(),
        isPinned: false,
      ),
    );
  }

  @override
  Future<void> setStatus(String circularId, CircularStatus status) async {
    _statuses[circularId] = status;
  }

  @override
  Future<void> setPinned(String circularId, bool pinned) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Meetings
// ---------------------------------------------------------------------------

class _FakeMeetings implements MeetingsRepository {
  _FakeMeetings();

  final List<Meeting> _added = [];
  final Set<String> _cancelled = {};

  @override
  Future<Sourced<List<Meeting>>> fetchMeetings() => _live([
    for (final m in [..._seed, ..._added])
      if (_cancelled.contains(m.id))
        m.copyWith(status: MeetingStatus.cancelled)
      else
        m,
  ]);

  static final _seed = <Meeting>[
    Meeting(
      id: 'mtg-governing',
      title: 'Governing Council — Q2 Review',
      type: MeetingType.governingCouncil,
      // Comfortably ahead of any plausible test-run date, so this stays in
      // the upcoming list rather than ageing into the past one.
      scheduledAt: DateTime(2099, 3, 12, 10),
      durationMinutes: 120,
      venue: 'Board Room',
      chairperson: 'Dr. S. Venkataraman',
      attendeeCount: 14,
      agenda: const ['Budget review', 'Accreditation readiness'],
      status: MeetingStatus.scheduled,
      minutesRecorded: false,
    ),
    Meeting(
      id: 'mtg-academic',
      title: 'Academic Council Meeting',
      type: MeetingType.academicCouncil,
      scheduledAt: DateTime(2099, 3, 20, 14),
      durationMinutes: 90,
      venue: 'Seminar Hall',
      chairperson: 'Dr. S. Venkataraman',
      attendeeCount: 22,
      agenda: const ['Regulation 2026 approval'],
      status: MeetingStatus.scheduled,
      minutesRecorded: false,
    ),
  ];

  @override
  Future<Sourced<List<MeetingMinutes>>> fetchMinutes() => _live([
    MeetingMinutes(
      meetingId: 'mtg-past-iqac',
      meetingTitle: 'IQAC Review',
      heldOn: DateTime(2026, 6, 18),
      recordedBy: 'Dr. R. Kavitha',
      decisions: const ['Adopt the revised feedback form'],
      openActionItems: 2,
    ),
  ]);

  @override
  Future<Sourced<List<AcademicCalendarEntry>>> fetchCalendar() => _live([
    AcademicCalendarEntry(
      title: 'Semester Examinations Begin',
      from: DateTime(2026, 11, 10),
      to: DateTime(2026, 11, 10),
      type: CalendarEntryType.examination,
      description: 'Odd semester end examinations',
    ),
  ]);

  @override
  Future<void> schedule({
    required String title,
    required MeetingType type,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String venue,
    required String chairperson,
    required List<String> agenda,
  }) async {
    _added.add(
      Meeting(
        id: 'mtg-new-${_added.length}',
        title: title,
        type: type,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        venue: venue,
        chairperson: chairperson,
        attendeeCount: 0,
        agenda: agenda,
        status: MeetingStatus.scheduled,
        minutesRecorded: false,
      ),
    );
  }

  @override
  Future<void> cancel(String meetingId) async {
    _cancelled.add(meetingId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Reports
// ---------------------------------------------------------------------------

class _FakeReports implements ReportsRepository {
  _FakeReports();

  final List<ReportRun> _queued = [];

  @override
  Future<Sourced<List<ReportItem>>> fetchLibrary() => _live([
    ReportItem(
      id: 'rpt-semester',
      title: 'Semester Result Summary',
      category: ReportCategory.academic,
      description: 'Pass percentage and grade distribution by department',
      lastGeneratedAt: DateTime(2026, 7, 30),
    ),
    ReportItem(
      id: 'rpt-attendance',
      title: 'Institution Attendance Summary',
      category: ReportCategory.attendance,
      description: 'Daily, weekly and monthly attendance rollup',
      lastGeneratedAt: DateTime(2026, 8, 1),
    ),
  ]);

  @override
  Future<Sourced<List<ReportRun>>> fetchRuns() =>
      _live([..._queued, ..._seedRuns]);

  static final _seedRuns = <ReportRun>[
    ReportRun(
      id: 'run-1',
      title: 'Semester Result Summary',
      module: 'academic',
      format: ReportFormat.pdf,
      period: ReportPeriod.currentSemester,
      requestedBy: 'Dr. S. Venkataraman',
      requestedAt: DateTime(2026, 8, 5),
      state: ReportRunState.ready,
    ),
  ];

  @override
  Future<Sourced<List<ScheduledReport>>> fetchSchedules() => _live([
    ScheduledReport(
      id: 'sched-1',
      title: 'Monthly Academic Digest',
      module: 'academic',
      frequency: ReportFrequency.monthly,
      format: ReportFormat.pdf,
      nextRun: DateTime(2026, 9, 1),
      recipients: const ['principal@ksrce.ac.in'],
      isEnabled: true,
    ),
  ]);

  @override
  Future<void> requestReport({
    required String title,
    required String module,
    required ReportFormat format,
    required ReportPeriod period,
    String requestedBy = 'Dr. S. Venkataraman',
  }) async {
    _queued.insert(
      0,
      ReportRun(
        id: 'run-new-${_queued.length}',
        title: title,
        module: module,
        format: format,
        period: period,
        requestedBy: requestedBy,
        requestedAt: DateTime.now(),
        state: ReportRunState.queued,
      ),
    );
  }

  @override
  Future<void> setScheduleEnabled(String scheduleId, bool enabled) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Faculty
// ---------------------------------------------------------------------------

const _faculty =
    <
      ({
        String id,
        String name,
        FacultyDesignation designation,
        String dept,
        int years,
        double attendance,
        int papers,
        double score,
      })
    >[
      (
        id: 'EMP_CSE_001',
        name: 'Dr. K. S. Ravichandran',
        designation: FacultyDesignation.professor,
        dept: 'CSE',
        years: 22,
        attendance: 96.4,
        papers: 34,
        score: 92,
      ),
      (
        id: 'EMP_CSE_002',
        name: 'Mr. P. Kalaiyarasan',
        designation: FacultyDesignation.assistantProfessor,
        dept: 'CSE',
        years: 8,
        attendance: 94.1,
        papers: 6,
        score: 84,
      ),
      (
        id: 'EMP_ECE_001',
        name: 'Dr. S. Meenakshi',
        designation: FacultyDesignation.professor,
        dept: 'ECE',
        years: 18,
        attendance: 95.2,
        papers: 27,
        score: 89,
      ),
      (
        id: 'EMP_IOT_001',
        name: 'Dr. M. Govindharaj',
        designation: FacultyDesignation.associateProfessor,
        dept: 'IOT',
        years: 14,
        attendance: 93.8,
        papers: 19,
        score: 87,
      ),
    ];

class _FakeFaculty implements FacultyRepository {
  const _FakeFaculty();

  @override
  Future<Sourced<List<Faculty>>> fetchAll() => _live([
    for (final f in _faculty)
      Faculty(
        id: f.id,
        name: f.name,
        designation: f.designation,
        departmentId: f.dept,
        experienceYears: f.years,
        attendancePercent: f.attendance,
        researchPapersCount: f.papers,
        performanceScore: f.score,
      ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFacultyDetails implements FacultyDetailRepository {
  const _FakeFacultyDetails();

  /// Stands in for `principal.faculty_details`.
  ///
  /// The **first** member is returned with no stored row, falling back to
  /// `FacultyDetail.fromRosterRow` exactly as the real repository does. That is
  /// deliberate: the widget tests must render the unrecorded case, because that
  /// is the case that used to be filled with figures invented from
  /// `id.hashCode` — and the case that must now show an em dash without
  /// throwing or printing `NaN`.
  @override
  Future<Sourced<Map<String, FacultyDetail>>> fetchAll(List<Faculty> roster) =>
      _live({
        for (final (index, faculty) in roster.indexed)
          faculty.id: index == 0
              ? FacultyDetail.fromRosterRow(faculty)
              : FacultyDetail(
                  facultyId: faculty.id,
                  weeklyTeachingHours: 14 + (index % 6),
                  subjectsHandled: 2 + (index % 3),
                  mentees: 18 + index,
                  appraisalScore: faculty.performanceScore,
                  feedbackScore: (faculty.performanceScore / 20).clamp(0, 5),
                  fundedProjects: faculty.researchPapersCount >= 25 ? 2 : 0,
                  qualification: 'Ph.D.',
                  email: 'staff${faculty.id}@example.test',
                ),
      });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Finance
// ---------------------------------------------------------------------------

class _FakeFinance implements FinanceRepository {
  const _FakeFinance();

  @override
  Future<Sourced<List<FinanceKpi>>> fetchKpis() => _live(const [
    FinanceKpi(
      label: 'Fee Collected',
      value: '₹32.4 Cr',
      trend: '+6.1%',
      isPositive: true,
    ),
  ]);

  @override
  Future<Sourced<List<MonthlyFinance>>> fetchMonthlyPosition() => _live(const [
    MonthlyFinance(month: 'Jan', revenue: 12000000, expenditure: 9500000),
    MonthlyFinance(month: 'Feb', revenue: 11400000, expenditure: 9800000),
    MonthlyFinance(month: 'Mar', revenue: 13100000, expenditure: 10200000),
  ]);

  @override
  Future<Sourced<List<DepartmentFeeStatus>>> fetchDepartmentFees() =>
      _live(const [
        DepartmentFeeStatus(
          departmentCode: 'CSE',
          departmentName: 'Computer Science & Engineering',
          studentsTotal: 840,
          studentsPaid: 792,
          demand: 77280000,
          collected: 72864000,
        ),
        DepartmentFeeStatus(
          departmentCode: 'ECE',
          departmentName: 'Electronics & Communication Engineering',
          studentsTotal: 520,
          studentsPaid: 460,
          demand: 47840000,
          collected: 42320000,
        ),
      ]);

  @override
  Future<Sourced<List<PaymentModeSplit>>> fetchPaymentModes() => _live(const [
    PaymentModeSplit(mode: 'Net Banking', amount: 18400000),
    PaymentModeSplit(mode: 'UPI', amount: 12600000),
  ]);

  @override
  Future<Sourced<List<ScholarshipScheme>>> fetchScholarships() => _live(const [
    ScholarshipScheme(
      name: 'First Graduate Scholarship',
      sponsor: 'Government of Tamil Nadu',
      beneficiaries: 486,
      sanctioned: 14580000,
      disbursed: 13120000,
    ),
    ScholarshipScheme(
      name: 'Post Matric SC/ST Scholarship',
      sponsor: 'Government of India',
      beneficiaries: 312,
      sanctioned: 10920000,
      disbursed: 9840000,
    ),
  ]);

  @override
  Future<Sourced<List<PayrollLine>>> fetchPayroll() => _live(const [
    PayrollLine(category: 'Teaching', headcount: 248, monthlyCost: 24800000),
    PayrollLine(category: 'Non-Teaching', headcount: 96, monthlyCost: 5760000),
  ]);

  @override
  Future<Sourced<List<ExpenditureHead>>> fetchExpenditure() => _live(const [
    ExpenditureHead(head: 'Salaries', budgeted: 367200000, actual: 351400000),
    ExpenditureHead(
      head: 'Infrastructure',
      budgeted: 48000000,
      actual: 41200000,
    ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Academic
// ---------------------------------------------------------------------------

class _FakeAcademic implements AcademicRepository {
  const _FakeAcademic();

  @override
  Future<Sourced<List<AcademicKpi>>> fetchKpis() => _live(const [
    AcademicKpi(
      label: 'Overall Pass Rate',
      value: '84.2%',
      trend: '+2.4%',
      isPositive: true,
    ),
  ]);

  @override
  Future<Sourced<DepartmentPassComparison>> fetchDepartmentPassRates() =>
      _live((
        currentLabel: 'Semester 6',
        previousLabel: 'Semester 5',
        rates: const [
          DepartmentPassRate(
            department: 'CSE',
            currentPercent: 73,
            previousPercent: 71,
          ),
          DepartmentPassRate(
            department: 'IOT',
            currentPercent: 81,
            previousPercent: 78,
          ),
        ],
      ));

  @override
  Future<Sourced<List<SemesterSummary>>> fetchSemesterSummaries() =>
      _live(const [
        SemesterSummary(
          semester: 'Semester 1',
          appeared: 920,
          passed: 810,
          averageSgpa: 8.1,
          averageCgpa: 8.0,
          backlogs: 110,
          topPerformer: 'Aravind Kumar S',
          topPerformerCgpa: 9.4,
        ),
        SemesterSummary(
          semester: 'Semester 2',
          appeared: 905,
          passed: 782,
          averageSgpa: 8.0,
          averageCgpa: 8.0,
          backlogs: 123,
          topPerformer: 'Divya Bharathi R',
          topPerformerCgpa: 9.3,
        ),
      ]);

  @override
  Future<Sourced<List<SubjectResult>>> fetchSubjectResults() => _live(const [
    SubjectResult(
      code: 'CS8491',
      name: 'Computer Architecture',
      departmentCode: 'CSE',
      semester: 'Semester 1',
      faculty: 'Dr. K. S. Ravichandran',
      appeared: 120,
      passed: 108,
      averageMarks: 68.4,
    ),
    SubjectResult(
      code: 'EC8351',
      name: 'Electronic Circuits',
      departmentCode: 'ECE',
      semester: 'Semester 2',
      faculty: 'Dr. S. Meenakshi',
      appeared: 96,
      passed: 84,
      averageMarks: 64.2,
    ),
  ]);

  @override
  Future<Sourced<List<SgpaBand>>> fetchSgpaBands() => _live(const [
    SgpaBand(label: '9.0 - 10.0', studentCount: 210),
    SgpaBand(label: '8.0 - 8.99', studentCount: 640),
    SgpaBand(label: 'Below 6.0', studentCount: 96),
  ]);

  @override
  Future<Sourced<List<GradeSlice>>> fetchGradeSlices() => _live(const [
    GradeSlice(grade: 'O', studentCount: 210),
    GradeSlice(grade: 'A+', studentCount: 460),
  ]);

  @override
  Future<Sourced<List<AttainmentLevel>>> fetchAttainmentLevels() =>
      _live(const [
        AttainmentLevel(
          label: 'High',
          courseOutcomes: 148,
          programOutcomes: 22,
        ),
        AttainmentLevel(
          label: 'Moderate',
          courseOutcomes: 96,
          programOutcomes: 14,
        ),
      ]);

  @override
  Future<Sourced<List<AtRiskReason>>> fetchAtRiskReasons() => _live(const [
    AtRiskReason(reason: 'Attendance below 75%', studentCount: 84),
    AtRiskReason(reason: 'Two or more backlogs', studentCount: 62),
  ]);

  @override
  Future<Sourced<List<YearlyPassRate>>> fetchYearlyPassRates() => _live(const [
    YearlyPassRate(year: '2024', passPercent: 81.4),
    YearlyPassRate(year: '2025', passPercent: 83.1),
    YearlyPassRate(year: '2026', passPercent: 84.2),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

/// Stands in for `principal.v_dashboard_summary`.
///
/// The Dashboard was the one screen with no fixture, so every widget test
/// rendered it as seven "Something went wrong" cards — which is also why
/// nothing had ever asserted what it shows.
///
/// The figures deliberately mirror the live database's awkward shape: more
/// placements than students, so the placement percentage is unstateable, and a
/// register covering fewer people than the roster.
class _FakeDashboard implements DashboardRepository {
  const _FakeDashboard();

  @override
  Future<Sourced<DashboardSummary>> fetch({
    required List<Department> departments,
  }) {
    final ranked = [...departments]..sort((a, b) => a.rank.compareTo(b.rank));

    return _live(
      DashboardSummary(
        institutionOverview: const InstitutionOverview(
          totalStudents: 10,
          totalFaculty: 16,
          totalDepartments: 12,
        ),
        departmentRows: [
          for (final d in ranked)
            DepartmentSummaryRow(
              name: d.name,
              shortCode: d.shortCode,
              studentCount: d.studentCount,
              attendancePercent: d.attendancePercent,
              rank: d.rank,
            ),
        ],
        facultySummary: const FacultySummary(
          totalFaculty: 16,
          averageExperienceYears: 0,
          averageAttendancePercent: 86.3,
          totalResearchPapers: 0,
        ),
        studentSummary: const StudentSummary(
          totalStudents: 10,
          averageCgpa: 8.7,
          averageAttendancePercent: 86.3,
          topPerformerCount: 8,
          atRiskCount: 2,
        ),
        todayAttendancePercent: 91.4,
        resultSummary: ResultSummary(
          semesterLabel: 'Semester 8 — 2025-26',
          overallPassPercent: 91.4,
          byDepartment: [
            for (final d in ranked)
              (departmentCode: d.shortCode, passPercent: d.passPercent),
          ],
        ),
        // 60 offers against a 10-student roll: no honest percentage, which is
        // exactly the case the card has to handle.
        placementSummary: const PlacementSummary(
          totalEligible: 10,
          totalPlaced: 60,
          placementPercent: null,
          averagePackageLpa: 8.4,
          highestPackageLpa: 42,
          topRecruiter: '—',
        ),
      ),
    );
  }

  @override
  Future<Sourced<List<RecentActivity>>> fetchRecentActivity() => _live([
    RecentActivity(
      icon: AppIcons.check,
      title: 'Approved laboratory equipment purchase for CSE',
      subtitle: 'Dr. K. S. Ravichandran · Approvals',
      timestamp: DateTime(2026, 8, 8),
    ),
    RecentActivity(
      icon: AppIcons.notifications,
      title: 'Published the semester examination circular',
      subtitle: 'Principal · Circulars',
      timestamp: DateTime(2026, 8, 6),
    ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The daily attendance trend the Dashboard KPI and Attendance Analytics read.
class _FakeAttendance implements AttendanceRepository {
  const _FakeAttendance();

  @override
  Future<Sourced<List<DailyAttendance>>> fetchDailyTrend({
    String? departmentCode,
  }) => _live(const [
    DailyAttendance(label: '7/8', percent: 88.2),
    DailyAttendance(label: '8/8', percent: 90.1),
    DailyAttendance(label: '11/8', percent: 91.4),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Students
// ---------------------------------------------------------------------------

/// Stands in for `student.students`.
///
/// There was no student fixture, so `studentListProvider` threw in every test
/// and every filter option list came back empty — which made any test of the
/// filter row pass without exercising it.
///
/// The two departments carry **different batches on purpose**: CSE admitted
/// 2022, IOT admitted 2021. That is what makes the cascade testable, because
/// selecting a CSE batch and then switching to IOT leaves a value the batch
/// dropdown no longer offers.
class _FakeStudents implements StudentRepository {
  const _FakeStudents();

  @override
  Future<Sourced<List<Student>>> fetchAll() => _live(const [
    Student(
      id: '22CSE001',
      name: 'A. Priya',
      rollNumber: '22CSE001',
      departmentId: 'CSE',
      semester: 5,
      cgpa: 9.1,
      attendancePercent: 92,
      isTopPerformer: true,
      isAtRisk: false,
      degree: 'B.E',
      batch: '2022',
      yearOfStudy: 'III',
    ),
    Student(
      id: '22CSE002',
      name: 'B. Karthik',
      rollNumber: '22CSE002',
      departmentId: 'CSE',
      semester: 5,
      cgpa: 6.1,
      attendancePercent: 68,
      isTopPerformer: false,
      isAtRisk: true,
      degree: 'B.E',
      batch: '2022',
      yearOfStudy: 'III',
    ),
    Student(
      id: '22CSE003',
      name: 'C. Meena',
      rollNumber: '22CSE003',
      departmentId: 'CSE',
      semester: 7,
      cgpa: 8.6,
      attendancePercent: 88,
      isTopPerformer: true,
      isAtRisk: false,
      degree: 'M.E',
      batch: '2022',
      yearOfStudy: 'IV',
    ),
    Student(
      id: '2021IOT001',
      name: 'D. Ravi',
      rollNumber: '2021IOT001',
      departmentId: 'IOT',
      semester: 8,
      cgpa: 8.8,
      attendancePercent: 94,
      isTopPerformer: true,
      isAtRisk: false,
      degree: 'B.Tech',
      batch: '2021',
      yearOfStudy: 'IV',
    ),
    Student(
      id: '2021IOT002',
      name: 'E. Lakshmi',
      rollNumber: '2021IOT002',
      departmentId: 'IOT',
      semester: 8,
      cgpa: 8.9,
      attendancePercent: 96,
      isTopPerformer: true,
      isAtRisk: false,
      degree: 'B.Tech',
      batch: '2021',
      yearOfStudy: 'IV',
    ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
